# Erea 🏛️

**Erea** est un jeu de culture historique inspiré de GeoGuessr, mais sur le **temps** au lieu de l'espace : un événement apparaît (titre, emoji, courte description — sans la date), et vous devez le placer sur une grande frise chronologique allant de **3000 av. J.-C. à 2025**. Plus votre réponse est proche de la vraie date, plus vous marquez de points.

▶️ **Jouer : [teiki5320.github.io/erea](https://teiki5320.github.io/erea/)**

## Règles

- Une partie = **10 manches**, maximum **1 000 points** par manche (10 000 au total).
- La frise utilise une **échelle non linéaire** : les époques récentes sont dilatées pour rester précises (le XXᵉ siècle occupe 30 % de la frise, l'Antiquité 20 %).
- La tolérance dépend de l'ancienneté : se tromper de 30 ans sur un événement antique est excusable, pas sur un événement du XXᵉ siècle (`tolérance = max(5 ans, 5 % de l'ancienneté)`).
- Réponse exacte = 1 000 points + **PERFECT** 🎯
- 4 catégories : Histoire de France, Monde, Sciences & inventions, Arts & culture — ou tout mélangé.
- 160 événements vérifiés, meilleur score sauvegardé par catégorie (localStorage).

## Technique

- 100 % statique : un seul fichier `index.html` (HTML + CSS + JS vanilla), aucune dépendance hors Google Fonts.
- Mobile-first : drag tactile sur la frise (Pointer Events), boutons − / + pour l'ajustement fin, clavier (← → et Entrée) sur ordinateur.
- `index-v1.html` est le fichier de travail versionné ; `index.html` en est la copie déployée sur GitHub Pages. Les évolutions futures incrémenteront la version (`index-v2.html`, etc.).
