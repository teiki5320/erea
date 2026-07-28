import 'dart:math' as math;

import 'timeline_scale.dart';

const int rounds = 10;
const int maxScore = 1000; // par manche (avant multiplicateur)
const int maxTotal = 11000; // 9 manches + manche finale x2
const int maxEcartBase = 200; // au-delà (en Normal) : 0 point

/// Difficulté choisie par le joueur : module la tolérance, l'XP et les repères.
enum Difficulty {
  // Les multiplicateurs d'XP compensent le barème : à niveau de jeu égal,
  // Difficile rapporte MOINS de points que Facile. Sans compensation,
  // 1,3× ne suffisait pas et le mode exigeant rapportait autant que le
  // mode facile — il n'y avait aucune raison de le choisir.
  facile(
    label: 'Facile',
    emoji: '😌',
    tolMult: 2.2,
    xpMult: 0.75,
    desc:
        'Grande marge d’erreur et événements connus — parfait pour débuter !',
  ),
  normal(
    label: 'Normal',
    emoji: '🙂',
    tolMult: 1.0,
    xpMult: 1.0,
    desc: 'L’équilibre classique : marge normale, événements variés.',
  ),
  difficile(
    label: 'Difficile',
    emoji: '🔥',
    tolMult: 0.55,
    xpMult: 1.75,
    desc: 'Marge réduite, événements pointus… mais +30 % d’XP !',
  );

  const Difficulty({
    required this.label,
    required this.emoji,
    required this.tolMult,
    required this.xpMult,
    required this.desc,
  });

  final String label;
  final String emoji;
  final double tolMult;
  final double xpMult;

  /// Montré au joueur dans le sélecteur : ne doit promettre que ce que le
  /// jeu fait réellement (les repères emoji du prototype web ne sont pas
  /// portés — ne pas réintroduire « repères affichés » / « frise nue »).
  final String desc;
}

/// Tolérance : 5 % de l'ancienneté, bornée entre 12 et 90 ans, × difficulté.
///
/// Le plancher est à 12 ans (et non 5) : avec 5, atteindre les 700 points
/// du « vert » sur un événement récent demandait l'ANNÉE EXACTE en
/// Difficile — le combo y était donc inatteignable. Le plafond est à 90
/// ans (et non 45) : placer les pyramides à 150 ans près est une bonne
/// réponse, pas un zéro.
double tolerance(int annee, Difficulty diff) {
  final base = ((maxYear - annee) * 0.05).clamp(12.0, 90.0).toDouble();
  return base * diff.tolMult;
}

/// Fenêtre au-delà de laquelle on marque 0 point. Elle reste à 200 ans
/// × difficulté pour les événements récents, mais s'élargit avec la
/// tolérance sur les très anciens, où 200 ans d'erreur ne sont pas une
/// faute grossière.
double maxEcart(int annee, Difficulty diff) => math.max(
      maxEcartBase * diff.tolMult,
      tolerance(annee, diff) * 4.5,
    );

/// Points d'une manche (hors multiplicateur de manche finale).
/// `points = round(1000 * exp(-écart / tolérance))`, 0 au-delà de la fenêtre.
int scoreFor(int annee, int guess, Difficulty diff) {
  final ecart = (guess - annee).abs();
  // Marge d'un cheveu : sans elle, un écart de PILE la fenêtre passait
  // sous le « >= » à cause de l'arithmétique flottante et rapportait
  // encore quelques points.
  if (ecart >= maxEcart(annee, diff) - 1e-9) return 0;
  final pts = (maxScore * math.exp(-ecart / tolerance(annee, diff))).round();
  return pts.clamp(0, maxScore).toInt();
}

/// Verdict d'une manche. SOURCE UNIQUE : le badge de révélation, la
/// couleur des points, le trait d'écart, la pastille de manche, la grille
/// emoji de partage et la série se calent tous dessus. Sans ça, le même
/// écran pouvait annoncer « dans la cible 🎯 » en menthe et « série
/// perdue » juste en dessous.
enum Verdict { reussi, moyen, rate }

Verdict verdictFor(int base) => base >= 700
    ? Verdict.reussi
    : base >= 350
        ? Verdict.moyen
        : Verdict.rate;

/// La dernière manche d'une partie classique/quotidienne vaut double.
int roundMultiplier(int roundIndex, {bool chrono = false}) {
  return (!chrono && roundIndex == rounds - 1) ? 2 : 1;
}
