import 'dart:math' as math;

import 'package:flutter/material.dart' hide Badge;

import '../../core/scoring.dart';
import '../../core/timeline_scale.dart';
import '../../game/game_controller.dart';
import '../sticker_widgets.dart';
import '../tape_widget.dart';
import 'gap_line_painter.dart';
import 'verdict_textes.dart';

/// Révélation : la frise reste grande, avec la place des deux pastilles
/// au-dessus (« Toi · … ») et en dessous (la vraie date).
const double _revealTapeH = 240;
const double revealTopPad = 44;
const double revealBottomPad = 46;

/// Au-delà de ce facteur, le bandeau de verdict cesse de grossir.
///
/// Partagé avec le bouton principal de l'écran de jeu : c'est un
/// contrôle, pas un texte à lire, et le laisser doubler de taille le
/// poussait hors de l'écran sur iPhone SE en « texte plus grand ».
///
/// Le badge, les points et la ligne d'écart sont déjà énormes : les
/// laisser doubler poussait la frise et le bouton hors de l'écran sur
/// iPhone SE. L'anecdote, elle — le seul texte qui apprend quelque
/// chose — garde l'échelle réglée par le système, sans plafond.
const double maxEchelleVerdict = 1.3;

/// Hauteur de la frise de révélation, bornée par la place réelle.
///
/// Sur petit écran ET en grande police, les blocs fixes du haut
/// gonflent : une frise de hauteur constante faisait alors déborder la
/// colonne de 280 px, et le bouton « Manche suivante » disparaissait.
double revealTapeHeightFor(double available) {
  final voulu = available < 620 ? 190.0 : _revealTapeH;
  // Les pastilles ont besoin de leurs marges hautes et basses : c'est la
  // frise elle-même qui cède, jamais elles.
  final place = available * 0.34 - revealTopPad - revealBottomPad;
  return math.min(voulu, math.max(110.0, place));
}

/// La révélation d'une manche : badge de verdict, points, puis la frise
/// figée qui porte les deux épingles RELIÉES par le trait de l'écart.
///
/// Sortie de `game_screen.dart` le 26 août 2026 : cinq cents lignes qui
/// n'avaient besoin que du résultat de la manche et des animations
/// d'apparition, mais partageaient l'état de tout l'écran de jeu.
class RevealView extends StatelessWidget {
  const RevealView({
    super.key,
    required this.controller,
    required this.r,
    required this.available,
    required this.pop,
    required this.popBadge,
    required this.popPoints,
    required this.popPointsMontee,
    required this.tapeKey,
  });

  final GameController controller;
  final RoundResult r;
  final double available;

  /// L'animation d'apparition du bandeau — le badge grossit, les points
  /// montent. Pilotée par l'écran de jeu, qui la relance à chaque manche.
  final AnimationController pop;
  final Animation<double> popBadge;
  final Animation<double> popPoints;
  final Animation<double> popPointsMontee;

  /// La frise de révélation partage sa clé avec celle du jeu : c'est ce
  /// qui permet au ruban de continuer son voyage sans être reconstruit.
  final GlobalKey tapeKey;

  /// Révélation : badge de verdict, points, puis la frise figée qui porte
  /// les deux épingles RELIÉES par le trait de l'écart — la longueur du
  /// trait EST l'erreur, c'est ce qui fait comprendre l'échelle non
  /// linéaire sans avoir à l'expliquer.
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final tol = tolerance(controller.diff);
    // UN SEUL verdict pour tout l'écran : badge, points, trait d'écart et
    // titre de la carte disent la même chose que la pastille de manche et
    // que la grille de partage (cf. scoring.dart).
    final verdict = verdictFor(r.base);
    final dansLaCible = verdict == Verdict.reussi;
    // Petit écran : on resserre pour que l'anecdote ne passe pas sous la
    // ligne de flottaison — c'est la partie qui apprend quelque chose.
    final serre = available < 620;
    final tapeH = revealTapeHeightFor(available);
    final ptsSize = serre ? 44.0 : 56.0;
    final badgeSize = serre ? 18.0 : 22.0;
    return Column(
      children: [
        // Le bandeau de verdict — badge, points, écart — cesse de grossir
        // au-delà de maxEchelleVerdict. Sans ce plafond, il chassait la
        // frise et le bouton de l'écran en « texte plus grand ».
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: maxEchelleVerdict,
          child: Column(
            children: [
        const SizedBox(height: 12),
        // liveRegion : VoiceOver lit la phrase dès qu'elle apparaît.
        // excludeSemantics : le résumé complet remplace le seul
        // « Incroyable ! » du badge, qui ne donnait ni l'année ni l'écart.
        Semantics(
          liveRegion: true,
          container: true,
          excludeSemantics: true,
          label: resumeVocalPour(r),
          child:
          ScaleTransition(
            key: const ValueKey('badge-verdict'),
            scale: popBadge,
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
                  '${reactionPour(r)} ${dansLaCible ? '🎯' : '😅'}',
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
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: pop,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, popPointsMontee.value),
            child: Transform.scale(scale: popPoints.value, child: child),
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
          '${directionPour(r)} · cible ± ${(tol * 0.3567).round()} ans',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: inkSoftColor,
          ),
        ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // La frise figée porte les deux épingles et le trait de l'écart
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final echelle = MediaQuery.textScalerOf(context);
            double xOf(int year) =>
                w / 2 + (yearToFrac(year) - controller.frac) * TapeWidget.tapeW;
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
              height: revealTopPad + tapeH + revealBottomPad,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: revealTopPad,
                    left: 0,
                    right: 0,
                    child: TapeWidget(
                      key: tapeKey,
                      frac: controller.frac,
                      locked: true,
                      height: tapeH,
                      onFracChanged: (_) {},
                    ),
                  ),
                  // Trait de l'écart : plein quand la manche est réussie,
                  // pointillé sinon.
                  if (r.ecart > 0)
                    Positioned(
                      top: revealTopPad + tapeH * 0.30,
                      left: math.min(gx, trueX),
                      child: SizedBox(
                        width: ecartX,
                        height: 3,
                        child: CustomPaint(
                          painter: GapLinePainter(dashed: !dansLaCible),
                        ),
                      ),
                    ),
                  // … et le nombre d'années, porté par le trait.
                  if (r.ecart > 0)
                    Positioned(
                      top: revealTopPad + tapeH * 0.30 - 11,
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
                      height: revealTopPad - 22,
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
                    top: revealTopPad + tapeH - 15,
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
                    top: revealTopPad + tapeH + 4,
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
        if (controller.combo > 0 || controller.comboBroken)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: controller.comboBroken
                    ? inkColor.withValues(alpha: 0.06)
                    : const Color(0xFFFFF3D9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: controller.comboBroken ? 0.4 : 1,
                    child: const Text('🔥', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.comboBroken
                              ? 'Série perdue — on repart de zéro'
                              : controller.combo == 1
                                  ? '1 bonne réponse'
                                  : '${controller.combo} bonnes réponses d’affilée',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: controller.comboBroken ? inkPaleColor : inkColor,
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
                                      widthFactor: controller.comboBroken
                                          ? 0.0
                                          : (controller.combo / 3)
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
                    controller.boostNext && !controller.isLastRound ? '×1,5' : '×1',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: controller.boostNext && !controller.isLastRound
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
