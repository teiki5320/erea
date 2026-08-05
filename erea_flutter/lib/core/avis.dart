import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../data/store.dart';

/// Lien public de l'app, ajouté au texte partagé : sans lui, une grille
/// qui circule ne mène nulle part.
const String lienAppStore = 'https://apps.apple.com/app/id6794918301';

/// La demande de note, au bon moment et pas plus d'une fois.
///
/// Apple plafonne lui-même ces invitations à trois par an et par
/// utilisateur, et n'affiche rien au-delà — d'où l'importance de ne pas
/// gâcher la cartouche. Deux règles tenues ici :
///
/// - **jamais au premier lancement** ni après une partie ratée : on
///   demande après une réussite, quand le joueur est content ;
/// - **une seule fois**, mémorisée dans le magasin. Même si le système
///   n'a rien affiché (quota atteint, réglage désactivé), on ne
///   redemande pas : le joueur qui refuse ne doit pas être relancé.
class Avis {
  Avis._();

  static final InAppReview _plugin = InAppReview.instance;

  /// Le joueur vient de réussir quelque chose. Retourne true si
  /// l'invitation a réellement été demandée au système.
  ///
  /// [merite] laisse l'appelant décider du moment : un PERFECT, une
  /// série de trois défis, un record battu.
  static Future<bool> proposer(Store store, {required bool merite}) async {
    if (!merite || store.avisDemande) return false;
    try {
      if (!await _plugin.isAvailable()) return false;
      // Marqué AVANT l'appel : si l'app est tuée pendant l'affichage de
      // la fenêtre système, on ne redemandera pas au lancement suivant.
      await store.marquerAvisDemande();
      await _plugin.requestReview();
      return true;
    } catch (e) {
      debugPrint('Demande de note impossible : $e');
      return false;
    }
  }
}
