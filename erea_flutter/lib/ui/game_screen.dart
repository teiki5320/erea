import 'package:flutter/material.dart';

import '../core/progression.dart';
import '../core/scoring.dart';
import '../core/timeline_scale.dart';
import '../data/events_repository.dart';
import '../data/store.dart';
import '../game/game_controller.dart';
import 'sticker_widgets.dart';
import 'tape_widget.dart';

/// Couleur d'étiquette par catégorie (carte de l'événement).
const Map<String, Color> _catColors = {
  'france': coralColor,
  'monde': skyColor,
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
    with TickerProviderStateMixin {
  late final AnimationController _travel;
  late final AnimationController _roundFade;
  int _fadedRound = -1;
  double _travelBegin = 0;
  double _travelEnd = 0;
  RoundResult? _lastResult;
  bool _showEnd = false;
  bool _finishing = false;

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
    _roundFade.dispose();
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
    var ms = (500 + dist * 2200).clamp(500.0, 1500.0).toInt();
    if (MediaQuery.of(context).disableAnimations) ms = 80;
    _travel.duration = Duration(milliseconds: ms);
    _travel.forward(from: 0);
  }

  Future<void> _next() async {
    if (_finishing) return; // évite le double-tap (XP doublée sinon)
    final continues = game.next();
    if (!continues) {
      _finishing = true;
      setState(() => _showEnd = true);
      // Fin de partie : XP (+ bonus de combo), records, anti-répétition.
      await widget.store.incGames();
      await widget.store.markSeen(game.results.map((r) => r.event.id));
      if (game.mode == GameMode.daily) {
        await widget.store
            .finishDaily(game.total, grid: _grid(), day: game.dailyKey);
      } else {
        await widget.store
            .submitScore('${game.catKey}|${game.diff.name}', game.total);
      }
      await widget.store
          .addXp(xpGain(game.total, game.diff.xpMult) + game.comboBonusXp);
      if (mounted) setState(() {});
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
    if (r.base == maxScore) return 'PILE DESSUS !';
    if (r.base >= 900) return 'Incroyable !';
    if (r.base >= 700) return 'Excellent !';
    if (r.base >= 500) return 'Bien joué !';
    if (r.base >= 250) return 'Pas mal !';
    if (r.base >= 80) return 'Pas loin…';
    return 'Trop loin !';
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
        body: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            if (game.round != _fadedRound && !_showEnd) {
              _fadedRound = game.round;
              _roundFade.forward(from: 0);
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                // Fond fondu : fonction pure de frac (aucune animation
                // pendant le geste). Seul le lancement d'une manche fait
                // un vrai fondu temporel de 320 ms.
                FadeTransition(
                  opacity: _roundFade
                      .drive(CurveTween(curve: Curves.easeOut)),
                  child: EraBackdrop(frac: game.frac),
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
                onPressed: () => _confirmQuit(context),
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
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: revealed && _lastResult != null
                    ? _revealBody(context, _lastResult!)
                    : _guessBody(context, guessing),
              ),
            ),
          ),
        ),
        // Bouton principal
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: guessing
              ? PushButton(
                  onPressed: game.touched ? _validate : null,
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
  Widget _guessBody(BuildContext context, bool guessing) {
    final ev = game.current;
    final cat = playableFor(ev.cat);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        // Carte de l'événement, étiquette de catégorie en débord
        Padding(
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
                        Text(ev.emoji, style: const TextStyle(fontSize: 44)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
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
        const SizedBox(height: 14),
        // Année : pastille d'époque + nombre, sans bulle
        EraPillPair(frac: game.frac, bordered: false),
        const SizedBox(height: 2),
        Padding(
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
        const SizedBox(height: 8),
        // La frise, plein-bord
        TapeWidget(
          frac: game.frac,
          locked: !guessing,
          height: 150,
          onFracChanged: (f) => game.setFrac(f),
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

  /// Révélation : verdict, frise figée à deux épingles, « Le savais-tu ? »,
  /// bandeau de combo.
  Widget _revealBody(BuildContext context, RoundResult r) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Text(
          _reaction(r),
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: verdictMintColor,
          ),
        ),
        Text(
          '+ ${r.pts}',
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: 56,
            height: 1.0,
            color: coralColor,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          '${_direction(r)} · tolérance '
          '${tolerance(r.event.annee, game.diff).round()} ans',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: inkSoftColor,
          ),
        ),
        // La frise figée porte les deux épingles (marges pour les pastilles)
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            double xOf(int year) =>
                w / 2 + (yearToFrac(year) - game.frac) * 3200;
            // Marge assez large pour « Toi · 3000 av. J.-C. »
            final gx = xOf(r.guess).clamp(78.0, w - 78.0);
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
            return SizedBox(
              height: 44.0 + 150 + 46,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 44,
                    left: 0,
                    right: 0,
                    child: TapeWidget(
                      frac: game.frac,
                      locked: true,
                      height: 150,
                      onFracChanged: (_) {},
                    ),
                  ),
                  // Épingle « Toi »
                  Positioned(
                    top: 2,
                    left: gx,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: pinScale(
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [softShadow],
                              ),
                              child: Text(
                                'Toi · ${formatYear(r.guess)}',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: inkColor,
                                ),
                              ),
                            ),
                            Container(
                                width: 3, height: 18, color: inkPaleColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Épingle de la vraie date (le ruban est centré dessus)
                  Positioned(
                    top: 44.0 + 150 - 14,
                    left: w / 2,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: pinScale(
                        Column(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: mintColor,
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: mintColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${formatYear(r.event.annee)} 🎯',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Le savais-tu ? + jetons
        if (r.event.fun.isNotEmpty)
          Padding(
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
                  const Text(
                    'Le savais-tu ? 💡',
                    style: TextStyle(
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
                        '+${(r.pts / 10 * game.diff.xpMult * (game.lastBoosted ? 1.5 : 1)).round()} XP',
                        const Color(0xFFFFF3D9),
                        const Color(0xFFA9761C),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        // Bandeau de combo
        if (game.combo > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.combo == 1
                              ? '1 bonne réponse'
                              : '${game.combo} bonnes réponses d’affilée',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: inkColor,
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
                                      color:
                                          inkColor.withValues(alpha: 0.10)),
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: (game.combo / 3)
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
                  if (game.boostNext && !game.isLastRound) ...[
                    const SizedBox(width: 10),
                    const Text(
                      '×1,5',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: coralColor,
                      ),
                    ),
                  ],
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
