/// Courbe d'XP et titres de niveaux.
library;

/// XP nécessaire pour passer du niveau [level] au suivant.
int xpNeededFor(int level) => 400 + (level - 1) * 300;

class LevelInfo {
  final int level;
  final int into; // XP accumulée dans le niveau courant
  final int need; // XP nécessaire pour le niveau suivant
  const LevelInfo(this.level, this.into, this.need);
}

LevelInfo levelFromXp(int xp) {
  var level = 1;
  var rest = xp;
  while (rest >= xpNeededFor(level)) {
    rest -= xpNeededFor(level);
    level++;
  }
  return LevelInfo(level, rest, xpNeededFor(level));
}

class LevelTitle {
  final int minLevel;
  final String titre;
  final String emoji;
  const LevelTitle(this.minLevel, this.titre, this.emoji);
}

const List<LevelTitle> levelTitles = [
  LevelTitle(1, 'Apprenti du temps', '🐣'),
  LevelTitle(2, 'Curieux d’histoire', '🔍'),
  LevelTitle(3, 'Explorateur', '🧭'),
  LevelTitle(4, 'Voyageur temporel', '⏳'),
  LevelTitle(5, 'Aventurier', '🗺️'),
  LevelTitle(6, 'Chasseur de dates', '🎯'),
  LevelTitle(7, 'Historien', '📚'),
  LevelTitle(9, 'Sage', '🦉'),
  LevelTitle(10, 'Maître du temps', '👑'),
  LevelTitle(13, 'Légende', '🌟'),
  // Un bon joueur atteignait le niveau 13 vers la 27e partie et ne voyait
  // plus jamais rien de neuf : la progression continue bien au-delà.
  LevelTitle(16, 'Érudit', '🎓'),
  LevelTitle(20, 'Archiviste', '🗄️'),
  LevelTitle(25, 'Oracle', '🔮'),
  LevelTitle(30, 'Gardien du temps', '⏰'),
  LevelTitle(40, 'Mémoire du monde', '🌍'),
  LevelTitle(50, 'Immortel', '💎'),
];

LevelTitle titleFor(int level) {
  var t = levelTitles.first;
  for (final item in levelTitles) {
    if (level >= item.minLevel) t = item;
  }
  return t;
}

/// Plafond d'XP pour une partie, bonus de combo compris.
const int maxXpPerGame = 2000;

/// XP d'une manche : points/10 × multiplicateur de difficulté, × 1,5 si la
/// manche bénéficiait du bonus de combo.
///
/// Les points passés ici sont ceux que la réponse aurait obtenus en
/// NORMAL (voir GameController.validate) : sur les points affichés, la
/// marge réduite de Difficile écrasait le score plus vite que ×1,75 ne
/// compensait, et Facile rapportait davantage dès ~12 ans d'erreur
/// moyenne. L'XP d'une partie est la SOMME de ces valeurs, chaque manche
/// étant déjà rognée au budget [maxXpPerGame] restant : ce qui est
/// annoncé à chaque révélation est exactement ce qui est crédité.
int xpForRound(int pts, double xpMult, {bool boosted = false}) =>
    (pts / 10 * xpMult * (boosted ? 1.5 : 1)).round();

/// XP d'une partie à partir du seul total de points (sans combo) : utilisé
/// pour les estimations et les tests de barème.
int xpGain(int total, double xpMult) {
  final gain = (total / 10 * xpMult).round();
  return gain.clamp(0, maxXpPerGame).toInt();
}
