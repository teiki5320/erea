# Erea 🏛️

**Erea** est un jeu de culture historique inspiré de GeoGuessr, mais sur le **temps** au lieu de l'espace : un événement apparaît (titre, emoji, courte description — sans la date), et vous devez le placer sur une grande frise chronologique allant de **3000 av. J.-C. à 2025**. Plus votre réponse est proche de la vraie date, plus vous marquez de points.

▶️ **Jouer : [teiki5320.github.io/erea](https://teiki5320.github.io/erea/)**

## Règles

- Une partie = **10 manches**, maximum **1 000 points** par manche (10 000 au total).
- On choisit l'année en **faisant défiler la frise** comme un ruban (avec inertie), aiguille fixe au centre ; boutons − / + pour l'ajustement fin.
- La frise utilise une **échelle non linéaire** : les époques récentes sont dilatées pour rester précises (le XXᵉ siècle occupe 30 % de la frise, l'Antiquité 20 %). Bandes de couleur par époque (Antiquité, Moyen Âge, moderne, contemporaine) et **événements-repères** (🔺 pyramides, ⛵ 1492, 🗼 1889…) pour se situer.
- La tolérance dépend de l'ancienneté (`tolérance = max(5 ans, 5 % de l'ancienneté)`) et de la **difficulté** : Facile 😌 (tolérance ×2,2), Normal 🙂, Difficile 🔥 (tolérance réduite, pas de repères).
- Réponse exacte = 1 000 points + **PERFECT** 🎯
- **Niveaux** : chaque partie rapporte de l'XP (bonus en Difficile) ; on grimpe d'Apprenti du temps 🐣 à Maître du temps 👑.
- 4 catégories : Histoire de France, Monde, Sciences & inventions, Arts & culture — ou tout mélangé.
- 160 événements vérifiés, records par catégorie × difficulté (localStorage).

## Technique

- 100 % statique : un seul fichier `index.html` (HTML + CSS + JS vanilla), aucune dépendance hors Google Fonts.
- Mobile-first : ruban tactile (Pointer Events + inertie), molette sur ordinateur, clavier (← → et Entrée), bouton ✕ avec confirmation pour quitter une partie.
- `index-v2.html` est la version courante ; `index.html` en est la copie déployée sur GitHub Pages. `index-v1.html` (design sombre « musée », curseur sur frise fixe) est conservé comme archive. Les évolutions futures incrémenteront la version (`index-v3.html`, etc.).
