import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale (équivalent du localStorage du prototype web) :
/// XP, records, anti-répétition, collection, défi du jour, réglages.
///
/// Deux principes :
/// - **aucune écriture silencieusement perdue** : chaque écriture est
///   vérifiée et retentée une fois, et un échec définitif lève le drapeau
///   [writeFailed] que l'interface peut signaler ;
/// - **l'horloge est injectable** ([clock]) : sans ça, le passage de minuit
///   et le changement d'heure ne seraient testables qu'en modifiant
///   l'heure de l'appareil.
class Store {
  Store._(this._prefs);

  final SharedPreferences _prefs;

  /// Horloge du store. Remplaçable dans les tests.
  DateTime Function() clock = DateTime.now;

  /// Passe à vrai dès qu'une écriture a définitivement échoué (stockage
  /// plein, plugin indisponible…). L'accueil peut alors prévenir plutôt
  /// que de laisser croire que la partie a été enregistrée.
  bool writeFailed = false;

  Set<int>? _seenCache;
  Set<int>? _discoveredCache;

  static Future<Store> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Store._(prefs);
  }

  DateTime get _now => clock();

  /// Écrit, vérifie, retente UNE fois. Ne relance jamais : une préférence
  /// perdue ne doit pas faire échouer la fin de partie et emporter avec
  /// elle l'XP et le record qui suivent dans la même séquence.
  Future<bool> _put(Future<bool> Function() write) async {
    for (var essai = 0; essai < 2; essai++) {
      try {
        if (await write()) return true;
      } catch (_) {
        // On retente une fois, puis on abandonne proprement.
      }
    }
    writeFailed = true;
    return false;
  }

  int get xp => _prefs.getInt('xp') ?? 0;
  Future<void> addXp(int gain) async {
    if (gain == 0) return;
    await _put(() => _prefs.setInt('xp', xp + gain));
  }

  int get games => _prefs.getInt('games') ?? 0;
  Future<void> incGames() => _put(() => _prefs.setInt('games', games + 1));

  /// Parcours d'accueil (présentation + choix du pays) déjà vu ?
  bool get onboardingVu => _prefs.getBool('onboardingVu') ?? false;
  Future<void> setOnboardingVu() =>
      _put(() => _prefs.setBool('onboardingVu', true));

  /// Pays choisi à l'accueil (nom affichable + code ISO). Vide = laisser
  /// l'appareil décider (réglage iOS/Android).
  String? get paysChoisiNom => _prefs.getString('paysChoisiNom');
  String? get paysChoisiIso => _prefs.getString('paysChoisiIso');
  Future<void> setPaysChoisi({String? nom, String? iso}) async {
    if (nom == null || iso == null) {
      await _put(() => _prefs.remove('paysChoisiNom'));
      await _put(() => _prefs.remove('paysChoisiIso'));
    } else {
      await _put(() => _prefs.setString('paysChoisiNom', nom));
      await _put(() => _prefs.setString('paysChoisiIso', iso));
    }
  }

  /// Records par « catKey|difficulty ». Retourne true si record battu.
  int bestFor(String key) => _prefs.getInt('best.$key') ?? 0;
  Future<bool> submitScore(String key, int total) async {
    if (total <= bestFor(key)) return false;
    await _put(() => _prefs.setInt('best.$key', total));
    return true;
  }

  /// Catégories et packs déjà joués (succès « toucher à tout »).
  Set<String> get catsPlayed =>
      (_prefs.getStringList('catsPlayed') ?? const <String>[]).toSet();
  Future<void> markCatPlayed(String key) async {
    final all = catsPlayed;
    if (!all.add(key)) return;
    await _put(() => _prefs.setStringList('catsPlayed', all.toList()..sort()));
  }

  /// Succès débloqués (clés de `lib/game/badges.dart`).
  Set<String> get badges =>
      (_prefs.getStringList('badges') ?? const <String>[]).toSet();
  Future<void> unlockBadges(Iterable<String> keys) async {
    final all = badges;
    final avant = all.length;
    all.addAll(keys);
    if (all.length == avant) return;
    await _put(() => _prefs.setStringList('badges', all.toList()..sort()));
  }

  /// Anti-répétition : ids des ~300 derniers événements joués. 80 ne
  /// couvrait que huit parties — dans une petite catégorie, le jeu se
  /// remettait à tourner en rond dès la troisième.
  static const int memoireSeen = 300;

  Set<int> get seen => _seenCache ??= _idSet('seen');

  Future<void> markSeen(Iterable<int> ids) async {
    final nouveaux = ids.where((id) => !seen.contains(id)).toList();
    if (nouveaux.isEmpty) return;
    final list = [...seen.where((id) => !nouveaux.contains(id)), ...nouveaux];
    final trimmed = list.length > memoireSeen
        ? list.sublist(list.length - memoireSeen)
        : list;
    _seenCache = trimmed.toSet();
    await _put(() => _prefs.setString('seen', jsonEncode(trimmed)));
  }

  /// Événements découverts (révélés au moins une fois), SANS plafond :
  /// c'est la collection du joueur, distincte du tampon anti-répétition
  /// [seen] qui, lui, ne garde que les 80 derniers.
  Set<int> get discovered => _discoveredCache ??= _idSet('discovered');

  Future<void> markDiscovered(Iterable<int> ids) async {
    final all = discovered;
    final avant = all.length;
    all.addAll(ids);
    if (all.length == avant) return; // rien de neuf : aucune écriture
    await _put(
        () => _prefs.setString('discovered', jsonEncode(all.toList()..sort())));
  }

  /// Liste d'ids persistée en JSON ; une préférence corrompue ne doit
  /// jamais bloquer le jeu.
  Set<int> _idSet(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return {};
      return (jsonDecode(raw) as List<dynamic>).cast<int>().toSet();
    } catch (_) {
      return {};
    }
  }

  // ---------------------------------------------------------------- réglages

  bool get soundOn => _prefs.getBool('opt.sound') ?? true;
  Future<void> setSoundOn(bool v) => _put(() => _prefs.setBool('opt.sound', v));

  bool get hapticsOn => _prefs.getBool('opt.haptics') ?? true;
  Future<void> setHapticsOn(bool v) =>
      _put(() => _prefs.setBool('opt.haptics', v));

  /// Le geste de la frise n'est montré qu'une fois.
  bool get tutoSeen => _prefs.getBool('opt.tuto') ?? false;
  Future<void> setTutoSeen() => _put(() => _prefs.setBool('opt.tuto', true));

  bool get remindersOn => _prefs.getBool('opt.reminders') ?? false;
  Future<void> setRemindersOn(bool v) =>
      _put(() => _prefs.setBool('opt.reminders', v));

  /// Remise à zéro complète (écran de réglages).
  ///
  /// Trois choses survivent, à dessein :
  /// - le VERROU du défi du jour, dès qu'une tentative a été LANCÉE
  ///   aujourd'hui (terminée ou non) : la série étant déterministe par
  ///   date, une remise à zéro rendait sinon le défi rejouable avec les
  ///   réponses déjà vues — et le score partait au classement mondial ;
  /// - le score et la grille du défi TERMINÉ : l'accueil affichait
  ///   sinon « Déjà joué · 0 pts », un score jamais réalisé ;
  /// - le pays choisi et le parcours d'accueil : remettre sa progression
  ///   à zéro n'est pas déménager, et l'écran « Mon pays » aurait montré
  ///   « Automatique » alors que l'ancien choix restait appliqué.
  Future<void> resetAll() async {
    _seenCache = null;
    _discoveredCache = null;
    final tentativeAujourdhui = dailyPlayedToday;
    final defiTermineAujourdhui = dailyFinishedToday;
    final score = dailyLastScore;
    final grille = dailyGrid;
    final pays = (nom: paysChoisiNom, iso: paysChoisiIso);
    final accueilVu = onboardingVu;
    final jour = dayKey(_now);
    await _put(() => _prefs.clear());
    if (tentativeAujourdhui) {
      await _put(() => _prefs.setString('daily.last', jour));
    }
    if (defiTermineAujourdhui) {
      await _put(() => _prefs.setString('daily.done', jour));
      await _put(() => _prefs.setInt('daily.lastScore', score));
      await _put(() => _prefs.setString('daily.grid', grille));
    }
    if (accueilVu) await setOnboardingVu();
    if (pays.iso != null) await setPaysChoisi(nom: pays.nom, iso: pays.iso);
  }

  // -------------------------------------------------------------- défi du jour

  /// - `daily.last` : jour de la TENTATIVE (verrou anti-rejeu) ;
  /// - `daily.done` : jour du défi réellement TERMINÉ ;
  /// - `daily.streakDay` : dernier jour terminé, base du calcul de série ;
  /// - `daily.progress*` : manches déjà jouées, pour reprendre après un
  ///   arrêt SUBI (l'app tuée par iOS) — un abandon volontaire, lui,
  ///   efface cette reprise.
  String get dailyLast => _prefs.getString('daily.last') ?? '';
  String get dailyDone => _prefs.getString('daily.done') ?? '';
  String get dailyStreakDay => _prefs.getString('daily.streakDay') ?? '';
  int get dailyLastScore => _prefs.getInt('daily.lastScore') ?? 0;
  int get dailyBest => _prefs.getInt('daily.best') ?? 0;

  /// Qualité des 10 manches du dernier défi joué : 'g' ≥ 700 points de
  /// base, 'y' ≥ 350, 'r' sinon (les barres du panneau d'accueil).
  String get dailyGrid => _prefs.getString('daily.grid') ?? '';

  static String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// La veille de [d] en CALENDRIER (pas 24 h absolues) : le lendemain
  /// d'un changement d'heure, un jour ne fait pas 24 h et `subtract`
  /// reculerait de deux jours entre 00:00 et 00:59, cassant la série.
  static String _yesterdayKey(DateTime d) =>
      dayKey(DateTime(d.year, d.month, d.day - 1));

  /// Tentative du jour déjà utilisée (terminée OU abandonnée).
  bool get dailyPlayedToday => dailyLast == dayKey(_now);

  /// Défi du jour mené à son terme : seul cas où un score est affichable.
  bool get dailyFinishedToday => dailyDone == dayKey(_now);

  /// Défi du jour interrompu par un arrêt subi : il peut être REPRIS là où
  /// il s'était arrêté. Un abandon volontaire efface la reprise.
  bool get dailyResumable =>
      dailyPlayedToday &&
      !dailyFinishedToday &&
      _prefs.getString('daily.progressDay') == dayKey(_now);

  /// Années déjà proposées pendant le défi en cours. La série d'événements
  /// étant déterministe (graine = date), ces réponses suffisent à
  /// reconstituer entièrement la partie.
  List<int> get dailyProgress {
    try {
      final raw = _prefs.getString('daily.progress');
      if (raw == null) return const [];
      return (jsonDecode(raw) as List<dynamic>).cast<int>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveDailyProgress(String day, List<int> guesses) async {
    // Les réponses AVANT le jour : si l'app meurt entre les deux écritures,
    // un progressDay orphelin ferait rejouer les réponses de la VEILLE sur
    // la série du jour. L'ordre inverse laisse au pire une reprise vide.
    await _put(() => _prefs.setString('daily.progress', jsonEncode(guesses)));
    await _put(() => _prefs.setString('daily.progressDay', day));
  }

  Future<void> clearDailyProgress() async {
    await _put(() => _prefs.remove('daily.progressDay'));
    await _put(() => _prefs.remove('daily.progress'));
  }

  /// Verrouille la tentative du jour DÈS LE LANCEMENT du défi : abandonner
  /// en cours de route ne permet plus de rejouer en connaissant les
  /// réponses. La série, elle, n'est PAS créditée ici : elle récompense un
  /// défi terminé (cf. [finishDaily]).
  Future<void> lockDaily({DateTime? now}) async {
    final key = dayKey(now ?? _now);
    if (dailyLast == key) return; // déjà verrouillé pour ce jour
    await _put(() => _prefs.setString('daily.last', key));
  }

  /// Enregistre le résultat du défi verrouillé par [lockDaily] et crédite
  /// la série. [day] est le jour du LANCEMENT : un défi commencé avant
  /// minuit et fini après reste crédité au bon jour, sans verrouiller le
  /// lendemain.
  Future<void> finishDaily(int total,
      {String grid = '', String? day, List<int> guesses = const []}) async {
    final key = day ?? dayKey(_now);
    if (dailyLast != key) return; // tentative d'un autre jour : on ignore
    if (dailyDone == key) return; // déjà enregistré
    final streak = dailyStreakDay == _dayBefore(key) ? dailyStreak + 1 : 1;
    await _put(() => _prefs.setString('daily.done', key));
    await _put(() => _prefs.setInt('daily.lastScore', total));
    await _put(() => _prefs.setString('daily.grid', grid));
    await _put(() => _prefs.setInt('daily.streak', streak));
    await _put(() => _prefs.setString('daily.streakDay', key));
    if (total > dailyBest) {
      await _put(() => _prefs.setInt('daily.best', total));
    }
    await clearDailyProgress();
  }

  /// Série brute telle que stockée (dernière valeur créditée).
  int get dailyStreak => _prefs.getInt('daily.streak') ?? 0;

  /// Série RÉELLE : une série s'éteint dès qu'un jour est sauté. La valeur
  /// stockée n'étant recalculée qu'à la fin du prochain défi, on la valide
  /// à la lecture — sinon l'accueil affiche encore « 🔥 5 » une semaine
  /// après le dernier défi.
  int get effectiveStreak {
    final day = dailyStreakDay;
    if (day.isEmpty) return 0;
    final now = _now;
    if (day == dayKey(now) || day == _yesterdayKey(now)) return dailyStreak;
    return 0;
  }

  /// La veille d'une clé AAAA-MM-JJ, en calendrier.
  static String _dayBefore(String key) => _yesterdayKey(DateTime(
        int.parse(key.substring(0, 4)),
        int.parse(key.substring(5, 7)),
        int.parse(key.substring(8, 10)),
      ));
}
