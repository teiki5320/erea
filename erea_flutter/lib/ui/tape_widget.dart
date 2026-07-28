import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/timeline_scale.dart';
import 'era_art.dart';
import 'era_theme.dart';

/// Le ruban chronologique défilant : bandes d'époques, graduations,
/// années, aiguille fixe au centre. Se pilote par glissement avec inertie.
class TapeWidget extends StatefulWidget {
  const TapeWidget({
    super.key,
    required this.frac,
    required this.onFracChanged,
    this.locked = false,
    this.height = 150,
  });

  /// Largeur du ruban virtuel, en px logiques. Toute vue qui positionne
  /// quelque chose au-dessus de la frise (épingles de révélation) doit
  /// utiliser cette constante plutôt que de la recopier.
  static const double tapeW = 3200;

  /// Position [0, 1] du ruban (l'année sous l'aiguille).
  final double frac;
  final ValueChanged<double> onFracChanged;
  final bool locked;
  final double height;

  @override
  State<TapeWidget> createState() => _TapeWidgetState();
}

class _TapeWidgetState extends State<TapeWidget>
    with SingleTickerProviderStateMixin {
  static const double tapeW = TapeWidget.tapeW;

  Ticker? _ticker;
  double _velocity = 0; // px par frame de référence (16,7 ms)
  Duration _lastTick = Duration.zero;

  // Sens de marche des personnages : on avance dans le temps → ils vont
  // vers la gauche avec le paysage ; on recule → ils font demi-tour.
  double _lastFrac = -1;
  bool _facingLeft = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    EraArt.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    // Amortissement basé sur le temps réel : même glisse à 60 ou 120 Hz.
    final dtMs = _lastTick == Duration.zero
        ? 16.7
        : (elapsed - _lastTick).inMicroseconds / 1000.0;
    _lastTick = elapsed;
    final frames = dtMs / 16.7;
    _velocity *= math.pow(0.94, frames).toDouble();
    if (_velocity.abs() < 0.3 || widget.locked) {
      _ticker?.stop();
      return;
    }
    final next =
        (widget.frac - _velocity * frames / tapeW).clamp(0.0, 1.0).toDouble();
    widget.onFracChanged(next);
    if (next <= 0.0 || next >= 1.0) _ticker?.stop();
  }

  void _onDragStart(DragStartDetails details) {
    _ticker?.stop();
    _velocity = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.locked) return;
    final dx = details.delta.dx;
    // Réglage fin : quand le doigt ralentit, le ruban défile moins vite.
    final speed = dx.abs(); // px par événement
    final factor = (0.4 + speed * 0.12).clamp(0.4, 1.0).toDouble();
    final next = (widget.frac - dx * factor / tapeW).clamp(0.0, 1.0).toDouble();
    widget.onFracChanged(next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.locked) return;
    // Vitesse en px/s -> px/frame (60 fps), bornée comme sur le web.
    _velocity = (details.velocity.pixelsPerSecond.dx / 60)
        .clamp(-48.0, 48.0)
        .toDouble();
    if (_velocity.abs() > 0.8 && !(_ticker?.isActive ?? true)) {
      _lastTick = Duration.zero;
      _ticker?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastFrac >= 0 && (widget.frac - _lastFrac).abs() > 1e-7) {
      _facingLeft = widget.frac > _lastFrac;
    }
    _lastFrac = widget.frac;
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            // Couche isolée : le ruban se repeint à chaque pixel de
            // glissement (jusqu'à 120 Hz) sans entraîner la carte, les
            // boutons et leurs ombres floues dans la re-rastérisation.
            Positioned.fill(
              child: RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _TapePainter(
                      frac: widget.frac,
                      tapeW: tapeW,
                      frise: EraArt.frise,
                      artVersion: EraArt.version,
                      facingLeft: _facingLeft,
                    ),
                  ),
                ),
              ),
            ),
            // Aiguille fixe au centre
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 4,
                height: widget.height,
                decoration: BoxDecoration(
                  color: const Color(0xFFF25B4D),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.white70, spreadRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  _TapePainter({
    required this.frac,
    required this.tapeW,
    this.frise,
    this.artVersion = 0,
    this.facingLeft = false,
  });

  final double frac;
  final double tapeW;

  /// Sens de marche des personnages (dessinés vers la droite dans les
  /// planches ; miroir quand on avance dans le temps).
  final bool facingLeft;

  /// Planche des panneaux d'époques (6 cellules côte à côte), ou null
  /// tant qu'elle n'est pas décodée.
  final ui.Image? frise;

  /// Incrémenté quand les images finissent de charger (force le repaint).
  final int artVersion;

  double _px(num year) => yearToFrac(year) * tapeW;

  /// Textes du ruban (années, noms d'époques) : styles et contenus sont
  /// constants, seule leur position bouge. Les mettre en page à chaque
  /// frame était le poste CPU dominant du glissement — on les garde donc
  /// tout prêts, indexés par contenu + taille + couleur.
  static final Map<String, TextPainter> _textCache = {};

  static TextPainter _text(
    String value,
    double fontSize,
    Color color, {
    double letterSpacing = 0,
  }) {
    final key = '$value|$fontSize|${color.toARGB32()}|$letterSpacing';
    return _textCache[key] ??= TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width / 2 - frac * tapeW;
    canvas.save();
    canvas.translate(dx, 0);

    // Fenêtre réellement visible, en coordonnées du ruban. Tout ce qui
    // tombe en dehors est de toute façon rogné par le ClipRect : ne pas
    // l'enregistrer produit exactement la même image, sans le coût.
    final visLeft = frac * tapeW - size.width / 2;
    final visRight = visLeft + size.width;
    bool visible(double left, double right, [double marge = 8]) =>
        right >= visLeft - marge && left <= visRight + marge;

    // Bandes d'époques : panneaux illustrés en tuiles (nom d'époque
    // compris dans l'image), ou bandes unies + filigrane en repli.
    final bandBottom = size.height * 0.66;
    for (var i = 0; i < eras.length; i++) {
      final e = eras[i];
      final left = _px(e.from);
      final right = _px(e.to);
      if (!visible(left, right)) continue; // époque hors écran
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, 0, right, size.height),
        const Radius.circular(16),
      );
      canvas.drawRRect(rrect, Paint()..color = eraThemes[i].tint);
      final imgPaint = Paint()..filterQuality = FilterQuality.medium;

      // Tuiles miroir alternées avec parallaxe : `shift` est la part du
      // défilement que la couche « rend » (0 = collée aux graduations,
      // plus c'est grand, plus la couche paraît lointaine et lente).
      void drawTiled(ui.Image im, Rect src, double shift) {
        final tileW = bandBottom * src.width / src.height;
        final period = tileW * 2;
        final phase = (frac * tapeW * shift) % period;
        var j = 0;
        for (var x = left + phase - period; x < right; x += tileW, j++) {
          // `j` continue de compter : l'alternance miroir des tuiles ne
          // dépend pas de ce qui est à l'écran.
          if (!visible(x, x + tileW)) continue;
          final dst = Rect.fromLTWH(x, 0, tileW, bandBottom);
          if (j.isOdd) {
            canvas.save();
            canvas.translate(x + tileW / 2, 0);
            canvas.scale(-1, 1);
            canvas.translate(-(x + tileW / 2), 0);
            canvas.drawImageRect(im, src, dst, imgPaint);
            canvas.restore();
          } else {
            canvas.drawImageRect(im, src, dst, imgPaint);
          }
        }
      }

      final bg = EraArt.bg[i];
      final trav = EraArt.travelers[i];
      final spec = travelerSpecs[i];
      final img = frise;
      if (bg != null || img != null) {
        canvas.save();
        canvas.clipRRect(rrect);
        if (bg != null) {
          // Fond lointain dédié, très lent : l'horizon recule.
          drawTiled(
            bg,
            Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
            0.60,
          );
          // Voile clair en bas de bande : les graduations doivent rester
          // bien lisibles sur les décors, même sombres.
          canvas.drawRect(
            Rect.fromLTRB(left, bandBottom - 56, right, bandBottom),
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(0, bandBottom - 56),
                Offset(0, bandBottom),
                [const Color(0x00FFFFFF), const Color(0xBFFFFFFF)],
              ),
          );
        } else if (img != null) {
          // Décor en panneaux (bandeau de titre coupé) en attendant le
          // fond dédié de cette époque.
          final cellW = img.width / 6;
          final cellH = img.height.toDouble();
          final srcTop = cellH * 0.30;
          drawTiled(
            img,
            Rect.fromLTWH(i * cellW, srcTop, cellW, cellH - srcTop),
            0.45,
          );
        }
        // Le personnage de l'époque, ancré dans sa bande : il ne peut
        // pas en sortir, donc toujours visible quand son époque est à
        // l'écran. Les frames du spritesheet avancent avec le
        // défilement — il marche sur place pendant que le paysage
        // glisse sous ses pas, et se fige à l'arrêt.
        if (trav != null && spec != null) {
          final frames = spec.frames;
          final fw = trav.width / frames;
          final fh = trav.height.toDouble();
          final sprH = bandBottom * 0.40;
          final sprW = sprH * fw / fh;
          final bandW = right - left;
          final n = math.max(1, bandW ~/ 640);
          final spacing = bandW / n;
          // Les personnages avancent réellement : ils traversent leur
          // époque au fil du défilement (50 % de la vitesse du ruban)
          // et reviennent par l'autre bord.
          final drift = frac * tapeW * 0.50;
          final sprTop = bandBottom - sprH - 2 + sprH * spec.dyFrac;
          for (var k = 0; k < n; k++) {
            final off = (spacing * (k + 0.5) - drift) % bandW;
            final x = left + off - sprW / 2;
            var fi = 0;
            if (frames > 1) {
              fi = ((frac * tapeW / 24).floor() + k) % frames;
              if (fi < 0) fi += frames;
            }
            if (!visible(x, x + sprW)) continue;
            final srcR = Rect.fromLTWH(fi * fw, 0, fw, fh);
            final dstR = Rect.fromLTWH(x, sprTop, sprW, sprH);
            if (facingLeft) {
              canvas.save();
              canvas.translate(x + sprW / 2, 0);
              canvas.scale(-1, 1);
              canvas.translate(-(x + sprW / 2), 0);
              canvas.drawImageRect(trav, srcR, dstR, imgPaint);
              canvas.restore();
            } else {
              canvas.drawImageRect(trav, srcR, dstR, imgPaint);
            }
          }
        }
        canvas.restore();
      } else {
        final tp = _text(e.name.toUpperCase(), 22, const Color(0x1A35406B),
            letterSpacing: 3);
        tp.paint(
          canvas,
          Offset((left + right) / 2 - tp.width / 2, size.height * 0.14),
        );
      }

      // Nom de l'époque sur les bandes illustrées : une pastille par
      // ~560 px de bande, visible où qu'on soit sans tapisser le ruban.
      if (bg != null || img != null) {
        final label = _text(e.name.toUpperCase(), 11, const Color(0xFF5F6890),
            letterSpacing: 1.5);
        final bandW = right - left;
        final n = math.max(1, bandW ~/ 560);
        final spacing = bandW / n;
        for (var k = 0; k < n; k++) {
          final cx = left + spacing * (k + 0.5);
          if (!visible(cx - label.width / 2 - 7, cx + label.width / 2 + 7)) {
            continue;
          }
          final at = Offset(cx - label.width / 2, 8);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                at.dx - 7,
                at.dy - 3,
                label.width + 14,
                label.height + 6,
              ),
              const Radius.circular(10),
            ),
            Paint()..color = const Color(0xD9FFFFFF),
          );
          label.paint(canvas, at);
        }
      }
    }

    // Ligne de base (bornée à la fenêtre visible : même trait à l'écran)
    final baseY = size.height * 0.66;
    canvas.drawLine(
      Offset(math.max(0, visLeft), baseY),
      Offset(math.min(tapeW, visRight), baseY),
      Paint()
        ..color = const Color(0x8C35406B)
        ..strokeWidth = 3,
    );

    // Graduations : pas adapté à chaque segment [minor, medium, major]
    const plans = [
      (seg: 0, minor: 100, medium: 500, major: 1000),
      (seg: 1, minor: 50, medium: 250, major: 500),
      (seg: 2, minor: 10, medium: 50, major: 100),
      (seg: 3, minor: 1, medium: 5, major: 10),
    ];
    // Trois poids de trait bien contrastés : c'est avec eux qu'on vise.
    final tickMinor = Paint()
      ..color = const Color(0x7335406B)
      ..strokeWidth = 1.6;
    final tickMedium = Paint()
      ..color = const Color(0xA635406B)
      ..strokeWidth = 2.2;
    final tickMajor = Paint()
      ..color = const Color(0xE635406B)
      ..strokeWidth = 2.8;
    for (final p in plans) {
      final s = segments[p.seg];
      for (var y = s.from; y <= s.to; y += p.minor) {
        final x = _px(y);
        if (x < visLeft - 4 || x > visRight + 4) continue;
        double h;
        Paint pt;
        if (y % p.major == 0) {
          h = size.height * 0.15;
          pt = tickMajor;
        } else if (y % p.medium == 0) {
          h = size.height * 0.10;
          pt = tickMedium;
        } else {
          h = size.height * 0.055;
          pt = tickMinor;
        }
        canvas.drawLine(Offset(x, baseY - h), Offset(x, baseY), pt);
      }
    }

    // Années écrites sous la ligne
    const bigLabels = [
      -3000,
      -2000,
      -1000,
      0,
      500,
      1000,
      1500,
      1600,
      1700,
      1800,
      1900,
      1950,
      2000,
      2026,
    ];
    const smallLabels = [
      -2500,
      -1500,
      -500,
      250,
      750,
      1250,
      1550,
      1650,
      1750,
      1850,
      1910,
      1920,
      1930,
      1940,
      1960,
      1970,
      1980,
      1990,
      2010,
      2020,
    ];
    void drawLabel(int year, double fontSize, Color color) {
      final x = _px(year);
      if (x < visLeft - 60 || x > visRight + 60) return;
      final tp = _text(year < 0 ? '-${-year}' : '$year', fontSize, color);
      tp.paint(canvas, Offset(x - tp.width / 2, baseY + 6));
    }

    final bigFont = (size.height * 0.087).clamp(13.0, 18.0).toDouble();
    final smallFont = (size.height * 0.07).clamp(10.5, 14.5).toDouble();
    for (final y in bigLabels) {
      drawLabel(y, bigFont, const Color(0xFF35406B));
    }
    for (final y in smallLabels) {
      drawLabel(y, smallFont, const Color(0xFF5F6890));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TapePainter oldDelegate) =>
      oldDelegate.frac != frac ||
      oldDelegate.tapeW != tapeW ||
      oldDelegate.frise != frise ||
      oldDelegate.artVersion != artVersion ||
      oldDelegate.facingLeft != facingLeft;
}
