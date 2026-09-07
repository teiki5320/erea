import 'package:erea/core/offre.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lundi = DateTime(2026, 9, 7, 15, 30);

  bool regle({
    bool sansPub = false,
    bool boutique = true,
    required int pubs,
    String? refusee,
  }) =>
      doitProposerOffre(
        sansPub: sansPub,
        boutiqueDisponible: boutique,
        pubsVues: pubs,
        refuseeLe: refusee,
        maintenant: lundi,
      );

  test('une pub sur trois, en commençant par la première', () {
    final proposees = [
      for (var p = 0; p <= 10; p++)
        if (regle(pubs: p)) p
    ];
    expect(proposees, [1, 4, 7, 10]);
  });

  test('jamais chez un acheteur', () {
    for (var p = 1; p <= 10; p++) {
      expect(regle(sansPub: true, pubs: p), isFalse, reason: 'pub $p');
    }
  });

  test('jamais quand la boutique est muette : pas de bouton mort', () {
    expect(regle(boutique: false, pubs: 1), isFalse);
  });

  test('« Non merci » fait taire l’offre jusqu’au lendemain', () {
    expect(regle(pubs: 1, refusee: '2026-09-07'), isFalse);
    expect(regle(pubs: 1, refusee: '2026-09-06'), isTrue);
  });

  test('la clé de jour est stable et zéro-paddée', () {
    expect(cleJour(DateTime(2026, 9, 7, 23, 59)), '2026-09-07');
    expect(cleJour(DateTime(2026, 12, 25)), '2026-12-25');
  });
}
