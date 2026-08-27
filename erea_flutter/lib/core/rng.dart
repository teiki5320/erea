/// PRNG mulberry32, identique bit à bit à celui du prototype web : à
/// graine égale il produit la même suite sur toutes les plateformes (y
/// compris Flutter Web, d'où l'arithmétique 32 bits explicite, sûre sous
/// dart2js). C'est ce qui rend le défi du jour identique pour TOUS les
/// joueurs de l'app à une date donnée.
///
/// En revanche la série n'est plus celle du prototype web : la base de
/// l'app compte 862 événements contre 613 côté web, et le tirage applique
/// des quotas par niveau — deux listes différentes, donc deux suites de
/// tirages différentes. La parité avec le site n'est pas un objectif.
library;

import 'dart:math' as math;

const int _mask32 = 0xFFFFFFFF;

/// Équivalent de Math.imul de JavaScript (multiplication 32 bits),
/// sans jamais dépasser 2^53 pour rester exact sur le web.
int _imul(int a, int b) {
  final al = a & 0xFFFF;
  final ah = (a >>> 16) & 0xFFFF;
  final bMasked = b & _mask32;
  return (al * bMasked + ((ah * (bMasked & 0xFFFF)) << 16)) & _mask32;
}

/// Retourne une fonction qui produit des doubles dans [0, 1).
double Function() mulberry32(int seed) {
  var a = seed & _mask32;
  return () {
    a = (a + 0x6D2B79F5) & _mask32;
    var t = a;
    t = _imul(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >>> 7), t | 61)) & _mask32)) & _mask32;
    return ((t ^ (t >>> 14)) & _mask32) / 4294967296;
  };
}

/// Graine du défi du jour : AAAAMMJJ en entier (ex. 20260726),
/// comme dans le prototype web.
int dailySeed(DateTime date) {
  return date.year * 10000 + date.month * 100 + date.day;
}

/// Mélange de Fisher-Yates avec un RNG fourni (ou aléatoire par défaut).
List<T> shuffled<T>(List<T> list, double Function() rng) {
  final a = List<T>.of(list);
  for (var i = a.length - 1; i > 0; i--) {
    final j = (rng() * (i + 1)).floor();
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

/// Mélange PONDÉRÉ : plus le poids d'un élément est grand, plus il a de
/// chances de se retrouver en tête.
///
/// Algorithme d'Efraimidis et Spirakis : on tire une clé `u^(1/poids)`
/// pour chaque élément et on trie dessus. Un poids double vaut exactement
/// deux billets de tombola, et l'ordre reste entièrement déterminé par le
/// RNG fourni — le défi du jour, qui rejoue la même graine pour tout le
/// monde, sort donc la même série partout.
List<T> shuffledWeighted<T>(
  List<T> list,
  double Function(T) poids,
  double Function() rng,
) {
  final cles = <(double, int)>[];
  for (var i = 0; i < list.length; i++) {
    final w = poids(list[i]);
    // Un poids nul sortirait toujours en dernier ; on garde un plancher
    // pour qu'aucun fait ne devienne inatteignable.
    final u = rng().clamp(1e-9, 1.0).toDouble();
    cles.add((math.pow(u, 1 / math.max(w, 1e-6)).toDouble(), i));
  }
  cles.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final c in cles) list[c.$2]];
}
