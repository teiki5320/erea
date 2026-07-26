import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/timeline_scale.dart';

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
  double _velocity = 0; // px par frame (~16 ms)

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _velocity *= 0.94;
    if (_velocity.abs() < 0.3 || widget.locked) {
      _ticker?.stop();
      return;
    }
    final next = (widget.frac - _velocity / tapeW).clamp(0.0, 1.0).toDouble();
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
    final next =
        (widget.frac - dx * factor / tapeW).clamp(0.0, 1.0).toDouble();
    widget.onFracChanged(next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.locked) return;
    // Vitesse en px/s -> px/frame (60 fps), bornée comme sur le web.
    _velocity =
        (details.velocity.pixelsPerSecond.dx / 60).clamp(-48.0, 48.0).toDouble();
    if (_velocity.abs() > 0.8 && !(_ticker?.isActive ?? true)) {
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
                  painter: _TapePainter(frac: widget.frac, tapeW: tapeW),
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
  _TapePainter({required this.frac, required this.tapeW});

  final double frac;
  final double tapeW;

  static const _eraColors = [
    Color(0xFFDCF7F0), // Antiquité
    Color(0xFFE0EEFF), // Moyen Âge
    Color(0xFFFFF1CC), // Moderne
    Color(0xFFFFE4DE), // Contemporaine
  ];

  double _px(num year) => yearToFrac(year) * tapeW;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width / 2 - frac * tapeW;
    canvas.save();
    canvas.translate(dx, 0);

    // Bandes d'époques + nom en filigrane
    for (var i = 0; i < eras.length; i++) {
      final e = eras[i];
      final left = _px(e.from);
      final right = _px(e.to);
      final rect = Rect.fromLTRB(left, 0, right, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        Paint()..color = _eraColors[i],
      );
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
          h = 20;
        } else if (y % p.medium == 0) {
          h = 14;
        } else {
          h = 8;
        }
        canvas.drawLine(Offset(x, baseY - h), Offset(x, baseY), tickPaint);
      }
    }

    // Années écrites sous la ligne
    const bigLabels = [
      -3000, -2000, -1000, 0, 500, 1000, 1500, 1600, 1700, 1800,
      1900, 1950, 2000, 2025,
    ];
    const smallLabels = [
      -2500, -1500, -500, 250, 750, 1250, 1550, 1650, 1750, 1850,
      1910, 1920, 1930, 1940, 1960, 1970, 1980, 1990, 2010, 2020,
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

    for (final y in bigLabels) {
      drawLabel(y, 13, const Color(0xFF35406B));
    }
    for (final y in smallLabels) {
      drawLabel(y, 10.5, const Color(0xFF5F6890));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TapePainter oldDelegate) =>
      oldDelegate.frac != frac || oldDelegate.tapeW != tapeW;
}
