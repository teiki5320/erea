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
  Set<int> get seen {
    final raw = _prefs.getString('seen');
    if (raw == null) return {};
    return (jsonDecode(raw) as List<dynamic>).cast<int>().toSet();
  }

  Future<void> markSeen(Iterable<int> ids) async {
    final list = [
      ...seen.where((id) => !ids.contains(id)),
      ...ids,
    ];
    final trimmed = list.length > 80 ? list.sublist(list.length - 80) : list;
    await _prefs.setString('seen', jsonEncode(trimmed));
  }

  /// Défi du jour : clé AAAA-MM-JJ du dernier défi joué + série.
  String get dailyLast => _prefs.getString('daily.last') ?? '';
  int get dailyStreak => _prefs.getInt('daily.streak') ?? 0;
  int get dailyLastScore => _prefs.getInt('daily.lastScore') ?? 0;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get dailyPlayedToday => dailyLast == dayKey(DateTime.now());

  Future<void> recordDaily(int total) async {
    final now = DateTime.now();
    final yesterday = dayKey(now.subtract(const Duration(days: 1)));
    final streak = dailyLast == yesterday ? dailyStreak + 1 : 1;
    await _prefs.setString('daily.last', dayKey(now));
    await _prefs.setInt('daily.streak', streak);
    await _prefs.setInt('daily.lastScore', total);
  }
}
