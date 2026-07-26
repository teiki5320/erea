import 'dart:math' as math;

import 'timeline_scale.dart';

const int rounds = 10;
const int maxScore = 1000; // par manche (avant multiplicateur)
const int maxTotal = 11000; // 9 manches + manche finale x2
const int maxEcartBase = 200; // au-delà (en Normal) : 0 point

/// Difficulté choisie par le joueur : module la tolérance, l'XP et les repères.
enum Difficulty {
  facile(
    label: 'Facile',
    emoji: '😌',
    tolMult: 2.2,
    xpMult: 0.8,
    anchors: true,
    desc:
        'Grande marge d’erreur, repères affichés, événements connus — parfait pour débuter !',
  ),
  normal(
    label: 'Normal',
    emoji: '🙂',
    tolMult: 1.0,
    xpMult: 1.0,
    anchors: true,
    desc: 'L’équilibre classique : marge normale et repères affichés.',
  ),
  difficile(
    label: 'Difficile',
    emoji: '🔥',
    tolMult: 0.55,
    xpMult: 1.3,
    anchors: false,
    desc: 'Marge réduite, frise nue, événements pointus… mais +30 % d’XP !',
  );

  const Difficulty({
    required this.label,
    required this.emoji,
    required this.tolMult,
    required this.xpMult,
    required this.anchors,
    required this.desc,
  });

  final String label;
  final String emoji;
  final double tolMult;
  final double xpMult;
  final bool anchors;
  final String desc;
}

/// Tolérance : 5 % de l'ancienneté, bornée entre 5 et 45 ans, x difficulté.
double tolerance(int annee, Difficulty diff) {
  final base = ((maxYear - annee) * 0.05).clamp(5.0, 45.0).toDouble();
  return base * diff.tolMult;
}

/// Fenêtre au-delà de laquelle on marque 0 point.
double maxEcart(Difficulty diff) => maxEcartBase * diff.tolMult;

/// Points d'une manche (hors multiplicateur de manche finale).
/// `points = round(1000 * exp(-écart / tolérance))`, 0 au-delà de la fenêtre.
int scoreFor(int annee, int guess, Difficulty diff) {
  final ecart = (guess - annee).abs();
  if (ecart >= maxEcart(diff)) return 0;
  final pts = (maxScore * math.exp(-ecart / tolerance(annee, diff))).round();
  return pts.clamp(0, maxScore).toInt();
}

/// La dernière manche d'une partie classique/quotidienne vaut double.
int roundMultiplier(int roundIndex, {bool chrono = false}) {
  return (!chrono && roundIndex == rounds - 1) ? 2 : 1;
}
