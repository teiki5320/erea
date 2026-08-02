import 'package:flutter/material.dart';

import '../core/accessibilite.dart';
import '../core/retour.dart';
import '../core/sons.dart';
import '../data/drapeaux.dart';
import '../data/events_repository.dart';
import 'sticker_widgets.dart';

/// La roulette des drapeaux : on la lance, elle ralentit, elle s'arrête
/// sur un pays, et toute la partie porte sur ce pays.
///
/// Le tirage est fait AVANT l'animation, par le dépôt : la roue ne fait
/// que montrer un résultat déjà décidé. C'est ce qui garantit qu'elle ne
/// s'arrête jamais sur un pays incapable de fournir dix manches — et ça
/// évite d'avoir à annuler une animation déjà lancée.
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({
    super.key,
    required this.repo,
    required this.seen,
  });

  final EventsRepository repo;
  final Set<int> seen;

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  static const double _cellule = 92;
  static const int _tours = 4;

  late final List<String> _pays;
  late final AnimationController _ctrl;
  late final Animation<double> _course;

  String? _choisi;
  bool _lance = false;

  /// État explicite plutôt que `_ctrl.isCompleted` : le contrôleur ne
  /// reconstruit pas l'écran en changeant de statut, et le mode
  /// « animations réduites » saute l'animation sans jamais passer par
  /// `completed`. Sans ce drapeau, le nom du pays et le bouton « Jouer »
  /// n'apparaissaient jamais.
  bool _termine = false;
  int _dernierCran = -1;

  @override
  void initState() {
    super.initState();
    _pays = widget.repo.paysJouables;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    )
      ..addListener(_cliqueter)
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed && mounted) {
          // La roue se cale : le clac de résultat.
          Sons.drapeau();
          setState(() => _termine = true);
        }
      });
    _course = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Un cran de montre chaque fois qu'un drapeau passe devant le repère.
  /// C'est le même son que la frise, et il ralentit tout seul avec la
  /// roue : la décélération s'entend autant qu'elle se voit.
  void _cliqueter() {
    if (_choisi == null) return;
    final cran = (_course.value * _distance / _cellule).floor();
    if (cran == _dernierCran) return;
    _dernierCran = cran;
    Retour.cran();
    // Bride propre à la roulette : la roue part très vite et le tic de
    // frise s'y noyait en bourdonnement.
    Sons.cranRoulette();
  }

  double get _distance {
    final cible = _pays.indexOf(_choisi!);
    return (_tours * _pays.length + cible) * _cellule;
  }

  void _lancer() {
    if (_lance || _pays.isEmpty) return;
    final tire = widget.repo.tirerPays(seen: widget.seen);
    if (tire == null) return;
    setState(() {
      _choisi = tire;
      _lance = true;
    });
    if (animationsReduites) {
      // Pas de roue qui tourne : le résultat s'affiche, point. Le clac
      // marque quand même l'arrêt.
      _ctrl.value = 1;
      Sons.drapeau();
      setState(() => _termine = true);
    } else {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final termine = _termine;
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E9),
      body: SafeArea(
        child: Column(
          children: [
            _entete(context),
            const Spacer(),
            _roue(),
            const SizedBox(height: 26),
            _legende(termine),
            const Spacer(),
            _actions(termine),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  Widget _entete(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                Sons.retour();
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.arrow_back_rounded, color: inkColor),
            ),
            const Spacer(),
            Text(
              '${_pays.length} pays',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                color: inkPaleColor,
              ),
            ),
          ],
        ),
      );

  /// La bande de drapeaux et son repère. La bande est volontairement
  /// répétée à l'infini par modulo : inutile de construire des milliers
  /// de cellules pour quatre tours.
  Widget _roue() => SizedBox(
        height: 130,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRect(
              child: AnimatedBuilder(
                animation: _course,
                builder: (context, _) {
                  final offset =
                      _choisi == null ? 0.0 : _course.value * _distance;
                  return LayoutBuilder(
                    builder: (context, box) {
                      final visibles = (box.maxWidth / _cellule).ceil() + 2;
                      final premier = (offset / _cellule).floor();
                      final glisse = offset % _cellule;
                      return Stack(
                        children: [
                          for (var i = 0; i < visibles; i++)
                            Positioned(
                              left: box.maxWidth / 2 -
                                  _cellule / 2 +
                                  (i - visibles ~/ 2) * _cellule -
                                  glisse,
                              top: 0,
                              child: _cellules(premier + i - visibles ~/ 2),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            IgnorePointer(
              child: Container(
                width: _cellule - 8,
                height: 118,
                decoration: BoxDecoration(
                  border: Border.all(color: coralColor, width: 4),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _cellules(int index) {
    final pays = _pays[index % _pays.length];
    return SizedBox(
      width: _cellule,
      height: 118,
      child: Center(
        child: Text(drapeauDe(pays), style: const TextStyle(fontSize: 52)),
      ),
    );
  }

  Widget _legende(bool termine) => SizedBox(
        height: 46,
        child: AnimatedOpacity(
          opacity: termine ? 1 : 0,
          duration: const Duration(milliseconds: 260),
          child: Text(
            _choisi ?? '',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 30,
              color: inkColor,
            ),
          ),
        ),
      );

  Widget _actions(bool termine) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: termine
            ? Row(
                children: [
                  Expanded(
                    child: PushButton(
                      onPressed: _relancer,
                      color: Colors.white,
                      shadowColor: inkPaleColor,
                      child: const Center(
                        child: Text(
                          'Relancer',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            color: inkColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PushButton(
                      onPressed: () => Navigator.of(context).pop(_choisi),
                      color: coralColor,
                      shadowColor: const Color(0xFFB93A2F),
                      child: Center(
                        child: Text(
                          'Jouer ${drapeauDe(_choisi!)}',
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : PushButton(
                onPressed: _lance ? null : _lancer,
                color: coralColor,
                shadowColor: const Color(0xFFB93A2F),
                child: const Center(
                  child: Text(
                    'Lancer la roulette',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      );

  void _relancer() {
    setState(() {
      _lance = false;
      _termine = false;
      _choisi = null;
      _dernierCran = -1;
      _ctrl.value = 0;
    });
  }
}
