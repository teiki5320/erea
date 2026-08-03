import '../core/progression.dart';
import '../core/scoring.dart';
import '../data/events_repository.dart';
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
  Badge(
      'premiers-pas', 'Premiers pas', '👣', 'Termine une partie', _premiersPas),
  Badge('perfect', 'Pile dessus', '🎯', 'Trouve une année exacte', _perfect),
  Badge('triple-perfect', 'Triplé', '🎪', 'Trois années exactes en une partie',
      _triplePerfect),
  Badge('8000', 'Grand score', '💫', 'Dépasse 8 000 points en une partie',
      _huitMille),
  Badge('touche-a-tout', 'Touche-à-tout', '🎨',
      'Joue les 4 catégories de thème', _toucheATout),
  Badge('10-parties', 'Habitué', '🔁', 'Joue 10 parties', _dixParties),
  Badge('50-parties', 'Pilier', '🏛️', 'Joue 50 parties', _cinquanteParties),
  Badge('difficile', 'Tête brûlée', '🔥', 'Marque des points en Difficile',
      _difficile),
  Badge(
      'serie-3', 'Trois jours', '📅', 'Trois défis du jour d’affilée', _serie3),
  Badge(
      'serie-7', 'Une semaine', '🗓️', 'Sept défis du jour d’affilée', _serie7),
  Badge('chrono-6000', 'Éclair', '⚡', 'Marque 6 000 points en Chrono',
      _chrono6000),
  Badge('roulette', 'Globe-trotteur', '🎡', 'Termine une partie de Roulette',
      _roulette),
  Badge('100-decouvertes', 'Collectionneur', '📚', 'Découvre 100 événements',
      _centDecouvertes),
  Badge(
      'niveau-10', 'Maître du temps', '👑', 'Atteins le niveau 10', _niveau10),
];

bool _premiersPas(Store s, GameController? g) => s.games >= 1;
bool _perfect(Store s, GameController? g) => (g?.perfects ?? 0) >= 1;
bool _triplePerfect(Store s, GameController? g) => (g?.perfects ?? 0) >= 3;
bool _huitMille(Store s, GameController? g) => (g?.total ?? 0) >= 8000;
// Les quatre catégories THÉMATIQUES, nommément. L'ancien prédicat
// comptait « toute clé qui n'est ni 'tout' ni un pack » et exigeait 5 :
// depuis la migration à 4 thèmes, c'était inatteignable par les
// catégories, et débloqué à tort par cinq PAYS de la roulette (clés
// 'pays:…', ni 'tout' ni 'pack:'). On énumère les vraies catégories.
final Set<String> _themesJouables =
    categories.map((c) => c.key).where((k) => k != 'tout').toSet();
bool _toucheATout(Store s, GameController? g) =>
    _themesJouables.every(s.catsPlayed.contains);
bool _dixParties(Store s, GameController? g) => s.games >= 10;
bool _cinquanteParties(Store s, GameController? g) => s.games >= 50;
bool _difficile(Store s, GameController? g) =>
    g != null && g.diff == Difficulty.difficile && g.total > 0;
bool _serie3(Store s, GameController? g) => s.effectiveStreak >= 3;
bool _serie7(Store s, GameController? g) => s.effectiveStreak >= 7;
// L'ancien « Éclair » exigeait 12 manches en Chrono — le mode n'en a que
// 10 : succès mathématiquement inatteignable, tout comme « Duelliste »
// (aucun écran ne lance GameMode.duel). Remplacés par deux objectifs
// réels ; les clés changent, personne n'avait pu les débloquer.
bool _chrono6000(Store s, GameController? g) =>
    g != null && g.mode == GameMode.chrono && g.total >= 6000;
bool _roulette(Store s, GameController? g) =>
    g != null && g.mode == GameMode.roulette && g.results.length >= rounds;
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
