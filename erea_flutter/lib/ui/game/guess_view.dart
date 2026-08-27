import 'package:flutter/material.dart' hide Badge;

import '../../data/events_repository.dart';
import '../../core/timeline_scale.dart';
import '../../data/store.dart';
import '../../game/game_controller.dart';
import '../sticker_widgets.dart';
import '../tape_widget.dart';

const Map<String, Color> _catColors = {
  'pouvoir': coralColor,
  'sciences': mintColor,
  'arts': violetColor,
  'quotidien': orangeColor,
};

/// Hauteur de la frise pendant le choix : c'est l'outil de visée, elle
/// doit dominer l'écran. Proportionnelle à la hauteur disponible, pour
/// rester généreuse sur grand écran sans repousser le réglage fin sous
/// la ligne de flottaison sur un iPhone SE.
/// Elle CÈDE avant la carte : en très grande police système, les blocs
/// fixes (année plafonnée, pastilles, réglage fin) plus une frise de
/// 210 px laissaient 0 px à la carte de l'événement — le fait à deviner
/// devenait invisible. La carte a droit à 140 px quoi qu'il arrive, et
/// c'est la frise qui descend, jusqu'à 150 px au pire.
double tapeHeightFor(double available) {
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

/// La phase de choix : la carte de l'événement, la frise qu'on fait
/// glisser, la mini-carte et le réglage fin à l'année près.
///
/// Sortie de `game_screen.dart` le 26 août 2026 — elle n'a besoin que du
/// contrôleur, de la place disponible, et d'un signal quand le joueur
/// touche la frise pour la première fois.
class GuessView extends StatelessWidget {
  const GuessView({
    super.key,
    required this.controller,
    required this.store,
    required this.guessing,
    required this.available,
    required this.tapeKey,
    required this.astuceGeste,
    required this.onPremierGeste,
  });

  final GameController controller;
  final Store store;

  /// Faux dès que la manche est validée : la frise se verrouille et le
  /// ruban part en voyage vers la vraie date.
  final bool guessing;
  final double available;
  final GlobalKey tapeKey;

  /// L'astuce « Fais glisser la frise » du tout premier lancement : elle
  /// disparaît au premier contact et ne revient jamais.
  final bool astuceGeste;
  final VoidCallback onPremierGeste;

  @override
  Widget build(BuildContext context) {
    final ev = controller.current;
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
                        if (controller.multiplier == 2)
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
        EraPillPair(frac: controller.frac, bordered: false),
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
                formatYear(controller.guessYear),
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
              key: tapeKey,
              frac: controller.frac,
              locked: !guessing,
              height: tapeHeightFor(available),
              onFracChanged: (f) {
                if (astuceGeste) {
                  onPremierGeste();
                }
                // Le cliquetis du glissement est géré par TapeWidget, qui
                // seul connaît la distance réellement parcourue sur le ruban.
                controller.setFrac(f);
              },
            ),
            // Astuce du premier lancement : elle disparaît au premier
            // contact avec la frise, et ne revient jamais.
            if (astuceGeste && guessing)
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
              _fineButton('−', 'Recule d’un an',
                  guessing ? () => controller.setYear(controller.guessYear - 1) : null),
              const SizedBox(width: 12),
              Expanded(
                child: MiniMap(
                  frac: controller.frac,
                  onChanged: (f) {
                    if (guessing) controller.setFrac(f);
                  },
                ),
              ),
              const SizedBox(width: 12),
              _fineButton('+', 'Avance d’un an',
                  guessing ? () => controller.setYear(controller.guessYear + 1) : null),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Bouton de réglage fin 46 × 46 : glyphe « − » / « + » en Baloo,
  /// blanc, ombre douce (0, 6, 14).
}

Widget _fineButton(String glyph, String label, VoidCallback? onTap) {
    // Le glyphe est un dessin : sans étiquette, VoiceOver n'annonce rien.
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
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
      ),
    );
  }

/// Sortie de l'écran de fin : la publicité s'intercale ICI, jamais
  /// avant. Le joueur a vu son score, son XP et son bilan ; il quitte de
  /// son plein gré. C'est le seul moment où une réclame ne coupe rien.
  ///
  /// Le Défi du jour en est exempté (voir `Pub`), et l'affichage échoue en
  /// silence : la navigation part de toute façon.
