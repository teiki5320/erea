import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import 'era_theme.dart';

/// Un personnage par époque. `frames > 1` = spritesheet horizontal.
/// `dyFrac` : décalage vertical (fraction de la hauteur du sprite, positif
/// = descendu) pour poser le point de contact au sol sur la ligne.
class TravelerSpec {
  final String asset;
  final int frames;
  final double dyFrac;
  const TravelerSpec(this.asset, [this.frames = 1, this.dyFrac = 0]);
}

const Map<int, TravelerSpec> travelerSpecs = {
  0: TravelerSpec('assets/img/anim-bronze.webp', 6),
  1: TravelerSpec('assets/img/anim-fer.webp', 6),
  2: TravelerSpec('assets/img/anim-antiquite.webp', 7),
  3: TravelerSpec('assets/img/anim-moyenage.webp', 5, 0.26),
  4: TravelerSpec('assets/img/anim-moderne.webp', 10, 0.03),
  5: TravelerSpec('assets/img/anim-contemporaine.webp', 5),
};

/// Cache unique des illustrations, décodées une fois pour toute la vie de
/// l'app : fonds d'époque (bande du ruban ET texture de haut d'écran),
/// personnages, planche de repli. Toute image absente est ignorée.
class EraArt {
  EraArt._();

  static ui.Image? frise;
  static final Map<int, ui.Image> bg = {};

  /// Versions pré-floutées (2 px) des fonds : le flou est payé UNE fois
  /// au chargement, pas à chaque frame de glissement dans EraBackdrop.
  static final Map<int, ui.Image> bgBlur = {};
  static final Map<int, ui.Image> travelers = {};

  /// Incrémenté quand le chargement se termine (force les repaints).
  static int version = 0;

  static Future<void>? _loading;

  static ui.Image? bgFor(int era) => bg[era];

  static Future<ui.Image?> _decode(String asset, {int? targetWidth}) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: targetWidth,
      );
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> _blurred(ui.Image src) async {
    try {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final paint = ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(
            sigmaX: 2, sigmaY: 2, tileMode: ui.TileMode.clamp);
      canvas.drawImage(src, ui.Offset.zero, paint);
      return await rec.endRecording().toImage(src.width, src.height);
    } catch (_) {
      return null;
    }
  }

  static Future<void> load() {
    return _loading ??= () async {
      // Les décors sont affichés au plus à ~1,2x la largeur d'écran :
      // décoder à 1200 px divise la mémoire par ~1,5 sans perte visible.
      frise = await _decode('assets/img/frise.webp', targetWidth: 1200);
      for (var i = 0; i < eraThemes.length; i++) {
        final img = await _decode(eraThemes[i].bgAsset, targetWidth: 1200);
        if (img != null) {
          bg[i] = img;
          final blur = await _blurred(img);
          if (blur != null) bgBlur[i] = blur;
        }
      }
      for (final e in travelerSpecs.entries) {
        final img = await _decode(e.value.asset);
        if (img != null) travelers[e.key] = img;
      }
      version++;
    }();
  }
}
