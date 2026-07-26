# Erea — application Flutter

Portage Flutter du jeu [Erea](https://teiki5320.github.io/erea/) (le prototype
web à la racine du dépôt reste la référence jouable).

## Démarrer

Ce dossier contient le code Dart et les assets, mais pas les dossiers de
plateformes (générés par Flutter). Sur ta machine :

```bash
cd erea_flutter
flutter create . --org com.teiki.erea --platforms=android,ios,web
flutter pub get
flutter analyze   # le code a été écrit hors SDK : corriger ce qu'il signale
flutter run
```

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

## À porter ensuite (décrit dans SPEC.md)

- Modes Chrono et Duel local (règles § 4)
- Succès, cosmétiques, album de collection (§ 5-6)
- Partage (grille emoji § 7), sons, haptique
- Achats intégrés sur les packs (§ 9)

`SPEC.md` est la spécification de référence : toutes les formules et règles
validées par le prototype web y sont consignées.
