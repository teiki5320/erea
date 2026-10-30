import 'package:flutter/material.dart' hide Badge;

import '../../core/progression.dart';
import '../../core/scoring.dart';
import '../../core/timeline_scale.dart';
import '../../data/events_repository.dart';
import '../../data/store.dart';
import '../../game/badges.dart';
import '../../game/game_controller.dart';
import '../../core/sons.dart';
import '../icone.dart';
import '../offre_sans_pub.dart';
import '../sticker_widgets.dart';

/// L'écran de fin de partie : ce que la partie a RAPPORTÉ.
///
/// L'XP, le niveau franchi et le record battu étaient déjà calculés mais
/// n'étaient dits nulle part — le joueur voyait dix promesses « +N XP »
/// et jamais le total.
///
/// Sorti de `game_screen.dart` le 26 août 2026. Il ne lui reste du
/// grand écran que ce qu'il montre : le contrôleur, la progression
/// d'avant la partie, et deux boutons dont il ne sait rien.
class EndView extends StatelessWidget {
  const EndView({
    super.key,
    required this.controller,
    required this.store,
    required this.xpAvant,
    required this.record,
    required this.badgesGagnes,
    required this.grilleCopiee,
    required this.onPartager,
    required this.onQuitter,
  });

  final GameController controller;
  final Store store;

  /// L'XP d'AVANT la partie : c'est elle qui permet de dire « niveau
  /// franchi » plutôt que d'afficher un total sans repère.
  final int xpAvant;
  final bool record;
  final List<Badge> badgesGagnes;

  /// Vrai quand la feuille de partage n'a pas pu s'ouvrir et que le texte
  /// a été copié à la place : le bouton le dit alors au joueur.
  final bool grilleCopiee;
  final VoidCallback onPartager;

  /// `true` pour rejouer, `false` pour revenir à l'accueil.
  final void Function(bool rejouer) onQuitter;

  /// Écran de fin : ce que la partie a RAPPORTÉ. L'XP, le niveau franchi
  /// et le record battu étaient déjà calculés mais n'étaient dits nulle
  /// part — le joueur voyait dix promesses « +N XP » et jamais le total.
  @override
  Widget build(BuildContext context) {
    final playable = playableFor(controller.catKey);
    final xpApres = xpAvant + controller.xpTotal;
    final nivAvant = levelFromXp(xpAvant);
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
            '${controller.total} / ${controller.mode == GameMode.chrono ? maxScore * rounds : maxTotal}',
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
        if (record)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: yellowColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [pillShadow],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icone('🏆', taille: 22),
                const SizedBox(width: 6),
                const Text(
                  'Nouveau record !',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: inkColor,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(controller.emojiGrid(), style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(
          '${playable.label} · ${controller.diff.label} · '
          'écart moyen ${controller.averageEcart.round()} ans',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: inkSoftColor,
          ),
        ),
        // Ce que la partie a rapporté : XP, barre de niveau, palier franchi,
        // et les succès débloqués accrochés SOUS la même carte. Dans un
        // encadré à part au milieu du bilan, ils passaient inaperçus.
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [softShadow],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Le niveau dans un carré jaune (maquette du 21 octobre
                          // 2026), à la place de l'émoji du titre.
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: yellowColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${nivApres.level}',
                              style: const TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: inkColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                            '+${controller.xpTotal} XP',
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: Color(0xFFA9761C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 10,
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
                if (badgesGagnes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    color: yellowColor.withValues(alpha: 0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badgesGagnes.length == 1
                              ? 'SUCCÈS DÉBLOQUÉ'
                              : '${badgesGagnes.length} SUCCÈS DÉBLOQUÉS',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1,
                            color: Color(0xFFA9761C),
                          ),
                        ),
                        for (final b in badgesGagnes) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              iconeBadge(b, taille: 34),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: '${b.titre}  ',
                                      style: const TextStyle(
                                        fontFamily: 'Baloo2',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: inkColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: b.comment,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        color: inkSoftColor,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
            onPressed: onPartager,
            color: Colors.white,
            shadowColor: const Color(0xFFD8DDEF),
            shadowHeight: 4,
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icone(grilleCopiee ? '✅' : '📤', taille: 24),
                  const SizedBox(width: 6),
                  Text(
                    grilleCopiee ? 'Partagé !' : 'Partager ma grille',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: inkColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: controller.results.length,
            itemBuilder: (context, i) => _ligneBilan(controller.results[i]),
          ),
        ),
        // L'offre là où la pub va tomber : sous le bilan, avant les
        // boutons. Rien ne s'affiche chez un acheteur ni boutique muette.
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OffreSansPubChip(store: store),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
          child: Row(
            children: [
              if (controller.mode != GameMode.daily) ...[
                Expanded(
                  child: PushButton(
                    onPressed: () => onQuitter(true),
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
                  onPressed: () => onQuitter(false),
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

}
