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
    final guessing = game.phase == GamePhase.guess;
    final revealed = game.phase == GamePhase.reveal;
    return Column(
      children: [
        // En-tête : quitter, manche, score (toujours en haut)
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
              const SizedBox(width: 48), // équilibre le bouton ✕
            ],
          ),
        ),
        // Corps : centré s'il y a de la place, défilant sur petit écran.
        // Le Stack porte la « comète » des points par-dessus.
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: _gameBody(context, guessing, revealed),
                  ),
                ),
              ),
              if (revealed && _lastResult != null)
                _buildComet(context, _lastResult!),
            ],
          ),
        ),
        // Bouton principal (toujours en bas)
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

  Widget _gameBody(BuildContext context, bool guessing, bool revealed) {
    final ev = game.current;
    final reveal = revealed ? _lastResult : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Carte événement : pendant la manche elle pose la question,
        // après validation elle porte aussi les explications.
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
                if (reveal == null)
                  Text(
                    ev.desc,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  Text(
                    _reaction(reveal),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'C’était en ${formatYear(reveal.event.annee)} — '
                    '${_direction(reveal)}',
                    textAlign: TextAlign.center,
                  ),
                  if (reveal.event.fun.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '💡 ${reveal.event.fun}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Bulle de l'année + ajustement fin
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed:
                  guessing ? () => game.setYear(game.guessYear - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            // Les libellés longs (« 3000 av. J.-C. », « ÉPOQUE
            // CONTEMPORAINE ») débordaient la ligne sur un iPhone standard :
            // ils se réduisent maintenant au lieu d'être rognés.
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatYear(game.guessYear),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      eraFor(game.guessYear).name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  guessing ? () => game.setYear(game.guessYear + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        // La frise-ruban, la plus grande possible : ~36 % de l'écran
        TapeWidget(
          frac: game.frac,
          locked: !guessing,
          height: (MediaQuery.of(context).size.height * 0.36)
              .clamp(220.0, 430.0)
              .toDouble(),
          onFracChanged: (f) => game.setFrac(f),
        ),
        const SizedBox(height: 8),
        // Le score vit sous la frise et grimpe en douceur quand les
        // points arrivent (la comète vient s'y écraser).
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: game.total.toDouble()),
          duration: const Duration(milliseconds: 700),
          builder: (context, v, _) => Chip(
            label: Text(
              '⭐ ${v.round()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: guessing
              ? Center(
                  child: Text(
                    '👈 Fais glisser la frise pour choisir l’année 👉',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : null,
        ),
      ],
    );
  }

  /// « + N pts » : gros popup qui rebondit au centre puis file en
  /// comète vers le score sous la frise, en s'estompant.
  Widget _buildComet(BuildContext context, RoundResult r) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('comet-${game.round}'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1300),
      builder: (context, t, _) {
        final pop =
            Curves.elasticOut.transform((t / 0.4).clamp(0.0, 1.0).toDouble());
        final fly =
            Curves.easeInCubic.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0).toDouble());
        return Align(
          alignment: Alignment(0, -0.25 + 0.85 * fly),
          child: IgnorePointer(
            child: Opacity(
              opacity: (1 - fly).clamp(0.0, 1.0).toDouble(),
              child: Transform.scale(
                scale: pop * (1 - 0.55 * fly),
                child: Text(
                  '+ ${r.pts}${game.multiplier == 2 ? ' ×2' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF25B4D),
                    shadows: [
                      Shadow(color: Colors.white, blurRadius: 12),
                      Shadow(color: Color(0x66F25B4D), blurRadius: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
        content:
            const Text('Ton score de cette partie ne sera pas enregistré.'),
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
