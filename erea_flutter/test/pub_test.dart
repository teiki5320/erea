import 'package:erea/core/pub.dart';
import 'package:flutter_test/flutter_test.dart';

/// La règle d'affichage de la publicité, vérifiée sans le SDK : c'est elle
/// qui porte les promesses faites au joueur, pas la régie.
void main() {
  group('quand montrer une interstitielle', () {
    test('qui a acheté ne voit jamais de publicité', () {
      for (var parties = 0; parties < 20; parties++) {
        expect(
          Pub.doitMontrer(
              sansPub: true, defiDuJour: false, partiesJouees: parties),
          isFalse,
          reason: 'partie $parties',
        );
      }
    });

    test('le Défi du jour n’en porte jamais, même acheté ou non', () {
      for (var parties = 0; parties < 20; parties++) {
        expect(
          Pub.doitMontrer(
              sansPub: false, defiDuJour: true, partiesJouees: parties),
          isFalse,
          reason: 'partie $parties',
        );
      }
    });

    test('une partie sur deux, et pas davantage', () {
      final montrees = [
        for (var p = 0; p < 10; p++)
          if (Pub.doitMontrer(
              sansPub: false, defiDuJour: false, partiesJouees: p))
            p
      ];
      expect(montrees, [0, 2, 4, 6, 8]);
    });

    test('un joueur qui n’a pas payé et joue le Classique en voit', () {
      expect(
        Pub.doitMontrer(
            sansPub: false, defiDuJour: false, partiesJouees: 4),
        isTrue,
      );
    });
  });
}
