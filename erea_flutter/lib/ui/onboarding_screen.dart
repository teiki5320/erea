import 'package:flutter/material.dart';

import '../core/region.dart' as region;
import '../core/sons.dart';
import '../data/store.dart';
import 'sticker_widgets.dart';

/// Parcours de premier lancement, sur le modèle de Kultiva : des pages qui
/// présentent le jeu (Suivant / Retour / points), puis le CHOIX DU PAYS.
/// Ce choix nourrit le mélange régional du mode Classique — un joueur de
/// Dakar n'a pas à dépendre du réglage de son iPhone pour retrouver
/// l'histoire de sa région.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store, this.onTermine});

  final Store store;
  final VoidCallback? onTermine;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Un pays proposé au choix. [iso] null = « un autre pays » : on laisse le
/// réglage de l'appareil décider.
class PaysPropose {
  final String nom;
  final String? iso;
  const PaysPropose(this.nom, this.iso);
}

/// France d'abord (le cœur historique de la base), puis l'Afrique en ordre
/// alphabétique — les pays que le jeu sait vraiment raconter — et enfin
/// « un autre pays » pour tout le reste du monde.
const List<PaysPropose> paysProposes = [
  PaysPropose('France', 'FR'),
  PaysPropose('Afrique du Sud', 'ZA'),
  PaysPropose('Algérie', 'DZ'),
  PaysPropose('Angola', 'AO'),
  PaysPropose('Bénin', 'BJ'),
  PaysPropose('Burkina Faso', 'BF'),
  PaysPropose('Cameroun', 'CM'),
  PaysPropose('Côte d’Ivoire', 'CI'),
  PaysPropose('Égypte', 'EG'),
  PaysPropose('Éthiopie', 'ET'),
  PaysPropose('Ghana', 'GH'),
  PaysPropose('Guinée', 'GN'),
  PaysPropose('Kenya', 'KE'),
  PaysPropose('Libye', 'LY'),
  PaysPropose('Madagascar', 'MG'),
  PaysPropose('Mali', 'ML'),
  PaysPropose('Maroc', 'MA'),
  PaysPropose('Mauritanie', 'MR'),
  PaysPropose('Mozambique', 'MZ'),
  PaysPropose('Niger', 'NE'),
  PaysPropose('Nigeria', 'NG'),
  PaysPropose('RD Congo', 'CD'),
  PaysPropose('Rwanda', 'RW'),
  PaysPropose('Sénégal', 'SN'),
  PaysPropose('Soudan', 'SD'),
  PaysPropose('Tanzanie', 'TZ'),
  PaysPropose('Tchad', 'TD'),
  PaysPropose('Togo', 'TG'),
  PaysPropose('Tunisie', 'TN'),
  PaysPropose('Zimbabwe', 'ZW'),
  PaysPropose('Un autre pays', null),
];

/// Drapeau emoji calculé depuis le code ISO (comme tools/drapeaux.py) :
/// deux « indicateurs régionaux », jamais de recopie sujette à coquille.
String drapeauIso(String? iso) => iso == null
    ? '🌐'
    : String.fromCharCodes(
        iso.toUpperCase().codeUnits.map((c) => 0x1F1A5 + c));

class _Page {
  final String emoji;
  final Color fond;
  final String titre;
  final String texte;
  const _Page(this.emoji, this.fond, this.titre, this.texte);
}

const List<_Page> _pages = [
  _Page('⏳', Color(0xFFFFE9C7), 'Bienvenue sur Erea',
      'Un événement, une frise du temps : à toi de deviner l’année. '
          'Plus tu vises juste, plus tu marques de points.'),
  _Page('👆', Color(0xFFDDF3EC), 'Fais glisser la frise',
      'De 3000 av. J.-C. à demain : approche-toi au doigt, ajuste à '
          'l’année près avec − et +, puis valide. La frise révèle la '
          'vraie date.'),
  _Page('🎯', Color(0xFFE3ECFF), 'Cinq façons de jouer',
      'Le Défi du jour (le même pour le monde entier), le Classique, le '
          'Chrono 10 s par question, la Roulette des drapeaux et les '
          'Packs à thème.'),
  _Page('🏆', Color(0xFFF6E3FF), 'Progresse',
      'Gagne de l’XP, débloque des succès et grimpe au classement '
          'mondial. Chaque partie enrichit ta collection d’événements.'),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  final ScrollController _listePays = ScrollController();
  int _page = 0;

  /// Pays sélectionné sur la dernière page (défaut : celui de l'appareil
  /// s'il est proposé, sinon la France).
  late PaysPropose _pays;

  @override
  void initState() {
    super.initState();
    final code = region.codePaysAppareil();
    // Même règle que le bouton « Détecter mon pays » : un appareil réglé
    // sur un pays hors liste présélectionne « Un autre pays », pas la
    // France — les deux chemins doivent donner la même réponse.
    _pays = paysProposes.firstWhere(
      (p) => p.iso != null && p.iso == code,
      orElse: () => paysProposes.last,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _listePays.dispose();
    super.dispose();
  }

  bool get _derniere => _page == _pages.length; // la page pays

  void _aller(int p) {
    _ctrl.animateToPage(
      p,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _commencer() async {
    if (_pays.iso == null) {
      await widget.store.setPaysChoisi(nom: null, iso: null);
      region.paysChoisiIso = null;
    } else {
      await widget.store.setPaysChoisi(nom: _pays.nom, iso: _pays.iso);
      region.paysChoisiIso = _pays.iso;
    }
    await widget.store.setOnboardingVu();
    widget.onTermine?.call();
  }

  void _detecter() {
    final code = region.codePaysAppareil();
    final trouve = paysProposes.where((p) => p.iso == code);
    setState(() {
      _pays = trouve.isNotEmpty ? trouve.first : paysProposes.last;
    });
    // Faire défiler la liste jusqu'à la ligne choisie : sans ça, détecter
    // un pays hors écran ne montrait rien — le bouton semblait mort.
    final index = paysProposes.indexOf(_pays);
    if (_listePays.hasClients) {
      _listePays.animateTo(
        (index * 61.0 - 120).clamp(0.0, _listePays.position.maxScrollExtent),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
    Sons.appui();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E9),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final p in _pages) _pagePresentation(p),
                  _pagePays(),
                ],
              ),
            ),
            _points(),
            const SizedBox(height: 10),
            _barreBoutons(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _pagePresentation(_Page p) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: p.fond,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: inkColor, width: 3),
                boxShadow: const [
                  BoxShadow(offset: Offset(0, 5), color: inkColor),
                ],
              ),
              child: Center(
                child: Text(p.emoji, style: const TextStyle(fontSize: 84)),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              p.titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 26,
                color: inkColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.texte,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                height: 1.45,
                color: inkSoftColor,
              ),
            ),
          ],
        ),
      );

  Widget _pagePays() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          children: [
            const SizedBox(height: 14),
            const Text('🌍', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 6),
            const Text(
              'Où joues-tu ?',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: inkColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Le mode Classique met en avant l’histoire de ta région.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: inkSoftColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: _listePays,
                itemCount: paysProposes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _lignePays(paysProposes[i]),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _detecter,
              icon: const Icon(Icons.my_location_rounded,
                  size: 18, color: inkColor),
              label: const Text(
                'Détecter mon pays',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  color: inkColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: inkColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      );

  Widget _lignePays(PaysPropose p) {
    final sel = identical(p, _pays) || (p.iso != null && p.iso == _pays.iso);
    return GestureDetector(
      onTap: () {
        Sons.appui();
        setState(() => _pays = p);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFEFEA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? coralColor : const Color(0xFFE3DCCB),
            width: sel ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(drapeauIso(p.iso), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                p.nom,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: inkColor,
                ),
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle_rounded,
                  color: coralColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _points() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i <= _pages.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _page ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _page
                    ? coralColor
                    : inkPaleColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      );

  Widget _barreBoutons() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            if (_page > 0)
              TextButton(
                onPressed: () {
                  Sons.retour();
                  _aller(_page - 1);
                },
                child: const Text(
                  'Retour',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: inkSoftColor,
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: 170,
              child: PushButton(
                onPressed: _derniere ? _commencer : () => _aller(_page + 1),
                color: coralColor,
                shadowColor: const Color(0xFFB93A2F),
                radius: 18,
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Center(
                  child: Text(
                    _derniere ? 'Commencer' : 'Suivant',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
