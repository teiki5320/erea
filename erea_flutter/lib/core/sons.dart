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

  /// Un lecteur pour les verdicts…
  static final AudioPlayer _joueur = AudioPlayer();

  /// … et un tour de rôle pour le cliquetis. Avec un seul lecteur, chaque
  /// cran couperait le précédent : à 20 crans par seconde on entendrait un
  /// hachis, pas un mécanisme.
  ///
  /// Six lecteurs et non quatre : les crans peuvent se suivre toutes les
  /// 26 ms pour une pointe qui dure ~32 ms, donc il faut de quoi en
  /// superposer une poignée sans jamais rattraper le premier.
  ///
  /// Le nombre est PAIR à dessein. Les rangs pairs jouent le tic, les
  /// impairs le tac, si bien que le tour de rôle alterne les deux tout
  /// seul (voir [alimenter]).
  ///
  /// Le nombre est une constante et non la longueur de la liste : la liste
  /// est paresseuse, et y toucher construirait de vrais [AudioPlayer], donc
  /// ouvrirait un canal de plateforme. Le test de l'alternance n'a pas à
  /// payer ça pour vérifier une parité.
  @visibleForTesting
  static const int nombreLecteursCran = 6;

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

  /// Un cran de la frise. Bridé à 26 ms : c'est la cadence d'un
  /// échappement lancé (~38 par seconde au plus vite), et au-delà
  /// l'oreille n'entendrait plus qu'un bourdonnement.
  ///
  /// `play(source)` et non seek()+resume() : c'est le chemin fiable des
  /// verdicts. Le pool tourne pour qu'un cran ne coupe pas le précédent,
  /// et la parité du rang alterne tic/tac toute seule.
  static void cran() => _cran(26);

  static void _cran(int brideMs) {
    if (!actif || !_pret) return;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    if (maintenant - _dernierCran < brideMs) return;
    _dernierCran = maintenant;
    try {
      final p = _crans[_prochainCran];
      final nom = alimenter(_prochainCran);
      _prochainCran = (_prochainCran + 1) % _crans.length;
      p.play(AssetSource(nom));
    } catch (_) {}
  }

  /// Le cran de la roulette de drapeaux. Bridé plus large (70 ms) : la roue
  /// démarre très vite, et sans ça les crans se chevauchaient en un
  /// bourdonnement à peine audible. À 70 ms on entend des tics distincts
  /// qui s'espacent tout seuls quand la roue ralentit — un vrai cliquet.
  static void cranRoulette() => _cran(70);

  static void validation() => _jouer('pop', 0.5);
  static void reussi() => _jouer('bien', 0.55);
  static void moyen() => _jouer('moyen', 0.5);
  static void rate() => _jouer('rate', 0.45);
  static void parfait() => _jouer('parfait', 0.6);

  static Future<void> liberer() async {
    try {
      await _joueur.dispose();
      for (final p in _crans) {
        await p.dispose();
      }
    } catch (_) {}
  }
}
