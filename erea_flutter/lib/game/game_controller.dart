import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/bonus.dart';
import '../core/progression.dart';
import '../core/region.dart';
import '../core/rng.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import '../data/events_repository.dart';
import '../data/store.dart';
import '../models/hist_event.dart';

enum GameMode { classique, daily, chrono, roulette }

enum GamePhase { guess, anim, reveal }

class RoundResult {
  final HistEvent event;
  final int guess;
  final int ecart;
  final int base; // points avant multiplicateur
  final int pts; // points avec multiplicateur (manche finale x2)

  /// XP de CETTE manche, bonus de combo compris. C'est exactement ce qui
  /// est annoncé au joueur à la révélation ET ce qui sera crédité : le
  /// total d'XP d'une partie est la somme de ces valeurs, jamais un
  /// arrondi calculé à part.
  final int xp;

  /// Mode Chrono : la manche s'est terminée SANS réponse (temps écoulé).
  /// L'écran doit dire « Temps écoulé », pas « Trop loin ! » — surtout
  /// quand le curseur était pile sur la bonne année.
  final bool tempsEcoule;
  const RoundResult(
      this.event, this.guess, this.ecart, this.base, this.pts, this.xp,
      {this.tempsEcoule = false});
}

/// État central d'une partie, pour tous les modes : Classique et packs,
/// défi du jour, Chrono, Roulette des drapeaux.
class GameController extends ChangeNotifier {
  GameController(this.repo);

  final EventsRepository repo;

  GameMode mode = GameMode.classique;
  String catKey = 'tout';

  /// Le pays sur lequel la roulette s'est arrêtée. Posé par l'écran de
  /// roulette avant `start`, ignoré dans tous les autres modes.
  String? pays;
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
  /// JAMAIS les points (barème et records intacts, cf. SPEC §10) : il ne
  /// joue que sur l'XP de la manche.
  int combo = 0;
  bool boostNext = false;
  bool lastBoosted = false;

  /// Vrai quand la manche qui vient d'être jouée a rompu une série en
  /// cours : la révélation l'annonce, au lieu de faire disparaître le
  /// bandeau sans explication.
  bool comboBroken = false;

  /// XP cumulée des manches jouées (somme des [RoundResult.xp]), bornée au
  /// crédit par le plafond de [xpTotal].
  int xpEarned = 0;

  /// XP réellement créditée en fin de partie : la somme annoncée manche
  /// après manche, plafonnée comme le veut SPEC §5.
  int get xpTotal => xpEarned.clamp(0, plafondXp);

  /// Le plafond d'XP de la partie : doublé avec le bonus XP double, sans
  /// quoi le bonus ne rapporterait rien à un bon joueur déjà au plafond.
  int get plafondXp => xpDoubleActif ? maxXpPerGame * 2 : maxXpPerGame;

  // ------------------------------------------------------------------ bonus
  // Règles : `lib/core/bonus.dart`. Le contrôleur applique les effets ; le
  // stock, lui, vit dans le Store, que l'écran débite par [onBonusConsomme].

  /// Appelé quand un bonus est réellement dépensé. La Seconde chance ne
  /// l'est qu'au moment où elle sert : armée pour rien, elle reste au stock.
  void Function(BonusType b)? onBonusConsomme;

  /// Bonus dépensés dans cette partie ([bonusParPartie] au plus).
  final List<BonusType> bonusJoues = [];

  /// Partie « aidée » : un bonus qui change le score a servi. Elle n'entre
  /// ni dans les records ni dans les classements.
  bool get aidee => bonusJoues.any((b) => b.aide);

  /// Pas de bonus dans le Défi du jour : tout le monde y joue à égalité.
  bool get bonusPermis => mode != GameMode.daily;

  /// Un bonus peut-il servir maintenant ?
  bool get bonusUtilisable =>
      bonusPermis &&
      phase == GamePhase.guess &&
      bonusJoues.length < bonusParPartie &&
      !secondeChanceArmee;

  /// Effets en cours sur la manche, effacés à la manche suivante.
  Era? epoqueAide;
  HistEvent? repere;
  ({int de, int a})? zoom;
  bool secondeChanceArmee = false;

  /// « Plus tôt ! » ou « Plus tard ! » : la Seconde chance vient de servir.
  String? indicationSecondeChance;

  /// XP double : vaut pour toutes les manches qui suivent son usage.
  bool xpDoubleActif = false;

  /// Événements déjà vus au lancement : un remplaçant frais passe avant.
  Set<int> _seen = const {};

  /// Instant de lancement du défi du jour (fourni par l'écran d'accueil,
  /// le même que celui du verrou) et sa clé AAAA-MM-JJ : un défi à cheval
  /// sur minuit reste crédité au jour de son lancement.
  DateTime? dailyNow;
  String dailyKey = '';

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
    comboBroken = false;
    xpEarned = 0;
    bonusJoues.clear();
    xpDoubleActif = false;
    _seen = seenIds;
    if (m == GameMode.daily) {
      final now = dailyNow ?? DateTime.now();
      dailyKey = Store.dayKey(now);
      final rng = mulberry32(dailySeed(now));
      events = repo.pick('tout', Difficulty.normal, rng: rng);
      catKey = 'tout';
      diff = Difficulty.normal;
    } else if (m == GameMode.roulette) {
      // La roulette s'est arrêtée sur UN drapeau : les dix manches
      // portent toutes sur ce pays. `pays` doit avoir été posé par
      // l'écran de roulette ; sans lui on ne devine pas, on refuse.
      final choisi = pays;
      if (choisi == null || choisi.isEmpty) return false;
      events = repo.partiePays(choisi, seen: seenIds);
      catKey = 'pays:$choisi';
      // Difficulté FIXE, comme le défi du jour. Sans ça, la roulette
      // héritait en silence du réglage fait dans la feuille « Partie
      // classique » — même réponse, score ×2,5 d'écart — alors que son
      // flux n'affiche ni ne propose de difficulté.
      diff = Difficulty.normal;
    } else if (m == GameMode.chrono) {
      // Chrono : 10 secondes par question. Tirage et barème FIXES (toute
      // la base, Normal) — le mode a son propre classement mondial, les
      // scores doivent être comparables entre joueurs, comme au défi.
      events = repo.pick('tout', Difficulty.normal, seen: seenIds);
      catKey = 'tout';
      diff = Difficulty.normal;
    } else if (m == GameMode.classique && catKey.startsWith('pack:')) {
      // La feuille Packs n'affiche ni ne propose de difficulté : comme la
      // roulette, on fixe Normal plutôt que d'hériter en silence du
      // dernier réglage de la feuille Classique — même réponse, score
      // très différent, sans que rien ne l'explique.
      diff = Difficulty.normal;
      events = repo.pick(catKey, diff, seen: seenIds);
    } else if (m == GameMode.classique && catKey == 'tout' && joueurEnAfrique) {
      // Joueur détecté en Afrique (pays de réglage de l'appareil) : le
      // Classique « Tout » n'est plus écrit pour un joueur français. Une
      // moitié de la partie vient de l'univers Afrique, l'autre du monde
      // entier — local ET varié. Le choix explicite d'une catégorie ou
      // d'un pack, lui, est toujours respecté tel quel, et le défi du
      // jour reste mondial (même série pour tous).
      final rng = math.Random().nextDouble;
      final afrique =
          repo.pick('pack:afrique', diff, seen: seenIds, count: rounds ~/ 2);
      final monde = repo.pick(
        'tout',
        diff,
        seen: seenIds,
        count: rounds - afrique.length,
        exclure: afrique.map((e) => e.id).toSet(),
      );
      events = shuffled([...afrique, ...monde], rng);
    } else {
      events = repo.pick(catKey, diff, seen: seenIds);
    }
    // Une partie incomplète resservirait les mêmes événements (`round %
    // events.length`) : la 2ᵉ occurrence donnerait la réponse. Mieux vaut
    // refuser de démarrer.
    if (events.length < rounds) return false;
    _setupRound();
    return true;
  }

  void _setupRound() {
    phase = GamePhase.guess;
    touched = false;
    epoqueAide = null;
    repere = null;
    zoom = null;
    secondeChanceArmee = false;
    indicationSecondeChance = null;
    setFrac(0.5, silent: true);
    notifyListeners();
  }

  /// Bornes de la frise en fraction : toute la frise, ou la fenêtre du
  /// Zoom.
  double get fracMin => zoom == null ? 0.0 : yearToFrac(zoom!.de);
  double get fracMax => zoom == null ? 1.0 : yearToFrac(zoom!.a);

  void setFrac(double f, {bool silent = false}) {
    frac = f.clamp(fracMin, fracMax).toDouble();
    guessYear = fracToYear(frac);
    if (!silent) touched = true;
    notifyListeners();
  }

  void setYear(int y) {
    final clamped =
        y.clamp(zoom?.de ?? minYear, zoom?.a ?? maxYear).toInt();
    frac = yearToFrac(clamped);
    guessYear = clamped;
    touched = true;
    notifyListeners();
  }

  /// Valide la réponse ; l'écran anime ensuite le ruban vers la vraie date
  /// (phase anim) puis appelle [finishReveal].
  RoundResult? validate() {
    if (phase != GamePhase.guess || !touched) return null;
    final ev = current;
    final ecart = (guessYear - ev.annee).abs();
    indicationSecondeChance = null;
    if (secondeChanceArmee) {
      secondeChanceArmee = false;
      if (ecart > secondeChanceEcart) {
        // La manche se rejoue : rien n'est révélé, la direction seule est
        // dite. Le bonus n'est dépensé que maintenant.
        _consommer(BonusType.secondeChance);
        indicationSecondeChance =
            guessYear < ev.annee ? 'Plus tard !' : 'Plus tôt !';
        notifyListeners();
        return null;
      }
      // Assez près : la Seconde chance n'a pas servi, elle reste au stock.
    }
    phase = GamePhase.anim;
    final base = scoreFor(ev.annee, guessYear, diff);
    final pts = base * multiplier;
    lastBoosted = boostNext;
    // L'XP se calcule sur le score que la MÊME réponse aurait obtenu en
    // Normal, pas sur les points affichés. Les points s'effondrent bien
    // plus vite en Difficile (marge ÷ 4) que le bonus ×1,75 ne compense :
    // dès ~12 ans d'erreur moyenne, Facile rapportait PLUS d'XP que
    // Difficile — l'inverse de la promesse du sélecteur. Sur une base
    // neutre, l'ordre Facile < Normal < Difficile tient à toute adresse.
    final ptsNeutres =
        scoreFor(ev.annee, guessYear, Difficulty.normal) * multiplier;
    // Plafond appliqué MANCHE PAR MANCHE : chaque « +N XP » annoncé est
    // déjà rogné au budget restant, si bien que la somme affichée est
    // exactement ce qui sera crédité. Avant, l'écran promettait manche
    // après manche jusqu'à 628 XP de plus que le versement final.
    final xp = math.min(
      xpForRound(ptsNeutres, diff.xpMult, boosted: lastBoosted) *
          (xpDoubleActif ? 2 : 1),
      plafondXp - xpEarned,
    );
    final result = RoundResult(ev, guessYear, ecart, base, pts, xp);
    results.add(result);
    xpEarned += xp;
    comboBroken = combo > 0 && base < 700;
    combo = base >= 700 ? combo + 1 : 0;
    boostNext = combo >= 3;
    notifyListeners();
    return result;
  }

  /// Temps écoulé (mode Chrono) : la manche vaut ZÉRO, quelle que soit la
  /// position du curseur — ne pas répondre à temps, c'est ne pas répondre.
  /// Même cheminement d'états que [validate], pour que l'écran enchaîne
  /// exactement pareil (voyage du ruban, révélation, manche suivante).
  RoundResult? validateTimeout() {
    if (phase != GamePhase.guess) return null;
    phase = GamePhase.anim;
    secondeChanceArmee = false;
    indicationSecondeChance = null;
    final ev = current;
    final ecart = (guessYear - ev.annee).abs();
    lastBoosted = false;
    final result =
        RoundResult(ev, guessYear, ecart, 0, 0, 0, tempsEcoule: true);
    results.add(result);
    comboBroken = combo > 0;
    combo = 0;
    boostNext = false;
    notifyListeners();
    return result;
  }

  void finishReveal() {
    phase = GamePhase.reveal;
    if (results.isNotEmpty) total += results.last.pts;
    notifyListeners();
  }

  /// Joue le bonus [b] sur la manche en cours. Rend false s'il ne peut pas
  /// servir (déjà un bonus dans la partie, Défi du jour, aucun Repère ou
  /// remplaçant possible) : rien n'est alors dépensé.
  bool utiliser(BonusType b, {double Function()? rng}) {
    if (!bonusUtilisable) return false;
    final hasard = rng ?? math.Random().nextDouble;
    switch (b) {
      case BonusType.remplacer:
        final nouveau = _remplacant(hasard);
        if (nouveau == null) return false;
        events[round % events.length] = nouveau;
      case BonusType.epoque:
        epoqueAide = eraFor(current.annee);
      case BonusType.repere:
        final r = _repere(hasard);
        if (r == null) return false;
        repere = r;
      case BonusType.zoom:
        zoom = fenetreZoom(current.annee, hasard());
        // Le curseur rentre dans la fenêtre, au milieu, s'il en était sorti.
        if (frac < fracMin || frac > fracMax) {
          final avant = touched;
          setFrac((fracMin + fracMax) / 2, silent: true);
          touched = avant;
        }
      case BonusType.secondeChance:
        // Armée, pas dépensée : elle ne coûte que si elle sert.
        secondeChanceArmee = true;
        notifyListeners();
        return true;
      case BonusType.xpDouble:
        xpDoubleActif = true;
    }
    _consommer(b);
    notifyListeners();
    return true;
  }

  void _consommer(BonusType b) {
    bonusJoues.add(b);
    onBonusConsomme?.call(b);
  }

  /// Un autre événement du même tirage (catégorie, pack ou pays), absent
  /// de la partie : du même niveau et jamais vu d'abord.
  HistEvent? _remplacant(double Function() hasard) {
    final dejaLa = events.map((e) => e.id).toSet();
    final dispo =
        repo.pool(catKey).where((e) => !dejaLa.contains(e.id)).toList();
    if (dispo.isEmpty) return null;
    final niveau = current.niveau;
    for (final filtre in <bool Function(HistEvent)>[
      (e) => e.niveau == niveau && !_seen.contains(e.id),
      (e) => !_seen.contains(e.id),
      (_) => true,
    ]) {
      final choix = dispo.where(filtre).toList();
      if (choix.isNotEmpty) return choix[(hasard() * choix.length).floor()];
    }
    return null;
  }

  /// Un fait connu (niveau 1 d'abord), daté entre [repereEcartMin] et
  /// [repereEcartMax] ans de la bonne date, pris dans toute la base.
  HistEvent? _repere(double Function() hasard) {
    final annee = current.annee;
    final dejaLa = events.map((e) => e.id).toSet();
    bool distance(HistEvent e) {
      final d = (e.annee - annee).abs();
      return d >= repereEcartMin && d <= repereEcartMax;
    }

    final proches = repo.events
        .where((e) => !dejaLa.contains(e.id) && distance(e))
        .toList();
    final connus = proches.where((e) => e.niveau == 1).toList();
    final source = connus.isNotEmpty ? connus : proches;
    if (source.isEmpty) return null;
    return source[(hasard() * source.length).floor()];
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

  /// Les années proposées jusqu'ici. La série d'un défi du jour étant
  /// déterministe, elles suffisent à reconstituer toute la partie.
  List<int> get guesses => [for (final r in results) r.guess];

  /// Rejoue des manches déjà validées (reprise d'un défi interrompu par un
  /// arrêt subi). Reconstruit résultats, total, combo et XP à l'identique.
  void restore(List<int> anciennes) {
    for (final g in anciennes) {
      if (results.length >= rounds) break;
      setYear(g);
      validate();
      finishReveal();
      if (!next()) break;
    }
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
