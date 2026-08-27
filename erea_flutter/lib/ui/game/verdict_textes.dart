/// Les phrases du verdict, séparées de l'écran qui les affiche.
///
/// Elles ne dépendent que du résultat d'une manche : ni contexte, ni
/// état, ni widget. Les sortir de `game_screen.dart` les rend lisibles
/// d'un coup d'œil et testables sans monter une interface — c'est ce
/// qu'un joueur lit ou entend à chaque manche, le texte le plus vu du
/// jeu.
library;

import '../../core/avis.dart';
import '../../core/scoring.dart';
import '../../data/events_repository.dart';
import '../../data/store.dart';
import '../../core/timeline_scale.dart';
import '../../game/game_controller.dart';

/// L'exclamation du bandeau, calée sur les paliers du barème (SPEC §3).
String reactionPour(RoundResult r) {
  if (r.tempsEcoule) return 'TEMPS ÉCOULÉ !';
  if (r.base == maxScore) return 'PILE DESSUS !';
  if (r.base >= 900) return 'Incroyable !';
  if (r.base >= 700) return 'Excellent !';
  if (r.base >= 500) return 'Bien joué !';
  if (r.base >= 250) return 'Pas mal !';
  if (r.base >= 80) return 'Pas loin…';
  return 'Trop loin !';
}

/// L'écart, dit dans le sens du temps : « 5 ans trop tôt ⏩ ».
String directionPour(RoundResult r) {
  // Temps écoulé avec le curseur pile dessus : le dire, sinon l'écran
  // afficherait « Année exacte ! » à côté de zéro point.
  if (r.tempsEcoule && r.ecart == 0) return 'Tu y étais… trop tard ⏱';
  if (r.ecart == 0) return 'Année exacte !';
  final unit = r.ecart == 1 ? 'an' : 'ans';
  return r.guess < r.event.annee
      ? '${r.ecart} $unit trop tôt ⏩'
      : '${r.ecart} $unit trop tard ⏪';
}

/// La phrase que VoiceOver lit d'une traite à la révélation. Le badge,
/// les points et le trait d'écart racontent le verdict aux yeux ; sans
/// elle, le moment le plus important d'une manche était muet.
String resumeVocalPour(RoundResult r) {
  final ecart = r.ecart == 0
      ? 'Année exacte !'
      : '${r.ecart} ${r.ecart == 1 ? 'an' : 'ans'} '
          '${r.guess < r.event.annee ? 'trop tôt' : 'trop tard'}.';
  return '${reactionPour(r)} La bonne année était '
      '${formatYear(r.event.annee)}. Ta réponse : ${formatYear(r.guess)}. '
      '$ecart ${r.pts} points.';
}

/// La grille du partage, une lettre par manche : vert, jaune, rouge.
/// Mêmes seuils que la pastille de manche et que le bandeau ci-dessus —
/// un seul verdict pour tout le jeu.
String grillePour(List<RoundResult> results) => results
    .map((r) => r.base >= 700
        ? 'g'
        : r.base >= 350
            ? 'y'
            : 'r')
    .join();

/// Le texte du partage, sans spoiler : score, grille emoji, et la série
/// pour le défi du jour.
String texteGrillePour(GameController game, Store store) {
  final quoi = game.mode == GameMode.daily
      ? 'Défi du jour'
      : game.mode == GameMode.chrono
          ? 'Chrono ⏱'
          : '${playableFor(game.catKey).label} · ${game.diff.label}';
  // En Chrono, pas de manche finale doublée : le maximum est 10 × 1000.
  final max = game.mode == GameMode.chrono ? maxScore * rounds : maxTotal;
  final serie =
      game.mode == GameMode.daily && store.effectiveStreak > 0
          ? '\n🔥 ${store.effectiveStreak} jours d’affilée'
          : '';
  return 'Erea ⏳ $quoi\n${game.total} / $max\n'
      '${game.emojiGrid()}$serie\n\n$lienAppStore';
}
