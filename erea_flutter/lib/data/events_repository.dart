import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../core/rng.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import '../models/hist_event.dart';
import 'drapeaux.dart';

/// Catégorie ou pack jouable (clé « pack:xxx » pour les packs).
class Playable {
  final String key;
  final String label;
  final String emoji;
  const Playable(this.key, this.label, this.emoji);
}

/// Les catégories sont désormais purement THÉMATIQUES.
///
/// L'ancienne liste mélangeait deux axes dans un seul champ :
/// « Histoire de France » est un critère géographique, « Sciences » et
/// « Arts » des critères thématiques, et « Monde » n'était ni l'un ni
/// l'autre — juste le reste, 44 % de la base. Un fait français ET
/// scientifique n'avait donc aucune place correcte, ce dont la base
/// portait la trace : le premier vol du Concorde était rangé dans
/// « France », son accident dans « Sciences ».
///
/// La géographie vit maintenant dans les champs `pays` et `continent`,
/// et alimente la roulette de drapeaux. Un fait français va dans son
/// thème, avec « France » à côté.
///
/// Un thème « croyances » a existé le temps du reclassement : il n'a
/// récolté que 4 % de la base, très loin des 150 faits qu'il faut pour
/// tenir 15 parties. Une religion étant d'abord un fait culturel, il a
/// été fondu dans « Culture & croyances ».
const List<Playable> categories = [
  Playable('tout', 'Tout', '🌍'),
  Playable('pouvoir', 'Pouvoir & guerres', '⚔️'),
  Playable('sciences', 'Sciences & explorations', '🔬'),
  Playable('arts', 'Culture & croyances', '🎭'),
  Playable('quotidien', 'Vie quotidienne & sport', '⚽'),
];

const List<Playable> packs = [
  Playable('pack:egypte', 'Antiquité & Orient ancien', '🏺'),
  Playable('pack:asie', 'Asie', '🏯'),
  Playable('pack:ameriques', 'Les Amériques', '🌎'),
  Playable('pack:espace', 'Ciel & conquête spatiale', '🚀'),
  Playable('pack:afrique', 'Afrique & Moyen-Orient', '🌍'),
];

/// Pays assez fournis pour une partie entière.
///
/// Le seuil valait 6 tant que la roue tournait à chaque manche : il
/// suffisait qu'un pays puisse fournir UN événement. Depuis que la
/// roulette s'arrête sur un seul drapeau pour toute la partie, il lui en
/// faut dix, sinon le tirage ne peut pas se remplir et la partie refuse
/// de démarrer.
const int minFaitsParPays = rounds;

Playable playableFor(String key) {
  for (final p in categories) {
    if (p.key == key) return p;
  }
  for (final p in packs) {
    if (p.key == key) return p;
  }
  // Une partie de roulette : l'étiquette est le pays et son drapeau.
  // Sans ce cas, l'écran de fin et le texte de partage annonçaient
  // « Tout 🌍 » — le pays joué disparaissait du bilan.
  if (key.startsWith('pays:')) {
    final pays = key.substring(5);
    return Playable(key, pays, drapeauDe(pays));
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
    if (catKey.startsWith('pays:')) {
      final pays = catKey.substring(5);
      return events.where((e) => e.pays == pays).toList();
    }
    if (catKey == 'tout') return List.of(events);
    return events.where((e) => e.cat == catKey).toList();
  }

  /// Les pays jouables, groupés par continent : de quoi faire tourner la
  /// roue du mode « Tour du monde ».
  Map<String, List<String>> get paysParContinent {
    final compte = <String, int>{};
    final continent = <String, String>{};
    for (final e in events) {
      final p = e.pays;
      if (p == null || p.isEmpty || e.continent == null) continue;
      compte[p] = (compte[p] ?? 0) + 1;
      continent[p] = e.continent!;
    }
    final parContinent = <String, List<String>>{};
    for (final entry in compte.entries) {
      if (entry.value < minFaitsParPays) continue;
      parContinent.putIfAbsent(continent[entry.key]!, () => []).add(entry.key);
    }
    for (final l in parContinent.values) {
      l.sort();
    }
    return parContinent;
  }

  /// Tous les pays sur lesquels la roulette peut s'arrêter, triés.
  ///
  /// Un pays n'y figure que s'il peut tenir une partie entière à lui
  /// seul : c'est [minFaitsParPays] qui pose la barre.
  List<String> get paysJouables {
    final compte = <String, int>{};
    for (final e in events) {
      final p = e.pays;
      if (p == null || p.isEmpty) continue;
      compte[p] = (compte[p] ?? 0) + 1;
    }
    final liste = [
      for (final entry in compte.entries)
        if (entry.value >= minFaitsParPays) entry.key,
    ]..sort();
    return liste;
  }

  /// Le pays sur lequel la roulette s'arrête.
  ///
  /// Les pays déjà épuisés passent en dernier plutôt que d'être exclus :
  /// mieux vaut rejouer un pays connu que refuser de lancer une partie.
  String? tirerPays({double Function()? rng, Set<int> seen = const {}}) {
    final random = rng ?? _defaultRng();
    final jouables = paysJouables;
    if (jouables.isEmpty) return null;
    final frais = <String>[];
    final epuises = <String>[];
    for (final p in jouables) {
      final restants =
          pool('pays:$p').where((e) => !seen.contains(e.id)).length;
      (restants >= rounds ? frais : epuises).add(p);
    }
    final source = frais.isNotEmpty ? frais : epuises;
    return shuffled(source, random).first;
  }

  /// Une partie entière sur un seul pays : dix manches, un drapeau.
  ///
  /// Le jamais-vu passe avant le déjà-vu, comme dans [pick] ; sans ça un
  /// pays tout juste au-dessus du seuil resservirait indéfiniment les
  /// mêmes dix faits.
  List<HistEvent> partiePays(
    String pays, {
    double Function()? rng,
    Set<int> seen = const {},
    int count = rounds,
  }) {
    final random = rng ?? _defaultRng();
    final dispo = pool('pays:$pays');
    final frais =
        shuffled(dispo.where((e) => !seen.contains(e.id)).toList(), random);
    final vus =
        shuffled(dispo.where((e) => seen.contains(e.id)).toList(), random);
    return [...frais, ...vus].take(count).toList();
  }

  /// Composition d'une partie par difficulté : combien de manches de
  /// chaque niveau (1 = connu des enfants, 2 = culture générale, 3 =
  /// pointu). Des QUOTAS, et non des tranches à épuiser : une tranche
  /// prioritaire plus grande que la partie rendrait tout le reste de la
  /// base mathématiquement inatteignable (le niveau 3 n'apparaissait
  /// jamais en Normal). Conforme à SPEC §3 : Facile ≤ 2, Difficile ≥ 2.
  ///
  /// Facile ne vise QUE le niveau 1 (les faits vraiment connus) : les
  /// niveau 2, même de « culture générale », passaient encore pour trop
  /// pointus. Le `2: 0` n'est pas un quota mais un REPLI : il n'ouvre le
  /// niveau 2 que si une petite sélection (p. ex. la catégorie Sciences, ou
  /// un pack étroit) n'a plus assez de faits niveau 1 pour tenir dix
  /// manches. Dans les catégories fournies, une partie Facile est donc
  /// entièrement composée de faits connus.
  static const Map<Difficulty, Map<int, int>> _quotas = {
    Difficulty.facile: {1: 10, 2: 0},
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
    // 2) Places restantes : du jamais-vu, dans les niveaux prévus par la
    //    difficulté.
    for (final niveau in quotas.keys) {
      if (picked.length >= count) break;
      drain(frais, niveau, count - picked.length);
    }
    // 3) Puis du DÉJÀ-VU, toujours dans les niveaux du mode. C'est l'étape
    //    qui manquait : l'ancien repli passait directement au jamais-vu
    //    des AUTRES niveaux, et dès la 3e partie d'un pack une partie
    //    Facile servait du niveau 3 « frais » alors qu'il restait plein de
    //    faits faciles simplement déjà vus (et Difficile s'adoucissait au
    //    niveau 1 à la 15e). Revoir un fait adapté vaut mieux que
    //    découvrir un fait qui trahit le mode choisi : le mode est un
    //    contrat.
    for (final niveau in quotas.keys) {
      if (picked.length >= count) break;
      drain(vus, niveau, count - picked.length);
    }
    // 4) Catégorie vraiment à sec pour ce mode : on ouvre aux autres
    //    niveaux, jamais-vu puis déjà-vu.
    for (final niveau in [1, 2, 3]) {
      if (picked.length >= count) break;
      drain(frais, niveau, count - picked.length);
    }
    for (final niveau in [1, 2, 3]) {
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
