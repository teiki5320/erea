import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

/// Classement mondial via Game Center. Zéro serveur à opérer : Apple gère
/// l'identité, le consentement parental des comptes enfants et l'écran de
/// classement lui-même.
///
/// Règles tenues ici :
/// - la connexion est PARESSEUSE : jamais au lancement, seulement à la
///   première fin de défi ou au tap sur « classement ». Une fenêtre Game
///   Center au démarrage est intrusive et perturbe un enfant ;
/// - tout échec est silencieux : sur un appareil où Game Center est
///   désactivé par le contrôle parental, le jeu doit rester entièrement
///   jouable ;
/// - les scores sont bornés avant envoi : un total hors barème ne part
///   pas.
class Classement {
  Classement._();

  /// Identifiants à créer à l'identique dans App Store Connect →
  /// Game Center. `defi` doit être un classement RÉCURRENT remis à zéro
  /// toutes les 24 h — sinon deux versions de l'app, avec des questions
  /// différentes, se retrouveraient dans le même tableau.
  static const String defi = 'erea.daily';
  static const String serie = 'erea.streak';
  static const String chrono = 'erea.chrono';
  static String classique(String difficulte) => 'erea.classic.$difficulte';

  /// Play Games ne laisse PAS choisir ses identifiants : la Play Console
  /// en génère un par classement, opaque et immuable. Les nôtres, ci-dessus,
  /// restent donc la clé du code — cette table les traduit pour Android.
  ///
  /// Tant qu'elle est vide, Android n'envoie rien et n'affiche rien : le
  /// jeu reste entièrement jouable, classements masqués, exactement comme
  /// sur un appareil où Game Center est désactivé.
  ///
  /// À remplir en recopiant les identifiants de la Play Console, une fois
  /// les six classements créés (voir docs/FICHE_PLAY_STORE.md §7).
  static const Map<String, String> _playGames = {
    // defi:                    'CgkI...',
    // serie:                   'CgkI...',
    // chrono:                  'CgkI...',
    // 'erea.classic.facile':   'CgkI...',
    // 'erea.classic.normal':   'CgkI...',
    // 'erea.classic.difficile':'CgkI...',
  };

  static bool get _surAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  /// L'identifiant à donner au plugin pour Android, ou null s'il manque.
  static String? _pourAndroid(String tableau) => _playGames[tableau];

  /// Vrai quand la plateforme courante ne sait pas nommer ce tableau :
  /// on s'abstient alors, plutôt que d'envoyer un identifiant vide.
  static bool _sansTableau(String tableau) =>
      _surAndroid && _pourAndroid(tableau) == null;

  static bool _connecte = false;

  /// Connexion EN COURS, partagée : les trois requêtes de rang du bloc
  /// d'accueil partent en parallèle — sans ce partage, chacune lançait sa
  /// propre tentative et deux sur trois échouaient à froid.
  static Future<bool>? _enCours;

  /// Dernier échec : on ne retente pas en boucle, mais on retente. La
  /// version précédente (« une seule tentative par lancement ») rendait
  /// tout Game Center définitivement muet après un simple raté réseau au
  /// démarrage — jusqu'à perdre l'envoi du score du défi du jour.
  static DateTime? _dernierEchec;
  static const Duration _repit = Duration(minutes: 1);

  /// Connexion paresseuse, partagée et ré-essayable. Retourne false sans
  /// bruit si Game Center est indisponible.
  static Future<bool> connecter() {
    if (_connecte) return Future.value(true);
    final echec = _dernierEchec;
    if (echec != null && DateTime.now().difference(echec) < _repit) {
      return Future.value(false);
    }
    return _enCours ??= _connecterVraiment().whenComplete(() {
      _enCours = null;
    });
  }

  static Future<bool> _connecterVraiment() async {
    try {
      final signed = await GameAuth.isSignedIn;
      if (!signed) {
        final res = await GameAuth.signIn();
        if (res != 'success') {
          _dernierEchec = DateTime.now();
          return false;
        }
      }
      _connecte = true;
      _dernierEchec = null;
      return true;
    } catch (e) {
      debugPrint('Game Center indisponible : $e');
      _dernierEchec = DateTime.now();
      return false;
    }
  }

  static Future<void> envoyer(String tableau, int valeur,
      {int max = 11000}) async {
    // Garde-fou anti-absurde : un score hors barème ne part pas.
    if (valeur < 0 || valeur > max) return;
    if (_sansTableau(tableau)) return;
    if (!await connecter()) return;
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: _pourAndroid(tableau) ?? '',
          iOSLeaderboardID: tableau,
          value: valeur,
        ),
      );
    } catch (e) {
      debugPrint('Envoi du score impossible : $e');
    }
  }

  static Future<void> afficher({String? tableau}) async {
    if (tableau != null && _sansTableau(tableau)) return;
    if (!await connecter()) return;
    try {
      await Leaderboards.showLeaderboards(
        androidLeaderboardID:
            tableau == null ? '' : (_pourAndroid(tableau) ?? ''),
        iOSLeaderboardID: tableau ?? '',
      );
    } catch (e) {
      debugPrint('Affichage du classement impossible : $e');
    }
  }

  /// Le rang MONDIAL du joueur sur un tableau (portée mondiale, tout temps),
  /// ou null si indisponible.
  ///
  /// Retourne null sans bruit dans tous les cas « normaux » : Game Center
  /// désactivé, joueur pas connecté, ou aucun score déposé sur ce tableau.
  /// L'appelant affiche alors une invite plutôt qu'un rang.
  ///
  /// Sur les tableaux Classique (un par difficulté), ce rang est PERMANENT :
  /// il existe dès que la difficulté a été jouée, contrairement au défi du
  /// jour qui repart de zéro chaque nuit.
  static Future<int?> rang(String tableau) async {
    if (_sansTableau(tableau)) return null;
    if (!await connecter()) return null;
    try {
      final data = await Leaderboards.getPlayerScoreObject(
        iOSLeaderboardID: tableau,
        androidLeaderboardID: _pourAndroid(tableau) ?? '',
        scope: PlayerScope.global,
        timeScope: TimeScope.allTime,
      );
      final r = data?.rank;
      // Un rang nul ou négatif n'a pas de sens : on le traite comme absent.
      return (r != null && r > 0) ? r : null;
    } catch (e) {
      // Cas fréquent et sans gravité : aucun score encore déposé.
      debugPrint('Rang indisponible : $e');
      return null;
    }
  }
}
