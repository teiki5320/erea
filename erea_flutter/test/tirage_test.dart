import 'package:erea/core/progression.dart';
import 'package:erea/core/rng.dart';
import 'package:erea/core/scoring.dart';
import 'package:erea/core/timeline_scale.dart';
import 'package:erea/data/events_repository.dart';
import 'package:erea/game/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Composition d'une partie : les quotas par niveau doivent rendre TOUTE
/// la base atteignable (le tirage par tranches condamnait 40 % des
/// événements) tout en respectant l'esprit de chaque difficulté.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventsRepository repo;

  setUpAll(() async {
    repo = await EventsRepository.load();
  });

  /// Niveaux rencontrés sur un grand nombre de parties.
  Set<int> niveauxVus(String catKey, Difficulty diff, {int parties = 200}) {
    final vus = <int>{};
    for (var i = 0; i < parties; i++) {
      for (final e in repo.pick(catKey, diff)) {
        vus.add(e.niveau);
      }
    }
    return vus;
  }

  test('le niveau 3 est réellement tiré en Normal', () {
    expect(niveauxVus('tout', Difficulty.normal), contains(3),
        reason: '40 % de la base était inatteignable');
  });

  test('le niveau 2 est réellement tiré en Difficile et en Facile', () {
    expect(niveauxVus('tout', Difficulty.difficile), contains(2));
    expect(niveauxVus('tout', Difficulty.facile), contains(2));
  });

  test('Facile ne sert jamais de niveau 3 (SPEC §3)', () {
    expect(niveauxVus('tout', Difficulty.facile), isNot(contains(3)));
  });

  test('Difficile ne sert jamais de niveau 1 (SPEC §3)', () {
    expect(niveauxVus('tout', Difficulty.difficile), isNot(contains(1)));
  });

  test('la difficulté moyenne monte bien de Facile à Difficile', () {
    double moyenne(Difficulty d) {
      var somme = 0;
      var n = 0;
      for (var i = 0; i < 100; i++) {
        for (final e in repo.pick('tout', d)) {
          somme += e.niveau;
          n++;
        }
      }
      return somme / n;
    }

    final facile = moyenne(Difficulty.facile);
    final normal = moyenne(Difficulty.normal);
    final difficile = moyenne(Difficulty.difficile);
    expect(facile, lessThan(normal));
    expect(normal, lessThan(difficile));
  });

  test('toutes les catégories et tous les packs remplissent 10 manches', () {
    for (final p in [...categories, ...packs]) {
      for (final d in Difficulty.values) {
        expect(repo.pick(p.key, d).length, rounds, reason: '${p.label} / $d');
      }
    }
  });

  test('un tirage ne contient jamais deux fois le même événement', () {
    for (final d in Difficulty.values) {
      for (var i = 0; i < 50; i++) {
        final picked = repo.pick('tout', d);
        expect(picked.map((e) => e.id).toSet().length, picked.length);
      }
    }
  });

  test('plusieurs parties d’affilée dans une petite catégorie sans redite',
      () {
    // Le tirage par tranches resservait du déjà-vu dès la 3e partie parce
    // qu'un niveau à court de frais ne cédait pas la place aux autres.
    for (final cat in ['sciences', 'pouvoir', 'arts', 'quotidien']) {
      for (final d in Difficulty.values) {
        final seen = <int>{};
        for (var partie = 1; partie <= 6; partie++) {
          final picked = repo.pick(cat, d, seen: seen);
          final redites = picked.where((e) => seen.contains(e.id)).length;
          expect(redites, 0, reason: '$cat / $d, partie $partie');
          seen.addAll(picked.map((e) => e.id));
        }
      }
    }
  });

  test('à niveau de jeu égal, Difficile rapporte plus d’XP que Facile', () {
    // Sinon le mode exigeant n'a aucune raison d'être choisi.
    int xpMoyen(Difficulty d) {
      var total = 0;
      for (final e in repo.events) {
        // Un joueur « à peu près juste » : 3 % de l'ancienneté d'erreur.
        final err = ((maxYear - e.annee) * 0.03).round().clamp(2, 120);
        total += xpForRound(scoreFor(e.annee, e.annee + err, d), d.xpMult);
      }
      return total ~/ repo.events.length;
    }

    final facile = xpMoyen(Difficulty.facile);
    final normal = xpMoyen(Difficulty.normal);
    final difficile = xpMoyen(Difficulty.difficile);
    expect(normal, greaterThan(facile), reason: '$normal vs $facile');
    expect(difficile, greaterThan(normal), reason: '$difficile vs $normal');
  });

  test('Roulette : un seul drapeau, dix manches sur ce pays', () {
    // Le mode a changé de nature. La roue tournait à chaque manche et une
    // partie visitait dix pays ; elle s'arrête maintenant sur un drapeau
    // et toute la partie porte dessus. D'où le seuil relevé à dix faits
    // par pays : à six, le tirage ne pouvait plus se remplir.
    for (var partie = 0; partie < 40; partie++) {
      final pays = repo.tirerPays();
      expect(pays, isNotNull);
      final picked = repo.partiePays(pays!);
      expect(picked.length, rounds, reason: 'une partie entière sur $pays');
      expect(picked.map((e) => e.pays).toSet(), {pays},
          reason: 'aucun intrus venu d’un autre pays');
      expect(picked.map((e) => e.id).toSet().length, picked.length,
          reason: 'jamais deux fois le même fait');
    }
  });

  test('la roulette ne s’arrête que sur des pays jouables', () {
    // Un pays sous le seuil ferait échouer le démarrage de la partie,
    // après l’animation : le joueur verrait la roue s’arrêter sur un
    // drapeau, puis un message d’erreur.
    for (final pays in repo.paysJouables) {
      expect(repo.pool('pays:$pays').length, greaterThanOrEqualTo(rounds),
          reason: pays);
    }
    expect(repo.paysJouables.length, greaterThanOrEqualTo(15),
        reason: 'trop peu de drapeaux pour que la roulette ait du sens');
  });

  test('Tour du monde : la roue ne tombe que sur des pays bien fournis', () {
    final parContinent = repo.paysParContinent;
    final compte = <String, int>{};
    for (final e in repo.events) {
      if (e.pays != null) compte[e.pays!] = (compte[e.pays!] ?? 0) + 1;
    }
    for (final liste in parContinent.values) {
      for (final p in liste) {
        expect(compte[p], greaterThanOrEqualTo(minFaitsParPays), reason: p);
      }
    }
    expect(parContinent.length, greaterThanOrEqualTo(5),
        reason: 'les cinq continents');
  });

  test('le jamais-vu passe avant le déjà-vu', () {
    final seen = repo.events.take(400).map((e) => e.id).toSet();
    final picked = repo.pick('tout', Difficulty.normal, seen: seen);
    expect(picked.where((e) => seen.contains(e.id)), isEmpty);
  });

  test('le défi du jour est identique à graine égale, et varie d’un jour à '
      'l’autre', () {
    List<int> serie(DateTime d) => repo
        .pick('tout', Difficulty.normal, rng: mulberry32(dailySeed(d)))
        .map((e) => e.id)
        .toList();

    final jour = DateTime(2026, 7, 28);
    expect(serie(jour), serie(jour), reason: 'reproductible');
    expect(serie(jour), isNot(serie(DateTime(2026, 7, 29))));
  });

  test('une sélection trop pauvre refuse de démarrer plutôt que de '
      'resservir les mêmes événements', () {
    // `current` boucle avec `round % events.length` : une partie
    // incomplète donnerait la réponse à la seconde occurrence.
    final controller = GameController(repo);
    controller.catKey = 'inexistant'; // pool vide
    expect(controller.start(GameMode.classique), isFalse);
  });

  test('l’XP annoncée manche après manche est exactement celle créditée',
      () {
    for (final d in Difficulty.values) {
      final controller = GameController(repo);
      controller.diff = d;
      expect(controller.start(GameMode.classique), isTrue);
      var more = true;
      while (more) {
        // Des scores volontairement variés : c'est sur les arrondis que
        // l'ancien calcul (arrondi du total) divergeait de l'affichage.
        controller.setYear(controller.current.annee + controller.round * 7);
        controller.validate();
        controller.finishReveal();
        more = controller.next();
      }
      final annonce = controller.results.fold<int>(0, (s, r) => s + r.xp);
      expect(controller.xpEarned, annonce, reason: '$d');
      expect(controller.xpTotal, annonce.clamp(0, maxXpPerGame), reason: '$d');
    }
  });

  test('l’XP d’une partie ne dépasse jamais le plafond, combo compris', () {
    final controller = GameController(repo);
    controller.diff = Difficulty.difficile;
    expect(controller.start(GameMode.classique), isTrue);
    var more = true;
    while (more) {
      controller.setYear(controller.current.annee); // PERFECT à chaque manche
      controller.validate();
      controller.finishReveal();
      more = controller.next();
    }
    expect(controller.total, maxTotal);
    expect(controller.xpTotal, lessThanOrEqualTo(maxXpPerGame));
  });

  test('le bonus de combo majore l’XP sans toucher aux points', () {
    final controller = GameController(repo);
    expect(controller.start(GameMode.classique), isTrue);
    // 3 réponses parfaites d'affilée arment le bonus de la 4e manche.
    for (var i = 0; i < 3; i++) {
      controller.setYear(controller.current.annee);
      controller.validate();
      controller.finishReveal();
      controller.next();
    }
    expect(controller.boostNext, isTrue);
    controller.setYear(controller.current.annee);
    final boostee = controller.validate()!;
    expect(boostee.base, maxScore, reason: 'les points restent au barème');
    expect(boostee.xp, xpForRound(boostee.pts, controller.diff.xpMult,
        boosted: true));
    expect(boostee.xp,
        greaterThan(xpForRound(boostee.pts, controller.diff.xpMult)));
  });
}
