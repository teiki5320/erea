import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import '../core/accessibilite.dart';
import '../core/avis.dart';
import '../core/classement.dart';
import '../core/pub.dart';
import '../core/rappels.dart';
import '../core/retour.dart';
import '../core/sons.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import 'game/end_view.dart';
import 'game/guess_view.dart';
import 'game/reveal_view.dart';
import 'game/verdict_textes.dart';
import '../data/store.dart';
import '../game/badges.dart';
import '../game/game_controller.dart';
import 'sticker_widgets.dart';

/// Couleur d'étiquette par catégorie (carte de l'événement).

/// Écran de jeu « Sticker Arcade » (handoff 3a) : fond fondu d'époque,
/// carte de l'événement, année sans bulle, frise plein-bord, minimap,
/// révélation à épingles sur la frise.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.store,
  });

  final GameController controller;
  final Store store;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Jingle du verdict, mis de côté à la validation et joué à la fin du
  /// voyage du ruban — au moment où le badge apparaît.
  void Function()? _jingleVerdict;

  late final AnimationController _travel;
  late final AnimationController _roundFade;

  /// Entrée de la révélation : le badge de verdict jaillit, les points
  /// arrivent juste derrière et rebondissent. C'est le moment de
  /// récompense de la manche, il doit claquer.
  late final AnimationController _pop;
  late final Animation<double> _popBadge;
  late final Animation<double> _popPoints;
  late final Animation<double> _popPointsMontee;

  /// Courbe du fondu de manche, construite UNE fois : la recréer à chaque
  /// build réattacherait des écouteurs à chaque mouvement du doigt.
  late final Animation<double> _roundFadeCurve;

  /// Même clé pour la frise de visée et celle de la révélation : Flutter
  /// réutilise alors le même State (sens de marche des personnages
  /// conservé, pas de re-création du ticker ni de re-rastérisation).
  final GlobalKey _tapeKey = GlobalKey();
  int _fadedRound = -1;
  double _travelBegin = 0;
  double _travelEnd = 0;
  RoundResult? _lastResult;
  bool _showEnd = false;
  bool _finishing = false;

  // Bilan de fin de partie : sans ça, l'écran final ne disait ni l'XP
  // gagnée, ni le niveau franchi, ni le record battu — les trois étaient
  // pourtant déjà calculés.
  /// Astuce du geste : le glissement de la frise est la mécanique unique
  /// du jeu et n'était expliqué nulle part.
  late bool _astuceGeste;

  int _xpAvant = 0;
  bool _record = false;
  List<Badge> _badgesGagnes = const [];
  bool _grilleCopiee = false;

  /// Mode Chrono : 10 secondes par question. Le temps restant est compté
  /// en TICS de 100 ms ([_restantMs]), pas à l'horloge murale : les tics
  /// s'arrêtent quand l'app passe en arrière-plan (personne ne perd sa
  /// manche pour un appel reçu) et suivent l'horloge simulée des tests.
  /// [_autoSuivant] expédie la révélation — le rythme ne retombe jamais.
  static const Duration dureeChrono = Duration(seconds: 10);
  Timer? _chrono;
  int _restantMs = 0;
  Timer? _autoSuivant;

  GameController get game => widget.controller;

  @override
  void initState() {
    super.initState();
    // Fondu temporel de 320 ms au lancement de chaque manche — la seule
    // animation autorisée sur le fond (le reste suit frac, sans délai).
    _roundFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
    _roundFadeCurve = _roundFade.drive(CurveTween(curve: Curves.easeOut));
    // Le fondu se déclenche sur un changement de manche — depuis un
    // écouteur du contrôleur, jamais depuis build() (un effet de bord en
    // pleine construction casserait dès qu'un listener appellera setState).
    game.addListener(_onGameChanged);
    // Chrono : le compte à rebours se fige quand l'app passe en
    // arrière-plan (appel reçu, changement d'app) — personne ne perd sa
    // manche pour une interruption. Les timers Dart, eux, continueraient
    // de tourner sur Android.
    WidgetsBinding.instance.addObserver(this);
    // La manche 1 est déjà en place quand l'écran se monte (le contrôleur
    // démarre avant la navigation) : son fondu se déclenche donc ici.
    _fadedRound = game.round;
    _astuceGeste = !widget.store.tutoSeen;
    _roundFade.forward(from: 0);
    _armerChrono();
    // Reprise d'un défi tué APRÈS la dixième révélation : tout est déjà
    // joué, plus rien à deviner — on file à l'écran de fin (XP, record,
    // série), qui n'avait jamais été crédité. Sans ça, l'écran remontait
    // en pleine phase de révélation, sans interface cohérente.
    if (game.results.length >= rounds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showEnd) _next();
      });
    }
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Ressort franc : les deux éléments dépassent leur taille finale avant
    // de se poser. Le badge part quasiment de rien, les points de plus bas
    // encore et avec un léger décalage — l'œil suit l'un puis l'autre.
    _popBadge = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(
        parent: _pop,
        curve: const Interval(0, 0.60, curve: Curves.elasticOut),
      ),
    );
    _popPoints = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(
        parent: _pop,
        curve: const Interval(0.14, 1, curve: Curves.elasticOut),
      ),
    );
    _popPointsMontee = Tween<double>(begin: 26, end: 0).animate(
      CurvedAnimation(
        parent: _pop,
        curve: const Interval(0.14, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _travel = AnimationController(vsync: this);
    _travel.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Le verdict sonne quand il s'AFFICHE, pas quand on appuie.
        _jingleVerdict?.call();
        _jingleVerdict = null;
        game.finishReveal();
        if (mounted) {
          // Lu à la source : ce callback tourne AVANT la phase de build,
          // MediaQuery y porterait encore la valeur de la frame passée.
          if (animationsReduites) {
            _pop.value = 1;
          } else {
            _pop.forward(from: 0);
          }
        }
        _persistRound();
        // Chrono : la révélation ne traîne pas, la manche suivante part
        // toute seule. Le bouton reste actif pour les impatients.
        if (game.mode == GameMode.chrono && mounted) {
          _autoSuivant?.cancel();
          _autoSuivant = Timer(const Duration(milliseconds: 2200), () {
            if (mounted && game.phase == GamePhase.reveal && !_showEnd) {
              _next();
            }
          });
        }
      }
    });
    _travel.addListener(() {
      final t = Curves.easeInOut.transform(_travel.value);
      game.setFrac(
        _travelBegin + (_travelEnd - _travelBegin) * t,
        silent: true,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (game.mode != GameMode.chrono) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _chrono?.cancel();
      _autoSuivant?.cancel();
    } else if (state == AppLifecycleState.resumed && mounted && !_showEnd) {
      if (game.phase == GamePhase.guess) {
        _demarrerTic(); // reprend le temps restant, sans le remettre à 10 s
      } else if (game.phase == GamePhase.reveal) {
        _autoSuivant = Timer(const Duration(milliseconds: 2200), () {
          if (mounted && game.phase == GamePhase.reveal && !_showEnd) {
            _next();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.removeListener(_onGameChanged);
    _chrono?.cancel();
    _autoSuivant?.cancel();
    _travel.dispose();
    _roundFade.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    if (game.round != _fadedRound && !_showEnd) {
      _fadedRound = game.round;
      _roundFade.forward(from: 0);
      // Nouvelle manche : le compte à rebours du Chrono repart.
      _armerChrono();
    }
  }

  /// (Ré)arme le compte à rebours d'une manche de Chrono. Hors Chrono,
  /// ne fait rien — aucun timer ne tourne dans les autres modes.
  void _armerChrono() {
    if (game.mode != GameMode.chrono) return;
    _restantMs = dureeChrono.inMilliseconds;
    _demarrerTic();
  }

  /// (Re)lance le tic SANS toucher au temps restant — c'est ce qui permet
  /// de mettre le compte à rebours en pause (dialogue d'abandon) puis de
  /// reprendre là où il en était.
  void _demarrerTic() {
    _chrono?.cancel();
    _chrono = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || game.phase != GamePhase.guess) return;
      _restantMs -= 100;
      if (_restantMs <= 0) {
        _tempsEcoule();
      } else {
        setState(() {}); // rafraîchit l'afficheur de secondes
      }
    });
  }

  /// Temps écoulé : la manche vaut zéro et la révélation s'enchaîne,
  /// exactement comme après une validation — même voyage du ruban.
  void _tempsEcoule() {
    _chrono?.cancel();
    final result = game.validateTimeout();
    if (result == null) return;
    _lastResult = result;
    Retour.validation();
    _jingleVerdict = Sons.rate;
    _travelBegin = game.frac;
    _travelEnd = yearToFrac(result.event.annee);
    final dist = (_travelEnd - _travelBegin).abs();
    var ms =
        dist < 0.0005 ? 120 : (500 + dist * 2200).clamp(500.0, 1500.0).toInt();
    if (animationsReduites) ms = 80;
    _travel.duration = Duration(milliseconds: ms);
    _travel.forward(from: 0);
    if (mounted) setState(() {});
  }

  void _validate() {
    final result = game.validate();
    if (result == null) return;
    _chrono?.cancel(); // répondu à temps : le compte à rebours s'arrête
    _lastResult = result;
    // Le « pop » répond à l'appui tout de suite ; le verdict, lui, arrive
    // après le voyage du ruban.
    Sons.validation();
    // L'haptique répond au doigt tout de suite. Le JINGLE de verdict, lui,
    // attend la fin du voyage du ruban (écouteur de _travel) : joué ici,
    // il partait avant la révélation et étouffait le « pop » d'appui.
    if (result.base == maxScore) {
      Retour.parfait();
      _jingleVerdict = Sons.parfait;
    } else {
      Retour.validation();
      _jingleVerdict = switch (verdictFor(result.base)) {
        Verdict.reussi => Sons.reussi,
        Verdict.moyen => Sons.moyen,
        Verdict.rate => Sons.rate,
      };
    }
    // Le ruban voyage de la réponse vers la vraie date.
    _travelBegin = game.frac;
    _travelEnd = yearToFrac(result.event.annee);
    final dist = (_travelEnd - _travelBegin).abs();
    // Réponse exacte : le ruban n'a nulle part où aller. Un plancher de
    // 500 ms faisait attendre devant un écran immobile, juste avant le
    // meilleur moment du jeu.
    var ms =
        dist < 0.0005 ? 120 : (500 + dist * 2200).clamp(500.0, 1500.0).toInt();
    if (animationsReduites) ms = 80; // idem : appelé depuis un geste
    _travel.duration = Duration(milliseconds: ms);
    _travel.forward(from: 0);
  }

  /// Le compte à rebours du Chrono : passe au corail sous 3 secondes.
  /// Largeur figée (chiffres tabulaires) pour que la barre ne « respire »
  /// pas dix fois par seconde.
  Widget _pastilleChrono() {
    final s = (_restantMs / 1000).clamp(0.0, dureeChrono.inSeconds.toDouble());
    final urgent = s <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: urgent ? coralColor : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: urgent ? coralColor : inkColor, width: 2),
      ),
      child: Text(
        '⏱ ${s.toStringAsFixed(1)}',
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: urgent ? Colors.white : inkColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Tout ce qui doit survivre à une partie interrompue est écrit DÈS la
  /// révélation, manche par manche : l'événement rejoint la collection, il
  /// est marqué comme vu (sinon il reviendrait aussitôt avec sa réponse),
  /// et le défi du jour mémorise les réponses déjà données pour pouvoir
  /// reprendre si iOS décharge l'app.
  Future<void> _persistRound() async {
    final ev = _lastResult?.event;
    if (ev == null) return;
    await widget.store.markDiscovered([ev.id]);
    await widget.store.markSeen([ev.id]);
    if (game.mode == GameMode.daily) {
      await widget.store.saveDailyProgress(game.dailyKey, game.guesses);
    }
  }

  Future<void> _next() async {
    if (_finishing) return; // évite le double-tap (XP doublée sinon)
    _autoSuivant?.cancel(); // tap manuel : l'enchaînement auto se tait
    final continues = game.next();
    if (!continues) {
      _finishing = true;
      _xpAvant = widget.store.xp;
      setState(() => _showEnd = true);
      // Fin de partie : XP (+ bonus de combo), records, anti-répétition.
      await widget.store.incGames();
      await widget.store.markCatPlayed(game.catKey);
      await widget.store.markSeen(game.results.map((r) => r.event.id));
      if (game.mode == GameMode.daily) {
        // Meilleur score AVANT enregistrement, et comparaison stricte :
        // finishDaily met le record à jour, donc « >= » après coup était
        // toujours vrai — « Nouveau record ! » s'affichait pour une simple
        // égalité, et même pour 0 point.
        final meilleurAvant = widget.store.dailyBest;
        await widget.store.finishDaily(game.total,
            grid: grillePour(game.results), day: game.dailyKey, guesses: game.guesses);
        _record = game.total > meilleurAvant;
      } else {
        // Le Chrono a son propre tableau : « tout|normal » aurait mélangé
        // ses records avec ceux du Classique, barème pourtant différent
        // (pas de manche finale doublée, temps limité).
        final cle = game.mode == GameMode.chrono
            ? 'chrono'
            : '${game.catKey}|${game.diff.name}';
        _record = await widget.store.submitScore(cle, game.total);
      }
      // Exactement la somme des « +N XP » annoncés manche après manche.
      await widget.store.addXp(game.xpTotal);
      // Les succès se jugent APRÈS l'enregistrement : sinon « niveau 10 »
      // ou « 100 découvertes » manqueraient toujours d'une manche.
      _badgesGagnes = nouveauxBadges(widget.store, game: game);
      if (_badgesGagnes.isNotEmpty) {
        await widget.store.unlockBadges(_badgesGagnes.map((b) => b.cle));
        // Le carillon accompagne la carte « nouveau succès » de l'écran de
        // fin. Sur le lecteur des verdicts, libre à cet instant.
        Sons.badge();
      }
      await _envoyerAuClassement();
      await _proposerNote();
      if (mounted) setState(() {});
    }
  }

  /// La note se demande à un moment de fierté, jamais à froid : un
  /// PERFECT dans la partie, un nouveau record, ou trois défis du jour
  /// d'affilée. Un joueur qui vient de rater n'a aucune raison de mettre
  /// cinq étoiles, et iOS ne laisse que trois invitations par an.
  Future<void> _proposerNote() async {
    final perfect = game.results.any((r) => r.base == maxScore);
    final serieBelle =
        game.mode == GameMode.daily && widget.store.effectiveStreak >= 3;
    await Avis.proposer(widget.store,
        merite: perfect || serieBelle || (_record && game.total > 0));
  }

  /// Classement mondial : le défi du jour est le seul vraiment comparable
  /// (même série pour tout le monde). Les records classiques partent dans
  /// un tableau PAR difficulté — les barèmes ne sont pas comparables
  /// entre eux.
  Future<void> _envoyerAuClassement() async {
    if (game.mode == GameMode.daily) {
      await Classement.envoyer(Classement.defi, game.total);
      final serie = widget.store.effectiveStreak;
      if (serie > 0) {
        await Classement.envoyer(Classement.serie, serie, max: 3650);
      }
      // L'autorisation de rappel n'est demandée qu'ici : après un premier
      // défi TERMINÉ, jamais au lancement.
      if (!widget.store.remindersOn && serie >= 2) {
        final ok = await Rappels.demanderAutorisation();
        if (ok) {
          await widget.store.setRemindersOn(true);
          await Rappels.programmer(serie: serie, defiFaitAujourdhui: true);
        }
      } else if (widget.store.remindersOn) {
        await Rappels.programmer(serie: serie, defiFaitAujourdhui: true);
      }
    } else if (game.mode == GameMode.classique &&
        !game.catKey.startsWith('pack:')) {
      // Les packs ne partent PAS au tableau du Classique : leurs pools
      // resserrés rendraient les scores incomparables.
      await Classement.envoyer(
          Classement.classique(game.diff.name), game.total);
    } else if (game.mode == GameMode.chrono) {
      // Barème sans manche doublée : le maximum est de 10 × 1000.
      await Classement.envoyer(Classement.chrono, game.total,
          max: maxScore * rounds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Le retour système passe par la confirmation, comme le bouton ✕.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showEnd) {
          Navigator.of(context).pop(false);
        } else {
          _confirmQuit(context);
        }
      },
      child: Scaffold(
        body: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Fond fondu : fonction pure de frac (aucune animation
                // pendant le geste). Seul le lancement d'une manche fait
                // un vrai fondu temporel de 320 ms.
                RepaintBoundary(
                  child: FadeTransition(
                    opacity: _roundFadeCurve,
                    child: EraBackdrop(frac: game.frac),
                  ),
                ),
                SafeArea(
                  child: _showEnd ? EndView(
          controller: game,
          store: widget.store,
          xpAvant: _xpAvant,
          record: _record,
          badgesGagnes: _badgesGagnes,
          grilleCopiee: _grilleCopiee,
          onPartager: _partagerGrille,
          onQuitter: (rejouer) => _quitter(rejouer: rejouer),
        ) : _buildGame(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final guessing = game.phase == GamePhase.guess;
    final revealed = game.phase == GamePhase.reveal;
    return Column(
      children: [
        // Barre de manche : ✕, MANCHE n/10, 10 pastilles, score
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 18, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Sons.retour();
                  _confirmQuit(context);
                },
                icon: const Icon(Icons.close, color: inkColor),
              ),
              Text(
                'MANCHE ${game.round + 1}/$rounds',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.78,
                  color: inkColor.withValues(alpha: 0.6),
                ),
              ),
              if (game.mode == GameMode.chrono && guessing) ...[
                const SizedBox(width: 8),
                _pastilleChrono(),
              ],
              const SizedBox(width: 10),
              Expanded(child: _roundPills()),
              const SizedBox(width: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: game.total.toDouble()),
                duration: const Duration(milliseconds: 700),
                builder: (context, v, _) => Text(
                  '${v.round()}',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: inkColor,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              // Visée : PAS de défilement global. La frise et le réglage
              // fin gardent leur place, et c'est la carte de l'événement
              // qui défile en interne si sa description est longue — sinon
              // les contrôles passaient sous la ligne de flottaison.
              if (!(revealed && _lastResult != null)) {
                return GuessView(
                controller: game,
                store: widget.store,
                guessing: guessing,
                available: h,
                tapeKey: _tapeKey,
                astuceGeste: _astuceGeste,
                onPremierGeste: _marquerGesteVu,
              );
              }
              // Même architecture que la phase de choix : AUCUN défilement
              // global. L'ancien SingleChildScrollView débordait de
              // quelques pixels sur certains iPhone — tout l'écran se
              // laissait glisser d'un demi-millimètre pour rien. C'est
              // l'anecdote qui défile en interne quand il manque de la
              // place.
              return RevealView(
                controller: game,
                r: _lastResult!,
                available: h,
                pop: _pop,
                popBadge: _popBadge,
                popPoints: _popPoints,
                popPointsMontee: _popPointsMontee,
                tapeKey: _tapeKey,
              );
            },
          ),
        ),
        // Bouton principal. Son libellé est plafonné comme le bandeau de
        // verdict : c'est un contrôle, pas un texte à lire, et le laisser
        // doubler de taille le poussait hors de l'écran sur iPhone SE en
        // « texte plus grand » — le joueur ne pouvait plus avancer.
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: maxEchelleVerdict,
          child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: guessing
              ? PushButton(
                  onPressed: game.touched ? _validate : null,
                  // « Je place ici » joue déjà le « pop » du verdict via
                  // _validate : pas de « toc » d'appui par-dessus.
                  son: SonBouton.aucun,
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment(0.94, 0.34),
                    colors: [coralColor, orangeColor],
                  ),
                  softShadowColor: coralColor,
                  padding: const EdgeInsets.all(17),
                  child: const Center(
                    child: Text(
                      'Je place ici !',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : PushButton(
                  onPressed: revealed ? _next : null,
                  color: inkColor,
                  shadowColor: navyShadowColor,
                  shadowHeight: 6,
                  padding: const EdgeInsets.all(15),
                  child: Center(
                    child: Text(
                      game.isLastRound
                          ? 'Voir mes résultats 🏁'
                          : 'Manche suivante →',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
        )
      ],
    );
  }

  /// Les 10 pastilles de progression, colorées sur les points de base.
  Widget _roundPills() {
    return Row(
      children: [
        for (var i = 0; i < rounds; i++)
          Expanded(
            child: Container(
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: i < game.results.length
                    ? (game.results[i].base >= 700
                        ? mintColor
                        : game.results[i].base >= 350
                            ? yellowColor
                            : coralColor)
                    : inkColor.withValues(alpha: 0.16),
              ),
            ),
          ),
      ],
    );
  }

  /// Phase de choix (et voyage du ruban) : carte, année, frise, réglage fin.
  /// Premier contact avec la frise : l'astuce disparaît, et ne revient
  /// jamais sur cet appareil.
  void _marquerGesteVu() {
    setState(() => _astuceGeste = false);
    widget.store.setTutoSeen();
  }

  Future<void> _quitter({required bool rejouer}) async {
    final navigateur = Navigator.of(context);
    await Pub.montrerSiDue(
      sansPub: widget.store.sansPub,
      defiDuJour: game.mode == GameMode.daily,
      partiesJouees: widget.store.games,
    );
    if (!mounted) return;
    navigateur.pop(rejouer);
  }

  /// Feuille de partage native : un tap suffit pour envoyer la grille
  /// vers Messages, WhatsApp ou ailleurs. Le presse-papiers reste le
  /// filet de sécurité — sur un appareil où la feuille ne s'ouvre pas
  /// (simulateur, iPad sans position d'ancrage), le texte est au moins
  /// copié et le bouton le dit.
  Future<void> _partagerGrille() async {
    final texte = texteGrillePour(game, widget.store);
    // L'iPad ancre la feuille à un rectangle d'origine : sans lui, le
    // partage lève une exception au lieu de s'afficher. Mesuré AVANT le
    // premier await — après, le contexte peut avoir disparu.
    final boite = context.findRenderObject() as RenderBox?;
    final ancrage = boite == null
        ? null
        : boite.localToGlobal(Offset.zero) & boite.size;
    await Clipboard.setData(ClipboardData(text: texte));
    if (mounted) setState(() => _grilleCopiee = true);
    try {
      await Share.share(
        texte,
        subject: 'Erea ⏳',
        sharePositionOrigin: ancrage,
      );
    } catch (e) {
      // Partage indisponible : la grille est déjà dans le presse-papiers.
      debugPrint('Partage impossible : $e');
    }
  }

  Future<void> _confirmQuit(BuildContext context) async {
    // Chrono : on fige TOUT pendant que le joueur réfléchit — sinon la
    // partie se jouait toute seule derrière la modale (manches à zéro,
    // score enregistré… alors que le dialogue promet le contraire).
    _chrono?.cancel();
    _autoSuivant?.cancel();
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: Text(
          game.mode == GameMode.daily
              // Le verrou est déjà posé : le dire, plutôt que de laisser
              // croire qu'on pourra recommencer le défi du jour.
              ? 'Ton score ne sera pas enregistré, et ta tentative du défi '
                  'du jour est déjà utilisée : le prochain défi sera demain.'
              : 'Ton score de cette partie ne sera pas enregistré.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer à jouer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (quit != true) {
      // Le joueur reste : le compte à rebours reprend où il en était, et
      // la révélation en cours retrouve son enchaînement automatique.
      if (game.mode == GameMode.chrono && mounted) {
        if (game.phase == GamePhase.guess) {
          _demarrerTic();
        } else if (game.phase == GamePhase.reveal && !_showEnd) {
          _autoSuivant = Timer(const Duration(milliseconds: 2200), () {
            if (mounted && game.phase == GamePhase.reveal && !_showEnd) {
              _next();
            }
          });
        }
      }
    }
    if (quit == true && context.mounted) {
      // Abandon VOLONTAIRE : on efface la reprise, sinon le joueur
      // relancerait le défi en connaissant déjà les réponses vues.
      if (game.mode == GameMode.daily) {
        await widget.store.clearDailyProgress();
      }
      if (context.mounted) Navigator.of(context).pop(false);
    }
  }
}

/// Trait qui relie l'épingle « Toi » à la vraie date. Sa LONGUEUR est
/// l'erreur : c'est ce qui fait sentir l'échelle non linéaire de la frise
/// sans avoir à l'expliquer. Plein quand la réponse tient dans la
/// tolérance, pointillé quand elle est loin.
