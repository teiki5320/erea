import 'package:flutter/foundation.dart';

import '../core/rng.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import '../data/events_repository.dart';
import '../models/hist_event.dart';

enum GameMode { classique, daily, chrono, duel }

enum GamePhase { guess, anim, reveal }

class RoundResult {
  final HistEvent event;
  final int guess;
  final int ecart;
  final int base; // points avant multiplicateur
  final int pts; // points avec multiplicateur (manche finale x2)
  const RoundResult(this.event, this.guess, this.ecart, this.base, this.pts);
}

/// État central d'une partie (solo classique / défi du jour pour ce squelette ;
/// chrono et duel sont décrits dans SPEC.md et à porter ensuite).
class GameController extends ChangeNotifier {
  GameController(this.repo);

  final EventsRepository repo;

  GameMode mode = GameMode.classique;
  String catKey = 'tout';
  Difficulty diff = Difficulty.normal;

  List<HistEvent> events = [];
  int round = 0;
  GamePhase phase = GamePhase.guess;
  double frac = 0.5;
  int guessYear = fracToYear(0.5);
  bool touched = false;
  final List<RoundResult> results = [];
  int total = 0;

  /// Combo : réponses consécutives ≥ 700 points de base. À partir de 3,
  /// la manche suivante rapporte 1,5× d'XP. Le multiplicateur ne touche
  /// JAMAIS les points (barème et records intacts, cf. SPEC §10) : il
  /// s'accumule dans [comboBonusXp], crédité en fin de partie.
  int combo = 0;
  bool boostNext = false;
  bool lastBoosted = false;
  int comboBonusXp = 0;

  HistEvent get current => events[round % events.length];
  bool get isLastRound => round == rounds - 1;
  int get multiplier => roundMultiplier(round, chrono: mode == GameMode.chrono);

  /// Lance une partie. Pour le défi du jour, [seenIds] est ignoré et le
  /// tirage est déterministe (même série pour tout le monde).
  bool start(GameMode m, {Set<int> seenIds = const {}}) {
    mode = m;
    round = 0;
    results.clear();
    total = 0;
    combo = 0;
    boostNext = false;
    lastBoosted = false;
    comboBonusXp = 0;
    if (m == GameMode.daily) {
      final rng = mulberry32(dailySeed(DateTime.now()));
      events = repo.pick('tout', Difficulty.normal, rng: rng);
      catKey = 'tout';
      diff = Difficulty.normal;
    } else {
      events = repo.pick(catKey, diff, seen: seenIds);
    }
    if (events.isEmpty) return false;
    _setupRound();
    return true;
  }

  void _setupRound() {
    phase = GamePhase.guess;
    touched = false;
    setFrac(0.5, silent: true);
    notifyListeners();
  }

  void setFrac(double f, {bool silent = false}) {
    frac = f.clamp(0.0, 1.0).toDouble();
    guessYear = fracToYear(frac);
    if (!silent) touched = true;
    notifyListeners();
  }

  void setYear(int y) {
    final clamped = y.clamp(minYear, maxYear).toInt();
    frac = yearToFrac(clamped);
    guessYear = clamped;
    touched = true;
    notifyListeners();
  }

  /// Valide la réponse ; l'écran anime ensuite le ruban vers la vraie date
  /// (phase anim) puis appelle [finishReveal].
  RoundResult? validate() {
    if (phase != GamePhase.guess || !touched) return null;
    phase = GamePhase.anim;
    final ev = current;
    final base = scoreFor(ev.annee, guessYear, diff);
    final ecart = (guessYear - ev.annee).abs();
    final pts = base * multiplier;
    final result = RoundResult(ev, guessYear, ecart, base, pts);
    results.add(result);
    lastBoosted = boostNext;
    if (lastBoosted) {
      comboBonusXp += (pts / 10 * diff.xpMult * 0.5).round();
    }
    combo = base >= 700 ? combo + 1 : 0;
    boostNext = combo >= 3;
    notifyListeners();
    return result;
  }

  void finishReveal() {
    phase = GamePhase.reveal;
    if (results.isNotEmpty) total += results.last.pts;
    notifyListeners();
  }

  /// Passe à la manche suivante. Retourne false quand la partie est finie.
  bool next() {
    if (phase != GamePhase.reveal) return true;
    if (round < rounds - 1) {
      round++;
      _setupRound();
      return true;
    }
    return false;
  }

  int get perfects => results.where((r) => r.base == maxScore).length;

  double get averageEcart {
    if (results.isEmpty) return 0;
    final sum = results.fold<int>(0, (s, r) => s + r.ecart);
    return sum / results.length;
  }

  /// Grille emoji façon Wordle pour le partage (sans spoiler).
  String emojiGrid() {
    final buffer = StringBuffer();
    for (final r in results) {
      if (r.base == maxScore) {
        buffer.write('🎯');
      } else if (r.base >= 700) {
        buffer.write('🟩');
      } else if (r.base >= 350) {
        buffer.write('🟨');
      } else {
        buffer.write('🟥');
      }
    }
    return buffer.toString();
  }
}
