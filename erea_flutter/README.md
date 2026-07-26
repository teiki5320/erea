# Erea — application Flutter

Portage Flutter du jeu [Erea](https://teiki5320.github.io/erea/) (le prototype
web à la racine du dépôt reste la référence jouable).

## Démarrer

Les dossiers de plateformes (`ios/`, `android/`, `web/`) sont versionnés :
ils portent la configuration de publication (bundle id, team, orientations,
icônes). Rien à générer.

```bash
cd erea_flutter
flutter pub get
flutter analyze
flutter test
flutter run
```

## Publier sur iOS

```bash
flutter build ipa --release   # -> build/ios/ipa/erea.ipa
```

L'archive est signée pour l'App Store avec la team `K597U7X3FZ`.
L'upload se fait ensuite via Transporter ou l'Organizer de Xcode.

| Réglage | Valeur |
|---|---|
| Bundle identifier | `com.teiki.erea` |
| Nom affiché | Erea |
| Version / build | `0.1.0` / `1` (depuis `pubspec.yaml`) |
| Langue | français (`CFBundleDevelopmentRegion` + `CFBundleLocalizations`) |
| Orientations | portrait sur iPhone, portrait + paysage sur iPad |
| Chiffrement | `ITSAppUsesNonExemptEncryption = false` |

Pour monter le numéro de build, incrémenter le suffixe de `version:` dans
`pubspec.yaml` (`0.1.0+2`, etc.) : le projet Xcode le suit automatiquement.

### Xcode Cloud

Le dépôt est prêt pour Xcode Cloud : `ios/ci_scripts/ci_post_clone.sh`
installe Flutter, génère `Generated.xcconfig` et fait le `pod install`
avant l'archive. Un workflow qui surveille `main` peut donc builder et
livrer sur TestFlight sans Mac.

## Ce qui est déjà implémenté

- **`assets/events.json`** — toute la base d'événements vérifiée (dates,
  anecdotes, niveaux, packs). C'est l'actif principal du projet.
- **`lib/core/`** — les règles du jeu, portées à l'identique du web :
  échelle non linéaire de la frise, barème (tolérance, fenêtre de 200 ans,
  manche finale ×2), courbe d'XP et titres, PRNG mulberry32 compatible bit à
  bit avec le web (le défi du jour tire la même série que le site).
- **`lib/data/`** — chargement de la base, filtres catégorie/pack/difficulté,
  anti-répétition, persistance (XP, records, défi du jour) via
  `shared_preferences`.
- **`lib/game/game_controller.dart`** — la machine à états d'une partie.
- **`lib/ui/`** — accueil « Focus », écran de jeu avec le **ruban défilant**
  (CustomPainter + inertie), révélation animée, écran de fin.
- **`assets/fonts/`** — Baloo 2 et Nunito embarquées : aucun accès réseau
  dans l'app, elle fonctionne entièrement hors ligne.
- **`test/`** — 49 tests (règles du jeu, intégrité des 613 événements,
  interface jusqu'à une partie complète).

## À porter ensuite (décrit dans SPEC.md)

- Modes Chrono et Duel local (règles § 4)
- Succès, cosmétiques, album de collection (§ 5-6)
- Partage (grille emoji § 7), sons, haptique
- Achats intégrés sur les packs (§ 9)

`SPEC.md` est la spécification de référence : toutes les formules et règles
validées par le prototype web y sont consignées.
