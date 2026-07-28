import 'package:erea/core/progression.dart';
import 'package:erea/core/rng.dart';
import 'package:erea/core/scoring.dart';
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
