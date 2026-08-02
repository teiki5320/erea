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
  static String classique(String difficulte) => 'erea.classic.$difficulte';

  static bool _connecte = false;
  static bool _tente = false;

  /// Connexion paresseuse. Retourne false sans bruit si Game Center est
  /// indisponible.
  static Future<bool> connecter() async {
    if (_connecte) return true;
    if (_tente) return false; // une seule tentative par lancement
    _tente = true;
    try {
      final signed = await GameAuth.isSignedIn;
      if (signed) {
        _connecte = true;
        return true;
      }
      final res = await GameAuth.signIn();
      _connecte = res == 'success';
      return _connecte;
    } catch (e) {
      debugPrint('Game Center indisponible : $e');
      return false;
    }
  }

  static Future<void> envoyer(String tableau, int valeur,
      {int max = 11000}) async {
    // Garde-fou anti-absurde : un score hors barème ne part pas.
    if (valeur < 0 || valeur > max) return;
    if (!await connecter()) return;
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: tableau,
          iOSLeaderboardID: tableau,
          value: valeur,
        ),
      );
    } catch (e) {
      debugPrint('Envoi du score impossible : $e');
    }
  }

  static Future<void> afficher({String? tableau}) async {
    if (!await connecter()) return;
    try {
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: tableau ?? '',
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
    if (!await connecter()) return null;
    try {
      final data = await Leaderboards.getPlayerScoreObject(
        iOSLeaderboardID: tableau,
        androidLeaderboardID: tableau,
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
