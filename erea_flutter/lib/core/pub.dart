import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Publicité interstitielle, montrée en quittant l'écran de fin.
///
/// Trois règles tenues ici, dans cet ordre :
/// - **qui a payé ne voit rien.** L'achat « Erea sans pub » coupe la
///   publicité définitivement, sans condition ;
/// - **le Défi du jour n'en porte jamais.** C'est le rituel qui fait
///   revenir les joueurs et alimente le partage : l'abîmer coûterait plus
///   que la publicité ne rapporte ;
/// - **une partie sur deux, et à la sortie.** Jamais pendant une manche,
///   jamais entre deux manches, jamais avant l'écran de fin — le joueur
///   voit toujours son score avant de voir une réclame.
///
/// Et comme partout ailleurs dans le projet : **tout échec est
/// silencieux.** Pas de réseau, consentement refusé, régie muette, SDK
/// absent en test — le jeu continue sans que rien ne le signale.
class Pub {
  Pub._();

  /// ⚠️ IDENTIFIANTS DE DÉMONSTRATION DE GOOGLE.
  ///
  /// Ils renvoient toujours une publicité de test et **ne rapportent
  /// rien**. À remplacer par ceux du compte AdMob d'Erea avant la
  /// publication, aux trois endroits suivants :
  ///
  /// 1. ici, `_blocAndroid` et `_blocIOS` (les blocs interstitiels) ;
  /// 2. `android/app/src/main/AndroidManifest.xml` (APPLICATION_ID) ;
  /// 3. `ios/Runner/Info.plist` (GADApplicationIdentifier).
  ///
  /// Les trois doivent appartenir au même compte AdMob, sinon la régie
  /// refuse de servir.
  static const String _blocAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _blocIOS = 'ca-app-pub-3940256099942544/4411468910';

  static String get _bloc => Platform.isAndroid ? _blocAndroid : _blocIOS;

  static bool _demarre = false;
  static bool _consentementDemande = false;
  static InterstitialAd? _prete;
  static bool _chargeEnCours = false;

  /// Démarre le SDK et récolte le consentement, une seule fois.
  ///
  /// Le formulaire européen (RGPD) est celui de Google : il ne s'affiche
  /// que là où il est exigé, et se souvient de la réponse. On ne charge
  /// aucune publicité avant qu'il soit clos.
  static Future<bool> _preparer() async {
    if (_demarre) return true;
    try {
      if (!_consentementDemande) {
        _consentementDemande = true;
        await _recolterConsentement();
      }
      await MobileAds.instance.initialize();
      _demarre = true;
      _precharger();
      return true;
    } catch (e) {
      debugPrint('Publicité indisponible : $e');
      return false;
    }
  }

  static Future<void> _recolterConsentement() async {
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((erreur) {
              if (erreur != null) {
                debugPrint('Formulaire de consentement : ${erreur.message}');
              }
            });
          } catch (e) {
            debugPrint('Consentement non recueilli : $e');
          }
        },
        (erreur) => debugPrint('Consentement indisponible : ${erreur.message}'),
      );
    } catch (e) {
      debugPrint('Consentement impossible : $e');
    }
  }

  /// Charge la prochaine interstitielle à l'avance : une publicité
  /// demandée au moment de l'afficher arrive trop tard et ne s'affiche
  /// jamais.
  static void _precharger() {
    if (_prete != null || _chargeEnCours) return;
    _chargeEnCours = true;
    InterstitialAd.load(
      adUnitId: _bloc,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _chargeEnCours = false;
          _prete = ad;
        },
        onAdFailedToLoad: (erreur) {
          _chargeEnCours = false;
          debugPrint('Interstitielle non chargée : ${erreur.message}');
        },
      ),
    );
  }

  /// Prépare le terrain sans rien afficher, au lancement de l'app.
  ///
  /// À n'appeler que si le joueur n'a pas acheté : inutile de démarrer une
  /// régie pour quelqu'un qui ne verra jamais de publicité.
  static Future<void> demarrer({required bool sansPub}) async {
    if (sansPub) return;
    await _preparer();
  }

  /// La règle, isolée du SDK pour être vérifiable par un test.
  ///
  /// Une partie sur deux : la parité du compteur de parties suffit, pas
  /// besoin d'une clé de plus dans les préférences.
  static bool doitMontrer({
    required bool sansPub,
    required bool defiDuJour,
    required int partiesJouees,
  }) {
    if (sansPub) return false;
    if (defiDuJour) return false;
    return partiesJouees % 2 == 0;
  }

  /// Montre l'interstitielle si c'est le moment, puis rend la main.
  ///
  /// Retourne toujours, même en cas d'échec : l'appelant enchaîne sur sa
  /// navigation sans avoir à s'en soucier.
  static Future<void> montrerSiDue({
    required bool sansPub,
    required bool defiDuJour,
    required int partiesJouees,
  }) async {
    if (!doitMontrer(
      sansPub: sansPub,
      defiDuJour: defiDuJour,
      partiesJouees: partiesJouees,
    )) {
      return;
    }
    if (!await _preparer()) return;

    final ad = _prete;
    if (ad == null) {
      _precharger(); // pour la prochaine fois
      return;
    }
    _prete = null;
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _precharger();
        },
        onAdFailedToShowFullScreenContent: (ad, erreur) {
          ad.dispose();
          debugPrint('Interstitielle non affichée : ${erreur.message}');
          _precharger();
        },
      );
      await ad.show();
    } catch (e) {
      debugPrint('Affichage de la publicité impossible : $e');
      await ad.dispose();
    }
  }
}
