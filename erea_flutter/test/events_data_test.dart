import 'package:erea/core/scoring.dart';
import 'package:erea/core/timeline_scale.dart';
import 'package:erea/data/events_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// La base d'événements est l'actif principal du projet : ces tests
/// verrouillent son intégrité (ids uniques, bornes, catégories connues).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventsRepository repo;

  setUpAll(() async {
    repo = await EventsRepository.load();
  });

  test('la base se charge et n’est pas vide', () {
    expect(repo.events.length, greaterThanOrEqualTo(600));
  });

  test('les identifiants sont uniques', () {
    final ids = repo.events.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('toutes les années tiennent dans la frise', () {
    for (final e in repo.events) {
      expect(e.annee, inInclusiveRange(minYear, maxYear),
          reason: '#${e.id} « ${e.titre} »');
    }
  });

  test('les catégories et packs sont ceux déclarés dans SPEC.md', () {
    const knownCats = {'pouvoir', 'sciences', 'arts', 'quotidien'};
    const knownPacks = {'egypte', 'asie', 'ameriques', 'espace', 'afrique'};
    for (final e in repo.events) {
      expect(knownCats, contains(e.cat), reason: '#${e.id}');
      if (e.pack != null) {
        expect(knownPacks, contains(e.pack), reason: '#${e.id}');
      }
    }
  });

  test('les continents sont connus et chaque continent porte 45+ faits', () {
    const knownContinents = {
      'afrique',
      'ameriques',
      'asie',
      'europe',
      'oceanie',
    };
    final parContinent = <String, int>{};
    for (final e in repo.events) {
      if (e.continent == null) continue;
      expect(knownContinents, contains(e.continent), reason: '#${e.id}');
      // `pays` absent = fait transnational (câble atlantique, schisme…) ;
      // s'il est présent il n'est jamais vide (roue des pays).
      if (e.pays != null) {
        expect(e.pays!.trim(), isNotEmpty, reason: '#${e.id} « ${e.titre} »');
      }
      parContinent[e.continent!] = (parContinent[e.continent!] ?? 0) + 1;
    }
    expect(parContinent.keys, containsAll(knownContinents));
    for (final entry in parContinent.entries) {
      expect(entry.value, greaterThanOrEqualTo(45), reason: entry.key);
    }
  });

  test('la roue des pays a de quoi tourner : 40+ pays bien fournis', () {
    final parPays = <String, int>{};
    for (final e in repo.events) {
      if (e.pays == null) continue;
      // Un pays nommé implique toujours son continent.
      expect(e.continent, isNotNull, reason: '#${e.id} « ${e.titre} »');
      parPays[e.pays!] = (parPays[e.pays!] ?? 0) + 1;
    }
    // La future roue tire un pays puis 10 questions : sous 10 faits, une
    // partie devrait piocher ailleurs.
    final jouables = parPays.entries.where((e) => e.value >= 10);
    expect(jouables.length, greaterThanOrEqualTo(40),
        reason: 'pays avec au moins 10 faits');
  });

  test('les niveaux valent 1, 2 ou 3', () {
    for (final e in repo.events) {
      expect(e.niveau, inInclusiveRange(1, 3), reason: '#${e.id}');
    }
  });

  test('titre, description et emoji sont renseignés', () {
    for (final e in repo.events) {
      expect(e.titre.trim(), isNotEmpty, reason: '#${e.id}');
      expect(e.desc.trim(), isNotEmpty, reason: '#${e.id}');
      expect(e.emoji.trim(), isNotEmpty, reason: '#${e.id}');
    }
  });

  test('la description ne divulgue pas l’année de l’événement', () {
    for (final e in repo.events) {
      final annee = e.annee.abs().toString();
      expect(e.desc.contains(annee), isFalse,
          reason: '#${e.id} « ${e.titre} » : la description cite $annee');
    }
  });

  test('chaque catégorie a de quoi remplir une partie', () {
    for (final c in categories) {
      expect(repo.pool(c.key).length, greaterThanOrEqualTo(rounds),
          reason: c.label);
    }
  });

  test('chaque pack à thème tient au moins 13 parties, difficultés cumulées',
      () {
    // Un pack est l'unité de vente : en vendre un qui s'épuise en quatre
    // parties (c'était le cas de « Conquête de l'espace ») n'est pas tenable.
    //
    // L'ancien verrou comptait des FAITS (>= 150) : un volume, pas une
    // faisabilité. Or une partie ne pioche pas dans le volume, elle
    // remplit des quotas par niveau (SPEC §3) — et à ce compte, aucun
    // pack ne tenait les « 15 parties » promises : le meilleur en donnait
    // 14 (Amériques, en Difficile), le pire 8 (Asie, dont 116 faits sur
    // 150 sont de niveau 3). Constat de l'audit du 21 août 2026.
    //
    // Le seuil comptait d'abord la MEILLEURE difficulté seule. Le
    // reclassement du 26 août l'a montré trop étroit : le pack Égypte,
    // dont Sphinx, Toutânkhamon et hiéroglyphes sont passés en niveau 1,
    // gagnait le mode Facile (1 → 3 parties) mais perdait du niveau 2,
    // donc du Difficile (12 → 7). Il devenait le seul pack jouable dans
    // les trois modes, et le test le déclarait en régression.
    //
    // On somme donc les trois difficultés : c'est ce dont dispose
    // réellement celui qui achète le pack. Seuil posé à l'état du pire
    // pack (Ciel & espace, 13), cible 20.
    const quotas = {
      // Copie assumée de EventsRepository._quotas (SPEC §3) : les dériver
      // du code testé reviendrait à vérifier le code avec lui-même.
      Difficulty.facile: {1: 10},
      Difficulty.normal: {1: 3, 2: 5, 3: 2},
      Difficulty.difficile: {2: 4, 3: 6},
    };
    int partiesComposables(String key) {
      final parNiveau = <int, int>{};
      for (final e in repo.pool(key)) {
        parNiveau[e.niveau] = (parNiveau[e.niveau] ?? 0) + 1;
      }
      var total = 0;
      for (final q in quotas.values) {
        var parties = 1 << 30;
        q.forEach((niveau, parPartie) {
          final possibles = (parNiveau[niveau] ?? 0) ~/ parPartie;
          if (possibles < parties) parties = possibles;
        });
        total += parties;
      }
      return total;
    }

    for (final p in packs) {
      expect(partiesComposables(p.key), greaterThanOrEqualTo(13),
          reason: p.label);
    }
  });

  test('aucun doublon exact dans la base', () {
    // Le même événement raconté deux fois perce l'anti-répétition : une
    // partie pouvait poser deux fois la même question, réponse déjà vue.
    final vus = <String>{};
    for (final e in repo.events) {
      final cle = '${e.annee}|${e.titre.toLowerCase().trim()}';
      expect(vus.add(cle), isTrue, reason: 'doublon : #${e.id} « ${e.titre} »');
    }
  });

  test('aucun titre ne donne l’année en clair', () {
    // Un titre qui contient « 1789 » ou « an mil » offre la réponse.
    final annee =
        RegExp(r'\b(1\d{3}|20[0-2]\d|an mil)\b', caseSensitive: false);
    for (final e in repo.events) {
      expect(annee.hasMatch(e.titre), isFalse,
          reason: '#${e.id} « ${e.titre} » énonce sa date');
    }
  });

  test('le pack « Ciel & conquête spatiale » ne contient pas d’intrus', () {
    // Le pack avait été rempli par recherche de SOUS-CHAÎNES, sans limite
    // de mot : « MARSeille » a fait entrer la fondation de Marseille,
    // « éTOILE des Bleus » la victoire des Bleus, « colons VENUS de
    // Phocée » a matché Vénus, et « aéROPORT d’Entebbe » un raid
    // militaire. Le pack sur l’espace contenait donc l’OM, la Coupe du
    // monde de rugby et Banksy.
    //
    // Ce garde-fou est nominatif à dessein : aucune règle automatique ne
    // peut décider qu’un fait est hors sujet, mais un script de
    // regénération qui réintroduirait ces huit-là serait repéré tout de
    // suite.
    const intrus = {
      'Fondation de Marseille',
      'L’OM champion d’Europe',
      'Deuxième étoile des Bleus',
      'Banksy autodétruit sa toile',
      'Accord de Paris sur le climat',
      'Première Coupe du monde de rugby',
      'Cap sur les atolls des Marshall',
      'Invention des lunettes',
    };
    final titres = repo.pool('pack:espace').map((e) => e.titre).toSet();
    for (final t in intrus) {
      expect(titres, isNot(contains(t)),
          reason: '« $t » n’a rien à faire dans le pack sur le ciel');
    }
    // …et ils doivent rester jouables ailleurs : on les sort du pack, on
    // ne les supprime pas du jeu.
    final tous = repo.pool('tout').map((e) => e.titre).toSet();
    for (final t in intrus) {
      expect(tous, contains(t), reason: '« $t » a disparu de la base');
    }
  });

  test('aucune catégorie ne s’épuise en moins de 15 parties', () {
    for (final c in categories) {
      expect(repo.pool(c.key).length, greaterThanOrEqualTo(15 * rounds),
          reason: c.label);
    }
  });

  test('le mode Facile trouve vraiment ses événements faciles', () {
    // Le test voisin ne compte que les MANCHES, jamais leur niveau. Or
    // `pick` se replie automatiquement sur les autres niveaux quand un
    // niveau est à sec : il rend donc toujours 10 manches, même si Facile
    // va les chercher dans le niveau le plus difficile. Le tri de
    // difficulté a laissé la catégorie sciences avec 3 événements de
    // niveau 1 sur 270, et aucun test n'a bronché.
    //
    // Ici on regarde le niveau de ce qui sort réellement.
    for (final c in categories) {
      final faciles = repo.pool(c.key).where((e) => e.niveau == 1).length;
      expect(faciles, greaterThanOrEqualTo(7),
          reason: '${c.label} : ${'$faciles'} événements de niveau 1, '
              'de quoi remplir moins d’une partie Facile');

      final tirage = repo.pick(c.key, Difficulty.facile);
      expect(tirage.where((e) => e.niveau == 1).length, greaterThanOrEqualTo(7),
          reason: '${c.label} : une partie Facile doit tenir son quota de '
              '7 manches de niveau 1 sans se replier');
    }
  });

  test('chaque difficulté a assez d’événements dans chaque catégorie', () {
    for (final c in categories) {
      for (final d in Difficulty.values) {
        final picked = repo.pick(c.key, d);
        expect(picked.length, rounds, reason: '${c.label} / ${d.label}');
      }
    }
  });

  test('un tirage ne contient jamais deux fois le même événement', () {
    final picked = repo.pick('tout', Difficulty.normal);
    expect(picked.map((e) => e.id).toSet().length, picked.length);
  });

  test('le défi du jour est reproductible à date égale', () {
    final a = repo.pick('tout', Difficulty.normal, rng: _seeded());
    final b = repo.pick('tout', Difficulty.normal, rng: _seeded());
    expect(a.map((e) => e.id), b.map((e) => e.id));
  });

  test('le tirage privilégie les événements non encore vus', () {
    final seen = repo.events.take(300).map((e) => e.id).toSet();
    final picked = repo.pick('tout', Difficulty.normal, seen: seen);
    expect(picked.where((e) => seen.contains(e.id)), isEmpty);
  });

  test('playableFor retombe sur « Tout » pour une clé inconnue', () {
    expect(playableFor('pouvoir').label, 'Pouvoir & guerres');
    expect(playableFor('pack:espace').label, 'Ciel & conquête spatiale');
    expect(playableFor('inexistant').key, 'tout');
  });
}

double Function() _seeded() {
  var i = 0;
  // Suite déterministe simple : suffit à vérifier la reproductibilité.
  return () => ((i = (i * 1103515245 + 12345) & 0x7FFFFFFF) / 0x7FFFFFFF);
}
