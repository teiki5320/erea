import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sons du jeu — famille « bois & feutre » : marimba pour les verdicts,
/// cran de roue en bois pour le glissement. Six petits WAV embarqués
/// (99 Ko au total), joués en local : rien ne part sur le réseau, l'app
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

  /// … et un petit tour de rôle pour le cliquetis. Avec un seul lecteur,
  /// chaque cran couperait le précédent : à 20 crans par seconde on
  /// entendrait un hachis, pas un mécanisme.
  static final List<AudioPlayer> _crans =
      List.generate(4, (i) => AudioPlayer(playerId: 'cran$i'));
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
        // Mode faible latence : indispensable pour un cliquetis qui doit
        // coller au doigt.
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource('sfx/tick.wav'));
        await p.setVolume(0.30);
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

  /// Un cran de la frise. Bridé à 45 ms : au-delà de ~22 crans par
  /// seconde, l'oreille n'entend plus qu'un bourdonnement.
  static void cran() {
    if (!actif || !_pret) return;
    final maintenant = DateTime.now().millisecondsSinceEpoch;
    if (maintenant - _dernierCran < 45) return;
    _dernierCran = maintenant;
    try {
      final p = _crans[_prochainCran];
      _prochainCran = (_prochainCran + 1) % _crans.length;
      p.seek(Duration.zero);
      p.resume();
    } catch (_) {}
  }

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
