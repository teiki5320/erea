import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale (équivalent du localStorage du prototype web) :
/// XP, records, anti-répétition, défi du jour.
class Store {
  Store._(this._prefs);

  final SharedPreferences _prefs;

  static Future<Store> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Store._(prefs);
  }

  int get xp => _prefs.getInt('xp') ?? 0;
  Future<void> addXp(int gain) => _prefs.setInt('xp', xp + gain);

  int get games => _prefs.getInt('games') ?? 0;
  Future<void> incGames() => _prefs.setInt('games', games + 1);

  /// Records par « catKey|difficulty ». Retourne true si record battu.
  int bestFor(String key) => _prefs.getInt('best.$key') ?? 0;
  Future<bool> submitScore(String key, int total) async {
    if (total > bestFor(key)) {
      await _prefs.setInt('best.$key', total);
      return true;
    }
    return false;
  }

  /// Anti-répétition : ids des ~80 derniers événements joués.
  /// Une préférence corrompue ne doit jamais bloquer le jeu.
  Set<int> get seen => _idSet('seen');

  Future<void> markSeen(Iterable<int> ids) async {
    final list = [
      ...seen.where((id) => !ids.contains(id)),
      ...ids,
    ];
    final trimmed = list.length > 80 ? list.sublist(list.length - 80) : list;
    await _prefs.setString('seen', jsonEncode(trimmed));
  }

  /// Événements découverts (révélés au moins une fois), SANS plafond :
  /// c'est la collection du joueur, distincte du tampon anti-répétition
  /// [seen] qui, lui, ne garde que les 80 derniers. Alimentée dès
  /// maintenant pour que l'album et le succès « 100 événements
  /// découverts » (SPEC §6) soient remplis rétroactivement.
  Set<int> get discovered => _idSet('discovered');

  Future<void> markDiscovered(Iterable<int> ids) async {
    final all = discovered..addAll(ids);
    await _prefs.setString('discovered', jsonEncode(all.toList()..sort()));
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

  /// Défi du jour. Trois dates distinctes :
  /// - `daily.last` : jour de la TENTATIVE (posé au lancement, verrou
  ///   anti-rejeu) ;
  /// - `daily.done` : jour du défi réellement TERMINÉ (10 manches) ;
  /// - `daily.streakDay` : dernier jour terminé, base du calcul de série.
  String get dailyLast => _prefs.getString('daily.last') ?? '';
  String get dailyDone => _prefs.getString('daily.done') ?? '';
  String get dailyStreakDay => _prefs.getString('daily.streakDay') ?? '';
  int get dailyLastScore => _prefs.getInt('daily.lastScore') ?? 0;

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
  bool get dailyPlayedToday => dailyLast == dayKey(DateTime.now());

  /// Défi du jour mené à son terme : seul cas où un score est affichable.
  bool get dailyFinishedToday => dailyDone == dayKey(DateTime.now());

  /// Série brute telle que stockée (dernière valeur créditée).
  int get dailyStreak => _prefs.getInt('daily.streak') ?? 0;

  /// Série RÉELLE : une série s'éteint dès qu'un jour est sauté. La valeur
  /// stockée n'étant recalculée qu'à la fin du prochain défi, on la valide
  /// à la lecture — sinon l'accueil affiche encore « 🔥 5 » une semaine
  /// après le dernier défi.
  int get effectiveStreak {
    final now = DateTime.now();
    final day = dailyStreakDay;
    if (day.isEmpty) return 0;
    if (day == dayKey(now) || day == _yesterdayKey(now)) return dailyStreak;
    return 0;
  }

  /// Verrouille la tentative du jour DÈS LE LANCEMENT du défi : abandonner
  /// en cours de route ne permet plus de rejouer en connaissant les
  /// réponses. La série, elle, n'est PAS créditée ici : elle récompense un
  /// défi terminé (cf. [finishDaily]), sinon elle s'entretiendrait en
  /// lançant puis quittant chaque jour.
  Future<void> lockDaily({DateTime? now}) async {
    final d = now ?? DateTime.now();
    final key = dayKey(d);
    if (dailyLast == key) return; // déjà verrouillé pour ce jour
    await _prefs.setString('daily.last', key);
  }

  /// Enregistre le résultat du défi verrouillé par [lockDaily] et crédite
  /// la série. [day] est le jour du LANCEMENT : un défi commencé avant
  /// minuit et fini après reste crédité au bon jour, sans verrouiller le
  /// lendemain.
  Future<void> finishDaily(int total, {String grid = '', String? day}) async {
    final key = day ?? dayKey(DateTime.now());
    if (dailyLast != key) return; // tentative d'un autre jour : on ignore
    if (dailyDone == key) return; // déjà enregistré
    final streak = dailyStreakDay == _dayBefore(key) ? dailyStreak + 1 : 1;
    await _prefs.setString('daily.done', key);
    await _prefs.setInt('daily.lastScore', total);
    await _prefs.setString('daily.grid', grid);
    await _prefs.setInt('daily.streak', streak);
    await _prefs.setString('daily.streakDay', key);
  }

  /// La veille d'une clé AAAA-MM-JJ, en calendrier.
  static String _dayBefore(String key) => _yesterdayKey(DateTime(
        int.parse(key.substring(0, 4)),
        int.parse(key.substring(5, 7)),
        int.parse(key.substring(8, 10)),
      ));
}
