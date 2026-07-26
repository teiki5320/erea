/// PRNG mulberry32, identique bit à bit à celui du prototype web :
/// le défi du jour tire ainsi la MÊME série que la version web pour une
/// même date, sur toutes les plateformes (y compris Flutter Web, d'où
/// l'arithmétique 32 bits explicite, sûre sous dart2js).
library;

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
