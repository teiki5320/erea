import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/timeline_scale.dart';

/// Planche des 6 panneaux d'époques (illustrations), chargée une seule
/// fois pour toute la vie de l'app. Tant qu'elle n'est pas prête — ou si
/// l'asset manque — le ruban dessine ses bandes de couleur unies.
ui.Image? _friseImage;
Future<ui.Image?>? _friseLoading;

Future<ui.Image?> _loadFrise() {
  return _friseLoading ??= () async {
    try {
      final data = await rootBundle.load('assets/img/frise.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _friseImage = frame.image;
    } catch (_) {
      // Pas d'image : le ruban reste sur ses bandes unies.
    }
    return _friseImage;
  }();
}

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
  static const double tapeW = 3200;

  Ticker? _ticker;
  double _velocity = 0; // px par frame de référence (16,7 ms)
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (_friseImage == null) {
      _loadFrise().then((_) {
        if (mounted) setState(() {});
      });
    }
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
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: CustomPaint(
                  painter: _TapePainter(
                    frac: widget.frac,
                    tapeW: tapeW,
                    frise: _friseImage,
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
  });

  final double frac;
  final double tapeW;

  /// Planche des panneaux d'époques (6 cellules côte à côte), ou null
  /// tant qu'elle n'est pas décodée.
  final ui.Image? frise;

  /// Teintes de repli, échantillonnées sur les panneaux illustrés.
  static const _eraColors = [
    Color(0xFFF9EAC9), // Âge du bronze
    Color(0xFFF2EDCF), // Âge du fer
    Color(0xFFE6DFF0), // Antiquité
    Color(0xFFD8E6F5), // Moyen Âge
    Color(0xFFFBE3C0), // Époque moderne
    Color(0xFFF9D9D4), // Époque contemporaine
  ];

  double _px(num year) => yearToFrac(year) * tapeW;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width / 2 - frac * tapeW;
    canvas.save();
    canvas.translate(dx, 0);

    // Bandes d'époques : panneaux illustrés en tuiles (nom d'époque
    // compris dans l'image), ou bandes unies + filigrane en repli.
    final bandBottom = size.height * 0.66;
    for (var i = 0; i < eras.length; i++) {
      final e = eras[i];
      final left = _px(e.from);
      final right = _px(e.to);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, 0, right, size.height),
        const Radius.circular(16),
      );
      canvas.drawRRect(rrect, Paint()..color = _eraColors[i]);
      final img = frise;
      if (img != null) {
        // Décor seul (le bandeau de titre des panneaux est coupé), en
        // tuiles miroir alternées : le paysage remplit la bande sans
        // raccord visible ni texte répété.
        final cellW = img.width / 6;
        final cellH = img.height.toDouble();
        final srcTop = cellH * 0.30;
        final srcH = cellH - srcTop;
        final tileW = bandBottom * cellW / srcH;
        final src = Rect.fromLTWH(i * cellW, srcTop, cellW, srcH);
        final paint = Paint()..filterQuality = FilterQuality.medium;
        canvas.save();
        canvas.clipRRect(rrect);
        // Parallaxe : le décor glisse à 55 % de la vitesse des
        // graduations (il « recule » de 45 % du défilement), la période
        // de deux tuiles (endroit + miroir) garde le motif continu.
        final period = tileW * 2;
        final phase = (frac * tapeW * 0.45) % period;
        var j = 0;
        for (var x = left + phase - period; x < right; x += tileW, j++) {
          final dst = Rect.fromLTWH(x, 0, tileW, bandBottom);
          if (j.isOdd) {
            canvas.save();
            canvas.translate(x + tileW / 2, 0);
            canvas.scale(-1, 1);
            canvas.translate(-(x + tileW / 2), 0);
            canvas.drawImageRect(img, src, dst, paint);
            canvas.restore();
          } else {
            canvas.drawImageRect(img, src, dst, paint);
          }
        }
        canvas.restore();
        // Nom de l'époque : une pastille par ~560 px de bande, pour
        // qu'il soit visible où qu'on soit sans tapisser le ruban.
        final label = TextPainter(
          text: TextSpan(
            text: e.name.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF5F6890),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final bandW = right - left;
        final n = math.max(1, bandW ~/ 560);
        final spacing = bandW / n;
        for (var k = 0; k < n; k++) {
          final cx = left + spacing * (k + 0.5);
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
      } else {
        final tp = TextPainter(
          text: TextSpan(
            text: e.name.toUpperCase(),
            style: const TextStyle(
              color: Color(0x1A35406B),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset((left + right) / 2 - tp.width / 2, size.height * 0.14),
        );
      }
    }

    // Ligne de base
    final baseY = size.height * 0.66;
    canvas.drawLine(
      Offset(0, baseY),
      Offset(tapeW, baseY),
      Paint()
        ..color = const Color(0x4735406B)
        ..strokeWidth = 3,
    );

    // Graduations : pas adapté à chaque segment [minor, medium, major]
    const plans = [
      (seg: 0, minor: 100, medium: 500, major: 1000),
      (seg: 1, minor: 50, medium: 250, major: 500),
      (seg: 2, minor: 10, medium: 50, major: 100),
      (seg: 3, minor: 1, medium: 5, major: 10),
    ];
    final tickPaint = Paint()
      ..color = const Color(0x4D35406B)
      ..strokeWidth = 1.5;
    for (final p in plans) {
      final s = segments[p.seg];
      for (var y = s.from; y <= s.to; y += p.minor) {
        final x = _px(y);
        double h;
        if (y % p.major == 0) {
          h = size.height * 0.133;
        } else if (y % p.medium == 0) {
          h = size.height * 0.093;
        } else {
          h = size.height * 0.053;
        }
        canvas.drawLine(Offset(x, baseY - h), Offset(x, baseY), tickPaint);
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
      2025,
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
      final tp = TextPainter(
        text: TextSpan(
          text: year < 0 ? '-${-year}' : '$year',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_px(year) - tp.width / 2, baseY + 6));
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
      oldDelegate.frise != frise;
}
