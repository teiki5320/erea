# Remplir la fiche App Store — Erea

> Refait le 4 août 2026 d'après l'interface réelle d'App Store Connect,
> mis à jour le 5 août 2026 avec l'état réel de la saisie.
>
> **Où on en est : tout est rempli sauf les captures d'écran.** Il reste
> à les déposer, à sélectionner le build, puis à cliquer sur « Ajouter
> pour vérification ». Les valeurs des blocs gris ci-dessous sont celles
> qui ont été saisies.

L'interface découpe la fiche en **deux pages différentes**, et c'est ce
qui perd tout le monde :

| Page | Ce qu'elle contient |
|---|---|
| **Informations sur l'app** | ce qui ne change jamais : nom, sous-titre, catégories, âge |
| **iOS 1.0** *(colonne de gauche)* | ce qui appartient à cette version : captures, description, mots-clés, **droits d'auteur**, build |

Suis l'ordre ci-dessous, il correspond à l'ordre des écrans.

---

# PAGE 1 — Distribution → Informations sur l'app

## Informations localisables *(sélecteur « Français » en haut à droite)*

**Nom** — 30 caractères maximum

```
Erea — Devine l'année !
```

*(Tu as saisi « Erea » tout court, ce qui est valable. Le nom est le
champ le plus fortement indexé par la recherche App Store : la version
longue te fait remonter sur « devine » et « année ». À toi de choisir
entre visibilité et sobriété.)*

**Sous-titre** — 30 caractères maximum ✅ déjà rempli

```
Le jeu d'histoire en famille
```

## Informations générales

**Catégorie principale** → **Jeux**
Deux sous-catégories apparaissent alors, choisis :
- **Quiz**
- **Famille**

**Catégorie secondaire** → **Éducation**

**Droits relatifs au contenu** → clique sur « Configurer », puis réponds
**non** : ton app ne contient aucun contenu appartenant à des tiers. Les
textes, les dates et les visuels sont les tiens.

**Contrat de licence** → laisse le contrat type d'Apple.

## Classifications par âge ✅ *(4+ obtenu)*

⚠️ Ce n'est pas une page de cases à cocher mais un **assistant en sept
étapes**, chacune avec des questions oui/non. Pour Erea, la réponse est
**NON partout**. La septième étape affiche la classification calculée et
propose un remplacement : **garder « Non applicable »** — cocher
« Conçue pour les enfants » ferait basculer l'app dans la catégorie
Enfants de l'App Store, dont les règles interdisent notamment les
fonctionnalités tierces sans barrière parentale, Game Center compris.

Apple a refondu ce questionnaire : les paliers sont désormais 4+, 9+,
**13+, 16+, 18+** (12+ et 17+ ont disparu), et les questions sont
beaucoup plus détaillées. Clique sur « Configurer les classifications
par âge » et réponds ainsi :

| Catégorie | Réponse |
|---|---|
| Contrôles intégrés (contrôle parental, validation de l'âge) | Aucun |
| Capacités (accès web libre, contenu généré par les utilisateurs, réseaux sociaux) | Aucune |
| Thèmes matures (vulgarité, horreur, références à…) | Aucun |
| Médical ou bien-être | Aucun |
| Sexualité ou nudité | Aucune |
| Violence | **Aucune** |
| Activités basées sur le hasard | **Aucune** |

Résultat attendu : **4+**.

Deux réponses méritent une explication, au cas où tu hésiterais :

- **Violence** — le jeu évoque des guerres et des batailles, mais la
  question porte sur des *scènes* de violence, animées ou réalistes.
  Erea n'affiche que du texte et une frise. Donc aucune.
- **Activités basées sur le hasard** — la Roulette des drapeaux tire un
  pays au sort, mais la question vise les jeux d'argent, les simulations
  de casino et les coffres à butin. Rien de tout cela ici.

## Documents sur le chiffrement des apps

**Rien à faire.** C'est déjà déclaré dans le code de l'app
(`ITSAppUsesNonExemptEncryption = false` dans `Info.plist`). Ne charge
aucun document.

## Réglementations et autorisations de l'App Store

**Législation sur les services numériques (DSA)** ✅ *(déclaré non-trader
le 4 août 2026)* — obligatoire, et sans elle l'app n'est pas distribuée
dans l'Union européenne. La déclaration se fait au niveau du **compte**
(App Store Connect → Business), pas de l'app.

Tu dois déclarer si tu es « trader » (professionnel) ou non. Un
développeur particulier qui publie une app **gratuite, sans publicité et
sans achat intégré** peut se déclarer **non-trader**. C'est ton cas
aujourd'hui.

⚠️ Le jour où tu ajouteras « Erea + » (achat unique), tu deviendras
trader et il faudra repasser la déclaration, avec adresse postale et
téléphone qui seront **affichés publiquement** sur ta fiche dans l'UE.

**Licence de jeu pour le Vietnam** — laisse vide, c'est facultatif.

Clique sur **Enregistrer** en haut à droite.

---

# PAGE 2 — Distribution → iOS 1.0

## Captures d'écran ⬜ **← la seule chose qui manque**

⚠️ **Fie-toi aux dimensions affichées dans le cadre de dépôt**, elles
varient selon les appareils que l'app déclare supporter. Pour Erea,
App Store Connect demande :

| Onglet | Dimensions acceptées | Nombre |
|---|---|---|
| **iPhone** — écran de 6,5" | 1242 × 2688 ou 1284 × 2778 px (portrait) · 2688 × 1242 ou 2778 × 1284 px (paysage) | 1 à 10 |
| **iPad** | voir les dimensions indiquées dans l'onglet iPad | 1 à 10 |

Formats acceptés : PNG ou JPEG, **sans transparence**.

Seules les **trois premières** captures apparaissent sur les fiches
d'installation — ce sont elles qui décident du téléchargement.

Le lien « Afficher toutes les tailles dans le gestionnaire des visuels »
permet de déposer d'autres formats, mais les tailles ci-dessus
suffisent : Apple dérive les autres.

**Les 6 écrans à capturer, dans cet ordre** — les deux premiers sont les
seuls visibles sans faire défiler, ce sont eux qui décident du
téléchargement :

1. Une partie en cours, la frise bien visible
2. Une révélation réussie, idéalement un **PERFECT 🎯**
3. Le défi du jour
4. L'écran de fin avec la grille de partage
5. Le mode Chrono, chronomètre en vue
6. La Roulette des drapeaux

## Aperçu de l'app *(facultatif)*

Une vidéo de 15 à 30 s. À garder pour plus tard — mais le geste de
défilement de la frise s'y prêterait très bien.

## Texte promotionnel ✅ — 170 caractères, modifiable sans mise à jour

```
Nouveau : le mode Chrono, 10 secondes par question. Et un classement mondial pour chaque difficulté.
```

## Description ✅ — 4 000 caractères, texte brut

```
Un événement s'affiche. Une frise du temps défile sous votre doigt. En quelle année ?

Erea, c'est le jeu de culture historique pour toute la famille : pas de QCM, pas de réponses toutes faites — vous placez vous-même l'événement sur une grande frise qui va de 3000 av. J.-C. à aujourd'hui. Plus vous tombez juste, plus vous marquez de points.

LES MODES DE JEU

• Classique — 10 manches, trois difficultés. En Facile, uniquement des événements que tout le monde connaît ; en Difficile, de quoi occuper les passionnés.
• Défi du jour — les 10 mêmes questions pour tous les joueurs, une seule tentative par jour. Enchaînez les jours pour faire grandir votre série.
• Chrono — 10 secondes par question, pas une de plus.
• Roulette des drapeaux — un pays tiré au sort, une partie entière consacrée à son histoire.
• Duel à deux — sur un seul téléphone, chacun son tour.
• Packs à thèmes — Égypte et Orient ancien, Asie, Amériques, Afrique, Conquête de l'espace.

PLUS DE 1700 ÉVÉNEMENTS VÉRIFIÉS

De la construction des pyramides à la première photo d'un trou noir, chaque fait est daté avec soin et accompagné d'une anecdote « Le savais-tu ? ». Les événements accessibles aux enfants sont identifiés un par un : en mode Facile, votre enfant de 8 ans ne tombera pas sur la bataille de Bouvines.

UN JEU QUI PARLE DE VOUS

Choisissez votre pays au premier lancement : si vous jouez depuis l'Afrique de l'Ouest, la moitié des questions du mode Classique portera sur l'histoire africaine. Le jeu s'adapte, sans jamais vous enfermer.

CLASSEMENTS ET PROGRESSION

Comparez-vous au monde entier via Game Center, gagnez de l'XP, débloquez des succès et remplissez votre album de collection au fil des événements rencontrés.

SANS PUBLICITÉ, SANS COMPTE, SANS INTERNET

Erea ne collecte aucune donnée, n'affiche aucune publicité et ne demande aucune inscription. Le jeu fonctionne entièrement hors ligne — en voiture, dans le train, partout.

Bonne partie !
```

## Mots-clés ✅ — **100 octets**, séparés par des virgules sans espace

```
quiz,frise,chronologie,date,culture,générale,brevet,éducatif,afrique,collège,révision,enfant
```

⚠️ Apple compte en **octets**, pas en caractères : chaque lettre accentuée
en vaut deux. Cette liste fait 92 caractères mais **97 octets** — elle
passe de justesse, donc si tu la modifies, retire un mot avant d'en
ajouter un. Inutile d'y remettre « histoire », « jeu », « famille » ou
« année » : le nom et le sous-titre sont déjà indexés.

## URL d'assistance ✅ — obligatoire

```
https://teiki5320.github.io/erea/support.html
```

## URL marketing ✅ — facultative

```
https://teiki5320.github.io/erea/
```

## Version

```
1.0
```

## Informations générales sur l'app ✅ *(en bas de page)*

**👉 C'est ici que se trouve « Droits d'auteur »**, et non sur la page
précédente.

```
2026 Toa
```

L'année d'abord, puis le nom du détenteur. **Ne mets pas le symbole ©** :
App Store Connect l'ajoute lui-même à l'affichage.

*(Si ton compte développeur est enregistré sous ton nom complet, mets
plutôt celui-là : c'est ce qu'Apple affiche déjà comme vendeur.)*

## Build ⬜

Sélectionne la version envoyée par Xcode Cloud, qui apparaît une
quinzaine de minutes après la fin du build.

⚠️ **Deux pièges qui rendent un build non sélectionnable**, tous deux
rencontrés :

1. Le workflow Xcode Cloud était réglé sur « TestFlight (tests internes
   uniquement) » dans son action *Archiver*. Il faut **« App Store
   Connect »**, sinon les builds n'apparaissent jamais dans la liste.
2. Le numéro de version du build doit être **identique** à celui de la
   fiche : un build en `0.1.0` ne peut pas servir à une version `1.0.0`.

## Game Center

Clique sur **Configurer**, puis **ajoute les 6 classements** à cette
version :

```
erea.daily · erea.streak · erea.classic.facile
erea.classic.normal · erea.classic.difficile · erea.chrono
```

Sans cette étape, ils resteront en « Finaliser avant soumission » et ne
seront jamais publiés.

## Informations pour la revue ✅ *(non visibles du public)*

Trois champs obligatoires : **ton nom**, **ton e-mail**, **ton numéro de
téléphone**. Prépare-les, Apple les exige pour joindre le développeur
pendant l'examen.

Pas de compte de démonstration à fournir : l'app n'a pas de connexion.

Dans **Notes**, ce texte évitera un aller-retour avec le testeur :

```
L'app fonctionne entièrement hors ligne, sans compte ni inscription.

Les classements mondiaux passent par Game Center : la fenêtre de connexion apparaît à la fin de la première partie, jamais au lancement. Si Game Center est désactivé sur l'appareil de test, le jeu reste entièrement jouable — les classements sont simplement masqués.

Le Défi du jour n'est jouable qu'une fois par jour (c'est le principe du mode : les mêmes 10 questions pour tous les joueurs). Pour tester plusieurs parties, utilisez le mode Classique.
```

## Publication de la version ✅

Choisis **Publier automatiquement** — l'app sortira dès qu'Apple l'aura
validée.

---

# PAGE 3 — Tarifs et disponibilité ✅

- **Prix** : Gratuit
- **Disponibilité** : tous les pays *(le jeu est en français, mais ça
  couvre la Belgique, la Suisse, le Québec, le Sénégal, la Côte
  d'Ivoire…)*

---

# PAGE 4 — Confidentialité de l'app ✅

Réponds : **« Non, nous ne collectons pas de données de cette app. »**

C'est exact et vérifiable : aucun analytics, aucun traceur, aucun
serveur. Tu obtiens le badge **« Aucune donnée collectée »**, rare dans
les jeux et rassurant pour les parents.

Game Center ne change rien à cette réponse : c'est Apple qui gère
l'identité et les scores, pas toi.

**URL de politique de confidentialité** :

```
https://teiki5320.github.io/erea/confidentialite.html
```

---

# Envoyer à la revue

Quand tout est vert dans la colonne de gauche, clique sur **Ajouter à la
revue**.

Compte 24 à 48 heures. En cas de refus, Apple explique précisément quoi
corriger — ce n'est jamais définitif, et un rejet au premier envoi est
banal.

---

# Ce qu'il reste à préparer

| Élément | État |
|---|---|
| Nom, sous-titre, catégories | ✅ saisis |
| Classification par âge (4+), droits de contenu, DSA | ✅ faits |
| Texte promotionnel, description, mots-clés | ✅ saisis |
| URL d'assistance et de confidentialité | ✅ en ligne et saisies |
| Droits d'auteur, coordonnées de revue, remarques | ✅ saisis |
| Prix (gratuit), disponibilité (175 pays) | ✅ |
| Confidentialité « aucune donnée collectée » | ✅ publiée |
| Game Center attaché à la version | ✅ |
| **Captures d'écran iPhone + iPad** | ⬜ **il ne manque que ça** |
| Sélection du build | ⬜ après le prochain build |
