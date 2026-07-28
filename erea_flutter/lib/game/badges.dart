import '../core/progression.dart';
import '../core/scoring.dart';
import '../data/store.dart';
import 'game_controller.dart';

/// Les 14 succès de SPEC §6.
///
/// Chacun sait se juger tout seul à partir de ce qui est persisté et de la
/// partie qui vient de finir : aucun compteur supplémentaire à tenir à
/// jour, donc aucun risque de désynchronisation.
class Badge {
  final String cle;
  final String titre;
  final String emoji;
  final String comment;

  /// Vrai si le succès est acquis. [game] est la partie qui vient de se
  /// terminer, ou null quand on évalue hors partie (écran des succès).
  final bool Function(Store store, GameController? game) atteint;

  const Badge(this.cle, this.titre, this.emoji, this.comment, this.atteint);
}

const List<Badge> badges = [
  Badge('premiers-pas', 'Premiers pas', '👣', 'Termine une partie',
      _premiersPas),
  Badge('perfect', 'Pile dessus', '🎯', 'Trouve une année exacte', _perfect),
  Badge('triple-perfect', 'Triplé', '🎪', 'Trois années exactes en une partie',
      _triplePerfect),
  Badge('8000', 'Grand score', '💫', 'Dépasse 8 000 points en une partie',
      _huitMille),
  Badge('touche-a-tout', 'Touche-à-tout', '🎨', 'Joue les 5 catégories',
      _toucheATout),
  Badge('10-parties', 'Habitué', '🔁', 'Joue 10 parties', _dixParties),
  Badge('50-parties', 'Pilier', '🏛️', 'Joue 50 parties', _cinquanteParties),
  Badge('difficile', 'Tête brûlée', '🔥', 'Marque des points en Difficile',
      _difficile),
  Badge('serie-3', 'Trois jours', '📅', 'Trois défis du jour d’affilée',
      _serie3),
  Badge('serie-7', 'Une semaine', '🗓️', 'Sept défis du jour d’affilée',
      _serie7),
  Badge('chrono-12', 'Éclair', '⚡', 'Douze événements en Chrono', _chrono12),
  Badge('duel', 'Duelliste', '⚔️', 'Termine un duel', _duel),
  Badge('100-decouvertes', 'Collectionneur', '📚',
      'Découvre 100 événements', _centDecouvertes),
  Badge('niveau-10', 'Maître du temps', '👑', 'Atteins le niveau 10',
      _niveau10),
];

bool _premiersPas(Store s, GameController? g) => s.games >= 1;
bool _perfect(Store s, GameController? g) => (g?.perfects ?? 0) >= 1;
bool _triplePerfect(Store s, GameController? g) => (g?.perfects ?? 0) >= 3;
bool _huitMille(Store s, GameController? g) => (g?.total ?? 0) >= 8000;
bool _toucheATout(Store s, GameController? g) =>
    s.catsPlayed.where((c) => c != 'tout' && !c.startsWith('pack:')).length >= 5;
bool _dixParties(Store s, GameController? g) => s.games >= 10;
bool _cinquanteParties(Store s, GameController? g) => s.games >= 50;
bool _difficile(Store s, GameController? g) =>
    g != null && g.diff == Difficulty.difficile && g.total > 0;
bool _serie3(Store s, GameController? g) => s.effectiveStreak >= 3;
bool _serie7(Store s, GameController? g) => s.effectiveStreak >= 7;
bool _chrono12(Store s, GameController? g) =>
    g != null && g.mode == GameMode.chrono && g.results.length >= 12;
bool _duel(Store s, GameController? g) =>
    g != null && g.mode == GameMode.duel && g.results.isNotEmpty;
bool _centDecouvertes(Store s, GameController? g) => s.discovered.length >= 100;
bool _niveau10(Store s, GameController? g) => levelFromXp(s.xp).level >= 10;

/// Évalue tous les succès et renvoie ceux qui viennent d'être débloqués.
/// À appeler APRÈS avoir enregistré la partie (XP, parties, découvertes),
/// sinon « niveau 10 » ou « 100 découvertes » manqueraient d'une manche.
List<Badge> nouveauxBadges(Store store, {GameController? game}) {
  final deja = store.badges;
  return [
    for (final b in badges)
      if (!deja.contains(b.cle) && b.atteint(store, game)) b,
  ];
}
