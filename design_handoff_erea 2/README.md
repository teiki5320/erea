# Handoff : Erea — fondu d'époque + habillage « Sticker Arcade »

**Cible : l'application Flutter `erea_flutter/`.** Le prototype web du dépôt reste une référence de règles, mais tout ce qui suit est à implémenter en Flutter.

## Overview

Refonte visuelle du jeu **Erea** (`teiki5320/erea`, branche `claude/erea-timeline-game-weermb`).
Les règles, le barème, l'échelle non linéaire et le rendu de la frise **ne changent pas**. Ce qui change :

1. **Le fond de l'écran suit l'époque visée**, en fondu continu piloté par la position du ruban (jamais une bascule).
2. **L'habillage « Sticker Arcade »** : contour d'encre + ombre dure sur tous les objets d'interface.
3. Quelques réglages de hiérarchie sur l'accueil, l'écran de manche et la révélation.

Fichiers concernés côté Flutter :

| Fichier | Ce qu'il devient |
|---|---|
| `lib/ui/` (accueil) | Refait selon **4a** : dérive d'époque, pastilles à contour d'encre, grille de 4 modes, mini-frise en pied d'écran |
| `lib/ui/` (écran de jeu) | Refait selon **3a** : fond fondu, carte, année sans bulle, frise pleine largeur |
| `lib/ui/` (révélation) | Verdict agrandi, deux épingles sur la frise figée, bandeau de combo |
| `lib/ui/tape_widget.dart` | **Presque inchangé** — seule évolution : il expose son fondu d'époque pour que l'écran l'utilise (voir plus bas) |
| `lib/core/*`, `lib/data/*`, `lib/game/*` | Inchangés, sauf `combo` (facultatif) |
| `assets/img/*` | Déjà présents, déjà déclarés dans `pubspec.yaml` — **aucun asset nouveau** |
| `SPEC.md` | À compléter d'un §10 « Fondu d'époque » reprenant l'algorithme ci-dessous |

## About the design files

Les fichiers de ce paquet sont des **références de design réalisées en HTML** : des prototypes qui montrent l'intention visuelle et le comportement, **pas du code à porter ligne à ligne**. `erea-design-references.dc.html` tourne sur un runtime de prototypage (`support.js`) qui n'a rien à voir avec le jeu.

Le travail consiste à **recréer ces écrans en Flutter**, avec les patterns déjà en place dans `erea_flutter/` : widgets composés, `CustomPainter` pour le ruban (comme `tape_widget.dart` le fait déjà), `Ticker` pour tout ce qui suit le temps, `shared_preferences` pour la persistance.

Toutes les valeurs ci-dessous sont données en **pixels logiques Flutter** (les maquettes sont dessinées sur une largeur de 372 dp, soit un iPhone standard moins les marges — les valeurs se transposent telles quelles).

## Fidelity

**Hi-fi.** Couleurs, typographies, tailles et espacements sont définitifs. La frise est déjà implémentée (`tape_widget.dart`) et reproduite à l'identique dans les maquettes — **ne pas la redessiner**.

## Ouvrir les références

Ouvrir `erea-design-references.dc.html` dans un navigateur. Canevas zoomable / déplaçable. De haut en bas :

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

Les 6 époques avec leur borne haute (année incluse), leur teinte et leur encre de libellé. Les teintes sont **déjà** dans `tape_widget.dart` (`_TapePainter._eraColors`) : les sortir dans un fichier partagé (`lib/ui/era_theme.dart`) pour que l'écran et le peintre lisent la même source.

| # | Nom | Borne | Teinte fond | Encre libellé | Asset décor |
|---|---|---|---|---|---|
| 0 | ÂGE DU BRONZE | ≤ −1200 | `0xFFF9EAC9` | `0xFFA97B36` | `bg-bronze.webp` |
| 1 | ÂGE DU FER | ≤ −500 | `0xFFF2EDCF` | `0xFF6E7A3A` | `bg-fer.webp` |
| 2 | ANTIQUITÉ | ≤ 476 | `0xFFE6DFF0` | `0xFF7A5FA8` | `bg-antiquite.webp` |
| 3 | MOYEN ÂGE | ≤ 1492 | `0xFFD8E6F5` | `0xFF3F76B5` | `bg-moyenage.webp` |
| 4 | ÉPOQUE MODERNE | ≤ 1789 | `0xFFFBE3C0` | `0xFFC2822C` | `bg-moderne.webp` |
| 5 | ÉPOQUE CONTEMPORAINE | ≤ 2026 | `0xFFF9D9D4` | `0xFFC9645A` | `bg-contemporaine.webp` |

### Algorithme

`frac` ∈ [0, 1] est la position du ruban déjà maintenue par le jeu (`TapeWidget.frac`).

```dart
/// Résultat du fondu : deux époques et le poids de la seconde.
class EraBlend {
  final int a, b;      // indices d'époque
  final double t;      // 0 → tout a, 1 → tout b (déjà adouci)
  const EraBlend(this.a, this.b, this.t);
}

const double kBlendW = 0.02; // demi-largeur du fondu, en fraction du ruban
                             // = 64 px sur les 3200 px du ruban virtuel

EraBlend eraBlendAt(double frac) {
  var a = eraIndexAt(fracToYear(frac));
  var b = a;
  var t = 0.0;
  for (var i = 0; i < eras.length - 1; i++) {
    final bf = yearToFrac(eras[i].to);
    if (frac > bf - kBlendW && frac < bf + kBlendW) {
      a = i;
      b = i + 1;
      t = (frac - (bf - kBlendW)) / (2 * kBlendW);
      break;
    }
  }
  final e = t * t * (3 - 2 * t); // smoothstep
  return EraBlend(a, b, e);
}
```

`yearToFrac`, `fracToYear` et `eras` existent déjà dans `lib/core/timeline_scale.dart`. **Ne rien réécrire.**

### Points non négociables

- **Le fondu n'est jamais une animation pendant le geste** : c'est une fonction pure de `frac`. Il suit le doigt, il est réversible, il ne peut pas être en retard sur le ruban.
  → Donc **jamais** d'`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher` ou `TweenAnimationBuilder` sur le fond pendant le glissement. Un `Opacity` (ou `Container(color: …)`) reconstruit à chaque `onFracChanged`, rien d'autre. Une transition de 300 ms déclenchée au franchissement produirait un clignotement sur un aller-retour du doigt — c'est exactement ce qu'il faut éviter.
- **Seul le lancement d'une manche** utilise une vraie animation : `AnimationController(duration: 320ms)`, `Curves.easeOut`, sur l'opacité, puisqu'il n'y a alors aucun geste à suivre.
- **`MediaQuery.of(context).disableAnimations`** (le « réduire les animations » du système, déjà respecté par l'app) : le fondu est conservé (c'est une opacité, pas un déplacement), la parallaxe du décor est coupée, la dérive automatique de l'accueil ne démarre pas.

### Ce qui fond / ce qui ne fond pas

| Fond avec `t` | Ne bouge jamais |
|---|---|
| Teinte de fond de l'écran | La carte blanche de l'événement |
| Texture de décor du haut d'écran | L'année |
| La bande de la frise (déjà géré par le peintre) | L'aiguille corail |
| La pastille d'époque sous l'année / sous le logo | Les boutons, contours et ombres |

Aucun contour, aucune ombre, aucun bouton ne prend jamais la couleur de l'époque : sinon l'écran vibre à chaque frontière.

### La texture de décor du haut d'écran

C'est le point le plus facile à rater. Ce n'est **pas** une image de fond, c'est une **texture** presque invisible.

```dart
// Une couche, à répéter pour A (opacité 1-t) et B (opacité t).
Positioned(
  top: 0, left: 0, right: 0, height: 200,        // 250 sur l'accueil
  child: IgnorePointer(
    child: Opacity(
      opacity: 0.30 * layerWeight,               // 0,30 MAXIMUM
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0.0, 0.23, 0.75],              // accueil : 0.0, 0.23, 0.76
        ).createShader(r),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Image.asset(
            eraAsset,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.32),  // ≈ "center 34%"
          ),
        ),
      ),
    ),
  ),
)
```

Résultat : la texture n'existe que derrière la barre du haut et s'éteint **avant** le haut de la carte blanche. Derrière la carte il n'y a que la teinte plate. **Si on distingue le décor derrière la carte, l'opacité ou le masque sont mal réglés** — c'est le défaut à surveiller en revue.

### Côté `tape_widget.dart`

Le peintre gère déjà les bandes d'époque et leurs décors : il n'y a **rien à changer** au rendu du ruban. Une seule évolution utile : exposer le fondu vers l'extérieur, pour que l'écran n'ait pas à le recalculer.

- soit l'écran appelle `eraBlendAt(frac)` de son côté (le plus simple, la fonction est pure) ;
- soit `TapeWidget` prend un `ValueChanged<EraBlend>? onBlendChanged`.

Préférer la première option : pas de nouveau canal d'état, pas de risque de désynchronisation.

---

## Écrans

### 4a — Accueil

**Rôle** : lancer une partie en un geste, et enseigner le geste de la frise avant même d'avoir joué.

`Stack` : [teinte A] · [teinte B à `t`] · [texture A] · [texture B] · [contenu].
Contenu = `Column`, `padding: EdgeInsets.fromLTRB(20, 22, 20, 0)`, `spacing`/`SizedBox` de 15.

1. **Barre du haut** — `MainAxisAlignment.spaceBetween`
   - Pastille profil : blanche, bordure `2.5` `0xFF35406B`, rayon `999`, `padding: (8, 5, 12, 5)`, `BoxShadow(offset: Offset(0,3), blurRadius: 0, color: 0xFF35406B)`. Contenu : 🦉 20 + colonne { « Explorateur » Baloo 2 w800 13 `0xFF35406B` / « NIV. 3 · 240/700 XP » Nunito w800 10 `0xFF8A90AC` }.
   - Pastille série : fond `0xFFFFC94D`, même bordure et ombre, `padding: (12, 6)`, « 🔥 5 » Baloo 2 w800 14 `0xFF35406B`.
2. **Bloc logo** — colonne centrée
   - Mascotte 🦉 42
   - « EREA » Baloo 2 w800 **60**, `letterSpacing: 2.4` — une couleur par lettre : `0xFFF25B4D`, `0xFFFFC94D`, `0xFF45CFB2`, `0xFF56A8F5` (4 `TextSpan` dans un `RichText`)
   - **Pastille d'époque** (voir plus bas)
3. **Panneau « Défi du jour »** — fond `0xFF35406B`, rayon 22, `padding: 16`, `BoxShadow(offset: Offset(0,6), blurRadius: 0, color: 0xFF232B4C)`
   - Titre « 🗓️ Défi du jour » Baloo 2 w800 18 blanc + « 27 JUILLET » Nunito w800 11 `0xFFFFC94D` `letterSpacing: 0.66`
   - 10 barres, `gap 5`, hauteur 9, rayon 999 : jouées `0xFF45CFB2` / `0xFFFFC94D` / `0xFFF25B4D` selon la qualité, à jouer `Colors.white.withOpacity(.22)`
   - Bouton `0xFFF25B4D`, rayon 16, `padding: 14`, Baloo 2 w800 21 blanc, ombre dure `0 5 0 0xFFB93A2F`
4. **Grille de 4 modes** — `GridView`/`Wrap` 2 colonnes, `gap 11`
   - Tuile : blanche, bordure `2.5` encre, rayon 20, `padding: 13`, ombre dure `0 5 0` encre, colonne `gap 3` : emoji 24 / titre Baloo 2 w800 17 encre / sous-titre Nunito w700 11 `0xFF8A90AC`
   - 🎯 Classique · record 8 240 — ⏱️ Chrono · record 14 évts — 👥 Duel · à deux, même tél. — 🚀 Packs · 5 thèmes (dégradé `LinearGradient(150°, 0xFF9B7BF7 → 0xFF56A8F5)`, textes blancs)
5. **Mini-frise en pied d'écran** — pleine largeur (sortir du padding), hauteur 92, `Border(top: BorderSide(width: 3, color: encre))`, décor de l'époque en tuiles de 62 de haut, voile blanc en bas, ligne de base, graduations, aiguille corail au centre. C'est le même peintre que le jeu, en hauteur réduite.

**Dérive automatique** : un `Ticker` fait avancer `homeFrac` de **+0,0183 par seconde** (≈ 3,5 px/s sur le ruban virtuel ; les 6 époques en ~15 min), en boucle (`% 1`). Le fond et la mini-frise suivent le même `eraBlendAt`.
Un `onHorizontalDragStart` sur la mini-frise **arrête le ticker** et passe la main au doigt (mêmes gestes que dans le jeu) : c'est le tutoriel implicite. Le ticker ne repart pas.
Si `disableAnimations`, le ticker ne démarre pas — on fige sur l'époque du dernier événement joué.

**Pastille d'époque** (sous le logo, et sous l'année dans le jeu) : blanche, bordure `2` encre (accueil) ou ombre douce `0 6 16 rgba(53,64,107,.12)` sans bordure (jeu), rayon 999, `padding: (12, 2)`, contenu = point de 8-9 rempli de la teinte d'époque et cerclé de son encre (`BoxShadow spreadRadius` ou `Container` avec `border`) + nom Nunito w900 10,5-11 `letterSpacing: 1.3` à l'encre de l'époque.
**Les deux pastilles (A et B) sont superposées** dans un `Stack` centré de 24-28 de haut, chacune dans un `Opacity` — c'est ce qui les fait fondre l'une dans l'autre. En Flutter, `Stack` + `Align(alignment: Alignment.center)` suffit : chaque pastille prend sa largeur intrinsèque (le piège du HTML n'existe pas ici).

### 3a — Manche

`Column`, `padding: EdgeInsets.fromLTRB(18, 20, 18, 22)`, `gap 14`, sur le même `Stack` de fond que l'accueil.

1. **Barre de manche** — « MANCHE 7/10 » Baloo 2 w800 13 `encre.withOpacity(.6)` `letterSpacing: 0.78` · **10 pastilles colorées** (hauteur 7, `gap 4`) à la place de l'ancien libellé de progression : `0xFF45CFB2` ≥ 700 pts, `0xFFFFC94D` ≥ 350, `0xFFF25B4D` en dessous, `encre.withOpacity(.16)` non jouées · score Baloo 2 w800 17 encre avec `FontFeature.tabularFigures()`
2. **Carte de l'événement** — `Colors.white.withOpacity(.92)`, rayon 24, `padding: 18`, `BoxShadow(offset: Offset(0,10), blurRadius: 26, color: rgba(53,64,107,.12))`
   - Étiquette de catégorie en débord (`Stack` + `Positioned(top: -10, left: 18)`, `clipBehavior: Clip.none`), fond de la catégorie (`0xFF45CFB2` pour Sciences), rayon 999, `padding: (12, 3)`, Nunito w900 10,5 blanc `letterSpacing: 0.84`
   - Ligne emoji 44 + titre Baloo 2 w800 **24** encre `height: 1.14`
   - Description Nunito w700 14 `0xFF5F6890` `height: 1.45`
3. **Année** — colonne centrée : pastille d'époque, puis le nombre **Baloo 2 w800 56** encre, `tabularFigures`.
   **La bulle autour de l'année disparaît** : la frise juste en dessous est déjà encadrée, un second cadre alourdit.
   Le nom de l'époque n'est plus affiché en gros : la pastille de 11 suffit, puisque la frise le porte déjà.
4. **La frise** — `TapeWidget` inchangé, mais **pleine largeur** : le sortir du padding (`Padding` négatif impossible → mettre la `Column` sans padding horizontal et re-padder chaque bloc, ou utiliser `OverflowBox`). Hauteur 150, sans arrondi puisqu'elle touche les bords.
5. **Réglage fin** — deux boutons 46 × 46, blancs, rayon 15, ombre douce `0 6 14 rgba(53,64,107,.12)`, « − » et « + » Baloo 2 w800 23, encadrant la **minimap** : hauteur 12, rayon 999, remplie du dégradé des 6 teintes aux bonnes proportions (`0xFFF9EAC9` 0-20 %, `0xFFF2EDCF` 20-27 %, `0xFFE6DFF0` 27-41 %, `0xFFD8E6F5` 41-63 %, `0xFFFBE3C0` 63-70 %, `0xFFF9D9D4` 70-100 %) + curseur corail de 4.
6. **Bouton** — `LinearGradient(100°, 0xFFF25B4D → 0xFFFF9F43)`, rayon 20, `padding: 17`, Baloo 2 w800 23 blanc, ombre `0 12 26 rgba(242,91,77,.35)`, poussé en bas (`Spacer()`). Libellé : **« Je place ici ! »**

### Révélation (voir 2a / 2b)

- **Le verdict explose** : mot Baloo 2 w800 24-28 `0xFF2AA88E`, puis les points **Baloo 2 w800 56** `0xFFF25B4D`, puis une seule ligne « 4 ans trop tard ⏪ · tolérance 8 ans » Nunito w800 13,5 `0xFF5F6890`.
- **La révélation se joue sur la frise**, pas dans un texte : le ruban se verrouille (`locked: true`, déjà prévu par `TapeWidget`) et porte **deux épingles** — « Toi · 1879 » (trait `0xFF8A90AC` de 3, pastille blanche au-dessus) et la vraie date (trait `0xFF45CFB2` de 4 cerclé de blanc, pastille menthe « 1883 🎯 » en dessous). Prévoir ~44 de marge au-dessus et ~46 en dessous du ruban pour les deux pastilles (elles débordent).
  Apparition : `scale 0.8 → 1`, 260 ms, `Curves.elasticOut` léger (cohérent avec le §8 de `SPEC.md`).
- **Carte « Le savais-tu ? »** blanche, rayon 24, titre Baloo 2 w800 18, texte Nunito w700 14,5 `height: 1.5`, puis deux jetons : « ＋ Album » (`0xFFEEF3FF` / `0xFF5F6890`) et « +82 XP » (`0xFFFFF3D9` / `0xFFA9761C`).
- **Combo (nouveau)** — bandeau `0xFFFFF3D9` : 🔥 + « 3 bonnes réponses d'affilée » + barre `LinearGradient(0xFFFFC94D → 0xFFF25B4D)` + « ×1,5 » `0xFFF25B4D`.
  Mécanique proposée : 3 réponses consécutives ≥ 700 points de base → ×1,5. **Attention au barème existant** (`SPEC.md` §3) : si le multiplicateur touche les points, il change les records et casse la comparabilité du défi du jour. Le plus sûr est de l'appliquer aux **XP** uniquement, et de n'afficher le ×1,5 que comme une récompense de progression. À trancher avant d'implémenter.
- Bouton « Manche suivante → » `0xFF35406B`, Baloo 2 w800 22 blanc.

---

## Interactions & comportement

| Élément | Comportement |
|---|---|
| Ruban | Inchangé : `GestureDetector` horizontal, inertie ×0,94/frame amortie au temps réel, réglage fin 0,4→1 selon la vitesse, minimap tapable |
| Fond de l'écran | Reconstruit à **chaque** `onFracChanged`, sans animation implicite |
| Lancement de manche | `AnimationController` 320 ms `Curves.easeOut` sur les deux couches |
| Dérive de l'accueil | `Ticker`, +0,0183 de `frac` par seconde, arrêté définitivement au premier `onHorizontalDragStart` sur la mini-frise |
| Boutons | « Pousse-bouton » : au `onTapDown`, `Transform.translate(Offset(0, 3))` et l'ombre dure passe de `0 5 0` à `0 2 0` ; retour au `onTapUp`/`onTapCancel`. 60-80 ms, pas plus |
| Révélation | Ruban verrouillé, deux épingles en `scale 0.8 → 1`, 260 ms |
| `disableAnimations` | Fondus conservés, parallaxe et dérive coupées, pousse-bouton réduit à un changement de teinte |

**Zones tactiles** : tous les boutons et tuiles font au moins 44 de haut. Les boutons − / + font 46 × 46.

## État

Rien de nouveau côté modèle, sauf :

- `frac` (déjà là, dans `GameController`) — pilote maintenant aussi le fond de l'écran.
- `homeFrac` — position de la dérive de l'accueil, locale à l'écran, non persistée.
- `homeDriftStopped` — booléen local, passe à vrai au premier contact.
- `combo` — compteur de réponses consécutives ≥ 700 points de base, remis à 0 sinon, non persisté entre les parties. À ajouter dans `GameController` **seulement** si la mécanique est retenue.

Le reste (XP, records, défi du jour, album, succès) est inchangé et reste en `shared_preferences`.

## Design tokens

**Couleurs d'interface** (déjà dans `SPEC.md` §8, inchangées) : encre `0xFF35406B`, encre douce `0xFF5F6890`, encre pâle `0xFF8A90AC`, corail `0xFFF25B4D`, jaune `0xFFFFC94D`, menthe `0xFF45CFB2`, ciel `0xFF56A8F5`, violet `0xFF9B7BF7`, orange `0xFFFF9F43`, menthe foncée (texte de verdict) `0xFF2AA88E`.
**Ombre dure** : `BoxShadow(offset: Offset(0, n), blurRadius: 0)` — n = 3 (petit), 5 (tuile), 6 avec `0xFF232B4C` (panneau navy), 10 (écran).
**Ombre douce** : `BoxShadow(offset: Offset(0, 10), blurRadius: 26, color: Color(0x1F35406B))`.
**Contour d'encre** : 2 (pastille d'époque), 2,5 (pastilles et tuiles), 3 (carte, frise, écran).
**Rayons** : 999 (pastilles), 15-16 (petits boutons), 20 (tuiles, boutons), 22-24 (cartes, panneaux), 34 (écran).
**Typographies** : Baloo 2 (600/700/800) pour titres, nombres et boutons ; Nunito (600/700/800/900) pour l'interface et le texte courant. **Déjà embarquées** dans `assets/fonts/` et déclarées dans `pubspec.yaml`.
**Échelle de type** : 60 logo · 56 année et points · 24 titre d'événement · 23 bouton principal · 17-18 titres de carte · 14,5 texte courant · 13 libellés · 10,5-11 pastilles (w900, `letterSpacing: 1.3`).
⚠️ En Flutter `letterSpacing` est en pixels logiques, pas en `em` : les `.12em` du CSS à 11 px valent **1,3**.
**Grille** : 14-15 entre blocs, 11-12 dans les grilles, padding d'écran 18-20.
**Chiffres** : partout où un nombre change (score, année, points), `fontFeatures: [FontFeature.tabularFigures()]` — sinon le texte tressaute.

## Assets

Tous **déjà présents et déclarés** dans `erea_flutter/pubspec.yaml`. Copiés ici dans `assets/` pour référence seulement. **Aucun asset nouveau n'est nécessaire.**

- `bg-bronze.webp`, `bg-fer.webp`, `bg-antiquite.webp`, `bg-moyenage.webp`, `bg-moderne.webp`, `bg-contemporaine.webp` — les 6 fonds d'époque : servent à la fois de décor de bande (déjà) et de texture de haut d'écran (nouveau).
- `anim-*.webp` — spritesheets des personnages (bronze 6 frames, fer 6, antiquité 7, moyen âge 5, moderne 10, contemporaine 5), inchangés.
- `frise.webp` — planche des 6 panneaux illustrés, repli quand le fond dédié n'est pas chargé, inchangé.

Les images sont déjà décodées une fois pour toute la vie de l'app par `_loadArt()` dans `tape_widget.dart` : **réutiliser ce cache** pour la texture de haut d'écran plutôt que de repasser par `Image.asset` (qui a son propre cache, mais on éviterait deux copies décodées de la même image). Le plus propre : sortir `_loadArt()` / `_eraBg` dans `lib/ui/era_art.dart`, et exposer `ui.Image? bgFor(int era)`.

## Tests

`test/` contient déjà 49 tests (règles, intégrité des 613 événements, interface jusqu'à une partie complète). À ajouter :

- `eraBlendAt` : renvoie `t == 0` au milieu d'une époque ; `t ≈ 0.5` exactement sur une frontière ; `t` monotone croissant sur la zone de fondu ; jamais hors [0, 1] ; `a == b` hors zone de fondu.
- Non-régression : les tests d'interface existants doivent passer sans modification — la refonte ne change aucune règle.

## Files

- `erea-design-references.dc.html` — le canevas de références (4a, 3a, 2a/2b, 1a/1b). **3a est jouable** : bouger le curseur montre le comportement attendu du fondu.
- `support.js` — runtime du prototype, nécessaire pour ouvrir le fichier ci-dessus. **À ne pas porter dans le jeu.**
- `assets/` — les 9 images, pour référence (elles sont déjà dans le dépôt).

Dans le dépôt, à lire avant d'implémenter :
- `erea_flutter/SPEC.md` — la spécification qui fait foi pour les règles (à compléter d'un §10 sur le fondu)
- `erea_flutter/lib/ui/tape_widget.dart` — la frise, sa géométrie et ses valeurs exactes
- `erea_flutter/lib/core/timeline_scale.dart` — `yearToFrac`, `fracToYear`, les segments, les époques
- `erea_flutter/README.md` — ce qui est déjà porté, ce qui reste à porter
