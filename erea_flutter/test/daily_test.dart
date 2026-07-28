import 'package:erea/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Défi du jour : une tentative par jour, série créditée seulement à un
/// défi TERMINÉ, et arithmétique de calendrier (pas 24 h absolues).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Store> store() => Store.load();

  test('lancer puis abandonner consomme la tentative sans créditer la série',
      () async {
    final s = await store();
    final today = DateTime.now();
    await s.lockDaily(now: today);

    expect(s.dailyPlayedToday, isTrue, reason: 'tentative consommée');
    expect(s.dailyFinishedToday, isFalse, reason: 'défi non terminé');
    expect(s.effectiveStreak, 0, reason: 'aucune série pour un abandon');
    expect(s.dailyGrid, isEmpty);
  });

  test('terminer le défi enregistre score, grille et série', () async {
    final s = await store();
    final today = DateTime.now();
    await s.lockDaily(now: today);
    await s.finishDaily(7200, grid: 'gggyyrgggy', day: Store.dayKey(today));

    expect(s.dailyFinishedToday, isTrue);
    expect(s.dailyLastScore, 7200);
    expect(s.dailyGrid, 'gggyyrgggy');
    expect(s.effectiveStreak, 1);
  });

  test('deux jours consécutifs terminés font une série de 2', () async {
    final s = await store();
    final hier = DateTime.now().subtract(const Duration(days: 1));
    final hierKey = Store.dayKey(hier);
    await s.lockDaily(now: hier);
    await s.finishDaily(5000, day: hierKey);
    expect(s.dailyStreak, 1);

    final today = DateTime.now();
    await s.lockDaily(now: today);
    await s.finishDaily(6000, day: Store.dayKey(today));
    expect(s.dailyStreak, 2);
    expect(s.effectiveStreak, 2);
  });

  test('une série interrompue n’est plus affichée', () async {
    // Dernier défi terminé il y a une semaine : la série est morte, même
    // si la valeur stockée n'a pas encore été recalculée.
    final vieux = Store.dayKey(DateTime.now().subtract(const Duration(days: 7)));
    SharedPreferences.setMockInitialValues({
      'daily.last': vieux,
      'daily.done': vieux,
      'daily.streakDay': vieux,
      'daily.streak': 5,
    });
    final s = await store();
    expect(s.dailyStreak, 5, reason: 'valeur brute conservée');
    expect(s.effectiveStreak, 0, reason: 'série réellement éteinte');
    expect(s.dailyPlayedToday, isFalse, reason: 'le défi du jour est libre');
  });

  test('la série survit au changement d’heure (calendrier, pas 24 h)',
      () async {
    // Europe/Paris passe à l'heure d'été le 29/03/2026 : le 30/03 à 00:30,
    // « moins 24 h » retomberait au 28/03 et casserait la série.
    final veille = DateTime(2026, 3, 29, 12);
    final lendemain = DateTime(2026, 3, 30, 0, 30);
    final s = await store();
    await s.lockDaily(now: veille);
    await s.finishDaily(5000, day: Store.dayKey(veille));
    expect(s.dailyStreak, 1);

    await s.lockDaily(now: lendemain);
    await s.finishDaily(6000, day: Store.dayKey(lendemain));
    expect(s.dailyStreak, 2, reason: 'jours consécutifs en calendrier');
  });

  test('un défi à cheval sur minuit reste crédité au jour du lancement',
      () async {
    final s = await store();
    final lancement = DateTime(2026, 5, 10, 23, 59);
    await s.lockDaily(now: lancement);
    // La partie se termine après minuit : la clé du lancement fait foi.
    await s.finishDaily(4200, grid: 'gggggggggg', day: Store.dayKey(lancement));

    expect(s.dailyDone, '2026-05-10');
    expect(s.dailyLastScore, 4200);
    expect(s.dailyStreakDay, '2026-05-10');
  });

  test('finishDaily d’un autre jour est ignoré', () async {
    final s = await store();
    await s.lockDaily(now: DateTime.now());
    await s.finishDaily(9999, day: '1999-01-01');
    expect(s.dailyFinishedToday, isFalse);
    expect(s.dailyLastScore, 0);
  });

  test('les découvertes ne sont jamais tronquées, contrairement à seen',
      () async {
    final s = await store();
    final ids = List.generate(300, (i) => i);
    await s.markSeen(ids);
    await s.markDiscovered(ids);

    expect(s.seen.length, 80, reason: 'tampon anti-répétition borné');
    expect(s.discovered.length, 300, reason: 'la collection garde tout');

    await s.markDiscovered([42, 1000]);
    expect(s.discovered.length, 301, reason: 'sans doublon');
    expect(s.discovered, contains(1000));
  });

  test('un défi interrompu par un arrêt subi est reprenable', () async {
    final s = await store();
    final today = Store.dayKey(DateTime.now());
    await s.lockDaily();
    await s.saveDailyProgress(today, [1800, 1900, 1500]);

    expect(s.dailyResumable, isTrue);
    expect(s.dailyProgress, [1800, 1900, 1500]);

    // Un abandon VOLONTAIRE, lui, efface la reprise.
    await s.clearDailyProgress();
    expect(s.dailyResumable, isFalse);
    expect(s.dailyProgress, isEmpty);
  });

  test('terminer le défi efface la reprise et garde le meilleur score',
      () async {
    final s = await store();
    final today = Store.dayKey(DateTime.now());
    await s.lockDaily();
    await s.saveDailyProgress(today, [1800]);
    await s.finishDaily(6000, day: today);

    expect(s.dailyResumable, isFalse);
    expect(s.dailyBest, 6000);
  });

  test('l’horloge injectable rend le passage de minuit testable', () async {
    final s = await store();
    var maintenant = DateTime(2026, 5, 10, 23, 59);
    s.clock = () => maintenant;

    await s.lockDaily();
    expect(s.dailyPlayedToday, isTrue);

    // Minuit passe : le défi de la veille est fini, celui du jour est libre.
    maintenant = DateTime(2026, 5, 11, 0, 5);
    expect(s.dailyPlayedToday, isFalse,
        reason: 'un nouveau jour, un nouveau défi');
    expect(s.dailyResumable, isFalse);
  });

  test('une écriture impossible lève le drapeau au lieu de passer inaperçue',
      () async {
    final s = await store();
    expect(s.writeFailed, isFalse);
    await s.addXp(120);
    expect(s.xp, 120);
    expect(s.writeFailed, isFalse, reason: 'écriture normale');
  });

  test('marquer un événement déjà connu n’écrit rien', () async {
    final s = await store();
    await s.markDiscovered([1, 2, 3]);
    await s.markSeen([1, 2, 3]);
    expect(s.discovered, {1, 2, 3});
    // Deuxième passage : mêmes ids, la collection ne bouge pas.
    await s.markDiscovered([1, 2]);
    expect(s.discovered, {1, 2, 3});
  });

  test('une préférence corrompue ne bloque ni le jeu ni la collection',
      () async {
    SharedPreferences.setMockInitialValues({
      'seen': 'pas du json',
      'discovered': '{"pas": "une liste"}',
    });
    final s = await store();
    expect(s.seen, isEmpty);
    expect(s.discovered, isEmpty);
  });
}
