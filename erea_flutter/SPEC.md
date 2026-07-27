# Erea — Spécification du jeu (pour le portage Flutter)

Référence complète des règles validées par le prototype web (`../index.html`).
Les modules `lib/core/*` implémentent déjà les formules ; ce document fait foi
pour ce qui reste à porter.

## 1. Données (`assets/events.json`)

Tableau d'objets :

| Champ | Type | Description |
|---|---|---|
| `id` | int | Identifiant stable (ne jamais renuméroter). |
| `annee` | int | Année de l'événement, négatif = av. J.-C. Bornes : −3000 à 2025. |
| `titre` | string | Court, sans l'année ni indice de date. |
| `desc` | string | Une ligne, SANS indice chronologique (affichée pendant la manche). |
| `cat` | string | `france` \| `monde` \| `sciences` \| `arts` \| `quotidien`. |
| `emoji` | string | Un emoji. |
| `niveau` | int | 1 = connu des enfants · 2 = culture générale · 3 = pointu. |
| `fun` | string | Anecdote « Le savais-tu ? » (affichée APRÈS la réponse, peut citer des dates). |
| `pack` | string? | Optionnel : `egypte` \| `asie` \| `ameriques` \| `espace` \| `afrique`. |

Toutes les dates ont été vérifiées par relecture croisée (génération puis
vérification adversariale). Ne pas modifier une date sans re-vérification.

## 2. Frise à échelle non linéaire

Position ∈ [0, 1] sur le ruban, par segments (part de largeur) :

- −3000 → 0 : 20 %
- 0 → 1500 : 25 %
- 1500 → 1900 : 25 %
- 1900 → 2025 : 30 %

Interpolation linéaire à l'intérieur d'un segment (`lib/core/timeline_scale.dart`).
Ruban virtuel de 3 200 px, aiguille fixe au centre, inertie au relâcher
(décroissance ×0,94 par frame), réglage fin quand le doigt ralentit
(facteur 0,4 → 1 selon la vitesse). Minimap tapable sous le ruban.
Grandes époques (panneaux illustrés `assets/img/frise.webp`, 6 cellules) :
Âge du bronze ≤ −1200, Âge du fer ≤ −500, Antiquité ≤ 476,
Moyen Âge ≤ 1492, Époque moderne ≤ 1789, Époque contemporaine ensuite.
Les panneaux sont dessinés en tuiles dans la bande de chaque époque ;
repli sur des bandes de couleur unies si l'image n'est pas chargée.

## 3. Barème

- `tolérance = clamp(5 % × (2025 − année), 5, 45) × multiplicateur de difficulté`
- `points = round(1000 × exp(−écart / tolérance))`, plafonné à 1000
- **0 point si `écart ≥ 200 × multiplicateur de difficulté`**
- Difficultés : Facile ×2,2 (repères affichés, événements niveau ≤ 2, XP ×0,8) ·
  Normal ×1 · Difficile ×0,55 (pas de repères, niveau ≥ 2, XP ×1,3)
- **Manche 10 : points × 2** (total maximal 11 000)
- Réponse exacte : PERFECT (confettis, fanfare)

Réactions : ≥ 1000 PERFECT · ≥ 900 Incroyable · ≥ 700 Excellent · ≥ 500 Bien
joué · ≥ 250 Pas mal · ≥ 80 Pas loin · sinon Trop loin/Oups (sur points de base).
Afficher la direction : « N ans trop tôt ⏩ / trop tard ⏪ ».

## 4. Modes

- **Classique** : 10 manches, catégorie + difficulté choisies, anti-répétition
  (mémoriser ~80 derniers ids joués, piocher d'abord les non-vus).
- **Défi du jour** : graine = AAAAMMJJ (`lib/core/rng.dart`, mulberry32 identique
  bit à bit au web → même série que le site pour une même date). Catégorie
  « Tout », difficulté Normal, une tentative par jour, série de jours consécutifs 🔥.
- **Chrono** : 90 s au total, décompte uniquement pendant la phase de choix,
  +5 s si points de base ≥ 700, événements illimités, pas de manche ×2.
- **Duel local** : 2 joueurs sur le même appareil, même série. Par manche :
  J1 devine → écran « passe le téléphone » (sans révélation) → J2 devine →
  révélation commune (deux épingles). Pas d'XP ni de record.

## 5. Progression

- XP en fin de partie (sauf duel) : `round(total / 10 × XPmult)`, plafonné à 2000.
- Niveau : passer du niveau n au n+1 coûte `400 + (n−1) × 300` XP.
- Titres : 1 Apprenti du temps 🐣 · 2 Curieux d'histoire 🔍 · 3 Explorateur 🧭 ·
  4 Voyageur temporel ⏳ · 5 Aventurier 🗺️ · 6 Chasseur de dates 🎯 ·
  7 Historien 📚 · 9 Sage 🦉 · 10 Maître du temps 👑 · 13 Légende 🌟.
- Cosmétiques par niveau : mascottes (🦉 1, 🦖 3, 🧙 5, 🤖 8, 🐉 12), thèmes de
  frise (Classique 1, Bonbon 2, Océan 4, Forêt 7), confettis (Fête 1, Or 6, Étoiles 9).

## 6. Succès (14)

premiers pas (1 partie) · PERFECT · 3 PERFECT en une partie · 8000 pts ·
jouer les 5 catégories · 10 parties · 50 parties · marquer en Difficile ·
série quotidienne de 3 · de 7 · 12 évts en Chrono · terminer un duel ·
100 événements découverts · niveau 10.

## 7. Partage (sans spoiler)

Grille emoji par manche sur les points de base : 🎯 =1000 · 🟩 ≥700 ·
🟨 ≥350 · 🟥 sinon. Exemple :
`Erea du samedi 26 juillet ⏳ 8 240 / 11 000 · 🔥 3 jours` + grille + URL.

## 8. Design system

- Fond dégradé `#FFF7E8 → #EAF4FF` ; encre `#35406B` (soft `#5F6890`) ;
  corail `#F25B4D` ; jaune `#FFC94D` ; menthe `#45CFB2` ; ciel `#56A8F5` ;
  violet `#9B7BF7` ; orange `#FF9F43`.
- Polices : Baloo 2 (titres) + Nunito (interface).
- Boutons « pousse-bouton » (ombre dure 4-6 px dessous, enfoncement au tap),
  cartes blanches très arrondies (20-24 px), animations rebondissantes
  (`Curves.elasticOut` léger), confettis aux grands moments.
- Écran de jeu : carte en haut, frise grande et centrale, explications sous la
  frise, bouton en bas. Respecter « réduire les animations » du système.

## 9. Monétisation envisagée

Les packs (`pack` dans les données) sont l'unité de vente naturelle en
achats intégrés. Le socle (catégories) reste gratuit ; les packs à thèmes
peuvent être payants ou débloqués par le niveau.
