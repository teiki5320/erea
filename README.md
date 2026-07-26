# Erea ⏳

**Erea** est un jeu de culture historique pour toute la famille, inspiré de GeoGuessr mais sur le **temps** : un événement apparaît (titre, emoji, courte description — sans la date), et vous devez le placer sur une grande frise chronologique allant de **3000 av. J.-C. à 2025** en faisant défiler un ruban. Plus votre réponse est proche de la vraie date, plus vous marquez de points.

▶️ **Jouer : [teiki5320.github.io/erea](https://teiki5320.github.io/erea/)**

## Modes de jeu

- **Classique** — 10 manches, 1 000 points max par manche, la 10ᵉ vaut **double** (11 000 max).
- **🗓️ Défi du jour** — les 10 mêmes événements pour tout le monde chaque jour (tirage basé sur la date, sans serveur), une tentative par jour, série de jours consécutifs 🔥.
- **⏱️ Chrono** — 90 secondes pour dater un maximum d'événements, +5 s par belle réponse.
- **👥 Duel à deux** — sur le même téléphone : chacun devine à son tour, révélation commune, vainqueur à la fin.

## Règles

- On choisit l'année en **faisant défiler la frise** comme un ruban (inertie, aiguille fixe au centre), avec une **minimap** pour se repérer, des boutons − / + pour l'ajustement fin, la molette et les flèches au clavier sur ordinateur.
- Frise à **échelle non linéaire** (le XXᵉ siècle occupe 30 % du ruban, l'Antiquité 20 %), bandes de couleur par époque avec leur nom en filigrane, **événements-repères** datés (🔺 pyramides, ⛵ 1492, 🗼 1889…).
- Barème : `tolérance = 5 % de l'ancienneté (entre 5 et 45 ans)` ; **0 point au-delà de 200 ans d'écart** ; le tout modulé par la difficulté (Facile ×2,2 · Normal · Difficile ×0,55 sans repères, +30 % d'XP). Réponse exacte = **PERFECT** 🎯.
- Chaque événement a un **niveau (1-3)** : en Facile on ne tire que des événements accessibles aux enfants, en Difficile des événements pointus.
- Après chaque réponse : la direction de l'erreur (« 40 ans trop tard ⏪ ») et une anecdote **« Le savais-tu ? »** vérifiée.

## Progression

- **XP et niveaux** avec titres (🐣 Apprenti du temps → 👑 Maître du temps → 🌟 Légende).
- **14 succès** à débloquer, **récompenses cosmétiques** par niveau (mascottes, thèmes de frise, styles de confettis).
- **Album de collection** : les événements rencontrés se dévoilent sur une frise chronologique.
- Records par catégorie × difficulté, le tout en `localStorage` (schéma versionné avec migrations).

## Contenu

613 événements vérifiés (dates contrôlées par relecture croisée) répartis en 5 catégories — Histoire de France, Monde, Sciences & inventions, Arts & culture, **Sport & vie quotidienne** — et 5 **packs à thèmes** jouables : 🏺 Égypte & Orient ancien, 🏯 Asie, 🌎 Les Amériques, 🚀 Conquête de l'espace, 🌍 Afrique & Moyen-Orient.

## Application Flutter

Le dossier [`erea_flutter/`](erea_flutter/) contient le portage Flutter en cours : la même base d'événements, les règles du jeu portées à l'identique (`SPEC.md`) et les premiers écrans. Le prototype web reste la référence jouable.

## Technique

- 100 % statique : un seul fichier `index.html` (HTML + CSS + JS vanilla), aucune dépendance hors Google Fonts. Sons en WebAudio (aucun fichier audio), lecture des cartes à voix haute (API Web Speech).
- Mobile-first : Pointer Events avec inertie et réglage fin, `prefers-reduced-motion` respecté, ARIA (curseur d'année pilotable au lecteur d'écran), zoom autorisé.
- `index-v8.html` est la version courante ; `index.html` en est la copie déployée sur GitHub Pages. Les fichiers `index-v1` à `index-v7` sont les versions précédentes, conservées en archive. Les évolutions futures incrémenteront la version (`index-v9.html`, etc.).
