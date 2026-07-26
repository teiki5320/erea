import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/events_repository.dart';
import 'data/store.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await EventsRepository.load();
  final store = await Store.load();
  runApp(EreaApp(repo: repo, store: store));
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

class EreaApp extends StatelessWidget {
  const EreaApp({super.key, required this.repo, required this.store});

  final EventsRepository repo;
  final Store store;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: EreaColors.coral,
        surface: EreaColors.bg1,
      ),
      scaffoldBackgroundColor: EreaColors.bg1,
    );
    return MaterialApp(
      title: 'Erea',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
          bodyColor: EreaColors.ink,
          displayColor: EreaColors.ink,
        ),
      ),
      home: HomeScreen(repo: repo, store: store),
    );
  }
}
