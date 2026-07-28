import 'package:flutter/services.dart';

/// Retour haptique du jeu. Aucune dépendance externe : iOS fournit les
/// trois intensités dont on a besoin.
///
/// Trois moments seulement, pour que ça reste un signal et pas un bruit :
/// - [cran] : cran léger tous les 24 px de ruban parcourus pendant le
///   glissement (bridé, sinon il partirait 120 fois par seconde) ;
/// - [validation] : impact moyen quand on pose sa réponse ;
/// - [parfait] : impact fort sur une réponse exacte.
class Retour {
  Retour._();

  /// Réglable par le joueur (écran de réglages).
  static bool actif = true;

  static int _dernierCran = 0;

  static void cran() {
    if (!actif) return;
    // Bride à 45 ms, soit près du double de celle du son (26 ms) : une
    // vibration à chaque cran serait un bourdonnement continu dans la
    // main, et viderait la batterie. Un cran sonore sur deux vibre.
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
