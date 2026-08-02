import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sons du jeu — marimba pour les verdicts, échappement de montre
/// mécanique pour le glissement de la frise. Sept petits WAV embarqués
/// (~104 Ko au total), joués en local : rien ne part sur le réseau, l'app
/// reste jouable hors ligne.
///
/// Tout est enveloppé de try/catch : sur un appareil où l'audio est
/// indisponible, le jeu doit continuer sans broncher — un son manquant
/// n'est jamais une raison d'interrompre une partie.
class Sons {
  Sons._();

  /// Réglable par le joueur (écran de réglages).
  static bool actif = true;

  /// Un lecteur pour les verdicts (et le carillon de succès, joué en fin de
  /// partie quand ce lecteur est libre)…
  static final AudioPlayer _joueur = AudioPlayer();

  /// … un lecteur à part pour les petits sons d'interface (appui, retour,
  /// clac de roulette). Séparé des verdicts pour qu'un appui de bouton ne
  /// coupe jamais un jingle, et l'inverse.
  static final AudioPlayer _ui = AudioPlayer(playerId: 'ui');

  /// … et un tour de rôle pour le cliquetis. Chaque cran est joué EXACTEMENT
  /// comme un verdict — `await stop()` puis `play(source)` dans une fonction
  /// async — parce que c'est le seul chemin qui n'a jamais lâché. Les
  /// versions précédentes (mode faible latence + seek/resume, puis play()
  /// sans stop ni await) se figeaient au bout de quelques secondes.
  ///
  /// Un tour de rôle sur quatre lecteurs, et non un seul : un cran ne doit
  /// pas couper le précédent (sinon un hachis), et sur du normal le stop()
  /// d'un lecteur ne doit pas tomber en plein milieu de sa propre pointe.
  /// À la bride de 55 ms, chaque lecteur n'est resollicité que toutes les
  /// ~220 ms — largement de quoi laisser son stop/play se poser.
  ///
  /// Le nombre est PAIR : les rangs pairs jouent le tic, les impairs le tac,
  /// l'alternance vient donc du tour de rôle (voir [alimenter]).
  @visibleForTesting
  static const int nombreLecteursCran = 4;

  static final List<AudioPlayer> _crans =
      List.generate(nombreLecteursCran, (i) => AudioPlayer(playerId: 'cran$i'));
  static int _prochainCran = 0;

  static bool _pret = false;
  static int _dernierCran = 0;

  static Future<void> preparer() async {
    if (_pret) return;
    try {
      // Catégorie « ambient » : Erea respecte le bouton silencieux de
      // l'iPhone et n'interrompt pas la musique en cours.
      final contexte = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      );
      await _joueur.setAudioContext(contexte);
      await _joueur.setReleaseMode(ReleaseMode.stop);
      await _ui.setAudioContext(contexte);
      await _ui.setReleaseMode(ReleaseMode.stop);
      for (final p in _crans) {
        await p.setAudioContext(contexte);
        await p.setReleaseMode(ReleaseMode.stop);
        // PAS de mode « faible latence » : sur iOS il passe par un chemin
        // natif qui, sollicité par seek()+resume() des dizaines de fois,
        // se fige au bout de quelques secondes — le cliquetis mourait
        // après ~10 s et ne revenait plus. Les sons de verdict, eux, n'ont
        // jamais lâché : ils passent par play() sur un lecteur normal.
        // Les crans empruntent désormais exactement ce chemin éprouvé.
        await p.setVolume(0.5);
      }
      _pret = true;
    } catch (e) {
      debugPrint('Sons indisponibles : $e');
    }
  }

  static Future<void> _jouer(String nom, double volume) async {
    if (!actif) return;
    try {
      await _joueur.stop();
      await _joueur.setVolume(volume);
      await _joueur.play(AssetSource('sfx/$nom.wav'));
    } catch (_) {
      // Silence : jamais au prix de la partie.
    }
  }

  /// Quel échantillon pour le lecteur de rang [i].
  ///
  /// Une vraie montre n'émet pas deux fois le même son : les deux
  /// palettes de l'ancre n'ont ni la même géométrie ni le même point de
  /// contact, d'où le « tic-tac » et non le « tic-tic ». Rejouer un
  /// échantillon unique est exactement ce qui sonnait artificiel avant.
  @visibleForTesting
  static String alimenter(int i) => i.isEven ? 'sfx/tic.wav' : 'sfx/tac.wav';

  /// Un cran de la frise. Bridé à 55 ms (~18 par seconde au plus vite) :
  /// assez pour un mécanisme vivant, assez large pour que chaque lecteur
  /// du tour de rôle ait fini sa pointe avant d'être resollicité.
  static void cran() => _cran(55);

  /// Le cran de la roulette de drapeaux. Bridé plus large (90 ms) : la roue
  /// démarre très vite, et sans ça les crans se chevauchaient en un
  /// bourdonnement à peine audible. À 90 ms on entend des tics distincts
  /// qui s'espacent tout seuls quand la roue ralentit — un vrai cliquet.
  static void cranRoulette() => _cran(90);

  static void _cran(int brideMs) {
    if (!actif || !_pret) return;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    if (maintenant - _dernierCran < brideMs) return;
    _dernierCran = maintenant;
    final rang = _prochainCran;
    _prochainCran = (_prochainCran + 1) % _crans.length;
    // Fire-and-forget, comme les verdicts : le geste est synchrone, la
    // lecture ne doit pas le bloquer.
    _jouerCran(rang);
  }

  static Future<void> _jouerCran(int rang) async {
    try {
      final p = _crans[rang];
      await p.stop();
      await p.play(AssetSource(alimenter(rang)));
    } catch (_) {
      // Silence : jamais au prix de la partie.
    }
  }

  static void validation() => _jouer('pop', 0.5);
  static void reussi() => _jouer('bien', 0.55);
  static void moyen() => _jouer('moyen', 0.5);
  static void rate() => _jouer('rate', 0.45);
  static void parfait() => _jouer('parfait', 0.6);

  /// Petit son d'interface, sur le lecteur [_ui] dédié : jamais au prix
  /// d'un verdict, et un tap ne coupe que le tap précédent.
  static Future<void> _jouerUi(String nom, double volume) async {
    if (!actif || !_pret) return;
    try {
      await _ui.stop();
      await _ui.setVolume(volume);
      await _ui.play(AssetSource('sfx/$nom.wav'));
    } catch (_) {
      // Silence : jamais au prix de la partie.
    }
  }

  /// Le « toc » d'un bouton principal. Volontairement discret : il ponctue
  /// chaque appui sans jamais fatiguer l'oreille.
  static void appui() => _jouerUi('appui', 0.4);

  /// Le son plus grave d'un retour en arrière (fermer, annuler, revenir).
  static void retour() => _jouerUi('retour', 0.42);

  /// Le clac de la roulette qui se cale sur un pays.
  static void drapeau() => _jouerUi('drapeau', 0.5);

  /// Le carillon d'un succès débloqué. Joué sur le lecteur des verdicts,
  /// libre en fin de partie : il peut ainsi sonner par-dessus rien.
  static void badge() => _jouer('badge', 0.55);

  /// Quel son pour un bouton, selon son rôle. Centralisé ici pour que
  /// [PushButton] n'ait qu'à déclarer sa nature.
  static void bouton(SonBouton s) {
    switch (s) {
      case SonBouton.appui:
        appui();
      case SonBouton.retour:
        retour();
      case SonBouton.aucun:
        break;
    }
  }

  static Future<void> liberer() async {
    try {
      await _joueur.dispose();
      await _ui.dispose();
      for (final p in _crans) {
        await p.dispose();
      }
    } catch (_) {}
  }
}

/// Le son attaché à un bouton, selon son rôle. [PushButton] le déclare et
/// [Sons.bouton] le joue — une seule source de vérité pour l'habillage.
enum SonBouton {
  /// Bouton d'action principal : le « toc » d'appui (défaut).
  appui,

  /// Bouton de retour/annulation : le son plus grave.
  retour,

  /// Aucun son propre : le bouton en déclenche déjà un (ex. « Je place ici »
  /// qui joue le « pop » du verdict). Évite le doublon.
  aucun,
}
