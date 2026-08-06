# Erea ⏳

**Erea** est un jeu de culture historique pour toute la famille : un
événement apparaît — titre, illustration, courte description, mais pas
la date — et il faut le placer sur une grande frise allant de **3000 av.
J.-C. à aujourd'hui** en faisant défiler un ruban. Plus la réponse est
proche, plus on marque de points.

Le produit, c'est l'**application iOS** (dossier [`erea_flutter/`](erea_flutter/)).
Le jeu web de ce dépôt en est le prototype d'origine, conservé et
toujours jouable.

▶️ **Vitrine : [teiki5320.github.io/erea](https://teiki5320.github.io/erea/)**
· [Jouer dans le navigateur](https://teiki5320.github.io/erea/jeu.html)

## Modes de jeu *(application)*

- **Classique** — 10 manches, 1 000 points max par manche, la 10ᵉ vaut
  **double** (11 000 max), trois difficultés.
- **🗓️ Défi du jour** — les 10 mêmes événements pour tout le monde
  chaque jour (tirage basé sur la date, sans serveur), une tentative par
  jour, série de jours consécutifs 🔥.
- **⏱️ Chrono** — 10 secondes par question, pas une de plus.
- **🎡 Roulette des drapeaux** — un pays tiré au sort, une partie
  entière consacrée à son histoire.
- **👥 Duel à deux** — sur le même téléphone, chacun son tour.
- **🌍 Packs à thèmes** — Égypte & Orient ancien, Asie, Amériques,
  Afrique & Moyen-Orient, Conquête de l'espace.

## Règles

- On choisit l'année en **faisant défiler la frise** comme un ruban
  (inertie, aiguille fixe au centre), avec des boutons − / + pour
  l'ajustement fin.
- Frise à **échelle non linéaire** (le XXᵉ siècle occupe 30 % du ruban,
  l'Antiquité 20 %), bandes de couleur par époque, **événements-repères**
  datés (🔺 pyramides, ⛵ 1492, 🗼 1889…).
- Barème : `tolérance = 5 % de l'ancienneté (entre 5 et 45 ans)` ;
  **0 point au-delà de 200 ans d'écart** ; modulé par la difficulté
  (Facile ×2,2 · Normal · Difficile ×0,55 sans repères, +30 % d'XP).
  Réponse exacte = **PERFECT** 🎯.
- Chaque événement porte un **niveau (1-3)** : en Facile, le jeu ne
  pioche que dans les 191 faits les plus connus ; en Difficile, dans les
  plus pointus.
- Après chaque réponse : la direction de l'erreur (« 40 ans trop tard
  ⏪ ») et une anecdote **« Le savais-tu ? »** vérifiée.

## Progression

- **XP et niveaux** avec titres (🐣 Apprenti du temps → 👑 Maître du
  temps → 🌟 Légende).
- **Succès** à débloquer et **album de collection** : les événements
  rencontrés se dévoilent au fil des parties.
- **Classements mondiaux** via Game Center : défi du jour, série,
  Classique par difficulté, Chrono.
- Records par catégorie × difficulté, tout en local sur l'appareil.

## Contenu

**1 738 événements vérifiés**, répartis en 4 catégories — Pouvoir &
guerres, Sciences & inventions, Arts & culture, Vie quotidienne — et 5
packs à thèmes. Le jeu s'adapte à la région : depuis l'Afrique de
l'Ouest, la moitié des questions du mode Classique porte sur l'histoire
africaine.

## Confidentialité

Aucune donnée collectée : ni compte, ni publicité, ni traceur, ni
serveur. Le jeu fonctionne entièrement hors ligne. Voir
[`confidentialite.html`](https://teiki5320.github.io/erea/confidentialite.html).

## Organisation du dépôt

| Chemin | Rôle |
|---|---|
| `erea_flutter/` | **l'application iOS** — le produit |
| `index.html` | la vitrine publique (GitHub Pages) |
| `jeu.html` | le prototype web, toujours jouable |
| `support.html`, `confidentialite.html` | les deux pages exigées par l'App Store |
| `index-v1` … `index-v8.html` | archives des versions successives du prototype |
| `docs/` | infrastructure, marketing, fiche App Store |

## Technique *(prototype web)*

- 100 % statique, un seul fichier (HTML + CSS + JS vanilla), aucune
  dépendance hors Google Fonts. Sons en WebAudio, lecture des cartes à
  voix haute (API Web Speech).
- Mobile-first : Pointer Events avec inertie, `prefers-reduced-motion`
  respecté, ARIA (curseur d'année pilotable au lecteur d'écran).
- `index-v8.html` est la dernière version de travail ; `jeu.html` en est
  la copie déployée.
