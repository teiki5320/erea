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
    const knownCats = {'france', 'monde', 'sciences', 'arts', 'quotidien'};
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
      'afrique', 'ameriques', 'asie', 'europe', 'oceanie',
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

  test('chaque pack à thème a de quoi remplir une partie', () {
    for (final p in packs) {
      expect(repo.pool(p.key).length, greaterThanOrEqualTo(rounds),
          reason: p.label);
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
    expect(playableFor('france').label, 'Histoire de France');
    expect(playableFor('pack:espace').label, 'Conquête de l’espace');
    expect(playableFor('inexistant').key, 'tout');
  });
}

double Function() _seeded() {
  var i = 0;
  // Suite déterministe simple : suffit à vérifier la reproductibilité.
  return () => ((i = (i * 1103515245 + 12345) & 0x7FFFFFFF) / 0x7FFFFFFF);
}
