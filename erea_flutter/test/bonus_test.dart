import 'package:erea/core/bonus.dart';
import 'package:erea/core/progression.dart';
import 'package:erea/core/scoring.dart';
import 'package:erea/core/timeline_scale.dart';
import 'package:erea/data/events_repository.dart';
import 'package:erea/data/store.dart';
import 'package:erea/game/game_controller.dart';
import 'package:erea/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// XP totale qu'il faut pour atteindre [niveau].
int xpPour(int niveau) {
  var xp = 0;
  for (var n = 1; n < niveau; n++) {
    xp += xpNeededFor(n);
  }
  return xp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventsRepository repo;
  setUpAll(() async => repo = await EventsRepository.load());
  setUp(() => SharedPreferences.setMockInitialValues({'onboardingVu': true}));

  group('calendrier des bonus', () {
    test('rien avant le niveau 5', () {
      expect(recompensesEntre(1, 4).vide, isTrue);
    });

    test('une découverte tous les quatre niveaux, de 5 à 25', () {
      expect([
        for (var n = 1; n <= 30; n++) ...recompensesEntre(n - 1, n).decouvertes
      ], BonusType.values);
      expect([for (final b in BonusType.values) b.niveau],
          [5, 9, 13, 17, 21, 25]);
    });

    test('entre deux découvertes, un bonus à choisir aux niveaux impairs', () {
      expect(recompensesEntre(5, 6).vide, isTrue);
      expect(recompensesEntre(6, 7).choix, 1);
      expect(recompensesEntre(8, 9).choix, 0); // découverte, pas de choix
      expect(recompensesEntre(5, 9).choix, 1);
      expect(recompensesEntre(26, 31).choix, 3); // 27, 29, 31
    });

    test('l’XP double revient aux titres 30, 40 et 50', () {
      expect(recompensesEntre(29, 30).xpDouble, 1);
      expect(recompensesEntre(30, 39).xpDouble, 0);
      expect(recompensesEntre(25, 50).xpDouble, 3);
    });

    test('on ne choisit que parmi les bonus découverts, hors XP double', () {
      expect(choisissables(7), [BonusType.remplacer]);
      expect(choisissables(30), isNot(contains(BonusType.xpDouble)));
      expect(choisissables(30).length, 5);
    });

    test('un joueur déjà avancé reçoit les découvertes de ses niveaux', () {
      expect(cadeauxDeBienvenue(4), isEmpty);
      expect(cadeauxDeBienvenue(14),
          [BonusType.remplacer, BonusType.epoque, BonusType.repere]);
    });
  });

  group('zoom', () {
    test('500 ans, la date jamais à moins de 50 ans d’un bord', () {
      for (final annee in [-2500, -400, 800, 1649, 1789]) {
        for (final r in [0.0, 0.3, 0.7, 0.999]) {
          final f = fenetreZoom(annee, r);
          expect(f.a - f.de, 500);
          expect(annee - f.de, greaterThanOrEqualTo(50));
          expect(f.a - annee, greaterThanOrEqualTo(50));
        }
      }
    });

    test('la fenêtre ne sort jamais de la frise', () {
      for (final annee in [minYear, minYear + 10, maxYear - 3, maxYear]) {
        final f = fenetreZoom(annee, 0.5);
        expect(f.de, greaterThanOrEqualTo(minYear));
        expect(f.a, lessThanOrEqualTo(maxYear));
        expect(annee, inInclusiveRange(f.de, f.a));
      }
    });
  });

  group('stock', () {
    test('jamais plus de deux exemplaires', () async {
      final s = await Store.load();
      expect(await s.ajouterBonus(BonusType.zoom), 1);
      expect(await s.ajouterBonus(BonusType.zoom, 5), 1);
      expect(await s.ajouterBonus(BonusType.zoom), 0);
      expect(s.bonus(BonusType.zoom), stockMax);
      await s.retirerBonus(BonusType.zoom);
      expect(s.bonus(BonusType.zoom), 1);
    });

    test('les cadeaux de la mise à jour ne se donnent qu’une fois', () async {
      SharedPreferences.setMockInitialValues({'xp': xpPour(14)});
      final s = await Store.load();
      expect(await s.distribuerBienvenue(), hasLength(3));
      expect(s.bonus(BonusType.repere), 1);
      expect(await s.distribuerBienvenue(), isEmpty);
      expect(s.bonus(BonusType.repere), 1);
    });

    test('un bonus par pub et par jour', () async {
      final s = await Store.load();
      var maintenant = DateTime(2026, 11, 2, 10);
      s.clock = () => maintenant;
      expect(s.bonusPubDispo, isTrue);
      await s.marquerBonusPub();
      expect(s.bonusPubDispo, isFalse);
      maintenant = DateTime(2026, 11, 3, 8);
      expect(s.bonusPubDispo, isTrue);
    });
  });

  group('en partie', () {
    GameController partie({GameMode mode = GameMode.classique}) {
      final g = GameController(repo)..diff = Difficulty.normal;
      expect(g.start(mode), isTrue);
      return g;
    }

    test('un seul bonus par partie, et le stock est débité', () {
      final g = partie();
      final depenses = <BonusType>[];
      g.onBonusConsomme = depenses.add;
      expect(g.utiliser(BonusType.epoque), isTrue);
      expect(g.epoqueAide, eraFor(g.current.annee));
      expect(g.utiliser(BonusType.repere), isFalse);
      expect(depenses, [BonusType.epoque]);
      expect(g.aidee, isTrue);
    });

    test('aucun bonus dans le Défi du jour', () {
      final g = partie(mode: GameMode.daily);
      expect(g.bonusPermis, isFalse);
      expect(g.utiliser(BonusType.remplacer), isFalse);
    });

    test('Remplacer met un autre événement, absent de la partie', () {
      final g = partie();
      final avant = g.current;
      final ids = g.events.map((e) => e.id).toSet();
      expect(g.utiliser(BonusType.remplacer, rng: () => 0.42), isTrue);
      expect(g.current.id, isNot(avant.id));
      expect(ids, isNot(contains(g.current.id)));
      expect(g.events.length, rounds);
    });

    test('le Repère tombe entre 50 et 300 ans de la bonne date', () {
      for (var i = 0; i < 20; i++) {
        final g = partie();
        expect(g.utiliser(BonusType.repere), isTrue);
        final d = (g.repere!.annee - g.current.annee).abs();
        expect(d, inInclusiveRange(repereEcartMin, repereEcartMax));
      }
    });

    test('le Zoom enferme le curseur dans sa fenêtre', () {
      final g = partie();
      expect(g.utiliser(BonusType.zoom, rng: () => 0.5), isTrue);
      final z = g.zoom!;
      expect(g.current.annee, inInclusiveRange(z.de, z.a));
      g.setYear(minYear);
      expect(g.guessYear, z.de);
      g.setFrac(1);
      expect(g.guessYear, z.a);
      g.next(); // sans effet hors révélation
      g.setYear(g.current.annee);
      g.validate();
      g.finishReveal();
      g.next();
      expect(g.zoom, isNull); // effacé à la manche suivante
    });

    test('la Seconde chance se dépense dès qu’elle est armée', () {
      final g = partie();
      final depenses = <BonusType>[];
      g.onBonusConsomme = depenses.add;
      // Réponse juste : la manche se révèle, le bonus est quand même parti.
      expect(g.utiliser(BonusType.secondeChance), isTrue);
      expect(depenses, [BonusType.secondeChance]);
      g.setYear(g.current.annee);
      expect(g.validate(), isNotNull);
      expect(g.aidee, isTrue);
    });

    test('la Seconde chance fait rejouer une réponse trop loin', () {
      final g = partie();
      final depenses = <BonusType>[];
      g.onBonusConsomme = depenses.add;
      expect(g.utiliser(BonusType.secondeChance), isTrue);
      final annee = g.current.annee;
      // 400 ans avant la date, sauf si la frise s'arrête avant.
      final avant = annee - 400 >= minYear;
      g.setYear(avant ? annee - 400 : annee + 400);
      expect(g.validate(), isNull);
      expect(g.phase, GamePhase.guess);
      expect(g.indicationSecondeChance, avant ? 'Plus tard !' : 'Plus tôt !');
      expect(depenses, [BonusType.secondeChance]);
      // La deuxième réponse garde ses points complets.
      g.setYear(annee);
      expect(g.validate()!.base, maxScore);
    });

    test('l’XP double double l’XP sans toucher aux points', () {
      final normale = partie();
      normale.setYear(normale.current.annee);
      final r1 = normale.validate()!;

      final doublee = partie();
      doublee.events[0] = normale.current;
      expect(doublee.utiliser(BonusType.xpDouble), isTrue);
      doublee.setYear(doublee.current.annee);
      final r2 = doublee.validate()!;
      expect(r2.pts, r1.pts);
      expect(r2.xp, r1.xp * 2);
      expect(doublee.aidee, isFalse); // les records restent ouverts
      expect(doublee.plafondXp, maxXpPerGame * 2);
    });
  });

  testWidgets('un joueur de niveau 14 reçoit ses bonus et les voit en partie',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues(
        {'onboardingVu': true, 'xp': xpPour(14)});
    await tester.pumpWidget(
        EreaApp(repo: repo, store: await Store.load()));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau : les bonus !'), findsOneWidget);
    await tester.tap(find.text('Super !'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Classique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C’est parti !'));
    await tester.pumpAndSettle();
    // Trois bonus découverts : Remplacer, Époque, Repère.
    expect(find.bySemanticsLabel(RegExp(r'^Repère, 1 en stock')),
        findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Zoom')), findsNothing);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Époque, 1 en stock')));
    await tester.pumpAndSettle();
    expect(find.textContaining('La bonne date est dans'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Époque, 0 en stock')),
        findsOneWidget);
  });
}
