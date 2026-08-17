import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import '../core/progression.dart';
import '../core/accessibilite.dart';
import '../core/avis.dart';
import '../core/classement.dart';
import '../core/pub.dart';
import '../core/rappels.dart';
import '../core/retour.dart';
import '../core/sons.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import '../data/events_repository.dart';
import '../data/store.dart';
import '../game/badges.dart';
import '../game/game_controller.dart';
import 'sticker_widgets.dart';
import 'tape_widget.dart';

/// Couleur d'étiquette par catégorie (carte de l'événement).
const Map<String, Color> _catColors = {
  'pouvoir': coralColor,
  'sciences': mintColor,
  'arts': violetColor,
  'quotidien': orangeColor,
};

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
  /// Hauteur de la frise pendant le choix : c'est l'outil de visée, elle
  /// doit dominer l'écran. Proportionnelle à la hauteur disponible, pour
  /// rester généreuse sur grand écran sans repousser le réglage fin sous
  /// la ligne de flottaison sur un iPhone SE.
  /// Elle CÈDE avant la carte : en très grande police système, les blocs
  /// fixes (année plafonnée, pastilles, réglage fin) plus une frise de
  /// 210 px laissaient 0 px à la carte de l'événement — le fait à deviner
  /// devenait invisible. La carte a droit à 140 px quoi qu'il arrive, et
  /// c'est la frise qui descend, jusqu'à 150 px au pire.
  static double _tapeHeightFor(double available) {
    // Somme des hauteurs fixes de _guessBody hors carte et hors frise :
    // 14 + 14 + 26 (pastilles) + 2 + 60 (année) + 8 + 12 + 46 (réglage
    // fin) + 8.
    const fixe = 190.0;
    // 84 px : ce que la carte a toujours eu sur iPhone SE — elle y défile
    // sur elle-même. La garantie sert le cas grande police, où elle
    // tombait à 0 ; elle ne doit pas rapetisser la frise sur petit écran.
    const carteMin = 84.0;
    final voulu = (available * 0.44).clamp(210.0, 310.0).toDouble();
    if (available - fixe - voulu >= carteMin) return voulu;
    return (available - fixe - carteMin).clamp(150.0, 310.0).toDouble();
  }

  /// Révélation : la frise reste grande, avec la place des deux pastilles
  /// au-dessus (« Toi · … ») et en dessous (la vraie date).
  static const double _revealTapeH = 240;
  static const double _revealTopPad = 44;
  static const double _revealBottomPad = 46;

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
            grid: _grid(), day: game.dailyKey, guesses: game.guesses);
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

  String _grid() => game.results
      .map((r) => r.base >= 700
          ? 'g'
          : r.base >= 350
              ? 'y'
              : 'r')
      .join();

  String _reaction(RoundResult r) {
    if (r.tempsEcoule) return 'TEMPS ÉCOULÉ !';
    if (r.base == maxScore) return 'PILE DESSUS !';
    if (r.base >= 900) return 'Incroyable !';
    if (r.base >= 700) return 'Excellent !';
    if (r.base >= 500) return 'Bien joué !';
    if (r.base >= 250) return 'Pas mal !';
    if (r.base >= 80) return 'Pas loin…';
    return 'Trop loin !';
  }

  String _direction(RoundResult r) {
    // Temps écoulé avec le curseur pile dessus : le dire, sinon l'écran
    // afficherait « Année exacte ! » à côté de zéro point.
    if (r.tempsEcoule && r.ecart == 0) return 'Tu y étais… trop tard ⏱';
    if (r.ecart == 0) return 'Année exacte !';
    final unit = r.ecart == 1 ? 'an' : 'ans';
    return r.guess < r.event.annee
        ? '${r.ecart} $unit trop tôt ⏩'
        : '${r.ecart} $unit trop tard ⏪';
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
                  child: _showEnd ? _buildEnd(context) : _buildGame(context),
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
                return _guessBody(context, guessing, h);
              }
              // Même architecture que la phase de choix : AUCUN défilement
              // global. L'ancien SingleChildScrollView débordait de
              // quelques pixels sur certains iPhone — tout l'écran se
              // laissait glisser d'un demi-millimètre pour rien. C'est
              // l'anecdote qui défile en interne quand il manque de la
              // place.
              return _revealBody(context, _lastResult!, h);
            },
          ),
        ),
        // Bouton principal
        Padding(
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
  Widget _guessBody(BuildContext context, bool guessing, double available) {
    final ev = game.current;
    final cat = playableFor(ev.cat);
    return Column(
      children: [
        const SizedBox(height: 14),
        // Carte de l'événement, étiquette de catégorie en débord. Elle est
        // la SEULE à céder de la place : une description à rallonge la fait
        // défiler sur elle-même au lieu de pousser la frise vers le bas.
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [softShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (game.multiplier == 2)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text('🌟 Manche finale : points × 2 !'),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ev.emoji,
                                style: const TextStyle(fontSize: 44)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ev.titre,
                                style: const TextStyle(
                                  fontFamily: 'Baloo2',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  height: 1.14,
                                  color: inkColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ev.desc,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.45,
                            color: inkSoftColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -10,
                    left: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: _catColors[ev.cat] ?? violetColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        cat.label.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          letterSpacing: 0.84,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Année : pastille d'époque + nombre, sans bulle
        EraPillPair(frac: game.frac, bordered: false),
        const SizedBox(height: 2),
        // Hauteur PLAFONNÉE : en très grande police système, ce nombre
        // gonflait les blocs fixes jusqu'à écraser la carte de l'événement
        // à 0 px. Dans une boîte bornée, FittedBox réduit au lieu de
        // pousser.
        SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatYear(game.guessYear),
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 56,
                  height: 1.05,
                  color: inkColor,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // La frise, plein-bord
        Stack(
          alignment: Alignment.center,
          children: [
            TapeWidget(
              key: _tapeKey,
              frac: game.frac,
              locked: !guessing,
              height: _tapeHeightFor(available),
              onFracChanged: (f) {
                if (_astuceGeste) {
                  setState(() => _astuceGeste = false);
                  widget.store.setTutoSeen();
                }
                // Le cliquetis du glissement est géré par TapeWidget, qui
                // seul connaît la distance réellement parcourue sur le ruban.
                game.setFrac(f);
              },
            ),
            // Astuce du premier lancement : elle disparaît au premier
            // contact avec la frise, et ne revient jamais.
            if (_astuceGeste && guessing)
              IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: inkColor.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '👆 Fais glisser la frise',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Réglage fin : − minimap +
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              _fineButton('−',
                  guessing ? () => game.setYear(game.guessYear - 1) : null),
              const SizedBox(width: 12),
              Expanded(
                child: MiniMap(
                  frac: game.frac,
                  onChanged: (f) {
                    if (guessing) game.setFrac(f);
                  },
                ),
              ),
              const SizedBox(width: 12),
              _fineButton('+',
                  guessing ? () => game.setYear(game.guessYear + 1) : null),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Bouton de réglage fin 46 × 46 : glyphe « − » / « + » en Baloo,
  /// blanc, ombre douce (0, 6, 14).
  Widget _fineButton(String glyph, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1 : 0.45,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 6),
                blurRadius: 14,
                color: Color(0x1F35406B),
              ),
            ],
          ),
          child: Text(
            glyph,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 23,
              height: 1.0,
              color: inkColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Révélation : badge de verdict, points, puis la frise figée qui porte
  /// les deux épingles RELIÉES par le trait de l'écart — la longueur du
  /// trait EST l'erreur, c'est ce qui fait comprendre l'échelle non
  /// linéaire sans avoir à l'expliquer.
  Widget _revealBody(BuildContext context, RoundResult r, double available) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final tol = tolerance(game.diff);
    // UN SEUL verdict pour tout l'écran : badge, points, trait d'écart et
    // titre de la carte disent la même chose que la pastille de manche et
    // que la grille de partage (cf. scoring.dart).
    final verdict = verdictFor(r.base);
    final dansLaCible = verdict == Verdict.reussi;
    // Petit écran : on resserre pour que l'anecdote ne passe pas sous la
    // ligne de flottaison — c'est la partie qui apprend quelque chose.
    final serre = available < 620;
    final tapeH = serre ? 190.0 : _revealTapeH;
    final ptsSize = serre ? 44.0 : 56.0;
    final badgeSize = serre ? 18.0 : 22.0;
    return Column(
      children: [
        const SizedBox(height: 12),
        ScaleTransition(
          key: const ValueKey('badge-verdict'),
          scale: _popBadge,
          child: Transform.rotate(
            angle: dansLaCible ? -0.035 : 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                // Menthe / jaune / blanc : les mêmes couleurs que la
                // pastille de manche. Jamais de rouge, on ne punit pas.
                color: switch (verdict) {
                  Verdict.reussi => verdictMintColor,
                  Verdict.moyen => yellowColor,
                  Verdict.rate => Colors.white,
                },
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [pillShadow],
              ),
              child: Text(
                '${_reaction(r)} ${dansLaCible ? '🎯' : '😅'}',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: badgeSize,
                  color: dansLaCible ? Colors.white : inkColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _pop,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _popPointsMontee.value),
            child: Transform.scale(scale: _popPoints.value, child: child),
          ),
          // FittedBox : à 200 % de taille de texte système, « +11000 pts »
          // débordait de l'écran.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '+${r.pts}',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: ptsSize,
                      height: 1.0,
                      color:
                          verdict == Verdict.rate ? inkPaleColor : coralColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'pts',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color:
                          verdict == Verdict.rate ? inkPaleColor : coralColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          // La « cible » affichée = l'écart qui donne encore le vert
          // (700 pts) : tolérance × ln(1000/700). Afficher la tolérance
          // brute (30 ans en Normal) contredisait le verdict du dessus.
          '${_direction(r)} · cible ± ${(tol * 0.3567).round()} ans',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: inkSoftColor,
          ),
        ),
        const SizedBox(height: 12),
        // La frise figée porte les deux épingles et le trait de l'écart
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final echelle = MediaQuery.textScalerOf(context);
            double xOf(int year) =>
                w / 2 + (yearToFrac(year) - game.frac) * TapeWidget.tapeW;
            final trueX = w / 2;
            final brutX = xOf(r.guess);
            // Marge jamais supérieure au quart de la largeur : sur une
            // fenêtre étroite, clamp(78, w - 78) lèverait une erreur.
            final marge = math.min(78.0, w / 4);
            final gx = brutX.clamp(marge, w - marge).toDouble();
            // Réponse hors champ : le trait file jusqu'au bord et un
            // chevron dit que ça continue au-delà.
            final horsChamp = (brutX - gx).abs() > 1;
            final versLaGauche = brutX < gx;

            /// Largeur RÉELLE d'une pastille (texte + 2 × 10 px de marge),
            /// à l'échelle de texte du système : c'est elle qui borne la
            /// position, sinon une pastille décalée sort de l'écran.
            double largeur(String texte) {
              final tp = TextPainter(
                text: TextSpan(
                  text: texte,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                textDirection: TextDirection.ltr,
                textScaler: echelle,
              )..layout();
              return tp.width + 20;
            }

            final texteToi =
                horsChamp ? (versLaGauche ? '‹ Toi · ' : 'Toi · ') : 'Toi · ';
            final libelleToi = horsChamp
                ? (versLaGauche
                    ? '‹ Toi · ${formatYear(r.guess)}'
                    : 'Toi · ${formatYear(r.guess)} ›')
                : '$texteToi${formatYear(r.guess)}';
            final libelleVrai = '${formatYear(r.event.annee)} 🎯';
            final wToi = largeur(libelleToi);
            final wVrai = largeur(libelleVrai);

            // Épingles trop proches : elles se recouvriraient. On les écarte
            // chacune du côté opposé à l'autre — c'est l'information la plus
            // lue de l'écran, elle ne doit jamais être illisible.
            final proches = (gx - trueX).abs() < (wToi + wVrai) / 2 + 8;
            final aGauche = gx <= trueX;
            final alignToi = proches ? (aGauche ? -1.0 : 1.0) : 0.0;
            final alignVrai = proches ? (aGauche ? 1.0 : -1.0) : 0.0;

            /// Bord gauche d'une pastille, borné à l'écran APRÈS le
            /// décalage d'alignement (align -1 : bord droit sur x ;
            /// 0 : centrée ; +1 : bord gauche sur x).
            double bordGauche(double x, double align, double largeurPastille) {
              final brut = x - largeurPastille * (0.5 - align * 0.5);
              final max = math.max(4.0, w - largeurPastille - 4);
              return brut.clamp(4.0, max).toDouble();
            }

            final ecartX = (gx - trueX).abs();
            Widget pinScale(Widget child) => reduce
                ? child
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.elasticOut,
                    builder: (context, s, c) =>
                        Transform.scale(scale: s, child: c),
                    child: child,
                  );

            Widget pastille(String texte, Color fond, Color encre) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: fond,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: fond == Colors.white ? const [softShadow] : null,
                  ),
                  child: Text(
                    texte,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: encre,
                    ),
                  ),
                );

            return SizedBox(
              height: _revealTopPad + tapeH + _revealBottomPad,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: _revealTopPad,
                    left: 0,
                    right: 0,
                    child: TapeWidget(
                      key: _tapeKey,
                      frac: game.frac,
                      locked: true,
                      height: tapeH,
                      onFracChanged: (_) {},
                    ),
                  ),
                  // Trait de l'écart : plein quand la manche est réussie,
                  // pointillé sinon.
                  if (r.ecart > 0)
                    Positioned(
                      top: _revealTopPad + tapeH * 0.30,
                      left: math.min(gx, trueX),
                      child: SizedBox(
                        width: ecartX,
                        height: 3,
                        child: CustomPaint(
                          painter: _GapLinePainter(dashed: !dansLaCible),
                        ),
                      ),
                    ),
                  // … et le nombre d'années, porté par le trait.
                  if (r.ecart > 0)
                    Positioned(
                      top: _revealTopPad + tapeH * 0.30 - 11,
                      left: (gx + trueX) / 2,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: coralColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            r.ecart == 1 ? '1 an' : '${r.ecart} ans',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Tige de l'épingle « Toi » : elle reste EXACTEMENT sur la
                  // position, même quand la pastille est décalée.
                  Positioned(
                    top: 24,
                    left: gx - 1.5,
                    child: Container(
                      width: 3,
                      height: _revealTopPad - 22,
                      color: inkPaleColor,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    left: bordGauche(gx, alignToi, wToi),
                    child:
                        pinScale(pastille(libelleToi, Colors.white, inkColor)),
                  ),
                  // Tige de la vraie date (le ruban est centré dessus)
                  Positioned(
                    top: _revealTopPad + tapeH - 15,
                    left: trueX - 2,
                    child: Container(
                      width: 4,
                      height: 19,
                      decoration: BoxDecoration(
                        color: mintColor,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _revealTopPad + tapeH + 4,
                    left: bordGauche(trueX, alignVrai, wVrai),
                    child: pinScale(
                        pastille(libelleVrai, mintColor, Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),

        // Le savais-tu ? + jetons. C'est la SEULE partie qui cède de la
        // place : longue anecdote ou grande police, elle défile sur
        // elle-même au lieu de pousser l'écran au-delà du bord.
        if (r.event.fun.isNotEmpty)
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [softShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Raté : ce n'est plus une anecdote en passant, c'est le
                        // moment où l'on apprend vraiment. Le titre le dit.
                        dansLaCible
                            ? 'Le savais-tu ? 💡'
                            : 'Pour t’en souvenir 💡',
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: inkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.event.fun,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          height: 1.5,
                          color: inkSoftColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _token('＋ Album', const Color(0xFFEEF3FF),
                              const Color(0xFF5F6890)),
                          const SizedBox(width: 8),
                          _token(
                            '+${r.xp} XP',
                            const Color(0xFFFFF3D9),
                            const Color(0xFFA9761C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Bandeau de série : montante en jaune-corail, ou perdue en gris —
        // une série qui se brise doit se dire, pas disparaître en silence.
        if (game.combo > 0 || game.comboBroken)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: game.comboBroken
                    ? inkColor.withValues(alpha: 0.06)
                    : const Color(0xFFFFF3D9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: game.comboBroken ? 0.4 : 1,
                    child: const Text('🔥', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.comboBroken
                              ? 'Série perdue — on repart de zéro'
                              : game.combo == 1
                                  ? '1 bonne réponse'
                                  : '${game.combo} bonnes réponses d’affilée',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: game.comboBroken ? inkPaleColor : inkColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 6,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ColoredBox(
                                      color: inkColor.withValues(alpha: 0.10)),
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: game.comboBroken
                                          ? 0.0
                                          : (game.combo / 3)
                                              .clamp(0.0, 1.0)
                                              .toDouble(),
                                      heightFactor: 1,
                                      child: const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [yellowColor, coralColor],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    game.boostNext && !game.isLastRound ? '×1,5' : '×1',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: game.boostNext && !game.isLastRound
                          ? coralColor
                          : inkPaleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _token(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: fg,
        ),
      ),
    );
  }

  /// Écran de fin : ce que la partie a RAPPORTÉ. L'XP, le niveau franchi
  /// et le record battu étaient déjà calculés mais n'étaient dits nulle
  /// part — le joueur voyait dix promesses « +N XP » et jamais le total.
  Widget _buildEnd(BuildContext context) {
    final playable = playableFor(game.catKey);
    final xpApres = _xpAvant + game.xpTotal;
    final nivAvant = levelFromXp(_xpAvant);
    final nivApres = levelFromXp(xpApres);
    final monteDeNiveau = nivApres.level > nivAvant.level;
    final titre = titleFor(nivApres.level);
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Partie terminée !',
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: inkColor,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            // Chrono : pas de manche finale doublée, le maximum est 10 000.
            '${game.total} / ${game.mode == GameMode.chrono ? maxScore * rounds : maxTotal}',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 46,
              height: 1.05,
              color: coralColor,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (_record)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: yellowColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [pillShadow],
            ),
            child: const Text(
              '🏆 Nouveau record !',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: inkColor,
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(game.emojiGrid(), style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(
          '${playable.label} · ${game.diff.label} · '
          'écart moyen ${game.averageEcart.round()} ans',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: inkSoftColor,
          ),
        ),
        // Ce que la partie a rapporté : XP, barre de niveau, palier franchi
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [softShadow],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(titre.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monteDeNiveau
                                ? 'Niveau ${nivApres.level} atteint ! '
                                    '${titre.titre}'
                                : '${titre.titre} · niveau ${nivApres.level}',
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: monteDeNiveau ? coralColor : inkColor,
                            ),
                          ),
                          Text(
                            '${nivApres.into} / ${nivApres.need} XP',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              color: inkPaleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${game.xpTotal} XP',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFFA9761C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                              color: inkColor.withValues(alpha: 0.10)),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (nivApres.into / nivApres.need)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                              heightFactor: 1,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [yellowColor, coralColor],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_badgesGagnes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: yellowColor.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _badgesGagnes.length == 1
                        ? 'Nouveau succès !'
                        : '${_badgesGagnes.length} nouveaux succès !',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: inkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final b in _badgesGagnes)
                    Text(
                      '${b.emoji}  ${b.titre} — ${b.comment}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: inkSoftColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        // Partage : la grille sans spoiler, prête à coller n'importe où.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: PushButton(
            onPressed: _partagerGrille,
            color: Colors.white,
            shadowColor: const Color(0xFFD8DDEF),
            shadowHeight: 4,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Text(
                _grilleCopiee ? '✅ Partagé !' : '📤 Partager ma grille',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: inkColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: game.results.length,
            itemBuilder: (context, i) => _ligneBilan(game.results[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
          child: Row(
            children: [
              if (game.mode != GameMode.daily) ...[
                Expanded(
                  child: PushButton(
                    onPressed: () => _quitter(rejouer: true),
                    color: inkColor,
                    shadowColor: navyShadowColor,
                    radius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: const Center(
                      child: Text(
                        'Rejouer',
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PushButton(
                  onPressed: () => _quitter(rejouer: false),
                  son: SonBouton.retour,
                  color: Colors.white,
                  shadowColor: const Color(0xFFD8DDEF),
                  radius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: const Center(
                    child: Text(
                      'Accueil',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: inkColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sortie de l'écran de fin : la publicité s'intercale ICI, jamais
  /// avant. Le joueur a vu son score, son XP et son bilan ; il quitte de
  /// son plein gré. C'est le seul moment où une réclame ne coupe rien.
  ///
  /// Le Défi du jour en est exempté (voir `Pub`), et l'affichage échoue en
  /// silence : la navigation part de toute façon.
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

  Widget _ligneBilan(RoundResult r) {
    final v = verdictFor(r.base);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(r.event.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.event.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    height: 1.15,
                    color: inkColor,
                  ),
                ),
                Text(
                  'Toi ${formatYear(r.guess)} · vraie date '
                  '${formatYear(r.event.annee)}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: inkSoftColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${r.pts}',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: switch (v) {
                Verdict.reussi => verdictMintColor,
                Verdict.moyen => const Color(0xFFA9761C),
                Verdict.rate => inkPaleColor,
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Texte de partage, sans spoiler : score, grille emoji, et la série
  /// pour le défi du jour.
  String _texteGrille() {
    final quoi = game.mode == GameMode.daily
        ? 'Défi du jour'
        : game.mode == GameMode.chrono
            ? 'Chrono ⏱'
            : '${playableFor(game.catKey).label} · ${game.diff.label}';
    // En Chrono, pas de manche finale doublée : le maximum est 10 × 1000.
    final max = game.mode == GameMode.chrono ? maxScore * rounds : maxTotal;
    final serie =
        game.mode == GameMode.daily && widget.store.effectiveStreak > 0
            ? '\n🔥 ${widget.store.effectiveStreak} jours d’affilée'
            : '';
    return 'Erea ⏳ $quoi\n${game.total} / $max\n'
        '${game.emojiGrid()}$serie\n\n$lienAppStore';
  }

  /// Feuille de partage native : un tap suffit pour envoyer la grille
  /// vers Messages, WhatsApp ou ailleurs. Le presse-papiers reste le
  /// filet de sécurité — sur un appareil où la feuille ne s'ouvre pas
  /// (simulateur, iPad sans position d'ancrage), le texte est au moins
  /// copié et le bouton le dit.
  Future<void> _partagerGrille() async {
    final texte = _texteGrille();
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
class _GapLinePainter extends CustomPainter {
  const _GapLinePainter({required this.dashed});

  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final trait = Paint()
      ..color = coralColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), trait);
      return;
    }
    const plein = 7.0;
    const vide = 5.0;
    for (var x = 0.0; x < size.width; x += plein + vide) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + plein, size.width), y),
        trait,
      );
    }
  }

  @override
  bool shouldRepaint(_GapLinePainter old) => old.dashed != dashed;
}
