# Handoff : Erea — fondu d'époque + habillage « Sticker Arcade »

## Overview

Refonte visuelle du jeu **Erea** (frise chronologique, `teiki5320/erea`, branche `claude/erea-timeline-game-weermb`).
Le jeu, ses règles, son barème et sa frise **ne changent pas**. Ce qui change :

1. **Le fond de l'écran suit l'époque visée**, en fondu continu piloté par la position du ruban (jamais une bascule).
2. **L'habillage « Sticker Arcade »** : contour d'encre + ombre dure sur tous les objets d'interface.
3. Quelques réglages de hiérarchie sur l'écran de manche et l'écran de révélation (voir § Écrans).

Cible : le prototype web `index.html` (HTML/CSS/JS vanilla, aucune dépendance hors Google Fonts) — à sortir en `index-v9.html` puis copié sur `index.html` comme le veut la convention du dépôt. Le portage Flutter (`erea_flutter/`) suit ensuite, avec les mêmes valeurs.

## About the design files

Les fichiers de ce paquet sont des **références de design réalisées en HTML** : des prototypes qui montrent l'intention visuelle et le comportement, **pas du code de production à copier tel quel**. Le fichier `erea-design-references.dc.html` utilise un runtime de prototypage (`support.js`) qui n'a rien à faire dans le jeu.

Le travail consiste à **recréer ces écrans dans l'environnement existant du dépôt** :
- prototype web → HTML + CSS + JS vanilla dans le fichier unique `index-v9.html`, avec les patterns déjà en place (variables CSS `--ink`, `--coral`…, Pointer Events, `prefers-reduced-motion`, ARIA sur le curseur d'année) ;
- app Flutter → `lib/ui/` avec `CustomPainter`, comme `tape_widget.dart` le fait déjà.

## Fidelity

**Hi-fi.** Couleurs, typographies, tailles et espacements sont définitifs et donnés ci-dessous en valeurs exactes. La frise elle-même est déjà implémentée dans le dépôt (`lib/ui/tape_widget.dart` côté Flutter, son équivalent JS côté web) et est reproduite à l'identique dans les maquettes — **ne pas la redessiner**.

## Ouvrir les références

Ouvrir `erea-design-references.dc.html` dans un navigateur. Le document est un canevas : on peut zoomer/déplacer. De haut en bas :

| id | Contenu | Statut |
|---|---|---|
| **4a** | **Accueil** — Sticker Arcade + dérive d'époque automatique | ✅ à implémenter |
| **3a** | **Manche** — démo *jouable* du fondu (curseur sous le téléphone) | ✅ à implémenter |
| 2a / 2b | Étude de la mise en page autour de la frise réelle | référence |
| 1a / 1b | Premier tour d'exploration | archive, ne pas implémenter |

**3a est la référence de comportement** : bouger le curseur montre exactement ce que doit faire le fond.

---

## Le système de fondu d'époque

C'est le cœur de la refonte. Tout le reste en découle.

### Données

Les 6 époques, dans l'ordre, avec leur borne haute (année incluse), leur teinte de fond et leur encre de libellé. Les teintes sont celles déjà échantillonnées dans `tape_widget.dart` (`_eraColors`).

| # | Nom | Borne | Teinte fond | Encre libellé | Asset décor |
|---|---|---|---|---|---|
| 0 | ÂGE DU BRONZE | ≤ −1200 | `#F9EAC9` | `#A97B36` | `bg-bronze.webp` |
| 1 | ÂGE DU FER | ≤ −500 | `#F2EDCF` | `#6E7A3A` | `bg-fer.webp` |
| 2 | ANTIQUITÉ | ≤ 476 | `#E6DFF0` | `#7A5FA8` | `bg-antiquite.webp` |
| 3 | MOYEN ÂGE | ≤ 1492 | `#D8E6F5` | `#3F76B5` | `bg-moyenage.webp` |
| 4 | ÉPOQUE MODERNE | ≤ 1789 | `#FBE3C0` | `#C2822C` | `bg-moderne.webp` |
| 5 | ÉPOQUE CONTEMPORAINE | ≤ 2026 | `#F9D9D4` | `#C9645A` | `bg-contemporaine.webp` |

### Algorithme

`frac` ∈ [0, 1] est la position du ruban déjà maintenue par le jeu (aiguille au centre).

```
W = 0.02                      // demi-largeur de la zone de fondu, en fraction du ruban
                              // = 64 px sur les 3200 px du ruban virtuel

a = eraAt(frac); b = a; t = 0
pour chaque frontière i (i de 0 à 4) :
    bf = yearToFrac(bornes[i])
    si  bf - W < frac < bf + W :
        a = i ; b = i + 1
        t = (frac - (bf - W)) / (2 * W)
        arrêter
e = t * t * (3 - 2 * t)       // smoothstep : adoucit les deux extrémités

couche A (époque a) : opacité 1 - e
couche B (époque b) : opacité e
```

`yearToFrac` / `eraAt` existent déjà (`lib/core/timeline_scale.dart` et son équivalent JS). **Ne rien réécrire.**

### Points non négociables

- **Le fondu n'est jamais une transition temporelle** pendant le geste : c'est une fonction de `frac`. Il suit le doigt, il est réversible, il ne peut pas être en retard sur le ruban. Une transition CSS de 300 ms déclenchée au franchissement produirait un clignotement sur un aller-retour du doigt — c'est exactement ce qu'il faut éviter.
- **Seul le lancement d'une manche** utilise un vrai fondu temporel : 320 ms, `ease-out`, sur l'opacité, puisqu'il n'y a alors aucun geste à suivre.
- **`prefers-reduced-motion`** : le fondu est conservé (c'est une opacité, pas un déplacement), la parallaxe du décor est coupée, la dérive automatique de l'accueil ne démarre pas.

### Ce qui fond / ce qui ne fond pas

| Fond avec `e` | Ne bouge jamais |
|---|---|
| Teinte de fond de l'écran | La carte blanche de l'événement |
| Texture de décor du haut d'écran | L'année |
| La bande de la frise | L'aiguille corail |
| La pastille d'époque sous l'année (ou sous le logo) | Les boutons, contours et ombres |

Aucun contour, aucune ombre, aucun bouton ne prend jamais la couleur de l'époque : sinon l'écran vibre à chaque frontière.

### La texture de décor du haut d'écran

C'est le point le plus facile à rater. Ce n'est **pas** une image de fond, c'est une **texture** :

- `background-image` = l'asset `bg-<époque>.webp`, `background-size: cover`, `background-position: center 34%` (38 % sur l'accueil)
- hauteur 200 px (250 px sur l'accueil), ancrée en haut
- **opacité 0,30 × l'opacité de la couche** (donc 0,30 max)
- `filter: blur(2px)`
- masque d'atténuation : `mask-image: linear-gradient(180deg, #000 0 46px, transparent 150px)` (accueil : `#000 0 58px, transparent 190px`)

Résultat : la texture n'existe que derrière la barre du haut et s'est complètement éteinte **avant** le haut de la carte blanche. Derrière la carte il n'y a que la teinte plate. Si le décor est encore visible derrière la carte, l'opacité ou le masque sont mal réglés.

---

## Écrans

### 4a — Accueil

**Rôle** : lancer une partie en un geste, et enseigner le geste de la frise avant même d'avoir joué.

**Structure** (téléphone 372 × 760, `padding: 22px 20px 0`, colonne, `gap: 15px`) :

1. **Barre du haut** — `space-between`
   - Pastille profil : blanc, `border: 2.5px solid #35406B`, `border-radius: 999px`, `padding: 5px 12px 5px 8px`, `box-shadow: 0 3px 0 #35406B`. Contenu : 🦉 20 px + colonne { « Explorateur » Baloo 2 800 13 px `#35406B` / « NIV. 3 · 240/700 XP » Nunito 800 10 px `#8A90AC` }.
   - Pastille série : fond `#FFC94D`, même contour et ombre, `padding: 6px 12px`, « 🔥 5 » Baloo 2 800 14 px `#35406B`.
2. **Bloc logo** — colonne centrée
   - Mascotte 🦉 42 px
   - « EREA » Baloo 2 800, **60 px**, `letter-spacing: .04em` — une couleur par lettre : `#F25B4D`, `#FFC94D`, `#45CFB2`, `#56A8F5`
   - **Pastille d'époque** (voir plus bas)
3. **Panneau « Défi du jour »** — fond `#35406B`, `border-radius: 22px`, `padding: 16px`, `box-shadow: 0 6px 0 #232B4C`
   - Titre « 🗓️ Défi du jour » Baloo 2 800 18 px blanc + date « 27 JUILLET » Nunito 800 11 px `#FFC94D` `letter-spacing: .06em`
   - Grille de 10 barres, `gap: 5px`, hauteur 9 px, `border-radius: 999px` : jouées = `#45CFB2` / `#FFC94D` / `#F25B4D` selon la qualité, à jouer = `rgba(255,255,255,.22)`
   - Bouton `#F25B4D`, `border-radius: 16px`, `padding: 14px`, Baloo 2 800 21 px blanc, `box-shadow: 0 5px 0 #B93A2F`
4. **Grille de 4 modes** — `grid-template-columns: 1fr 1fr`, `gap: 11px`
   - Tuile : blanc, `border: 2.5px solid #35406B`, `border-radius: 20px`, `padding: 13px`, `box-shadow: 0 5px 0 #35406B`, colonne `gap: 3px` : emoji 24 px / titre Baloo 2 800 17 px `#35406B` / sous-titre Nunito 700 11 px `#8A90AC`
   - 🎯 Classique · record 8 240 — ⏱️ Chrono · record 14 évts — 👥 Duel · à deux, même tél. — 🚀 Packs · 5 thèmes (fond `linear-gradient(150deg, #9B7BF7, #56A8F5)`, textes blancs)
5. **Mini-frise en pied d'écran** — pleine largeur (déborde du padding), hauteur 92 px, `border-top: 3px solid #35406B`, décor de l'époque en tuiles hautes de 62 px, voile blanc en bas, ligne de base, graduations, aiguille corail au centre.

**Dérive automatique** : `frac` de l'accueil avance de **+0,0011 toutes les 60 ms** (≈ 3,5 px/s sur le ruban ; les 6 époques en ~15 min), en boucle. Le fond et la mini-frise suivent le même algorithme de fondu que le jeu.
Un appui sur la mini-frise **arrête la dérive** et passe la main au doigt (mêmes gestes que dans le jeu) : c'est le tutoriel implicite.
Avec `prefers-reduced-motion`, la dérive ne démarre pas — on fige sur l'époque du dernier événement joué.

**Pastille d'époque** (sous le logo, et sous l'année dans le jeu) : blanc, `border: 2px solid #35406B` (accueil) ou `box-shadow: 0 6px 16px rgba(53,64,107,.12)` sans contour (jeu), `border-radius: 999px`, `padding: 2px 12px`, `white-space: nowrap`, contenu = pastille ronde 8-9 px remplie de la teinte d'époque et cerclée de l'encre + nom en Nunito 900 10,5-11 px `letter-spacing: .12em` à l'encre de l'époque.
**Les deux pastilles (A et B) sont superposées** en `position: absolute; left: 50%; transform: translateX(-50%)` dans un conteneur de 24-28 px, chacune à son opacité — c'est ce qui les fait fondre l'une dans l'autre. Le `translateX(-50%)` est indispensable : sans lui, la pastille absolue hérite de la largeur de sa voisine et le texte passe à la ligne.

### 3a — Manche

Ordre vertical (`padding: 20px 18px 22px`, `gap: 14px`) :

1. **Barre de manche** — « MANCHE 7/10 » Baloo 2 800 13 px `rgba(53,64,107,.6)` · **10 pastilles colorées** (hauteur 7 px, `gap: 4px`) à la place de l'ancien libellé de progression : `#45CFB2` ≥ 700 pts, `#FFC94D` ≥ 350, `#F25B4D` en dessous, `rgba(53,64,107,.16)` non jouées · score total Baloo 2 800 17 px `#35406B` `font-variant-numeric: tabular-nums`
2. **Carte de l'événement** — `rgba(255,255,255,.92)`, `border-radius: 24px`, `padding: 18px`, `box-shadow: 0 10px 26px rgba(53,64,107,.12)`
   - Étiquette de catégorie en débord : `top: -10px; left: 18px`, fond de la catégorie (`#45CFB2` pour Sciences), `border-radius: 999px`, `padding: 3px 12px`, Nunito 900 10,5 px blanc `letter-spacing: .08em`
   - Ligne emoji 44 px + titre Baloo 2 800 **24 px** `#35406B` `line-height: 1.14`
   - Description Nunito 700 14 px `#5F6890` `line-height: 1.45`
3. **Année** — colonne centrée : pastille d'époque, puis le nombre **Baloo 2 800 56 px** `#35406B`, `tabular-nums`.
   **La bulle autour de l'année disparaît** : la frise juste en dessous est déjà encadrée, un second cadre alourdit.
   Le nom de l'époque n'est plus affiché en gros : la pastille de 11 px suffit, puisque la frise le porte déjà.
4. **La frise** — inchangée, mais **pleine largeur** (déborde du padding de 18 px de chaque côté), hauteur 150 px, sans arrondi. Tout le reste (tuiles miroir, voile blanc en bas de bande, pastille d'époque, ligne de base à 66 %, 3 poids de graduations, années sous la ligne, aiguille corail 4 px à halo blanc, personnages) est exactement celle du dépôt.
5. **Réglage fin** — deux boutons 46 × 46, blanc, `border-radius: 15px`, `box-shadow: 0 6px 14px rgba(53,64,107,.12)`, « − » et « + » Baloo 2 800 23 px, encadrant la **minimap** : hauteur 12 px, `border-radius: 999px`, remplie du dégradé des 6 teintes d'époque aux bonnes proportions (`#F9EAC9` 0-20 %, `#F2EDCF` 20-27 %, `#E6DFF0` 27-41 %, `#D8E6F5` 41-63 %, `#FBE3C0` 63-70 %, `#F9D9D4` 70-100 %) + curseur corail 4 px.
6. **Bouton** — `linear-gradient(100deg, #F25B4D, #FF9F43)`, `border-radius: 20px`, `padding: 17px`, Baloo 2 800 23 px blanc, `box-shadow: 0 12px 26px rgba(242,91,77,.35)`, collé en bas (`margin-top: auto`). Libellé : **« Je place ici ! »**

### Révélation (voir 2a / 2b)

- **Le verdict explose** : mot Baloo 2 800 24-28 px `#2AA88E`, puis les points **Baloo 2 800 56 px** `#F25B4D`, puis une seule ligne « 4 ans trop tard ⏪ · tolérance 8 ans » Nunito 800 13,5 px `#5F6890`.
- **La révélation se joue sur la frise**, pas dans un texte : le ruban se fige et porte **deux épingles** — « Toi · 1879 » (trait `#8A90AC` 3 px, pastille blanche au-dessus) et la vraie date (trait `#45CFB2` 4 px cerclé de blanc, pastille menthe « 1883 🎯 » en dessous). Prévoir ~44 px de marge au-dessus et ~46 px en dessous du ruban pour les deux pastilles.
- **Carte « Le savais-tu ? »** blanche, `border-radius: 24px`, titre Baloo 2 800 18 px, texte Nunito 700 14,5 px `line-height: 1.5`, puis deux jetons : « ＋ Album » (`#EEF3FF` / `#5F6890`) et « +82 XP » (`#FFF3D9` / `#A9761C`).
- **Combo (nouveau)** — bandeau `#FFF3D9` : 🔥 + « 3 bonnes réponses d'affilée » + barre de progression `linear-gradient(90deg, #FFC94D, #F25B4D)` + « ×1,5 » `#F25B4D`. Mécanique proposée : 3 réponses consécutives ≥ 700 pts de base → multiplicateur ×1,5 sur les points **affichés** de la manche suivante. À arbitrer avec le barème existant (§3 de `SPEC.md`) : si le multiplicateur touche le score final, il change les records — le plus sûr est de l'appliquer aux XP, pas aux points.
- Bouton « Manche suivante → » `#35406B`, Baloo 2 800 22 px blanc.

---

## Interactions & comportement

| Élément | Comportement |
|---|---|
| Ruban | Inchangé : Pointer Events, inertie ×0,94/frame, réglage fin 0,4→1 selon la vitesse, molette et flèches au clavier, ARIA `role="slider"` |
| Fond de l'écran | Recalculé à **chaque** changement de `frac`, sans transition CSS (voir algorithme) |
| Lancement de manche | Fondu temporel 320 ms `ease-out` sur les deux couches |
| Dérive de l'accueil | `setInterval` 60 ms, +0,0011 de `frac`, arrêtée au premier contact sur la mini-frise |
| Boutons | « Pousse-bouton » : au `:active`, `transform: translateY(3px)` et l'ombre dure passe de `0 5px 0` à `0 2px 0` |
| Révélation | Le ruban se verrouille, les deux épingles apparaissent (pastille : `scale(0.8) → 1`, 260 ms, léger rebond) |
| `prefers-reduced-motion` | Fondus conservés, parallaxe et dérive coupées |

## État

Rien de nouveau côté modèle, sauf :

- `frac` (déjà là) — pilote maintenant aussi le fond.
- `homeFrac` — position de la dérive de l'accueil, non persistée.
- `homeDriftPaused` — booléen, passe à vrai au premier contact.
- `combo` — compteur de réponses consécutives ≥ 700 pts de base, remis à 0 sinon, non persisté entre les parties.

Le reste (XP, records, défi du jour, album, succès) est inchangé et reste en `localStorage` / `shared_preferences`.

## Design tokens

**Couleurs d'interface** (déjà dans `SPEC.md` §8, inchangées) : encre `#35406B`, encre douce `#5F6890`, encre pâle `#8A90AC`, corail `#F25B4D`, jaune `#FFC94D`, menthe `#45CFB2`, ciel `#56A8F5`, violet `#9B7BF7`, orange `#FF9F43`, menthe foncée (texte de verdict) `#2AA88E`.
**Ombre dure** : `0 3px 0` (petit), `0 5px 0` (tuile), `0 6px 0 #232B4C` (panneau navy), `0 10px 0 #35406B` (écran).
**Ombre douce** : `0 10px 26px rgba(53,64,107,.12)`.
**Contour d'encre** : 2 px (pastille d'époque), 2,5 px (pastilles et tuiles), 3 px (carte, frise, écran).
**Rayons** : 999 px (pastilles), 15-16 px (petits boutons), 20 px (tuiles, boutons), 22-24 px (cartes, panneaux), 34 px (écran).
**Typographies** : Baloo 2 (600/700/800) pour les titres, nombres et boutons ; Nunito (600/700/800/900) pour l'interface et le texte courant. Déjà embarquées dans `erea_flutter/assets/fonts/`.
**Échelle de type** : 60 px logo · 56 px année et points · 24 px titre d'événement · 23 px bouton principal · 17-18 px titres de carte · 14,5 px texte courant · 13 px libellés · 10,5-11 px pastilles (`letter-spacing: .12em`, poids 900).
**Grille** : gouttière 14-15 px entre blocs, 11-12 px dans les grilles, padding d'écran 18-20 px.

## Assets

Tous déjà dans le dépôt, sous `erea_flutter/assets/img/` — copiés ici dans `assets/` pour référence. Aucun asset nouveau n'est nécessaire.

- `bg-bronze.webp`, `bg-fer.webp`, `bg-antiquite.webp`, `bg-moyenage.webp`, `bg-moderne.webp`, `bg-contemporaine.webp` — les 6 fonds d'époque : servent à la fois de décor de la bande et de texture du haut d'écran.
- `anim-*.webp` — spritesheets horizontaux des personnages (bronze 6 frames, fer 6, antiquité 7, moyen âge 5, moderne 10, contemporaine 5), inchangés.
- `frise.webp` — planche des 6 panneaux illustrés, utilisée en repli quand le fond dédié d'une époque n'est pas chargé.

Côté web, ces assets ne sont pas encore utilisés par `index.html` : il faudra les servir depuis le dépôt (les référencer en chemin relatif) ou les inliner en base64 pour rester sur le fichier unique. **Le fichier unique n'est pas une contrainte absolue** — un dossier `assets/` à côté de `index.html` sur GitHub Pages fonctionne très bien et évite d'alourdir le HTML de ~400 Ko.

## Files

- `erea-design-references.dc.html` — le canevas de références (4a, 3a, 2a/2b, 1a/1b). **3a est jouable** : bouger le curseur montre le comportement attendu du fondu.
- `support.js` — runtime du prototype, nécessaire pour ouvrir le fichier ci-dessus. **À ne pas porter dans le jeu.**
- `assets/` — les 9 images ci-dessus.

Dans le dépôt d'origine, les fichiers à lire avant d'implémenter :
- `erea_flutter/SPEC.md` — la spécification qui fait foi pour les règles
- `erea_flutter/lib/ui/tape_widget.dart` — la frise, sa géométrie et ses valeurs exactes
- `erea_flutter/lib/core/timeline_scale.dart` — `yearToFrac`, les segments, les époques
- `index.html` / `index-v8.html` — le prototype web courant
