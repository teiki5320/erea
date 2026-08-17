import 'package:erea/core/achat.dart';
import 'package:erea/core/pub.dart';
import 'package:erea/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ce que l'achat promet au joueur : plus une seule publicité, et rien
/// d'autre qui change. Vérifié sans la boutique — c'est la promesse qui
/// compte, pas le plugin.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('l’identifiant du produit est le même sur les deux boutiques', () {
    // Il est saisi à la main dans App Store Connect et dans la Play
    // Console : une faute de frappe rendrait l'achat introuvable, sans
    // message d'erreur côté joueur.
    expect(Achat.idSansPub, 'com.teiki.erea.sanspub');
  });

  test('la boutique est muette par défaut : aucune offre affichée', () {
    // L'interface ne doit jamais montrer un bouton d'achat qui échouerait
    // — mode avion, restrictions parentales, produit pas encore validé.
    expect(Achat.disponible, isFalse);
    expect(Achat.prix, isNull);
  });

  test('un joueur neuf n’a pas payé, et voit donc la publicité', () async {
    final store = await Store.load();
    expect(store.sansPub, isFalse);
    expect(
      Pub.doitMontrer(
          sansPub: store.sansPub, defiDuJour: false, partiesJouees: 0),
      isTrue,
    );
  });

  test('l’achat coupe la publicité, et survit au redémarrage', () async {
    final store = await Store.load();
    await store.setSansPub(true);
    expect(store.sansPub, isTrue);
    expect(
      Pub.doitMontrer(
          sansPub: store.sansPub, defiDuJour: false, partiesJouees: 0),
      isFalse,
    );

    // Relecture depuis les préférences : ce que verra le prochain
    // lancement de l'app.
    final apresRedemarrage = await Store.load();
    expect(apresRedemarrage.sansPub, isTrue);
    expect(
      Pub.doitMontrer(
          sansPub: apresRedemarrage.sansPub,
          defiDuJour: false,
          partiesJouees: 2),
      isFalse,
    );
  });

  test('l’achat n’ouvre rien d’autre : il ne touche ni XP ni records',
      () async {
    final store = await Store.load();
    final xpAvant = store.xp;
    final partiesAvant = store.games;
    await store.setSansPub(true);
    expect(store.xp, xpAvant);
    expect(store.games, partiesAvant);
  });
}
