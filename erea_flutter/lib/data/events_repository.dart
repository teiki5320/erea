import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../core/rng.dart';
import '../core/scoring.dart';
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

  static Future<EventsRepository> load() async {
    final raw = await rootBundle.loadString('assets/events.json');
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => HistEvent.fromJson(e as Map<String, dynamic>))
        .toList();
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

  /// Tirage d'une partie : filtre par difficulté (niveau), évite les
  /// événements vus récemment, mélange (RNG fourni pour le défi du jour).
  List<HistEvent> pick(
    String catKey,
    Difficulty diff, {
    double Function()? rng,
    Set<int> seen = const {},
    int count = rounds,
  }) {
    final p = pool(catKey);
    final random = rng ?? _defaultRng();

    // Tranches par priorité selon la difficulté : on épuise la première
    // avant de piocher dans la suivante. Facile ne touche jamais au
    // niveau 3 ; Normal n'y recourt qu'en dernier ressort ; Difficile
    // pioche d'abord le pointu.
    final List<List<HistEvent>> tiers;
    if (diff == Difficulty.facile) {
      tiers = [
        p.where((e) => e.niveau == 1).toList(),
        p.where((e) => e.niveau == 2).toList(),
      ];
    } else if (diff == Difficulty.difficile) {
      tiers = [
        p.where((e) => e.niveau == 3).toList(),
        p.where((e) => e.niveau == 2).toList(),
      ];
    } else {
      tiers = [
        p.where((e) => e.niveau <= 2).toList(),
        p.where((e) => e.niveau == 3).toList(),
      ];
    }

    // Filet de sécurité : si les tranches ne suffisent pas (petit pack),
    // le reste du pool complète en dernier plutôt que d'écourter la partie.
    final inTiers = {for (final t in tiers) for (final e in t) e.id};
    final rest = p.where((e) => !inTiers.contains(e.id)).toList();
    if (rest.isNotEmpty) tiers.add(rest);

    // Anti-répétition d'abord : tout le jamais-vu (dans l'ordre des
    // tranches), puis le déjà-vu.
    final ordered = <HistEvent>[
      for (final tier in tiers)
        ...shuffled(tier.where((e) => !seen.contains(e.id)).toList(), random),
      for (final tier in tiers)
        ...shuffled(tier.where((e) => seen.contains(e.id)).toList(), random),
    ];
    return ordered.take(count).toList();
  }

  static double Function() _defaultRng() {
    final r = math.Random();
    return r.nextDouble;
  }
}
