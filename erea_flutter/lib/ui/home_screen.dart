import 'package:flutter/material.dart';

import '../core/progression.dart';
import '../core/scoring.dart';
import '../data/events_repository.dart';
import '../data/store.dart';
import '../game/game_controller.dart';
import 'game_screen.dart';

/// Accueil « Focus » : héros + Jouer, réglages en deux lignes qui ouvrent
/// un panneau de choix, défi du jour, tuiles de modes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repo, required this.store});

  final EventsRepository repo;
  final Store store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String catKey = 'tout';
  Difficulty diff = Difficulty.normal;
  bool _navigating = false;

  Future<void> _play(GameMode mode) async {
    if (_navigating) return; // évite le double-tap qui empile deux écrans
    _navigating = true;
    try {
      var again = true;
      while (again && mounted) {
        final controller = GameController(widget.repo);
        controller.catKey = catKey;
        controller.diff = diff;
        final ok = controller.start(mode, seenIds: widget.store.seen);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Pas assez d’événements dans cette sélection !')),
          );
          return;
        }
        final replay = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                GameScreen(controller: controller, store: widget.store),
          ),
        );
        again = replay == true;
      }
    } finally {
      _navigating = false;
      if (mounted) setState(() {});
    }
  }

  void _pickCategory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const _SheetTitle('Choisis une catégorie'),
            for (final c in categories)
              _pickTile(c, widget.repo.pool(c.key).length),
            if (packs.any((p) => widget.repo.pool(p.key).length >= rounds))
              const _SheetTitle('Packs à thèmes'),
            for (final p in packs)
              if (widget.repo.pool(p.key).length >= rounds)
                _pickTile(p, widget.repo.pool(p.key).length),
          ],
        );
      },
    );
  }

  Widget _pickTile(Playable p, int count) {
    final selected = catKey == p.key;
    return ListTile(
      leading: Text(p.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(p.label),
      subtitle: Text('$count événements'),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: () {
        setState(() => catKey = p.key);
        Navigator.of(context).pop();
      },
    );
  }

  void _pickDifficulty() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const _SheetTitle('Choisis une difficulté'),
            for (final d in Difficulty.values)
              ListTile(
                leading: Text(d.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(d.label),
                subtitle: Text(d.desc),
                trailing: diff == d ? const Icon(Icons.check) : null,
                selected: diff == d,
                onTap: () {
                  setState(() => diff = d);
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = levelFromXp(widget.store.xp);
    final title = titleFor(level.level);
    final playable = playableFor(catKey);
    final best = widget.store.bestFor('$catKey|${diff.name}');
    final dailyDone = widget.store.dailyPlayedToday;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barre haute : marque + niveau
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('⏳ EREA',
                      style: Theme.of(context).textTheme.titleMedium),
                  Chip(label: Text('${title.emoji} Niv. ${level.level}')),
                ],
              ),
              const Spacer(),
              // Héros
              const Center(child: Text('🦉', style: TextStyle(fontSize: 64))),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Prêt à voyager dans le temps ?',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _play(GameMode.classique),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Jouer !'),
              ),
              const SizedBox(height: 12),
              // Réglages
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Text(playable.emoji,
                          style: const TextStyle(fontSize: 20)),
                      title: const Text('Catégorie'),
                      trailing: Text(playable.label),
                      onTap: _pickCategory,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Text(diff.emoji,
                          style: const TextStyle(fontSize: 20)),
                      title: const Text('Difficulté'),
                      trailing: Text(diff.label),
                      onTap: _pickDifficulty,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Défi du jour
              Card(
                child: ListTile(
                  leading: const Text('🗓️', style: TextStyle(fontSize: 22)),
                  title: const Text('Défi du jour'),
                  subtitle: Text(
                    dailyDone
                        ? 'Déjà joué : ${widget.store.dailyLastScore} pts'
                            '${widget.store.dailyStreak > 0 ? ' · 🔥 ${widget.store.dailyStreak} j' : ''}'
                        : 'Les 10 mêmes événements pour tout le monde',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed:
                        dailyDone ? null : () => _play(GameMode.daily),
                    child: Text(dailyDone ? 'Demain !' : 'Jouer'),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '${widget.repo.events.length} événements'
                  '${best > 0 ? ' · record ${playable.label} · ${diff.label} : $best' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
