# Erea ⏳

**Erea** est un jeu de culture historique pour toute la famille : un
événement apparaît — titre, illustration, courte description, mais pas
la date — et il faut le placer sur une grande frise allant de **3000 av.
J.-C. à aujourd'hui** en faisant défiler un ruban. Plus la réponse est
proche, plus on marque de points.

Le produit, c'est l'**application iOS et Android** (dossier [`erea_flutter/`](erea_flutter/)).
Le jeu web de ce dépôt en est le prototype d'origine, conservé et
toujours jouable.

▶️ **Vitrine : [erea.toakeur.com](https://erea.toakeur.com/)**
· [Jouer dans le navigateur](https://erea.toakeur.com/jeu.html)

## Modes de jeu *(application)*

- **Classique** — 10 manches, 1 000 points max par manche, la 10ᵉ vaut
  **double** (11 000 max), trois difficultés.
- **🗓️ Défi du jour** — les 10 mêmes événements pour tout le monde
  chaque jour (tirage basé sur la date, sans serveur), une tentative par
  jour, série de jours consécutifs 🔥.
- **⏱️ Chrono** — 10 secondes par question, pas une de plus.
- **🎡 Roulette des drapeaux** — un pays tiré au sort, une partie
  entière consacrée à son histoire.
- **🌍 Packs à thèmes** — Antiquité & Orient ancien, Asie, Les Amériques,
  Ciel & conquête spatiale, Afrique & Moyen-Orient.

## Règles

- On choisit l'année en **faisant défiler la frise** comme un ruban
  (inertie, aiguille fixe au centre), avec des boutons − / + pour
  l'ajustement fin.
- Frise à **échelle non linéaire** (le XXᵉ siècle occupe 30 % du ruban,
  l'Antiquité 20 %), grandes époques illustrées le long du ruban.
- Barème : `points = 1000 × exp(−écart / tolérance)`, avec une
  **tolérance de 30 ans** identique à toutes les époques, modulée par la
  difficulté (Facile ×2,2 · Normal · Difficile ×0,55, +75 % d'XP).
  Réponse exacte = **« PILE DESSUS ! »** 🎯.
- Chaque événement porte un **niveau (1-3)** : en Facile, le jeu ne
  pioche que dans les 268 faits les plus connus ; en Difficile, dans les
  plus pointus.
- Après chaque réponse : la bonne année en très grand, l'écart (« 40 ans
  d'écart ») et une anecdote **« Le savais-tu ? »** vérifiée.

## Progression

- **XP et niveaux** avec titres (🐣 Apprenti du temps → 👑 Maître du
  temps → 🌟 Légende).
- **Succès** à débloquer et **album de collection** : les événements
  rencontrés se dévoilent au fil des parties.
- **Classements mondiaux** via Game Center (iPhone) : défi du jour, série,
  Classique par difficulté, Chrono.
- Records par catégorie × difficulté, tout en local sur l'appareil.

## Contenu

**1 830 événements vérifiés**, répartis en 4 catégories — Pouvoir &
guerres, Sciences & explorations, Culture & croyances, Vie quotidienne &
sport — et 5 packs à thèmes. Le jeu s'adapte à la région : depuis un pays
d'Afrique, la moitié des questions du mode Classique porte sur l'histoire
africaine.

## Confidentialité

Ni compte, ni serveur : la progression reste sur l'appareil et le jeu
fonctionne entièrement hors ligne. L'app est financée par une publicité
(Google AdMob) qu'un achat unique retire — c'est le seul tiers qui
collecte quoi que ce soit. Voir
[`confidentialite.html`](https://erea.toakeur.com/confidentialite.html).

## Organisation du dépôt

| Chemin | Rôle |
|---|---|
| `erea_flutter/` | **l'application iOS et Android** — le produit |
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
