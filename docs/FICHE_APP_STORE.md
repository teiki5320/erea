# Remplir la fiche App Store — mode d'emploi

> Écrit le 4 août 2026. Tous les textes ci-dessous sont prêts à
> copier-coller dans App Store Connect. Les limites de caractères
> d'Apple sont respectées.

L'ordre compte : certaines sections en débloquent d'autres. Suis les
étapes dans l'ordre, coche au fur et à mesure.

---

## Étape 1 — Informations sur l'app *(valable pour toutes les versions)*

App Store Connect → **Erea** → Distribution → **Informations sur l'app**

**Nom** (30 caractères max) :
```
Erea — Devine l'année !
```

**Sous-titre** (30 caractères max) :
```
Le jeu d'histoire en famille
```

**Catégorie principale** : Jeux → sous-catégories **Quiz** et **Famille**
**Catégorie secondaire** : Éducation

**Droits d'auteur** :
```
2026 Teiki
```

**Classification par âge** : réponds **non** à toutes les questions du
questionnaire → tu obtiendras **4+**. C'est exact : aucun contenu
sensible, aucune interaction avec des inconnus (Game Center gère les
classements sans chat), pas de pub, pas d'achat.

---

## Étape 2 — Confidentialité *(la section qui fait ta différence)*

App Store Connect → Erea → **Confidentialité de l'app**

Réponds : **« Non, nous ne collectons pas de données de cette app. »**

C'est la stricte vérité et c'est vérifiable : aucun analytics, aucun
traceur, aucun serveur (voir `docs/INFRA.md`). Tu obtiens le badge
« Aucune donnée collectée » sur ta fiche — rare dans les jeux, et
rassurant pour les parents.

⚠️ Game Center ne change rien à cette réponse : c'est Apple qui gère
l'identité et les scores, pas toi.

**URL de politique de confidentialité** — champ **obligatoire**, même
sans collecte. Il te faut une page en ligne. Voir l'étape 6.

---

## Étape 3 — Tarifs et disponibilité

- **Prix** : Gratuit
- **Disponibilité** : tous les pays (le jeu est en français, mais rien
  n'empêche un francophone de l'étranger de le télécharger — et ça
  compte pour le Sénégal, la Côte d'Ivoire, la Belgique, le Québec…)
- **Distribution App Store** : cochée

---

## Étape 4 — La version 1.0

App Store Connect → Erea → **iOS 1.0** (colonne de gauche)

### Texte promotionnel (170 caractères, modifiable sans mise à jour)
```
Nouveau : le mode Chrono, 10 secondes par question. Et un classement mondial pour chaque difficulté.
```

### Description (4000 caractères max)
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

### Mots-clés (100 caractères max, séparés par des virgules SANS espace)
```
quiz,frise,chronologie,date,culture,générale,brevet,éducatif,afrique,collège,révision,enfant
```
*(92 caractères. Inutile d'y remettre « histoire », « jeu », « famille »
ou « année » : Apple indexe déjà le nom et le sous-titre.)*

### Nouveautés de cette version
```
Première version d'Erea. Bon voyage dans le temps !
```

### URL marketing
```
https://teiki5320.github.io/erea/
```

### URL de support
Champ **obligatoire**. Voir l'étape 6.

---

## Étape 5 — Captures d'écran

Deux tailles seulement sont exigées aujourd'hui ; Apple dérive les
autres automatiquement.

| Appareil | Dimensions exactes | Nombre |
|---|---|---|
| iPhone 6,9" | 1320 × 2868 px (portrait) | 3 minimum, 10 max |
| iPad 13" | 2064 × 2752 px (portrait) | 3 minimum, 10 max |

**Les 6 captures à faire, dans cet ordre** (l'ordre compte : les deux
premières sont les seules visibles sans faire défiler) :

1. Une partie en cours, la frise bien visible
2. Une révélation réussie — idéalement un **PERFECT 🎯**
3. Le défi du jour avec une série en cours 🔥
4. L'écran de fin avec la grille de partage
5. Le mode Chrono, chronomètre en vue
6. L'album de collection

**Comment les prendre :** ouvre le simulateur (Xcode → Open Developer
Tool → Simulator), choisis **iPhone 16 Pro Max** puis **iPad Pro 13"**,
lance l'app, et fais **Cmd + S** à chaque écran (la capture atterrit sur
le Bureau, déjà aux bonnes dimensions).

💡 Je peux aussi te les générer automatiquement aux deux formats depuis
le dépôt — dis-le-moi si tu préfères.

---

## Étape 6 — Les deux pages web obligatoires ✅

Apple exige une URL de **support** et une URL de **politique de
confidentialité**. Les deux sont écrites, en ligne sur le GitHub Pages
du dépôt, et affichent `erea.toa@gmail.com` comme contact :

**URL d'assistance**
```
https://teiki5320.github.io/erea/support.html
```

**URL de politique de confidentialité**
```
https://teiki5320.github.io/erea/confidentialite.html
```

À coller telles quelles dans App Store Connect (la première dans la
version 1.0, la seconde dans « Confidentialité de l'app »).

---

## Étape 7 — Rattacher le build et Game Center

1. Dans la version 1.0, section **Build** : choisis la version envoyée
   par Xcode Cloud (elle apparaît une fois le traitement terminé,
   environ 15 minutes après le build).
2. Section **Game Center** : clique sur **Configurer**, puis **ajoute
   les 6 classements** à cette version. Sans ça, ils resteront en
   « Finaliser avant soumission » et ne seront pas publiés.

---

## Étape 8 — Envoyer à la revue

Vérifie une dernière fois que tout est vert dans la colonne de gauche,
puis **Ajouter à la revue**.

Réponds **non** à « Utilise-t-elle un chiffrement ? » (c'est déjà
déclaré dans le code via `ITSAppUsesNonExemptEncryption`).

Compte 24 à 48 heures de délai. En cas de refus, Apple explique
précisément quoi corriger — ce n'est jamais définitif.

---

## Récapitulatif : ce qui bloque, et par qui

| Élément | Qui |
|---|---|
| Textes de la fiche (nom, description, mots-clés) | ✅ prêts ci-dessus, à copier |
| Captures d'écran | Toi (iPhone + iPad, après le build en cours) |
| Pages support + confidentialité | ✅ en ligne, URL ci-dessus |
| Classement par âge, prix, disponibilité | Toi (quelques clics) |
| Rattacher build + classements | Toi |
