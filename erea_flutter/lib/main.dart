import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'core/achat.dart';
import 'core/pub.dart';
import 'core/region.dart' as region;
import 'core/retour.dart';
import 'core/sons.dart';
import 'data/events_repository.dart';
import 'data/store.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Heure et batterie en SOMBRE : tous les écrans d'Erea sont sur fond
  // crème. Sans cette ligne, iOS gardait le blanc par défaut tant qu'aucun
  // écran à AppBar n'avait été ouvert — l'heure était illisible sur toute
  // la présentation du premier lancement.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  try {
    // Les deux chargements sont indépendants : les mener de front rogne
    // quelques dizaines de ms sur le premier affichage.
    final chargements =
        await Future.wait([EventsRepository.load(), Store.load()]);
    final repo = chargements[0] as EventsRepository;
    final store = chargements[1] as Store;
    if (repo.events.isEmpty) {
      runApp(const _EcranPanne(
          message: 'La base d’événements est vide ou illisible.'));
      return;
    }
    Retour.actif = store.hapticsOn;
    Sons.actif = store.soundOn;
    // Le pays choisi au premier lancement nourrit le mélange régional du
    // Classique — posé ici pour être prêt avant la première partie.
    region.paysChoisiIso = store.paysChoisiIso;
    unawaited(Sons.preparer());
    // Boutique et régie, en tâche de fond : ni l'une ni l'autre ne doit
    // retarder l'affichage du jeu d'une milliseconde. La boutique en
    // premier — c'est elle qui dit s'il faut une régie du tout, et un
    // acheteur ne doit pas voir passer une publicité au lancement.
    unawaited(Achat.demarrer(store)
        .then((_) => Pub.demarrer(sansPub: store.sansPub)));
    runApp(EreaApp(repo: repo, store: store));
  } catch (e) {
    // Sans ce filet, la moindre défaillance laissait l'écran de lancement
    // figé à vie, sans message ni bouton.
    runApp(_EcranPanne(message: 'Erea n’a pas pu démarrer.\n$e'));
  }
}

/// Dernier recours : mieux vaut un message lisible qu'un écran crème figé.
class _EcranPanne extends StatelessWidget {
  const _EcranPanne({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: EreaColors.bg1,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⏳', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: EreaColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Réinstaller l’app devrait suffire à la remettre d’aplomb.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: EreaColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Palette du design system validé par le prototype web.
class EreaColors {
  static const ink = Color(0xFF35406B);
  static const inkSoft = Color(0xFF5F6890);
  static const coral = Color(0xFFF25B4D);
  static const yellow = Color(0xFFFFC94D);
  static const mint = Color(0xFF45CFB2);
  static const sky = Color(0xFF56A8F5);
  static const bg1 = Color(0xFFFFF7E8);
  static const bg2 = Color(0xFFEAF4FF);
}

class EreaApp extends StatefulWidget {
  const EreaApp({super.key, required this.repo, required this.store});

  final EventsRepository repo;
  final Store store;

  @override
  State<EreaApp> createState() => _EreaAppState();
}

class _EreaAppState extends State<EreaApp> {
  EventsRepository get repo => widget.repo;
  Store get store => widget.store;

  /// Premier lancement : la présentation puis le choix du pays, comme sur
  /// Kultiva. Les lancements suivants vont droit à l'accueil.
  late bool _onboarding = !store.onboardingVu;

  @override
  Widget build(BuildContext context) {
    // Palette explicite : fromSeed recalculait les teintes et rendait le
    // bouton principal marron au lieu du corail du design system.
    final base = ThemeData(
      useMaterial3: true,
      // Un AppBar reprend la main sur la barre d'état à chaque montage :
      // on lui impose le même style sombre qu'au démarrage.
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      colorScheme: const ColorScheme.light(
        primary: EreaColors.coral,
        onPrimary: Colors.white,
        secondary: EreaColors.sky,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE0EEFF),
        onSecondaryContainer: EreaColors.ink,
        tertiary: EreaColors.mint,
        onTertiary: Colors.white,
        surface: Colors.white,
        onSurface: EreaColors.ink,
        onSurfaceVariant: EreaColors.inkSoft,
        outline: Color(0xFFD8DDEF),
      ),
      scaffoldBackgroundColor: EreaColors.bg1,
    );
    return MaterialApp(
      title: 'Erea',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(textTheme: _textTheme(base.textTheme)),
      home: _onboarding
          ? OnboardingScreen(
              store: store,
              onTermine: () => setState(() => _onboarding = false),
            )
          : HomeScreen(repo: repo, store: store),
    );
  }
}

/// Typographie du design system : Baloo 2 pour les titres (display /
/// headline / title), Nunito pour tout le reste. Les polices sont
/// embarquées dans `assets/fonts` — aucun téléchargement au lancement.
TextTheme _textTheme(TextTheme base) {
  TextStyle? titre(TextStyle? s) => s?.copyWith(
        fontFamily: 'Baloo2',
        fontWeight: FontWeight.w700,
        color: EreaColors.ink,
      );
  TextStyle? corps(TextStyle? s) => s?.copyWith(
        fontFamily: 'Nunito',
        color: EreaColors.ink,
      );

  return base.copyWith(
    displayLarge: titre(base.displayLarge),
    displayMedium: titre(base.displayMedium),
    displaySmall: titre(base.displaySmall),
    headlineLarge: titre(base.headlineLarge),
    headlineMedium: titre(base.headlineMedium),
    headlineSmall: titre(base.headlineSmall),
    titleLarge: titre(base.titleLarge),
    titleMedium: titre(base.titleMedium),
    titleSmall: titre(base.titleSmall),
    bodyLarge: corps(base.bodyLarge),
    bodyMedium: corps(base.bodyMedium),
    bodySmall: corps(base.bodySmall),
    labelLarge: corps(base.labelLarge),
    labelMedium: corps(base.labelMedium),
    labelSmall: corps(base.labelSmall),
  );
}
