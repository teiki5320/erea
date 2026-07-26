import 'package:flutter/material.dart';

import '../core/progression.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import '../data/events_repository.dart';
import '../data/store.dart';
import '../game/game_controller.dart';
import 'tape_widget.dart';

/// Écran de jeu : carte événement en haut, frise centrale, explications
/// sous la frise, bouton en bas — l'agencement validé par le prototype web.
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _travel;
  double _travelBegin = 0;
  double _travelEnd = 0;
  RoundResult? _lastResult;
  bool _showEnd = false;
  bool _finishing = false;

  GameController get game => widget.controller;

  @override
  void initState() {
    super.initState();
    _travel = AnimationController(vsync: this);
    _travel.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        game.finishReveal();
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
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  void _validate() {
    final result = game.validate();
    if (result == null) return;
    _lastResult = result;
    // Le ruban voyage de la réponse vers la vraie date.
    _travelBegin = game.frac;
    _travelEnd = yearToFrac(result.event.annee);
    final dist = (_travelEnd - _travelBegin).abs();
    final ms = (500 + dist * 2200).clamp(500.0, 1500.0).toInt();
    _travel.duration = Duration(milliseconds: ms);
    _travel.forward(from: 0);
  }

  Future<void> _next() async {
    if (_finishing) return; // évite le double-tap (XP doublée sinon)
    final continues = game.next();
    if (!continues) {
      _finishing = true;
      setState(() => _showEnd = true);
      // Fin de partie : XP, records, anti-répétition.
      await widget.store.incGames();
      await widget.store.markSeen(game.results.map((r) => r.event.id));
      if (game.mode == GameMode.daily) {
        await widget.store.recordDaily(game.total);
      } else {
        await widget.store
            .submitScore('${game.catKey}|${game.diff.name}', game.total);
      }
      await widget.store.addXp(xpGain(game.total, game.diff.xpMult));
      if (mounted) setState(() {});
    }
  }

  String _reaction(RoundResult r) {
    if (r.base == maxScore) return '🤩 PERFECT !';
    if (r.base >= 900) return '🤩 Incroyable !';
    if (r.base >= 700) return '🎉 Excellent !';
    if (r.base >= 500) return '😄 Bien joué !';
    if (r.base >= 250) return '🙂 Pas mal !';
    if (r.base >= 80) return '😅 Pas loin…';
    return '😵 Trop loin !';
  }

  String _direction(RoundResult r) {
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
        body: SafeArea(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              if (_showEnd) return _buildEnd(context);
              return _buildGame(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final ev = game.current;
    final guessing = game.phase == GamePhase.guess;
    final revealed = game.phase == GamePhase.reveal;
    return Column(
      children: [
        // En-tête : quitter, manche, score
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _confirmQuit(context),
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Text(
                  'Manche ${game.round + 1}/$rounds',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Chip(label: Text('⭐ ${game.total}')),
            ],
          ),
        ),
        // Carte événement
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (game.multiplier == 2)
                  const Text('🌟 Manche finale : points × 2 !'),
                Text(ev.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 6),
                Text(
                  ev.titre,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  ev.desc,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bulle de l'année + ajustement fin
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed:
                  guessing ? () => game.setYear(game.guessYear - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Column(
              children: [
                Text(
                  formatYear(game.guessYear),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  eraFor(game.guessYear).name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            IconButton(
              onPressed:
                  guessing ? () => game.setYear(game.guessYear + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        // La frise-ruban
        TapeWidget(
          frac: game.frac,
          locked: !guessing,
          showAnchors: game.diff.anchors,
          maskYear: game.current.annee,
          onFracChanged: (f) => game.setFrac(f),
        ),
        // Explications sous la frise
        SizedBox(
          height: 120,
          child: revealed && _lastResult != null
              ? _buildReveal(context, _lastResult!)
              : Center(
                  child: Text(
                    '👈 Fais glisser la frise pour choisir l’année 👉',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
        ),
        // Bouton principal
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: guessing
                  ? (game.touched ? _validate : null)
                  : (revealed ? _next : null),
              child: Text(
                guessing
                    ? 'Valider ✓'
                    : game.isLastRound
                        ? 'Voir mes résultats 🏁'
                        : 'Manche suivante →',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReveal(BuildContext context, RoundResult r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(_reaction(r), style: Theme.of(context).textTheme.titleMedium),
          Text('C’était en ${formatYear(r.event.annee)} — ${_direction(r)}'),
          if (r.event.fun.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '💡 ${r.event.fun}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Text(
            '+ ${r.pts} pts${game.multiplier == 2 ? ' (× 2 !)' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEnd(BuildContext context) {
    final playable = playableFor(game.catKey);
    return Column(
      children: [
        const SizedBox(height: 12),
        Text('Partie terminée !',
            style: Theme.of(context).textTheme.headlineSmall),
        Text(
          '${game.total} / $maxTotal',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        Text(game.emojiGrid(), style: const TextStyle(fontSize: 20)),
        Text(
          '${playable.label} · ${game.diff.label} · '
          'écart moyen ${game.averageEcart.round()} ans',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: game.results.length,
            itemBuilder: (context, i) {
              final r = game.results[i];
              return Card(
                child: ListTile(
                  leading:
                      Text(r.event.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(r.event.titre),
                  subtitle: Text(
                    'Toi : ${formatYear(r.guess)} · '
                    'Vraie date : ${formatYear(r.event.annee)}',
                  ),
                  trailing: Text('${r.pts}'),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (game.mode != GameMode.daily) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Rejouer'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Accueil'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text('Ton score de cette partie ne sera pas enregistré.'),
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
    if (quit == true && context.mounted) {
      Navigator.of(context).pop(false);
    }
  }
}
