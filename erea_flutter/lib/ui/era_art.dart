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

  /// Libère les textures de fond d'écran sous pression mémoire. Ce sont
  /// les plus lourdes après le ruban, et les moins critiques : elles ne
  /// servent qu'à un décor à 30 % d'opacité derrière le contenu.
  /// Le prochain [load] les redécodera — sans ce remise à zéro de
  /// `_loading`, le cache restait vide pour de bon.
  static void libererDecor() {
    for (final img in bgBlur.values) {
      img.dispose();
    }
    bgBlur.clear();
    _loading = null;
    version++;
  }

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

  /// Copie floutée en DEMI-résolution : cette texture n'est affichée que
  /// derrière le contenu, à 30 % d'opacité et déjà floue — la moitié des
  /// pixels suffit, et un flou σ=1 sur une image deux fois plus petite
  /// rend le même σ=2 une fois réaffichée. Économise ~11 Mo de mémoire.
  static Future<ui.Image?> _blurred(ui.Image src) async {
    try {
      final w = (src.width / 2).round();
      final h = (src.height / 2).round();
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final paint = ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..imageFilter = ui.ImageFilter.blur(
            sigmaX: 1, sigmaY: 1, tileMode: ui.TileMode.clamp);
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        paint,
      );
      return await rec.endRecording().toImage(w, h);
    } catch (_) {
      return null;
    }
  }

  static Future<void> load() {
    return _loading ??= () async {
      // Les décors sont affichés au plus à ~1,2x la largeur d'écran :
      // décoder à 1200 px divise la mémoire par ~1,5 sans perte visible.
      // Les 12 chargements partent ENSEMBLE : le temps d'apparition des
      // décors devient celui du plus lent, pas leur somme.
      await Future.wait<void>([
        // Après une libération mémoire, seul ce qui manque est redécodé —
        // sinon on remplacerait des images encore vivantes et on les
        // laisserait fuir.
        for (var i = 0; i < eraThemes.length; i++)
          if (bgBlur[i] == null)
            (bg[i] != null
                ? Future.value(bg[i])
                : _decode(eraThemes[i].bgAsset, targetWidth: 1200)
            ).then((img) async {
              if (img == null) return;
              bg[i] = img;
              final blur = await _blurred(img);
              if (blur != null) bgBlur[i] = blur;
            }),
        for (final e in travelerSpecs.entries)
          if (travelers[e.key] == null)
            _decode(e.value.asset).then((img) {
              if (img != null) travelers[e.key] = img;
            }),
      ]);
      // Planche de repli : utile seulement si une époque n'a pas son fond
      // dédié. Tant que les 6 sont là, ne pas la décoder du tout.
      if (bg.length < eraThemes.length) {
        frise = await _decode('assets/img/frise.webp', targetWidth: 1200);
      }
      version++;
    }();
  }
}
