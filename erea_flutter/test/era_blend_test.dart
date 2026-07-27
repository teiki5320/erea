import 'package:erea/core/timeline_scale.dart';
import 'package:erea/ui/era_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('eraBlendAt', () {
    test('au milieu d’une époque : pas de fondu', () {
      for (final y in [-2000, -800, 0, 1000, 1600, 1950]) {
        final b = eraBlendAt(yearToFrac(y));
        expect(b.a, b.b, reason: 'année $y');
        expect(b.t, 0, reason: 'année $y');
      }
    });

    test('exactement sur une frontière : t = 0,5 entre les deux époques',
        () {
      for (var i = 0; i < eras.length - 1; i++) {
        final b = eraBlendAt(yearToFrac(eras[i].to));
        expect(b.a, i);
        expect(b.b, i + 1);
        expect(b.t, closeTo(0.5, 1e-9));
      }
    });

    test('monotone croissant et borné sur la zone de fondu', () {
      final bf = yearToFrac(1492);
      var prev = -1.0;
      for (var k = 1; k < 40; k++) {
        final f = bf - kBlendW + 2 * kBlendW * k / 40;
        final b = eraBlendAt(f);
        expect(b.t, inInclusiveRange(0.0, 1.0));
        expect(b.t, greaterThanOrEqualTo(prev));
        prev = b.t;
      }
    });

    test('hors zone de fondu : a == b', () {
      final bf = yearToFrac(476);
      expect(eraBlendAt(bf - kBlendW - 0.001).a,
          eraBlendAt(bf - kBlendW - 0.001).b);
      expect(eraBlendAt(bf + kBlendW + 0.001).a,
          eraBlendAt(bf + kBlendW + 0.001).b);
    });

    test('les thèmes couvrent les 6 époques de la frise', () {
      expect(eraThemes.length, eras.length);
      expect(eraIndexAt(-3000), 0);
      expect(eraIndexAt(2026), eras.length - 1);
    });
  });
}
