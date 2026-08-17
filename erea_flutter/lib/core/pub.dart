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

  /// Blocs interstitiels du compte AdMob d'Erea (éditeur
  /// `ca-app-pub-2680784147246798`), créés le 17 août 2026 sous le nom
  /// « Fin de partie ».
  ///
  /// Chaque plateforme est une app distincte chez AdMob, avec son propre
  /// identifiant d'app et son propre bloc. Les identifiants d'app, eux,
  /// vivent côté natif :
  /// - `android/app/src/main/AndroidManifest.xml` (APPLICATION_ID) ;
  /// - `ios/Runner/Info.plist` (GADApplicationIdentifier).
  ///
  /// Les quatre valeurs doivent appartenir au même compte, sinon la régie
  /// refuse de servir.
  static const String _blocAndroid =
      'ca-app-pub-2680784147246798/7670278436';
  static const String _blocIOS = 'ca-app-pub-2680784147246798/6744159246';

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
          await _releverOptions();
        },
        (erreur) => debugPrint('Consentement indisponible : ${erreur.message}'),
      );
    } catch (e) {
      debugPrint('Consentement impossible : $e');
    }
  }

  /// Vrai quand Google réclame un point d'entrée permanent vers ses
  /// « options de confidentialité » — en pratique, partout où le
  /// formulaire de consentement s'est affiché.
  ///
  /// Ce n'est pas une politesse : un joueur qui a accepté la publicité
  /// personnalisée doit pouvoir revenir sur son choix à tout moment, sinon
  /// le consentement n'en est pas un. Les réglages n'affichent donc la
  /// ligne que lorsque Google la demande, et jamais chez un acheteur qui
  /// ne voit plus une seule publicité.
  static bool optionsRequises = false;

  static Future<void> _releverOptions() async {
    try {
      final statut =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      optionsRequises = statut == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      optionsRequises = false;
      debugPrint('Options de confidentialité indisponibles : $e');
    }
  }

  /// Rouvre le formulaire de Google pour que le joueur révise son choix.
  ///
  /// Rend la main dans tous les cas, y compris si le formulaire refuse de
  /// s'ouvrir : l'écran de réglages ne doit jamais rester bloqué.
  static Future<void> ouvrirOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((erreur) {
        if (erreur != null) {
          debugPrint('Options de confidentialité : ${erreur.message}');
        }
      });
    } catch (e) {
      debugPrint('Options de confidentialité impossibles : $e');
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
