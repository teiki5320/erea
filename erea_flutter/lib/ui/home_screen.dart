import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/accessibilite.dart';
import '../core/progression.dart';
import '../core/scoring.dart';
import '../data/events_repository.dart';
import '../data/store.dart';
import '../game/game_controller.dart';
import 'era_art.dart';
import 'game_screen.dart';
import 'reglages_screen.dart';
import 'roulette_screen.dart';
import 'sticker_widgets.dart';
import 'tape_widget.dart';

const _mois = [
  'JANVIER', 'FÉVRIER', 'MARS', 'AVRIL', 'MAI', 'JUIN',
  'JUILLET', 'AOÛT', 'SEPTEMBRE', 'OCTOBRE', 'NOVEMBRE', 'DÉCEMBRE',
];

/// Accueil « Sticker Arcade » (handoff 4a) : dérive d'époque automatique,
/// pastilles à contour d'encre, panneau du défi, grille de 4 modes et
/// mini-frise en pied d'écran — le tutoriel implicite du geste.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repo, required this.store});

  final EventsRepository repo;
  final Store store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String catKey = 'tout';
  Difficulty diff = Difficulty.normal;
  bool _navigating = false;
  DateTime? _dailyNow;

  // Dérive d'époque : 0,0011/s (≈ 3,5 px/s sur le ruban virtuel, la
  // frise entière en ~15 min), en aller-retour — le modulo ferait
  // claquer le fondu au passage 1 → 0. Arrêtée définitivement au
  // premier contact sur la mini-frise.
  double homeFrac = 0.03;
  double _driftDir = 1;
  double _driftPending = 0;
  bool _driftStopped = false;
  Ticker? _drift;
  Duration _lastTick = Duration.zero;
  bool _driftInit = false;

  @override
  void initState() {
    super.initState();
    // Le défi du jour dépend de la DATE : une app laissée en arrière-plan
    // et rouverte le lendemain doit rendre le défi disponible sans qu'on
    // ait à la tuer. Idem pour « réduire les animations », modifiable à
    // tout moment dans les réglages du système.
    WidgetsBinding.instance.addObserver(this);
    // Les textures de fond peuvent finir de se décoder après le premier
    // build : on force alors une reconstruction (sinon, avec « réduire
    // les animations », elles n'apparaîtraient jamais).
    EraArt.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void didHaveMemoryPressure() {
    // iOS tue d'abord les apps qui retiennent le plus : mieux vaut rendre
    // le décor (redécodé à la demande) que de perdre la partie en cours.
    EraArt.libererDecor();
    if (mounted) {
      EraArt.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (!mounted) return;
    if (animationsReduites) {
      _drift?.stop();
    } else {
      _reprendreDerive();
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_driftInit) return;
    _driftInit = true;
    // Le ticker existe toujours : il n'est simplement pas démarré tant que
    // « réduire les animations » est actif — ainsi il peut démarrer si le
    // réglage est désactivé en cours de route.
    _drift = createTicker(_onDrift);
    if (!animationsReduites) _drift!.start();
  }

  void _onDrift(Duration elapsed) {
    var dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt > 0.5) dt = 0.0; // retour d'arrière-plan : pas de saut
    // La dérive est lente : reconstruire ~10 fois par seconde suffit
    // largement et ménage la batterie.
    _driftPending += dt;
    if (_driftPending < 0.1) return;
    final step = 0.0011 * _driftPending * _driftDir;
    _driftPending = 0;
    setState(() {
      homeFrac += step;
      if (homeFrac >= 1.0) {
        homeFrac = 1.0;
        _driftDir = -1;
      } else if (homeFrac <= 0.0) {
        homeFrac = 0.0;
        _driftDir = 1;
      }
    });
  }

  void _stopDrift() {
    if (_driftStopped) return;
    _driftStopped = true;
    _drift?.stop();
  }

  /// Relance la dérive — jamais si le joueur a touché la mini-frise, jamais
  /// non plus si « réduire les animations » est actif (le ticker existe
  /// pourtant toujours, pour pouvoir démarrer si le réglage est levé).
  void _reprendreDerive() {
    if (_driftStopped || !mounted) return;
    // Pas de dérive derrière l'écran de jeu : lever le réglage en pleine
    // partie n'a aucune raison de réveiller l'accueil, qui n'est pas visible.
    if (_navigating) return;
    if (animationsReduites) return;
    if (_drift?.isActive ?? true) return;
    _lastTick = Duration.zero;
    _drift!.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drift?.dispose();
    super.dispose();
  }

  /// La roulette d'abord, la partie ensuite. L'écran rend le pays choisi
  /// (ou `null` si le joueur revient en arrière), et c'est seulement à ce
  /// moment que la partie démarre.
  Future<void> _lancerRoulette() async {
    if (_navigating) return;
    _navigating = true;
    _drift?.stop();
    try {
      final pays = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => RouletteScreen(
            repo: widget.repo,
            seen: widget.store.seen,
          ),
        ),
      );
      if (pays == null || !mounted) return;
      _paysRoulette = pays;
    } finally {
      _navigating = false;
      _reprendreDerive();
    }
    if (mounted) await _play(GameMode.roulette);
  }

  /// Le pays retenu par la roulette, transmis au contrôleur au démarrage.
  String? _paysRoulette;

  Future<void> _play(GameMode mode) async {
    if (_navigating) return; // évite le double-tap qui empile deux écrans
    _navigating = true;
    _drift?.stop(); // pas de dérive derrière l'écran de jeu
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      var again = true;
      while (again && mounted) {
        final controller = GameController(widget.repo);
        controller.catKey = catKey;
        controller.diff = diff;
        controller.dailyNow = _dailyNow;
        controller.pays = _paysRoulette;
        final ok = controller.start(mode, seenIds: widget.store.seen);
        if (!ok) {
          messenger.showSnackBar(
            const SnackBar(
                content: Text('Pas assez d’événements dans cette sélection !')),
          );
          return;
        }
        // Le verrou du défi n'est posé qu'une fois la partie réellement
        // constituée : jamais de tentative brûlée sans avoir joué.
        if (mode == GameMode.daily) {
          await widget.store.lockDaily(now: _dailyNow);
          // Défi interrompu par un arrêt SUBI (iOS a déchargé l'app) : on
          // rejoue les manches déjà validées et le joueur reprend où il
          // s'était arrêté. Un abandon volontaire, lui, a effacé la reprise.
          if (widget.store.dailyResumable) {
            controller.restore(widget.store.dailyProgress);
          }
        }
        final replay = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                GameScreen(controller: controller, store: widget.store),
          ),
        );
        controller.dispose();
        again = replay == true;
      }
    } finally {
      _navigating = false;
      if (mounted) {
        setState(() {});
        _reprendreDerive();
      }
    }
  }

  Future<void> _pickCategory() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const _SheetTitle('Choisis une catégorie'),
            for (final c in categories)
              _pickTile(c, widget.repo.pool(c.key).length),
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

  Future<void> _pickDifficulty() async {
    await showModalBottomSheet<void>(
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

  /// Tuile Classique : catégorie + difficulté + départ.
  Future<void> _openClassique() async {
    if (!categories.any((c) => c.key == catKey)) catKey = 'tout';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            final playable = playableFor(catKey);
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                const _SheetTitle('Partie classique'),
                ListTile(
                  leading: Text(playable.emoji,
                      style: const TextStyle(fontSize: 20)),
                  title: const Text('Catégorie'),
                  trailing: Text(playable.label),
                  onTap: () async {
                    await _pickCategory();
                    setSheet(() {});
                  },
                ),
                ListTile(
                  leading:
                      Text(diff.emoji, style: const TextStyle(fontSize: 20)),
                  title: const Text('Difficulté'),
                  trailing: Text(diff.label),
                  onTap: () async {
                    await _pickDifficulty();
                    setSheet(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: PushButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _play(GameMode.classique);
                    },
                    color: coralColor,
                    shadowColor: const Color(0xFFB93A2F),
                    radius: 16,
                    child: const Center(
                      child: Text(
                        'C’est parti !',
                        style: TextStyle(
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
            );
          },
        );
      },
    );
  }

  /// Tuile Packs : un thème → départ immédiat.
  Future<void> _openPacks() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListView(
          shrinkWrap: true,
          children: [
            const _SheetTitle('Packs à thèmes'),
            for (final p in packs)
              if (widget.repo.pool(p.key).length >= rounds)
                ListTile(
                  leading: Text(p.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(p.label),
                  subtitle: Text('${widget.repo.pool(p.key).length} événements'),
                  onTap: () {
                    setState(() => catKey = p.key);
                    Navigator.of(sheetContext).pop();
                    _play(GameMode.classique);
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
    // Tentative consommée (le bouton se ferme) vs défi mené à son terme
    // (seul cas où un score et une grille existent).
    final dailyUsed = widget.store.dailyPlayedToday;
    final dailyDone = widget.store.dailyFinishedToday;
    // Le record de la tuile Classique : jamais celui d'un pack.
    final classiqueKey =
        categories.any((c) => c.key == catKey) ? catKey : 'tout';
    final best = widget.store.bestFor('$classiqueKey|${diff.name}');
    final now = DateTime.now();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          EraBackdrop(
            frac: homeFrac,
            textureHeight: 250,
            maskStops: const [0.0, 0.23, 0.76],
            textureAlignment: const Alignment(0, -0.24), // "center 38%"
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Barre du haut : profil + série. Le profil peut
                        // se réduire (texte agrandi par accessibilité) sans
                        // jamais déborder ; à taille normale, rendu identique.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _profilePill(level, title),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _streakPill(),
                            const SizedBox(width: 8),
                            _reglagesPill(),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Bloc logo
                        const Center(
                            child:
                                Text('🦉', style: TextStyle(fontSize: 42))),
                        const SizedBox(height: 2),
                        const Center(child: _Logo()),
                        const SizedBox(height: 6),
                        EraPillPair(frac: homeFrac),
                        const SizedBox(height: 15),
                        _dailyPanel(dailyUsed, dailyDone, now),
                        const SizedBox(height: 15),
                        // Grille des 4 modes
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _modeTile(
                                emoji: '🎯',
                                titre: 'Classique',
                                sousTitre: best > 0
                                    ? 'record $best'
                                    : 'catégories & niveaux',
                                onTap: _openClassique,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: _modeTile(
                                emoji: '⏱️',
                                titre: 'Chrono',
                                sousTitre: 'Bientôt !',
                                onTap: null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _modeTile(
                                emoji: '🎡',
                                titre: 'Roulette',
                                sousTitre:
                                    '${widget.repo.paysJouables.length} drapeaux',
                                onTap: _lancerRoulette,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment(0.7, 1),
                                  colors: [mintColor, skyColor],
                                ),
                                light: true,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: _modeTile(
                                emoji: '🚀',
                                titre: 'Packs',
                                sousTitre: '5 thèmes',
                                onTap: _openPacks,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment(0.7, 1),
                                  colors: [violetColor, skyColor],
                                ),
                                light: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // « X / Y découverts » : un objectif dès le premier
                        // lancement, à la place d'un simple total mort.
                        _collectionBar(),
                      ],
                    ),
                  ),
                ),
                // Mini-frise pied d'écran : le tutoriel implicite du geste
                Listener(
                  onPointerDown: (_) => _stopDrift(),
                  child: Container(
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: inkColor, width: 3)),
                    ),
                    child: TapeWidget(
                      frac: homeFrac,
                      height: 92,
                      onFracChanged: (f) {
                        _stopDrift();
                        setState(() => homeFrac = f);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Accès aux réglages et aux succès.
  Widget _reglagesPill() {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReglagesScreen(store: widget.store),
          ),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: inkColor, width: 2.5),
          boxShadow: const [
            BoxShadow(offset: Offset(0, 3), blurRadius: 0, color: inkColor),
          ],
        ),
        child: const Icon(Icons.tune, size: 18, color: inkColor),
      ),
    );
  }

  /// Avancement de la collection : les événements déjà révélés au moins
  /// une fois, sur toute la base.
  Widget _collectionBar() {
    final total = widget.repo.events.length;
    final trouves = widget.store.discovered.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            '$trouves / $total événements découverts',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: inkSoftColor,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 7,
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
                        widthFactor:
                            (trouves / total).clamp(0.0, 1.0).toDouble(),
                        heightFactor: 1,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient:
                                LinearGradient(colors: [mintColor, skyColor]),
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
    );
  }

  Widget _profilePill(LevelInfo level, LevelTitle title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: inkColor, width: 2.5),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 3), blurRadius: 0, color: inkColor),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.titre,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.1,
                  color: inkColor,
                ),
              ),
              Text(
                'NIV. ${level.level} · ${level.into}/${level.need} XP',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: inkPaleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streakPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: yellowColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: inkColor, width: 2.5),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 3), blurRadius: 0, color: inkColor),
        ],
      ),
      child: Text(
        // Série RÉELLE : une série interrompue ne doit plus s'afficher.
        '🔥 ${widget.store.effectiveStreak}',
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: inkColor,
        ),
      ),
    );
  }

  Widget _dailyPanel(bool dailyUsed, bool dailyDone, DateTime now) {
    final grid = widget.store.dailyGrid;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inkColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              offset: Offset(0, 6), blurRadius: 0, color: navyShadowColor),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '🗓️ Défi du jour',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${now.day} ${_mois[now.month - 1]}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.66,
                  color: yellowColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < rounds; i++)
                Expanded(
                  child: Container(
                    height: 9,
                    margin: EdgeInsets.only(right: i < rounds - 1 ? 5 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: dailyDone && i < grid.length
                          ? (grid[i] == 'g'
                              ? mintColor
                              : grid[i] == 'y'
                                  ? yellowColor
                                  : coralColor)
                          : Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          PushButton(
            onPressed: dailyUsed
                ? null
                : () async {
                    // Le verrou est posé dans _play, après un démarrage
                    // réussi : une seule tentative, même en abandonnant en
                    // cours de partie.
                    _dailyNow = DateTime.now();
                    await _play(GameMode.daily);
                  },
            color: coralColor,
            shadowColor: const Color(0xFFB93A2F),
            radius: 16,
            child: Center(
              child: Text(
                dailyDone
                    ? 'Déjà joué · ${widget.store.dailyLastScore} pts'
                    : dailyUsed
                        // Tentative consommée sans aller au bout : ne pas
                        // présenter ça comme un score de 0.
                        ? 'Prochain défi demain !'
                        : 'Jouer !',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTile({
    required String emoji,
    required String titre,
    required String sousTitre,
    required VoidCallback? onTap,
    Gradient? gradient,
    bool light = false,
  }) {
    return PushButton(
      onPressed: onTap,
      color: gradient == null ? Colors.white : null,
      gradient: gradient,
      border: Border.all(color: inkColor, width: 2.5),
      shadowColor: inkColor,
      radius: 20,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 3),
          Text(
            titre,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: light ? Colors.white : inkColor,
            ),
          ),
          Text(
            sousTitre,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: light
                  ? Colors.white.withValues(alpha: 0.85)
                  : inkPaleColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// « EREA » en Baloo 2, une couleur par lettre.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Baloo2',
      fontWeight: FontWeight.w800,
      fontSize: 60,
      height: 1.0,
      letterSpacing: 2.4,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('E', style: style.copyWith(color: coralColor)),
        Text('R', style: style.copyWith(color: yellowColor)),
        Text('E', style: style.copyWith(color: mintColor)),
        Text('A', style: style.copyWith(color: skyColor)),
      ],
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
