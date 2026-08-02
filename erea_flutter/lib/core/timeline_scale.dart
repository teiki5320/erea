/// Échelle non linéaire de la frise : chaque segment d'années occupe une
/// part différente de la largeur, pour que le XXe siècle reste précis.
library;

const int minYear = -3000;
const int maxYear = 2026;

class Segment {
  final int from;
  final int to;
  final double w; // part de la largeur totale (somme = 1)
  const Segment(this.from, this.to, this.w);
}

const List<Segment> segments = [
  Segment(-3000, 0, 0.20),
  Segment(0, 1500, 0.25),
  Segment(1500, 1900, 0.25),
  Segment(1900, 2026, 0.30),
];

/// Année → position [0, 1] sur la frise.
double yearToFrac(num year) {
  final y = year.clamp(minYear, maxYear).toDouble();
  var acc = 0.0;
  for (final s in segments) {
    if (y <= s.to) {
      return acc + s.w * (y - s.from) / (s.to - s.from);
    }
    acc += s.w;
  }
  return 1.0;
}

/// Position [0, 1] → année entière.
int fracToYear(double frac) {
  final f = frac.clamp(0.0, 1.0);
  var acc = 0.0;
  for (var i = 0; i < segments.length; i++) {
    final s = segments[i];
    if (f <= acc + s.w || i == segments.length - 1) {
      final y = (s.from + (f - acc) / s.w * (s.to - s.from)).round();
      return y.clamp(minYear, maxYear).toInt();
    }
    acc += s.w;
  }
  return maxYear;
}

/// « 480 av. J.-C. » pour les années négatives, « 1515 » sinon.
String formatYear(int y) {
  if (y < 0) return '${-y} av. J.-C.';
  return '$y';
}

/// Grandes époques scolaires (bandes de couleur de la frise).
class Era {
  final int from;
  final int to;
  final String name;
  const Era(this.from, this.to, this.name);
}

const List<Era> eras = [
  Era(-3000, -1200, 'Âge du bronze'),
  Era(-1200, -500, 'Âge du fer'),
  Era(-500, 476, 'Antiquité'),
  Era(476, 1492, 'Moyen Âge'),
  Era(1492, 1789, 'Époque moderne'),
  Era(1789, 2026, 'Époque contemporaine'),
];

Era eraFor(int y) {
  for (final e in eras) {
    if (y <= e.to) return e;
  }
  return eras.last;
}

/// Années par unité de position autour de [frac] : la « densité » locale
/// de l'échelle. L'Antiquité en met 15 000 là où l'époque contemporaine
/// en met 420 — un rapport de 36 que le doigt, lui, ne voit pas.
double densiteLocale(double frac) {
  final f = frac.clamp(0.0, 1.0);
  var acc = 0.0;
  for (final s in segments) {
    if (f <= acc + s.w) return (s.to - s.from) / s.w;
    acc += s.w;
  }
  final s = segments.last;
  return (s.to - s.from) / s.w;
}

/// La densité de l'époque contemporaine : c'est elle qui définit la
/// précision de référence du réglage fin.
final double densiteContemporaine =
    (segments.last.to - segments.last.from) / segments.last.w;

/// Fraction de la vitesse du doigt appliquée au ruban, selon l'époque et
/// la vitesse du geste (en px par frame de 60 Hz).
///
/// Le problème résolu ici : à geste égal, l'Antiquité faisait défiler 36
/// fois plus d'années que l'époque contemporaine — l'ajustement fin y
/// était impossible. Mais brider uniformément interdirait de la
/// traverser : 3 000 ans à la précision contemporaine, c'est 23 000 px de
/// doigt.
///
/// D'où deux régimes, fondus par une interpolation douce :
/// - geste LENT (ajustement) : le ruban est freiné dans le rapport des
///   densités, si bien qu'un pixel de doigt déplace le même nombre
///   d'ANNÉES à toutes les époques — la précision contemporaine partout ;
/// - geste RAPIDE (navigation) : le ruban suit le doigt en pixels, comme
///   avant — traverser trente siècles reste un seul balayage.
///
/// À l'époque contemporaine, la formule redonne l'ancien comportement
/// (plancher 0,4, plafond 1) : rien ne change là où c'était déjà bien.
double facteurGlissement(double frac, double vitessePxParFrame) {
  final plancherLocal = 0.4 * densiteContemporaine / densiteLocale(frac);
  // Fondu entre 2 et 8 px/frame (≈ 120 à 480 px/s), lissé : sans lui, le
  // passage ajustement → navigation ferait un à-coup au milieu du geste.
  final t = ((vitessePxParFrame - 2.0) / 6.0).clamp(0.0, 1.0);
  final doux = t * t * (3 - 2 * t);
  return plancherLocal + (1.0 - plancherLocal) * doux;
}
