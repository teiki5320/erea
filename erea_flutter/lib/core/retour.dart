import 'package:flutter/services.dart';

/// Retour haptique du jeu. Aucune dépendance externe : iOS fournit les
/// trois intensités dont on a besoin.
///
/// Trois moments seulement, pour que ça reste un signal et pas un bruit :
/// - [decennie] : cran léger en franchissant une dizaine d'années pendant
///   le glissement (bridé, sinon il partirait 120 fois par seconde) ;
/// - [validation] : impact moyen quand on pose sa réponse ;
/// - [parfait] : impact fort sur une réponse exacte.
class Retour {
  Retour._();

  /// Réglable par le joueur (écran de réglages).
  static bool actif = true;

  static int _dernierCran = 0;

  static void decennie() {
    if (!actif) return;
    // Bride à 45 ms : à 120 Hz, un glissement rapide traverserait
    // plusieurs dizaines par frame.
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    if (maintenant - _dernierCran < 45) return;
    _dernierCran = maintenant;
    HapticFeedback.selectionClick();
  }

  static void validation() {
    if (actif) HapticFeedback.mediumImpact();
  }

  static void parfait() {
    if (actif) HapticFeedback.heavyImpact();
  }
}
