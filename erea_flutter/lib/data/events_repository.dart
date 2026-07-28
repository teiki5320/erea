import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../core/rng.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import '../models/hist_event.dart';

/// Catégorie ou pack jouable (clé « pack:xxx » pour les packs).
class Playable {
  final String key;
  final String label;
  final String emoji;
  const Playable(this.key, this.label, this.emoji);
}

const List<Playable> categories = [
  Playable('tout', 'Tout', '🌍'),
  Playable('france', 'Histoire de France', '🇫🇷'),
  Playable('monde', 'Monde', '🗺️'),
  Playable('sciences', 'Sciences & inventions', '🔬'),
  Playable('arts', 'Arts & culture', '🎨'),
  Playable('quotidien', 'Sport & vie quotidienne', '⚽'),
];

const List<Playable> packs = [
  Playable('pack:egypte', 'Égypte & Orient ancien', '🏺'),
  Playable('pack:asie', 'Asie', '🏯'),
  Playable('pack:ameriques', 'Les Amériques', '🌎'),
  Playable('pack:espace', 'Conquête de l’espace', '🚀'),
  Playable('pack:afrique', 'Afrique & Moyen-Orient', '🌍'),
];

Playable playableFor(String key) {
  for (final p in categories) {
    if (p.key == key) return p;
  }
  for (final p in packs) {
    if (p.key == key) return p;
  }
  return categories.first;
}

/// Charge et sert la base d'événements (assets/events.json).
class EventsRepository {
  EventsRepository._(this.events);

  final List<HistEvent> events;

  /// Charge la base. Une entrée malformée est ignorée plutôt que de faire
  /// échouer tout le chargement : `main()` attend ce Future avant le
  /// premier rendu, une exception ici figerait l'app sur l'écran de
  /// lancement, sans message. Les tests d'intégrité, eux, restent stricts.
  static Future<EventsRepository> load() async {
    final raw = await rootBundle.loadString('assets/events.json');
    final list = <HistEvent>[];
    for (final entry in jsonDecode(raw) as List<dynamic>) {
      try {
        final e = HistEvent.fromJson(entry as Map<String, dynamic>);
        if (e.annee < minYear || e.annee > maxYear) continue;
        if (e.titre.trim().isEmpty || e.desc.trim().isEmpty) continue;
        list.add(e);
      } catch (error) {
        assert(false, 'Événement illisible dans events.json : $error');
      }
    }
    return EventsRepository._(list);
  }

  List<HistEvent> pool(String catKey) {
    if (catKey.startsWith('pack:')) {
      final pk = catKey.substring(5);
      return events.where((e) => e.pack == pk).toList();
    }
    if (catKey == 'tout') return List.of(events);
    return events.where((e) => e.cat == catKey).toList();
  }

  /// Composition d'une partie par difficulté : combien de manches de
  /// chaque niveau (1 = connu des enfants, 2 = culture générale, 3 =
  /// pointu). Des QUOTAS, et non des tranches à épuiser : une tranche
  /// prioritaire plus grande que la partie rendrait tout le reste de la
  /// base mathématiquement inatteignable (le niveau 3 n'apparaissait
  /// jamais en Normal). Conforme à SPEC §3 : Facile ≤ 2, Difficile ≥ 2.
  static const Map<Difficulty, Map<int, int>> _quotas = {
    Difficulty.facile: {1: 7, 2: 3},
    Difficulty.normal: {1: 3, 2: 5, 3: 2},
    Difficulty.difficile: {2: 4, 3: 6},
  };

  /// Tirage d'une partie : quotas par niveau selon la difficulté, priorité
  /// au jamais-vu, mélange (RNG fourni pour le défi du jour).
  List<HistEvent> pick(
    String catKey,
    Difficulty diff, {
    double Function()? rng,
    Set<int> seen = const {},
    int count = rounds,
  }) {
    final p = pool(catKey);
    final random = rng ?? _defaultRng();
    final quotas = _quotas[diff]!;

    // Deux piles par niveau : le jamais-vu et le déjà-vu, mélangées
    // séparément. Le déjà-vu n'est servi qu'en tout dernier recours —
    // sinon, dans une petite catégorie, un niveau à court de frais
    // resservait aussitôt du connu alors que d'autres niveaux avaient
    // encore de quoi faire.
    final frais = <int, List<HistEvent>>{};
    final vus = <int, List<HistEvent>>{};
    for (var niveau = 1; niveau <= 3; niveau++) {
      final tier = p.where((e) => e.niveau == niveau);
      frais[niveau] =
          shuffled(tier.where((e) => !seen.contains(e.id)).toList(), random);
      vus[niveau] =
          shuffled(tier.where((e) => seen.contains(e.id)).toList(), random);
    }

    final picked = <HistEvent>[];
    void drain(Map<int, List<HistEvent>> pile, int niveau, int wanted) {
      final file = pile[niveau]!;
      final take = wanted.clamp(0, file.length);
      picked.addAll(file.take(take));
      file.removeRange(0, take);
    }

    // 1) Les quotas, sur du jamais-vu uniquement (au prorata de `count`
    //    si la partie est plus courte).
    final quotaTotal = quotas.values.fold<int>(0, (s, v) => s + v);
    for (final entry in quotas.entries) {
      drain(frais, entry.key, (entry.value * count / quotaTotal).round());
    }
    // 2) Places restantes : encore du jamais-vu, d'abord dans les niveaux
    //    prévus par la difficulté, puis ailleurs dans la base.
    final ordreSecours = [...quotas.keys, 1, 2, 3];
    for (final niveau in ordreSecours) {
      if (picked.length >= count) break;
      drain(frais, niveau, count - picked.length);
    }
    // 3) Vraiment plus rien de neuf : on repasse sur du déjà-vu.
    for (final niveau in ordreSecours) {
      if (picked.length >= count) break;
      drain(vus, niveau, count - picked.length);
    }

    // Les quotas ont regroupé les événements par niveau : on rebat les
    // cartes pour que la difficulté ne soit pas croissante d'une manche à
    // l'autre.
    return shuffled(picked, random).take(count).toList();
  }

  static double Function() _defaultRng() {
    final r = math.Random();
    return r.nextDouble;
  }
}
