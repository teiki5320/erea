import 'package:erea/core/region.dart' as region;
import 'package:erea/data/events_repository.dart';
import 'package:erea/data/store.dart';
import 'package:erea/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parcours de premier lancement : présentation, choix du pays, et le
/// branchement du choix sur le mélange régional du Classique.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventsRepository repo;

  setUpAll(() async {
    repo = await EventsRepository.load();
  });

  tearDown(() {
    // Globals de région : ne jamais laisser fuir un choix entre deux tests.
    region.paysChoisiIso = null;
    region.regionForcee = null;
  });

  Future<Store> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = await Store.load();
    await tester.pumpWidget(EreaApp(repo: repo, store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets(
      'premier lancement : présentation, choix du pays, arrivée à l’accueil',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await pumpApp(tester);

    // Les pages de présentation défilent avec « Suivant ».
    expect(find.text('Bienvenue sur Erea'), findsOneWidget);
    for (final titre in [
      'Fais glisser la frise',
      'Cinq façons de jouer',
      'Progresse',
      'Où joues-tu ?',
    ]) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text(titre), findsOneWidget);
    }

    // Choix d'un pays africain, puis « Commencer ».
    await tester.tap(find.text('Algérie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    // On est à l'accueil, le choix est mémorisé et branché sur la région.
    expect(find.textContaining('Défi du jour'), findsOneWidget);
    expect(store.onboardingVu, isTrue);
    expect(store.paysChoisiIso, 'DZ');
    expect(region.paysChoisiIso, 'DZ');
    expect(region.joueurEnAfrique, isTrue,
        reason: 'le choix doit nourrir le mélange régional du Classique');
  });

  testWidgets('« Retour » revient à la page précédente', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Fais glisser la frise'), findsOneWidget);
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue sur Erea'), findsOneWidget);
  });

  testWidgets('les lancements suivants vont droit à l’accueil',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboardingVu': true});
    await pumpApp(tester);
    expect(find.textContaining('Défi du jour'), findsOneWidget);
    expect(find.text('Bienvenue sur Erea'), findsNothing);
  });
}
