import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sticker_widgets.dart';

/// Le trait qui relie les deux épingles de la révélation.
///
/// Sa LONGUEUR est l'erreur du joueur : c'est ce qui fait comprendre
/// l'échelle non linéaire de la frise sans avoir à l'expliquer. Plein
/// quand la manche est réussie, pointillé sinon.
class GapLinePainter extends CustomPainter {
  const GapLinePainter({required this.dashed});

  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final trait = Paint()
      ..color = coralColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), trait);
      return;
    }
    const plein = 7.0;
    const vide = 5.0;
    for (var x = 0.0; x < size.width; x += plein + vide) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + plein, size.width), y),
        trait,
      );
    }
  }

  @override
  bool shouldRepaint(GapLinePainter old) => old.dashed != dashed;
}
