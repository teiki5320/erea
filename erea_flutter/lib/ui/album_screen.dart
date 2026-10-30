import 'package:flutter/material.dart';

import '../core/timeline_scale.dart';
import '../data/events_repository.dart';
import '../data/store.dart';
import '../models/hist_event.dart';
import 'era_theme.dart';
import 'icone.dart';
import 'sticker_widgets.dart';

/// L'album de collection : chaque événement révélé au moins une fois, rangé
/// par époque, de l'âge du bronze à aujourd'hui.
///
/// Les faits pas encore découverts ne sont JAMAIS montrés, même grisés :
/// leur titre donnerait la question avant la partie. Seul leur nombre
/// s'affiche, époque par époque. Toucher un fait ouvre sa fiche complète,
/// réponse et anecdote comprises — l'album sert aussi à réviser.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.repo, required this.store});

  final EventsRepository repo;
  final Store store;

  @override
  Widget build(BuildContext context) {
    // Seuls les faits encore dans la base comptent (un doublon retiré
    // reste dans `discovered`).
    final decouverts = store.discovered;
    final parEpoque = List.generate(eras.length, (_) => <HistEvent>[]);
    final totalParEpoque = List.filled(eras.length, 0);
    for (final e in repo.events) {
      final i = eraIndexAt(e.annee);
      totalParEpoque[i]++;
      if (decouverts.contains(e.id)) parEpoque[i].add(e);
    }
    for (final liste in parEpoque) {
      liste.sort((a, b) => a.annee.compareTo(b.annee));
    }
    final trouves = parEpoque.fold<int>(0, (s, l) => s + l.length);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Album',
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            color: inkColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _Progression(repo: repo, decouverts: decouverts, trouves: trouves),
          if (trouves == 0)
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 24, 8, 0),
              child: Text(
                'Ton album est vide. Joue une partie : chaque événement '
                'révélé vient s’y ranger, à sa place dans le temps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: inkSoftColor,
                ),
              ),
            ),
          for (var i = 0; i < eras.length; i++)
            _Epoque(
              theme: eraThemes[i],
              faits: parEpoque[i],
              restants: totalParEpoque[i] - parEpoque[i].length,
            ),
        ],
      ),
    );
  }
}

/// En tête : le total, puis une ligne par catégorie.
class _Progression extends StatelessWidget {
  const _Progression({
    required this.repo,
    required this.decouverts,
    required this.trouves,
  });

  final EventsRepository repo;
  final Set<int> decouverts;
  final int trouves;

  @override
  Widget build(BuildContext context) {
    final total = repo.events.length;
    return _Carte(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$trouves / $total',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 30,
              height: 1.1,
              color: inkColor,
            ),
          ),
          const Text(
            'événements découverts',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: inkSoftColor,
            ),
          ),
          const SizedBox(height: 8),
          _Barre(part: total == 0 ? 0 : trouves / total, hauteur: 9),
          const SizedBox(height: 14),
          for (final c in categories.where((c) => c.key != 'tout')) ...[
            _LigneCategorie(
              categorie: c,
              trouves: repo.events
                  .where((e) => e.cat == c.key && decouverts.contains(e.id))
                  .length,
              total: repo.events.where((e) => e.cat == c.key).length,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LigneCategorie extends StatelessWidget {
  const _LigneCategorie({
    required this.categorie,
    required this.trouves,
    required this.total,
  });

  final Playable categorie;
  final int trouves;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            iconeJouable(categorie, taille: 22),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                categorie.label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: inkColor,
                ),
              ),
            ),
            Text(
              '$trouves / $total',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: inkSoftColor,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _Barre(part: total == 0 ? 0 : trouves / total, hauteur: 5),
      ],
    );
  }
}

/// Une époque : son bandeau aux couleurs de la frise, ses faits
/// découverts dans l'ordre du temps, et ce qu'il reste à trouver.
class _Epoque extends StatelessWidget {
  const _Epoque({
    required this.theme,
    required this.faits,
    required this.restants,
  });

  final EraTheme theme;
  final List<HistEvent> faits;
  final int restants;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _Carte(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: theme.tint,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      theme.name,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.6,
                        color: theme.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${faits.length} / ${faits.length + restants}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: theme.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            for (final e in faits)
              ListTile(
                leading: Text(e.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(
                  e.titre,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: inkColor,
                  ),
                ),
                subtitle: Text(
                  formatYear(e.annee),
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: theme.ink,
                  ),
                ),
                onTap: () => _ouvrirFiche(context, e, theme),
              ),
            if (restants > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Text(
                  faits.isEmpty
                      ? '$restants événements à découvrir'
                      : restants == 1
                          ? 'Encore 1 événement à découvrir'
                          : 'Encore $restants événements à découvrir',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: inkPaleColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La fiche d'un fait de l'album : tout ce que la révélation avait montré.
void _ouvrirFiche(BuildContext context, HistEvent e, EraTheme theme) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: MediaQuery.sizeOf(context).height * .85,
    ),
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.titre,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    height: 1.15,
                    color: inkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatYear(e.annee),
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 40,
              height: 1.1,
              color: theme.ink,
            ),
          ),
          Text(
            [
              playableFor(e.cat).label,
              if (e.pays != null) e.pays!,
            ].join(' · '),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: inkPaleColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            e.desc,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.45,
              color: inkSoftColor,
            ),
          ),
          if (e.fun.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Le savais-tu ?',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: inkColor,
                  ),
                ),
                const SizedBox(width: 6),
                icone('💡', taille: 24),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              e.fun,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                height: 1.5,
                color: inkSoftColor,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Carte extends StatelessWidget {
  const _Carte({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [softShadow],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// Barre de progression menthe → ciel, celle de l'accueil.
class _Barre extends StatelessWidget {
  const _Barre({required this.part, required this.hauteur});

  final double part;
  final double hauteur;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: hauteur,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: inkColor.withValues(alpha: 0.12)),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: part.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [mintColor, skyColor]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
