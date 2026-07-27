import 'dart:ui';

import '../core/timeline_scale.dart';

/// Thème visuel d'une époque : teinte de fond, encre de libellé et décor.
/// Source unique partagée par le peintre du ruban, le fond d'écran et les
/// pastilles d'époque (handoff « Sticker Arcade », tableau §Données).
class EraTheme {
  final String name;
  final Color tint;
  final Color ink;
  final String bgAsset;
  const EraTheme(this.name, this.tint, this.ink, this.bgAsset);
}

const List<EraTheme> eraThemes = [
  EraTheme('ÂGE DU BRONZE', Color(0xFFF9EAC9), Color(0xFFA97B36),
      'assets/img/bg-bronze.webp'),
  EraTheme('ÂGE DU FER', Color(0xFFF2EDCF), Color(0xFF6E7A3A),
      'assets/img/bg-fer.webp'),
  EraTheme('ANTIQUITÉ', Color(0xFFE6DFF0), Color(0xFF7A5FA8),
      'assets/img/bg-antiquite.webp'),
  EraTheme('MOYEN ÂGE', Color(0xFFD8E6F5), Color(0xFF3F76B5),
      'assets/img/bg-moyenage.webp'),
  EraTheme('ÉPOQUE MODERNE', Color(0xFFFBE3C0), Color(0xFFC2822C),
      'assets/img/bg-moderne.webp'),
  EraTheme('ÉPOQUE CONTEMPORAINE', Color(0xFFF9D9D4), Color(0xFFC9645A),
      'assets/img/bg-contemporaine.webp'),
];

/// Indice d'époque d'une année (mêmes bornes que [eras]).
int eraIndexAt(int year) {
  for (var i = 0; i < eras.length; i++) {
    if (year <= eras[i].to) return i;
  }
  return eras.length - 1;
}

/// Résultat du fondu : deux époques et le poids de la seconde.
class EraBlend {
  final int a, b; // indices d'époque
  final double t; // 0 → tout a, 1 → tout b (déjà adouci)
  const EraBlend(this.a, this.b, this.t);
}

/// Demi-largeur de la zone de fondu, en fraction du ruban
/// (= 64 px sur les 3 200 px du ruban virtuel).
const double kBlendW = 0.02;

/// Fondu d'époque en fonction de la position du ruban. Fonction PURE de
/// `frac` : le fond suit le doigt, il est réversible, jamais en retard —
/// aucune animation implicite ne doit s'y superposer pendant le geste.
EraBlend eraBlendAt(double frac) {
  var a = eraIndexAt(fracToYear(frac));
  var b = a;
  var t = 0.0;
  for (var i = 0; i < eras.length - 1; i++) {
    final bf = yearToFrac(eras[i].to);
    if (frac > bf - kBlendW && frac < bf + kBlendW) {
      a = i;
      b = i + 1;
      t = (frac - (bf - kBlendW)) / (2 * kBlendW);
      break;
    }
  }
  final e = t * t * (3 - 2 * t); // smoothstep
  return EraBlend(a, b, e);
}
