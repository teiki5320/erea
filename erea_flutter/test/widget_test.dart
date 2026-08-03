import 'package:erea/core/scoring.dart';
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

  Future<void> pumpApp(WidgetTester tester,
      {Size size = _iphone14, double textScale = 1.0}) async {
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
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

  /// Tape un élément qui peut se trouver sous la ligne de flottaison : les
  /// événements à longue description repoussent le réglage fin hors de
  /// l'écran, et un tap « à l'aveugle » tomberait dans le vide.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Joue les 10 manches d'une partie déjà lancée.
  Future<void> playAllRounds(WidgetTester tester) async {
    for (var i = 1; i <= rounds; i++) {
      expect(find.text('MANCHE $i/$rounds'), findsOneWidget);
      // Le +1 « touche » la frise : sans ça la validation reste désactivée.
      await tapVisible(tester, find.text('+'));
      await tapVisible(tester, find.text('Je place ici !'));
      await tapVisible(
        tester,
        find.text(i < rounds ? 'Manche suivante →' : 'Voir mes résultats 🏁'),
      );
    }
  }

  testWidgets('l’accueil affiche le logo, le défi du jour et les modes',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('R'), findsOneWidget); // le logo lettre à lettre
    expect(find.textContaining('Défi du jour'), findsOneWidget);
    expect(find.text('Jouer !'), findsOneWidget);
    expect(find.text('Classique'), findsOneWidget);
    expect(find.text('Packs'), findsOneWidget);
    expect(find.textContaining('/ ${repo.events.length} événements découverts'),
        findsOneWidget);
  });

  testWidgets('le joueur démarre au niveau 1', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('NIV. 1'), findsOneWidget);
  });

  testWidgets('le Chrono décompte, met zéro au temps écoulé et enchaîne seul',
      (tester) async {
    // PAS de pumpAndSettle après l'entrée en jeu : le tic d'affichage
    // (100 ms) du compte à rebours ne « settle » jamais.
    await pumpApp(tester);
    await tester.tap(find.text('Chrono'));
    await tester.pump(); // montage de la route
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('MANCHE 1/10'), findsOneWidget);
    expect(find.textContaining('⏱'), findsWidgets);
    // On ne répond pas : à 10 s le temps expire (manche à zéro), le ruban
    // voyage (80 ms en animations réduites) puis la révélation s'affiche.
    await tester.pump(const Duration(seconds: 10, milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Manche suivante →'), findsOneWidget);
    // …et la manche suivante part toute seule (~2,2 s plus tard).
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('MANCHE 2/10'), findsOneWidget);
  });

  test('en Facile, une partie ne tire que des faits connus (niveau 1)', () {
    // « tout » a largement assez de faits niveau 1 pour dix manches : aucun
    // niveau 2 ne doit apparaître. Le « 2: 0 » du quota Facile n'est qu'un
    // repli pour les petites sélections à court de faits connus.
    final ev = repo.pick('tout', Difficulty.facile);
    expect(ev, isNotEmpty);
    expect(
      ev.every((e) => e.niveau == 1),
      isTrue,
      reason: 'niveaux tirés : ${ev.map((e) => e.niveau).toList()}',
    );
  });

  // Le bloc « Classement mondial » de l'accueil : il doit s'afficher sans
  // déborder (le libellé + le rang/l'invite tenaient de justesse), sur les
  // deux formats. En test Game Center est indisponible : on vérifie surtout
  // la mise en page, pas le rang lui-même.
  for (final format in [('iPhone 14', _iphone14), ('iPhone SE', _iphoneSE)]) {
    testWidgets('l’accueil montre le classement mondial sans déborder '
        '(${format.$1})', (tester) async {
      await pumpApp(tester, size: format.$2);
      expect(find.text('Classement mondial'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('le sélecteur de catégorie s’ouvre et applique le choix',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Classique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    expect(find.text('Choisis une catégorie'), findsOneWidget);
    await tester.tap(find.text('Pouvoir & guerres'));
    await tester.pumpAndSettle();
    expect(find.text('Pouvoir & guerres'), findsOneWidget);
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
    await tapVisible(tester, find.text('+'));
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

  // C'est l'outil de visée : la frise doit rester nettement plus haute que
  // les 150 px d'origine, sur tous les formats.
  for (final format in [('iPhone 14', _iphone14), ('iPhone SE', _iphoneSE)]) {
    testWidgets('la frise domine l’écran de jeu (${format.$1})',
        (tester) async {
      await pumpApp(tester, size: format.$2);
      await startClassique(tester);
      expect(
        tester.getSize(find.byType(TapeWidget)).height,
        greaterThan(200),
      );
    });
  }

  testWidgets('en très grande police, la carte de l’événement reste visible',
      (tester) async {
    // Réglage iOS « texte plus grand » au maximum : les blocs fixes
    // (année, pastilles) sont plafonnés, donc la carte garde sa place et
    // défile sur elle-même. Avant, elle était écrasée à 0 px — le fait à
    // deviner disparaissait de l'écran.
    await pumpApp(tester);
    await startClassique(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Débordements horizontaux de pastilles : cosmétiques, hors sujet ici.
    while (tester.takeException() != null) {}
    final carte = tester.getSize(find.byType(SingleChildScrollView).first);
    expect(carte.height, greaterThanOrEqualTo(84),
        reason: 'la carte de l’événement doit rester lisible');
    expect(tester.getSize(find.byType(TapeWidget)).height,
        greaterThanOrEqualTo(150));
  });

  testWidgets('la révélation tient dans l’écran, sans défilement global',
      (tester) async {
    // Le « demi-millimètre » : l'écran de révélation débordait de quelques
    // pixels et TOUT se laissait glisser pour rien. Désormais seule
    // l'anecdote défile, en interne : la frise, ses épingles et le bouton
    // ne sont plus dans aucune zone défilante et tiennent à l'écran.
    await pumpApp(tester);
    await startClassique(tester);
    await tapVisible(tester, find.text('+'));
    await tapVisible(tester, find.text('Je place ici !'));
    expect(
      find.ancestor(
          of: find.byType(TapeWidget), matching: find.byType(Scrollable)),
      findsNothing,
      reason: 'la frise ne doit plus vivre dans un défilement global',
    );
    final ecran = tester.getSize(find.byType(MaterialApp));
    final frise = tester.getRect(find.byType(TapeWidget));
    expect(frise.bottom, lessThanOrEqualTo(ecran.height));
    final bouton = tester.getRect(find.text('Manche suivante →'));
    expect(bouton.bottom, lessThanOrEqualTo(ecran.height));
    await tapVisible(tester, find.text('Manche suivante →'));
  });

  // Le réglage fin et la mini-carte ne doivent JAMAIS passer sous la ligne
  // de flottaison : c'est la carte de l'événement qui défile sur elle-même.
  for (final format in [('iPhone 14', _iphone14), ('iPhone SE', _iphoneSE)]) {
    testWidgets('le réglage fin reste visible sans défiler (${format.$1})',
        (tester) async {
      await pumpApp(tester, size: format.$2);
      await startClassique(tester);
      final ecran = tester.getSize(find.byType(MaterialApp));
      for (final glyphe in ['−', '+']) {
        final r = tester.getRect(find.text(glyphe));
        expect(r.bottom, lessThanOrEqualTo(ecran.height),
            reason: '« $glyphe » sous la ligne de flottaison');
        expect(r.top, greaterThanOrEqualTo(0.0));
      }
    });
  }

  testWidgets('un événement déjà révélé ne revient pas après un abandon',
      (tester) async {
    await pumpApp(tester);
    await startClassique(tester);
    await tapVisible(tester, find.text('+'));
    await tapVisible(tester, find.text('Je place ici !'));
    // La manche est révélée : l'événement doit être mémorisé AVANT même
    // que la partie se termine.
    final store = await Store.load();
    expect(store.discovered, isNotEmpty);
    expect(store.seen, isNotEmpty);
  });

  testWidgets('« Réduire les animations » est pris en compte à chaud',
      (tester) async {
    // Le réglage iOS peut être activé PENDANT que le jeu tourne : l'app le
    // lisait une seule fois au démarrage et continuait d'animer ensuite.
    tester.view.physicalSize = _iphone14;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    // On démarre AVEC les animations : la dérive d'époque tourne.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(EreaApp(repo: repo, store: await Store.load()));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue,
        reason: 'la dérive d’époque anime l’accueil');

    // Le joueur active le réglage sans quitter l'app.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'plus rien ne doit animer une fois le réglage activé');

    // … puis il le désactive : l'accueil doit se remettre à respirer.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue,
        reason: 'la dérive doit repartir quand le réglage est levé');
  });

  testWidgets(
      'l’inertie de la frise s’arrête net si le réglage est activé '
      'en pleine glissade', (tester) async {
    tester.view.physicalSize = _iphone14;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(EreaApp(repo: repo, store: await Store.load()));
    await tester.pump();

    // Lancer la mini-frise arrête DÉFINITIVEMENT la dérive d'époque : la
    // seule chose encore animée est donc l'élan du ruban.
    await tester.fling(find.byType(TapeWidget), const Offset(-320, 0), 900);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue,
        reason: 'le ruban est lancé sur son élan');

    // Le joueur active le réglage sans quitter l'app (raccourci iOS).
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'l’élan ne doit pas finir sa course sur une seconde');
  });

  testWidgets(
      'le réglage activé pendant le voyage du ruban coupe le ressort '
      'du verdict', (tester) async {
    await pumpApp(tester); // animations réduites : on part au calme
    await startClassique(tester);
    // On rétablit les animations, puis on valide : le ruban voyage.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tapVisible(tester, find.text('+'));
    await tester.tap(find.text('Je place ici !'));
    await tester.pump();

    // … et le joueur active « réduire les animations » PENDANT le voyage.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump(const Duration(seconds: 2)); // le voyage s'achève

    // Le badge de verdict ne doit pas jaillir : il est déjà à sa taille.
    final badge = tester
        .widget<ScaleTransition>(find.byKey(const ValueKey('badge-verdict')));
    expect(badge.scale.value, 1.0,
        reason: 'le ressort du badge a joué malgré le réglage');
  });

  testWidgets('la révélation raconte l’écart SUR la frise', (tester) async {
    await pumpApp(tester);
    await startClassique(tester);
    // On vise volontairement l'extrémité de la frise : l'écart est énorme,
    // donc le trait doit être visible entre les deux épingles.
    tester.widget<TapeWidget>(find.byType(TapeWidget)).onFracChanged(0.0);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Je place ici !'));

    // Les deux épingles…
    expect(find.textContaining('Toi · '), findsOneWidget);
    expect(find.textContaining('🎯'), findsWidgets);
    // … reliées par le trait de l'écart, qui porte le nombre d'années.
    expect(
      find.byWidgetPredicate((w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_GapLinePainter'),
      findsOneWidget,
      reason: 'la longueur du trait EST l’erreur',
    );
    // La carte de savoir est là, sous l'un de ses deux titres.
    final savoir = find.text('Le savais-tu ? 💡').evaluate().length +
        find.text('Pour t’en souvenir 💡').evaluate().length;
    expect(savoir, 1);
  });

  testWidgets('la révélation ne déborde pas sur un iPhone SE', (tester) async {
    await pumpApp(tester, size: _iphoneSE);
    await startClassique(tester);
    await tapVisible(tester, find.text('+'));
    await tapVisible(tester, find.text('Je place ici !'));
    expect(tester.takeException(), isNull);
    expect(find.text('Manche suivante →'), findsOneWidget);
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
    await playAllRounds(tester);

    expect(find.text('Partie terminée !'), findsOneWidget);
    expect(find.textContaining('/ 11000'), findsOneWidget);
    expect(find.text('Rejouer'), findsOneWidget);

    // L'XP de la partie a bien été créditée au retour à l'accueil.
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Classique'), findsOneWidget);
  });

  testWidgets(
      'le défi du jour se verrouille et affiche son score une fois '
      'terminé', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Jouer !'));
    await tester.pumpAndSettle();

    await playAllRounds(tester);
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();

    // Tentative consommée, score restitué, série créditée.
    expect(find.textContaining('Déjà joué ·'), findsOneWidget);
    expect(find.text('Jouer !'), findsNothing);
    expect(find.text('🔥 1'), findsOneWidget);
  });

  testWidgets('un défi abandonné consomme la tentative sans afficher de score',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Jouer !'));
    await tester.pumpAndSettle();
    // Une manche entamée, puis on quitte.
    await tapVisible(tester, find.text('+'));
    await tapVisible(tester, find.byIcon(Icons.close));
    await tapVisible(tester, find.text('Quitter'));

    expect(find.text('Prochain défi demain !'), findsOneWidget);
    expect(find.text('Jouer !'), findsNothing);
    // Un abandon ne crédite aucune série.
    expect(find.text('🔥 0'), findsOneWidget);
  });

  testWidgets(
      'la confirmation d’abandon prévient que la tentative du jour '
      'est perdue', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Jouer !'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.textContaining('tentative du défi du jour'), findsOneWidget);
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
