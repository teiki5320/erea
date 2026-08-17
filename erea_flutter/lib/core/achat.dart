import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/store.dart';

/// « Erea sans pub » : un achat unique, non consommable, définitif.
///
/// Ce qu'il débloque : rien. Il ENLÈVE — la publicité, et c'est tout.
/// Aucun événement, aucun mode, aucune fonction n'est réservé à ceux qui
/// paient : le jeu complet reste gratuit, ce qui est la promesse faite
/// dans la description de la fiche.
///
/// Trois principes tenus ici :
/// - **la boutique est la source de vérité.** `Store.sansPub` n'est qu'un
///   cache local, pour ne pas attendre le réseau avant de savoir s'il
///   faut préparer une régie publicitaire ;
/// - **la restauration est obligatoire.** Un joueur qui change de
///   téléphone doit retrouver son achat sans repayer, et Apple refuse
///   toute app qui n'offre pas ce bouton ;
/// - **tout échec est silencieux.** Boutique indisponible, achat annulé,
///   paiement refusé : le jeu continue, avec de la publicité.
class Achat {
  Achat._();

  /// Identifiant du produit, identique sur les deux boutiques. À créer à
  /// l'identique dans App Store Connect (non consommable) et dans la Play
  /// Console (produit unique).
  static const String idSansPub = 'com.teiki.erea.sanspub';

  static final InAppPurchase _boutique = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _flux;
  static Store? _store;

  /// Prix formaté par la boutique (« 3,99 € »), ou null si elle n'a pas
  /// répondu. On n'écrit JAMAIS le prix en dur dans l'interface : il
  /// dépend du pays, de la devise et des taxes locales.
  static String? prix;

  /// Vrai dès que la boutique a confirmé qu'elle est joignable et que le
  /// produit existe. Tant que c'est faux, l'interface ne propose rien
  /// plutôt que de proposer un bouton qui échouerait.
  static bool disponible = false;

  /// À appeler une fois au lancement. Écoute la boutique et met le cache
  /// local à jour — y compris pour un achat fait sur un autre appareil,
  /// qu'iOS restitue spontanément.
  static Future<void> demarrer(Store store) async {
    _store = store;
    try {
      if (!await _boutique.isAvailable()) return;

      _flux ??= _boutique.purchaseStream.listen(
        _traiter,
        onError: (Object e) => debugPrint('Flux d’achats interrompu : $e'),
      );

      final reponse = await _boutique.queryProductDetails({idSansPub});
      final produit =
          reponse.productDetails.where((p) => p.id == idSansPub).firstOrNull;
      if (produit == null) {
        debugPrint('Produit $idSansPub introuvable : ${reponse.error}');
        return;
      }
      prix = produit.price;
      disponible = true;
    } catch (e) {
      debugPrint('Boutique indisponible : $e');
    }
  }

  static Future<void> _traiter(List<PurchaseDetails> achats) async {
    for (final achat in achats) {
      switch (achat.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (achat.productID == idSansPub) {
            await _store?.setSansPub(true);
          }
        case PurchaseStatus.error:
          debugPrint('Achat en erreur : ${achat.error}');
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }
      // À faire dans TOUS les cas terminés, sinon la boutique represente
      // la transaction à chaque lancement, indéfiniment.
      if (achat.pendingCompletePurchase) {
        try {
          await _boutique.completePurchase(achat);
        } catch (e) {
          debugPrint('Transaction non clôturée : $e');
        }
      }
    }
  }

  /// Lance l'achat. Retourne false si la boutique n'a pas pu l'ouvrir —
  /// le résultat, lui, arrive par le flux, pas par cette valeur.
  static Future<bool> acheter() async {
    if (!disponible) return false;
    try {
      final reponse = await _boutique.queryProductDetails({idSansPub});
      final produit =
          reponse.productDetails.where((p) => p.id == idSansPub).firstOrNull;
      if (produit == null) return false;
      return await _boutique.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: produit),
      );
    } catch (e) {
      debugPrint('Achat impossible : $e');
      return false;
    }
  }

  /// Restaure un achat déjà payé, sur un nouvel appareil ou après une
  /// réinstallation. Le résultat passe par le flux, comme un achat neuf.
  static Future<void> restaurer() async {
    try {
      await _boutique.restorePurchases();
    } catch (e) {
      debugPrint('Restauration impossible : $e');
    }
  }

  static Future<void> arreter() async {
    await _flux?.cancel();
    _flux = null;
  }
}
