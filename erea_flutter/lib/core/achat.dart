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

  /// Issue de l'achat ou de la restauration en cours, complétée par le
  /// flux de la boutique : c'est lui, et non un délai, qui dit quand le
  /// joueur a fini.
  static Completer<bool>? _attente;

  static Future<bool> _attendreIssue() {
    final enCours = _attente;
    if (enCours != null && !enCours.isCompleted) return enCours.future;
    return (_attente = Completer<bool>()).future;
  }

  static void _conclure(bool paye) {
    final enCours = _attente;
    if (enCours != null && !enCours.isCompleted) enCours.complete(paye);
  }

  static bool get _dejaPaye => _store?.sansPub ?? false;

  /// À appeler une fois au lancement. Écoute la boutique et met le cache
  /// local à jour. Chez un joueur que le cache croit non acheteur, la
  /// restauration part aussitôt : après une réinstallation ou sur un
  /// nouvel appareil, il retrouve son achat sans toucher « Restaurer »,
  /// et la régie ne démarre pas pour rien. Elle est silencieuse sur les
  /// deux boutiques (droits en cours sur iOS, achats du compte sur
  /// Android) : aucune demande de mot de passe.
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
      if (!store.sansPub) await restaurer();
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
            _conclure(true);
          }
        case PurchaseStatus.error:
          debugPrint('Achat en erreur : ${achat.error}');
          if (achat.productID == idSansPub) _conclure(false);
        case PurchaseStatus.canceled:
        // En attente de l'accord d'un parent : le joueur n'a pas payé
        // aujourd'hui ; l'achat arrivera par le flux s'il est accepté.
        case PurchaseStatus.pending:
          if (achat.productID == idSansPub) _conclure(false);
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

  /// Lance l'achat et attend que le joueur en ait fini. Retourne null si
  /// la boutique n'a pas pu s'ouvrir ; sinon true s'il a payé, false s'il
  /// a renoncé, si le paiement a échoué ou s'il attend l'accord d'un
  /// parent.
  static Future<bool?> acheter() async {
    if (!disponible) return null;
    final issue = _attendreIssue();
    try {
      final reponse = await _boutique.queryProductDetails({idSansPub});
      final produit =
          reponse.productDetails.where((p) => p.id == idSansPub).firstOrNull;
      if (produit != null &&
          await _boutique.buyNonConsumable(
            purchaseParam: PurchaseParam(productDetails: produit),
          )) {
        // Filet pour une boutique qui ne répondrait jamais : le joueur ne
        // reste pas bloqué devant « Un instant… ».
        return await issue.timeout(const Duration(minutes: 10),
            onTimeout: () => _dejaPaye);
      }
    } catch (e) {
      debugPrint('Achat impossible : $e');
    }
    _conclure(false);
    return null;
  }

  /// Restaure un achat déjà payé, sur un nouvel appareil ou après une
  /// réinstallation. Retourne vrai si le joueur est (désormais) acheteur.
  ///
  /// La boutique restitue les achats par le flux, puis se tait : elle ne
  /// signale jamais qu'il n'y avait rien. Le délai ne court donc qu'après
  /// sa réponse, pour laisser le flux livrer ce qu'elle a trouvé.
  static Future<bool> restaurer() async {
    final issue = _attendreIssue();
    try {
      await _boutique.restorePurchases();
    } catch (e) {
      debugPrint('Restauration impossible : $e');
      _conclure(_dejaPaye);
    }
    return issue.timeout(const Duration(seconds: 5),
        onTimeout: () => _dejaPaye);
  }

  static Future<void> arreter() async {
    await _flux?.cancel();
    _flux = null;
  }
}
