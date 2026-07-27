/// Échelle non linéaire de la frise : chaque segment d'années occupe une
/// part différente de la largeur, pour que le XXe siècle reste précis.
library;

const int minYear = -3000;
const int maxYear = 2025;

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
  Segment(1900, 2025, 0.30),
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
  Era(1789, 2025, 'Époque contemporaine'),
];

Era eraFor(int y) {
  for (final e in eras) {
    if (y <= e.to) return e;
  }
  return eras.last;
}
