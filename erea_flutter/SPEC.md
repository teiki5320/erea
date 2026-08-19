# Erea — Spécification du jeu (pour le portage Flutter)

Référence complète des règles validées par le prototype web (`../index.html`).
Les modules `lib/core/*` implémentent déjà les formules ; ce document fait foi
pour ce qui reste à porter.

## 1. Données (`assets/events.json`)

Tableau d'objets :

| Champ | Type | Description |
|---|---|---|
| `id` | int | Identifiant stable (ne jamais renuméroter). |
| `annee` | int | Année de l'événement, négatif = av. J.-C. Bornes : −3000 à 2025 (la frise, elle, va jusqu'à 2026 = maxYear). |
| `titre` | string | Court, sans l'année ni indice de date. |
| `desc` | string | Une ligne, SANS indice chronologique (affichée pendant la manche). |
| `cat` | string | `pouvoir` \| `sciences` \| `arts` \| `quotidien` (voir `categories` dans `lib/data/events_repository.dart`). |
| `emoji` | string | Un emoji. |
| `niveau` | int | 1 = connu des enfants · 2 = culture générale · 3 = pointu. |
| `fun` | string | Anecdote « Le savais-tu ? » (affichée APRÈS la réponse, peut citer des dates). |
| `pack` | string? | Optionnel : `egypte` \| `asie` \| `ameriques` \| `espace` \| `afrique`. **Chaque pack tient au moins 15 parties (150 événements)** : c'est l'unité de vente, elle ne doit pas s'épuiser en quatre parties. Verrouillé par un test. |
| `continent` | string? | Optionnel : `afrique` \| `ameriques` \| `asie` \| `europe` \| `oceanie`. Réservé aux futures catégories géographiques. |
| `pays` | string? | Pays en français, renseigné avec `continent` (sauf quelques faits transnationaux). Alimente la future « roue des pays » : 113 pays couverts, dont 52 avec au moins 10 faits. |

Toutes les dates ont été vérifiées par relecture croisée (génération puis
vérification adversariale). Ne pas modifier une date sans re-vérification.

## 2. Frise à échelle non linéaire

Position ∈ [0, 1] sur le ruban, par segments (part de largeur) :

- −3000 → 0 : 20 %
- 0 → 1500 : 25 %
- 1500 → 1900 : 25 %
- 1900 → 2026 : 30 %

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

- `tolérance = clamp(5 % × (maxYear − année), 12, 90) × multiplicateur de difficulté` — avec `maxYear = 2026`
- `points = round(1000 × exp(−écart / tolérance))`, plafonné à 1000
- **0 point au-delà de `max(200 × mult, tolérance × 4,5)`** — la fenêtre
  s'élargit sur les faits très anciens, où 200 ans d'erreur ne sont pas
  une faute grossière
- Difficultés : Facile ×2,2 (XP ×0,75) · Normal ×1 · Difficile ×0,55 (XP ×1,75).
  Le plancher de tolérance est à 12 ans (et non 5) : à 5, décrocher le vert
  en Difficile sur un fait récent exigeait l'ANNÉE EXACTE et le combo y
  était inatteignable. Les multiplicateurs d'XP compensent le barème :
  sans ça, Difficile rapportait autant que Facile malgré sa promesse.
- Composition d'une partie (QUOTAS par niveau, `EventsRepository._quotas`) :
  Facile 10×N1 · Normal 3×N1 + 5×N2 + 2×N3 · Difficile 4×N2 + 6×N3.
  Facile ne vise QUE le niveau 1 : le niveau 2 n'y est qu'un repli, ouvert
  seulement si une sélection étroite manque de faits niveau 1.
  Des quotas, pas des tranches à épuiser : une tranche prioritaire plus
  grande que la partie rendrait le reste de la base inatteignable.
  Places non pourvues (petit pack) : report sur les niveaux de la
  difficulté, puis sur le reste de la base.
- Les « repères » (emoji d'ancrage du prototype web) ne sont PAS portés :
  ne rien promettre de tel dans les descriptions de difficulté.
- **Manche 10 : points × 2** (total maximal 11 000)
- Réponse exacte : PERFECT (confettis, fanfare)

Réactions : ≥ 1000 PERFECT · ≥ 900 Incroyable · ≥ 700 Excellent · ≥ 500 Bien
joué · ≥ 250 Pas mal · ≥ 80 Pas loin · sinon Trop loin/Oups (sur points de base).
Afficher la direction : « N ans trop tôt ⏩ / trop tard ⏪ ».

## 4. Modes

- **Classique** : 10 manches, catégorie + difficulté choisies, anti-répétition
  (mémoriser les ~300 derniers ids joués, épuiser TOUT le jamais-vu — tous
  niveaux confondus — avant de resservir quoi que ce soit).
- **Tour du monde** : 10 manches, 10 pays différents, deux par continent
  quand la base le permet. La roue tourne à CHAQUE manche et non une fois
  par partie : aucun pays n'a de quoi tenir dix manches à lui seul.
- **Défi du jour** : graine = AAAAMMJJ (`lib/core/rng.dart`, mulberry32) → même
  série pour tous les joueurs de l'app à une date donnée. La parité avec le
  prototype web n'est plus tenable (1 738 événements contre 613) et n'est pas
  un objectif. Catégorie « Tout », difficulté Normal, **une tentative par
  jour** : le verrou est posé au lancement (abandonner consomme la tentative),
  mais la série 🔥 n'est créditée qu'à un défi TERMINÉ, et une série est
  éteinte dès qu'un jour est sauté (`Store.effectiveStreak`).
- **Chrono** : 90 s au total, décompte uniquement pendant la phase de choix,
  +5 s si points de base ≥ 700, événements illimités, pas de manche ×2.
- **Duel local** : 2 joueurs sur le même appareil, même série. Par manche :
  J1 devine → écran « passe le téléphone » (sans révélation) → J2 devine →
  révélation commune (deux épingles). Pas d'XP ni de record.

## 5. Progression

- XP d'une MANCHE : `round(points / 10 × XPmult × (1,5 si combo))`. L'XP
  d'une partie est la SOMME de ces valeurs, plafonnée à 2000 — c'est
  exactement ce qui est annoncé au joueur à chaque révélation, donc ce qui
  doit lui être crédité. Ne jamais recalculer l'XP à partir du seul total :
  les arrondis divergeraient de l'affichage.
- Niveau : passer du niveau n au n+1 coûte `400 + (n−1) × 300` XP.
- Titres : 1 Apprenti du temps 🐣 · 2 Curieux d'histoire 🔍 · 3 Explorateur 🧭 ·
  4 Voyageur temporel ⏳ · 5 Aventurier 🗺️ · 6 Chasseur de dates 🎯 ·
  7 Historien 📚 · 9 Sage 🦉 · 10 Maître du temps 👑 · 13 Légende 🌟 ·
  16 Érudit 🎓 · 20 Archiviste 🗄️ · 25 Oracle 🔮 · 30 Gardien du temps ⏰ ·
  40 Mémoire du monde 🌍 · 50 Immortel 💎.
- Cosmétiques par niveau : mascottes (🦉 1, 🦖 3, 🧙 5, 🤖 8, 🐉 12), thèmes de
  frise (Classique 1, Bonbon 2, Océan 4, Forêt 7), confettis (Fête 1, Or 6, Étoiles 9).

## 6. Succès (14) — implémentés dans `lib/game/badges.dart`

Chacun se juge tout seul à partir de ce qui est persisté, et est évalué
APRÈS l'enregistrement de la partie (sinon « niveau 10 » et « 100
découvertes » manqueraient toujours d'une manche).

premiers pas (1 partie) · PERFECT · 3 PERFECT en une partie · 8000 pts ·
jouer les 4 catégories · 10 parties · 50 parties · marquer en Difficile ·
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

## 9. Monétisation (choisie en août 2026)

**Le jeu est complet et gratuit pour tous — rien n'est jamais bloqué.**
Une interstitielle s'affiche en quittant l'écran de fin, une partie sur
deux, jamais dans le Défi du jour (règle dans `lib/core/pub.dart`,
testée). Un achat unique non consommable, `com.teiki.erea.sanspub`
(3,99 €), retire la publicité et ne débloque rien d'autre
(`lib/core/achat.dart`).

L'idée antérieure de vendre les packs à l'unité est **écartée** : elle
contredirait la promesse « rien ne se débloque, il n'y a rien à
débloquer » affichée dans la description de l'achat.

## 10. Fondu d'époque & habillage « Sticker Arcade »

Handoff de référence : `../design_handoff_erea/` (écrans 4a accueil, 3a
manche, 2a/2b révélation).

- **Le fond de l'écran suit l'époque visée** : fonction PURE de `frac`
  (`lib/ui/era_theme.dart` — `eraBlendAt`, demi-fenêtre `kBlendW` = 0,02
  soit 64 px du ruban virtuel, adoucie par smoothstep). Jamais d'animation
  implicite pendant le geste ; seul le lancement d'une manche fait un
  fondu temporel de 320 ms `easeOut`.
- **Texture de décor du haut d'écran** : `bg-<époque>.webp`, opacité
  0,30 maximum, flou 2 px, masquée avant le haut de la première carte
  (dégradé 0 / 23 % / 75-76 %). Rien ne doit se voir derrière la carte.
- **Ce qui ne fond jamais** : carte blanche, année, aiguille corail,
  boutons, contours et ombres.
- **Dérive de l'accueil** : `homeFrac` avance de +0,0183/s en boucle,
  arrêtée définitivement au premier contact sur la mini-frise ; jamais
  démarrée si « réduire les animations ».
- **Combo** : 3 réponses consécutives ≥ 700 points de base → la manche
  suivante rapporte ×1,5 d'**XP** (somme des `RoundResult.xp`, plafonnée à
  `maxXpPerGame`). Le multiplicateur ne touche JAMAIS les points : le
  barème §3, les records et la comparabilité du défi du jour restent
  intacts. Une série rompue se DIT (« Série perdue — on repart de zéro »,
  bandeau grisé, ×1) plutôt que de disparaître sans explication.
- Le rendu du ruban (`tape_widget.dart`) est inchangé ; ses teintes
  d'époque vivent désormais dans `era_theme.dart` (source unique) et ses
  images dans le cache partagé `era_art.dart` (réutilisé par le fond).

## 11. La révélation : la frise DEVIENT le graphique

- **La frise domine les deux écrans.** Pendant le choix c'est l'outil de
  visée : 44 % de la hauteur disponible, bornée à [210, 310] px — soit
  ~280 px sur un iPhone 14 contre 150 px à l'origine. À la révélation :
  240 px. Le réglage fin et la mini-carte peuvent passer sous la ligne de
  flottaison sur les événements à longue description : c'est assumé, la
  frise elle-même reste le contrôle principal.
- **L'arrivée du verdict claque.** Badge et points entrent au ressort
  (`elasticOut`, 900 ms) : le badge jaillit de 0,3 à 1, les points suivent
  avec 14 % de décalage, montent de 26 px et rebondissent. Neutralisé par
  « réduire les animations ».
- **L'écart n'est pas raconté, il est MONTRÉ.** Les deux épingles (« Toi ·
  année » au-dessus du ruban, la vraie date en dessous) sont reliées par un
  trait corail qui porte le nombre d'années. Trait PLEIN dans la tolérance,
  POINTILLÉ au-delà. Sa longueur EST l'erreur : c'est ce qui fait
  comprendre l'échelle non linéaire du jeu sans jamais l'expliquer.
- **Les épingles ne se recouvrent jamais.** Sous 92 px d'écart à l'écran,
  chaque pastille se décale du côté opposé à l'autre ; au-delà, chacune est
  centrée sur son trait. C'est l'information la plus lue de l'écran.
- **Réussite et échec ne sont pas symétriques.** Dans la tolérance : badge
  menthe légèrement incliné, points en corail, carte « Le savais-tu ? ».
  Hors tolérance : badge BLANC (jamais rouge — on ne punit pas), points en
  gris, et la carte change de titre pour « Pour t'en souvenir » — c'est le
  moment où le joueur apprend vraiment.
