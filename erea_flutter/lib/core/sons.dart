import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sons du jeu. Six petits WAV embarqués (84 Ko au total), joués en local :
/// rien ne part sur le réseau, l'app reste jouable hors ligne.
///
/// Tout est enveloppé de try/catch : sur un appareil où l'audio est
/// indisponible, le jeu doit continuer sans broncher — un son manquant
/// n'est jamais une raison d'interrompre une partie.
class Sons {
  Sons._();

  /// Réglable par le joueur (écran de réglages).
  static bool actif = true;

  static final AudioPlayer _joueur = AudioPlayer();
  static final AudioPlayer _cadran = AudioPlayer();
  static bool _pret = false;
  static int _dernierTick = 0;

  static Future<void> preparer() async {
    if (_pret) return;
    try {
      // Catégorie « ambient » : Erea respecte le bouton silencieux de
      // l'iPhone et n'interrompt pas la musique en cours.
      await _joueur.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _joueur.setReleaseMode(ReleaseMode.stop);
      await _cadran.setReleaseMode(ReleaseMode.stop);
      _pret = true;
    } catch (e) {
      debugPrint('Sons indisponibles : $e');
    }
  }

  static Future<void> _jouer(AudioPlayer p, String nom, double volume) async {
    if (!actif) return;
    try {
      await p.stop();
      await p.setVolume(volume);
      await p.play(AssetSource('sfx/$nom.wav'));
    } catch (_) {
      // Silence : jamais au prix de la partie.
    }
  }

  /// Cran du cadran en franchissant une dizaine d'années. Bridé, sinon un
  /// glissement rapide en déclencherait des dizaines par seconde.
  static void decennie() {
    if (!actif) return;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    if (maintenant - _dernierTick < 55) return;
    _dernierTick = maintenant;
    _jouer(_cadran, 'tick', 0.25);
  }

  static void validation() => _jouer(_joueur, 'pop', 0.5);
  static void reussi() => _jouer(_joueur, 'bien', 0.55);
  static void moyen() => _jouer(_joueur, 'moyen', 0.5);
  static void rate() => _jouer(_joueur, 'rate', 0.45);
  static void parfait() => _jouer(_joueur, 'parfait', 0.6);

  static Future<void> liberer() async {
    try {
      await _joueur.dispose();
      await _cadran.dispose();
    } catch (_) {}
  }
}
