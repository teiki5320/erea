import 'package:erea/data/events_repository.dart';
import 'package:erea/data/store.dart';
import 'package:erea/game/game_controller.dart';
import 'package:erea/main.dart';
import 'package:erea/ui/sticker_widgets.dart';
import 'package:erea/ui/tape_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iPhone 14 en points logiques.
const Size _iphone14 = Size(390, 844);

/// iPhone SE (2e/3e génération) : le plus petit écran encore supporté.
const Size _iphoneSE = Size(375, 667);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventsRepository repo;

  setUpAll(() async {
    repo = await EventsRepository.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester, {Size size = _iphone14}) async {
    // L'app est en portrait uniquement : on teste sur une vraie taille de
    // téléphone plutôt que sur le 800x600 par défaut de flutter_test.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // « Réduire les animations » : fige la dérive d'époque de l'accueil
    // (un ticker infini empêcherait pumpAndSettle de converger).
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = await Store.load();
    await tester.pumpWidget(EreaApp(repo: repo, store: store));
    await tester.pumpAndSettle();
  }

  Future<void> startClassique(WidgetTester tester) async {
    await tester.tap(find.text('Classique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C’est parti !'));
    await tester.pumpAndSettle();
  }

  testWidgets('l’accueil affiche le logo, le défi du jour et les modes',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('R'), findsOneWidget); // le logo lettre à lettre
    expect(find.textContaining('Défi du jour'), findsOneWidget);
    expect(find.text('Jouer !'), findsOneWidget);
    expect(find.text('Classique'), findsOneWidget);
    expect(find.text('Packs'), findsOneWidget);
    expect(find.text('${repo.events.length} événements'), findsOneWidget);
  });

  testWidgets('le joueur démarre au niveau 1', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('NIV. 1'), findsOneWidget);
  });

  testWidgets('le sélecteur de catégorie s’ouvre et applique le choix',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Classique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    expect(find.text('Choisis une catégorie'), findsOneWidget);
    await tester.tap(find.text('Histoire de France'));
    await tester.pumpAndSettle();
    expect(find.text('Histoire de France'), findsOneWidget);
  });

  testWidgets('le sélecteur de difficulté s’ouvre et applique le choix',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Classique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Difficulté'));
    await tester.pumpAndSettle();
    expect(find.text('Choisis une difficulté'), findsOneWidget);
    await tester.tap(find.text('Difficile'));
    await tester.pumpAndSettle();
    expect(find.text('Difficile'), findsOneWidget);
  });

  testWidgets('« Classique » ouvre l’écran de jeu sur la manche 1',
      (tester) async {
    await pumpApp(tester);
    await startClassique(tester);
    expect(find.text('MANCHE 1/10'), findsOneWidget);
    expect(find.text('Je place ici !'), findsOneWidget);
    expect(find.byType(TapeWidget), findsOneWidget);
  });

  testWidgets('valider est impossible tant que la frise n’a pas bougé',
      (tester) async {
    await pumpApp(tester);
    await startClassique(tester);
    final button = tester.widget<PushButton>(
      find.widgetWithText(PushButton, 'Je place ici !'),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    final enabled = tester.widget<PushButton>(
      find.widgetWithText(PushButton, 'Je place ici !'),
    );
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('l’écran de jeu ne déborde pas sur un iPhone SE', (tester) async {
    await pumpApp(tester, size: _iphoneSE);
    await startClassique(tester);
    // pumpAndSettle relance le rendu : un débordement lèverait ici.
    expect(tester.takeException(), isNull);
    expect(find.text('Je place ici !'), findsOneWidget);
  });

  testWidgets('les années les plus longues ne débordent pas', (tester) async {
    // « 3000 av. J.-C. » + « ÉPOQUE CONTEMPORAINE » sont les libellés les
    // plus larges ; ils apparaissent notamment pendant l'animation de
    // révélation, quand le ruban voyage vers la vraie date.
    await pumpApp(tester, size: _iphoneSE);
    await startClassique(tester);
    final tape = tester.widget<TapeWidget>(find.byType(TapeWidget));

    tape.onFracChanged(0.0); // -3000
    await tester.pumpAndSettle();
    expect(find.text('3000 av. J.-C.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tape.onFracChanged(1.0); // 2026, époque contemporaine
    await tester.pumpAndSettle();
    expect(find.text('2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la police embarquée Nunito est bien appliquée au thème',
      (tester) async {
    await pumpApp(tester);
    final theme = Theme.of(tester.element(find.text('Classique')));
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Nunito');
    expect(theme.textTheme.headlineSmall?.fontFamily, 'Baloo2');
  });

  testWidgets('une partie complète de 10 manches se termine par l’écran final',
      (tester) async {
    await pumpApp(tester);
    await startClassique(tester);

    for (var i = 1; i <= 10; i++) {
      expect(find.text('MANCHE $i/10'), findsOneWidget);
      // Le +1 « touche » la frise : sans ça la validation reste désactivée.
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Je place ici !'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(i < 10 ? 'Manche suivante →' : 'Voir mes résultats 🏁'),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('Partie terminée !'), findsOneWidget);
    expect(find.textContaining('/ 11000'), findsOneWidget);
    expect(find.text('Rejouer'), findsOneWidget);

    // L'XP de la partie a bien été créditée au retour à l'accueil.
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Classique'), findsOneWidget);
  });

  test('le contrôleur de partie enchaîne bien 10 manches', () async {
    final controller = GameController(repo);
    expect(controller.start(GameMode.classique), isTrue);
    var played = 0;
    var more = true;
    while (more) {
      controller.setYear(1800);
      controller.validate();
      controller.finishReveal();
      played++;
      more = controller.next();
    }
    expect(played, 10);
    expect(controller.results.length, 10);
    expect(controller.emojiGrid().runes.length, 10);
    expect(controller.total, inInclusiveRange(0, 11000));
  });
}
