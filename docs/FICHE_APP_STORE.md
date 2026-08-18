# Remplir la fiche App Store — Erea

> Refait le 4 août 2026 d'après l'interface réelle d'App Store Connect,
> mis à jour le 17 août 2026 pour la version 1.1.
>
> **Où on en est.** La version **1.0.0** est partie à la revue le 14 août
> 2026 à 11 h 42 avec le build **90** ; la sortie est réglée sur
> *manuelle*, pour pouvoir la faire coïncider avec celle du Play Store.
>
> Le 15 août, Apple a demandé un complément (**Guideline 2.1 —
> Information Needed**) : une capture vidéo du parcours type, filmée sur
> un iPhone physique. Réponse envoyée le **18 août à 11 h 39** dans le
> fil de la soumission, avec `Erea.mov` en pièce jointe — l'examen
> reprend de là. Au passage, deux leçons sur ce fil de messages, payées
> en deux jours : depuis l'iPad (navigation privée, VPN), l'envoi
> échouait avec un « Une erreur s'est produite » sans détail ; depuis le
> Mac, en fenêtre Safari normale, **le même fichier est passé tel
> quel** — le « Traitement en cours » d'une vidéo dure de longues
> minutes, c'est normal, il aboutit. Mac + navigation normale + patience,
> et rien d'autre.
>
> La version **1.1** apporte la publicité et l'achat qui l'enlève. Elle
> change **quatre choses** dans cette fiche, et aucune n'est cosmétique :
>
> | Ce qui change | Où |
> |---|---|
> | La description ne peut plus promettre « sans publicité » | [Description](#description--4-000-caractères-texte-brut) |
> | La confidentialité passe de « aucune donnée » à une déclaration en règle | [Page 4](#page-4--confidentialité-de-lapp) |
> | La déclaration DSA passe de non-trader à **trader** | [Réglementations](#réglementations-et-autorisations-de-lapp-store) |
> | Un achat intégré à créer, et un accord à signer avant tout | [Page 3](#page-3--tarifs-et-disponibilité) |
>
> ⚠️ **Rien ne peut être testé avant la signature de l'accord
> « Applications payantes ».** Sans lui, la boutique reste muette,
> `Achat.disponible` reste faux, et l'offre ne s'affiche même pas dans
> l'app. C'est la première marche, pas la dernière.

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

**Droits relatifs au contenu** ✅ → clique sur « Configurer », puis
réponds **non** : ton app ne contient aucun contenu appartenant à des
tiers. Les textes, les dates et les visuels sont les tiens.

⚠️ **Sans ce champ, le bouton « Ajouter pour vérification » reste
inerte** et l'erreur renvoie ici. Il vit sur la page *Informations sur
l'app*, loin de la page de version où l'on croit tout remplir — ce
document l'a d'ailleurs longtemps donné pour fait alors qu'il ne l'était
pas, et c'est ce qui a bloqué l'envoi du 14 août.

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

**Législation sur les services numériques (DSA)** ⬜ **à refaire pour la
1.1** — obligatoire, et sans elle l'app n'est pas distribuée dans l'Union
européenne. La déclaration se fait au niveau du **compte** (App Store
Connect → Business), pas de l'app.

Tu t'es déclaré **non-trader** le 4 août 2026, ce qui était juste : l'app
était gratuite, sans publicité et sans achat intégré.

⚠️ **Ce n'est plus vrai avec la 1.1**, et il faut reprendre la
déclaration. Apple ne dit pas que monétiser fait *automatiquement* de toi
un trader : elle dit que le fait de tirer un revenu de l'app — achat
intégré, app payante ou **financée par la publicité** — est l'un des
facteurs qui l'établissent, avec le volume d'activité. Erea cumule
désormais publicité *et* achat intégré : le faisceau penche clairement du
côté trader, et se déclarer non-trader en encaissant de l'argent est le
genre de déclaration qu'on ne veut pas avoir à défendre.

Ce que le statut trader implique, et qu'il vaut mieux savoir **avant** de
cliquer :

- **adresse postale, téléphone et e-mail sont publiés sur ta fiche App
  Store** dans les 27 pays de l'UE. Ce n'est pas un effet de bord, c'est
  l'objet des articles 30 et 31 du DSA : permettre au public de joindre
  un professionnel. Pas d'option pour les masquer ;
- Apple **vérifie** ces coordonnées avant de les publier ;
- **les apps sans statut trader vérifié sont retirées de l'App Store
  européen** — Apple l'applique depuis le 17 février 2025. Ce n'est pas
  un avertissement théorique ;
- si tu ne veux pas exposer ton adresse personnelle, c'est **ici** que la
  question d'une structure ou d'une adresse de domiciliation se pose, et
  non après la déclaration.

📎 [Apple — Manage European Union Digital Services Act trader
requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)
· [Apps without trader status will be removed from the App Store in the
EU](https://developer.apple.com/news/?id=einwn76m)

**Licence de jeu pour le Vietnam** — laisse vide, c'est facultatif.

Clique sur **Enregistrer** en haut à droite.

---

# PAGE 2 — Distribution → iOS 1.0

## Captures d'écran ✅ *(déposées le 9 août 2026)*

⚠️ **Fie-toi aux dimensions affichées dans le cadre de dépôt**, elles
varient selon les appareils que l'app déclare supporter. Pour Erea,
App Store Connect demande :

| Onglet | Dimensions acceptées | Nombre |
|---|---|---|
| **iPhone** — écran de 6,9" | 1260 × 2736 px (portrait) · 2736 × 1260 px (paysage) | 1 à 10 |
| **iPad** — écran de 13" | 2064 × 2752 px (portrait) · 2752 × 2064 px (paysage) | 1 à 10 |

Formats acceptés : PNG ou JPEG, **sans transparence**.

Ces **deux tailles sont les seules obligatoires**, et elles suffisent :
App Store Connect dérive tout le reste. Les 6,5", 6,3", 12,9", 11" et
10,5" affichent alors « Illustrations utilisées : écran de 6,9 pouces »
et n'ont pas à être remplies. Un onglet replié n'est pas un oubli.

⚠️ Ce sont les tailles de 2026 : Apple demandait auparavant le 6,5"
(1242 × 2688). Le tableau ci-dessus a déjà été périmé une fois — vérifie
la page « Screenshot specifications » de l'aide App Store Connect avant
de t'y fier.

Seules les **trois premières** captures apparaissent sur les fiches
d'installation — ce sont elles qui décident du téléchargement.

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

SANS COMPTE, SANS INTERNET

Aucune inscription, aucun serveur : votre progression reste sur votre appareil, et le jeu fonctionne entièrement hors ligne — en voiture, dans le train, partout.

UNE PUBLICITÉ, UNE PARTIE SUR DEUX

Erea est gratuit et complet : tous les modes, tous les événements, rien de réservé à ceux qui paient. Une publicité s'affiche en quittant l'écran de fin, une partie sur deux — jamais pendant une manche, jamais avant que vous ayez vu votre score, et jamais dans le Défi du jour. Si elle vous gêne, un achat unique la retire pour toujours.

Bonne partie !
```

⚠️ **La 1.1 doit remplacer les deux derniers paragraphes**, faute de quoi
la fiche promet une app sans publicité en en affichant une : contradiction
que la revue relève, et qui vaut un rejet au titre de la règle 2.3
(*Accurate Metadata*). Le bloc ci-dessus est déjà la version corrigée.

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

## Publication de la version ✅ *(réglée sur manuelle)*

Deux choix : **Publier automatiquement**, et l'app sort dès qu'Apple l'a
validée, ou **Publier manuellement**, et tu déclenches la sortie toi-même.

C'est **manuelle** qui a été choisie pour la 1.0, afin de pouvoir faire
coïncider la sortie avec celle du Play Store. Conséquence à ne pas
oublier : une fois l'app validée par Apple, **elle ne sort pas toute
seule** — il faut revenir cliquer.

---

# PAGE 3 — Tarifs et disponibilité

- **Prix** : Gratuit ✅ *(et ça ne change pas : c'est la publicité qui
  paie)*
- **Disponibilité** : tous les pays ✅ *(le jeu est en français, mais ça
  couvre la Belgique, la Suisse, le Québec, le Sénégal, la Côte
  d'Ivoire…)*

## L'accord « Applications payantes » ✅ *(signé le 18 août 2026)*

Fait le 18 août, en une demi-heure, dans cet ordre — le chemin réel,
pour la prochaine fois :

1. **Business → Contrats** : un bandeau exige d'abord de confirmer
   l'**entité juridique** (nom, type « Particulier », adresse) ;
2. ligne « Contrat relatif aux applications payantes » →
   **accepter les conditions** ;
3. **Comptes bancaires** : le RIB (les champs « code banque/guichet »
   et « numéro de compte » se lisent dans l'IBAN : FR76 + 5 + 5 + 11 +
   clé) — vérification par Apple sous 24 h ;
4. **Formulaires fiscaux** : deux formulaires distincts, tous deux
   remplis en ligne — l'attestation de statut étranger (champ « Title » :
   `Individual`) puis le **W-8BEN** (numéro fiscal français en 6.a,
   date de naissance au format américain MM-JJ-AAAA, et la convention
   France–USA en partie II : article 12, 0 %, « Income from the sale of
   applications »). Aucun des deux n'est modifiable après envoi.

État au 18 août à midi : fiscal **Actif**, banque et contrat
**« Traitement en cours »** — le contrat passe à « Actif » seul, sous
24 h environ.

⚠️ Tant que le contrat n'est pas « Actif », le produit ne peut pas être
créé et la boutique reste muette (`Achat.disponible` faux) : l'app
n'affiche aucune offre, c'est voulu.

## L'achat intégré ⬜

**Monétisation → Achats intégrés → +**, puis :

| Champ | Valeur |
|---|---|
| Type | **Non consommable** *(il s'achète une fois, pour toujours)* |
| Nom de référence | `Erea sans publicité` *(interne, jamais affiché)* |
| ID de produit | `com.teiki.erea.sanspub` |
| Prix | **3,99 €** *(choisis le prix, App Store Connect déduit les 174 autres pays)* |
| Nom affiché (FR) | `Erea sans publicité` |
| Description (FR) | `Retire définitivement les publicités. Le jeu reste entier : rien ne se débloque, il n'y a rien à débloquer.` |

⚠️ **L'ID de produit doit être saisi au caractère près** : il est écrit en
dur dans `lib/core/achat.dart` (`Achat.idSansPub`), et un test le vérifie.
Une faute de frappe rend l'achat introuvable **sans aucun message
d'erreur** côté joueur.

Il faut aussi joindre une **capture de l'écran de réglages** montrant
l'offre, et l'achat doit être **soumis avec la version 1.1** (case à
cocher dans la page de la version) — sinon il reste en « Prêt à
soumettre » et n'est jamais examiné.

---

# PAGE 4 — Confidentialité de l'app ⬜ **à refaire entièrement**

⚠️ **C'est le changement le plus lourd de la 1.1, et le plus risqué.** La
réponse actuelle — « Non, nous ne collectons pas de données de cette
app. » — était exacte pour la 1.0. Avec AdMob elle devient **fausse**, et
une déclaration de confidentialité fausse est un motif de rejet immédiat
(règle 5.1.1), voire de retrait après publication.

**Tu perds le badge « Aucune donnée collectée ».** C'était un argument
réel auprès des parents ; c'est le prix de la monétisation, et il n'y a
pas de moyen de le garder tout en affichant de la publicité.

Réponds donc **« Oui, nous collectons des données de cette app »**, puis
déclare ce que le SDK de Google recueille. Google le publie lui-même :

| Catégorie Apple | Type | Usage | Lié à l'identité | Suivi |
|---|---|---|---|---|
| Identifiants | **ID d'appareil** | Publicité tierce | oui | **oui** |
| Données d'utilisation | **Données publicitaires** | Publicité tierce | oui | **oui** |
| Données d'utilisation | **Interactions avec le produit** | Publicité tierce | oui | **oui** |
| Localisation | **Localisation approximative** | Publicité tierce | oui | non |
| Diagnostic | **Données de performance** | Fonctionnalité de l'app | oui | non |
| Diagnostic | **Données de plantage** | Diagnostic | non | non |

Ce tableau vient de la page de Google, qui décrit en prose ce que le SDK
« peut recueillir » : adresse IP *(d'où la localisation approximative)*,
journaux de plantage non rattachés à l'utilisateur, données de
performance rattachées à l'utilisateur, identifiant publicitaire de
l'appareil, publicités vues, et interactions.

⚠️ **Vérifie case à case sur la page de Google au moment de remplir** :
c'est elle qui fait foi, elle change avec les versions du SDK, et Google
rappelle que la déclaration reste la responsabilité du développeur. Les
intitulés exacts d'App Store Connect peuvent différer de ma traduction.

📎 [Google — App Store data disclosure
(iOS)](https://developers.google.com/admob/ios/privacy/data-disclosure)

Deux choses qui ne changent pas :

- **Game Center** n'entre pas dans cette déclaration : c'est Apple qui
  gère l'identité et les scores, pas toi.
- **Tes propres données restent nulles** : pas de serveur, pas
  d'analytics, pas de rapport d'erreurs. Tout ce qui est déclaré
  ci-dessus est collecté *par Google*, et tu ne le vois jamais.

**URL de politique de confidentialité** :

```
https://teiki5320.github.io/erea/confidentialite.html
```

✅ La page a été mise à jour le 17 août 2026 : elle décrit la publicité,
les données que Google recueille, le consentement européen révocable et
l'achat qui supprime tout. Elle doit être **en ligne avant** l'envoi de
la 1.1 — la revue la lit.

---

# Envoyer à la revue

Quand tout est vert dans la colonne de gauche, clique sur **Ajouter à la
revue**.

Compte 24 à 48 heures. En cas de refus, Apple explique précisément quoi
corriger — ce n'est jamais définitif, et un rejet au premier envoi est
banal.

---

# Sortir la version 1.1

L'ordre compte : chaque étape dépend de la précédente.

1. ✅ **Signer l'accord « Applications payantes »** *(page 3)* — fait le
   18 août ; reste à attendre que la vérification bancaire le passe à
   « Actif », sous 24 h environ.
2. **Repasser la déclaration DSA en trader** *(page 1)*, en ayant décidé
   quelle adresse sera publique.
3. **Créer l'achat** `com.teiki.erea.sanspub` à 3,99 € *(page 3)*.
4. **Créer le bloc interstitiel iOS** dans AdMob — fait ✅, et les quatre
   identifiants réels sont déjà dans le code.
5. **Passer `pubspec.yaml` en `1.1.0`** et pousser sur `main` : Xcode
   Cloud produit le build.
6. **Créer la version 1.1** dans App Store Connect *(le numéro doit être
   identique à celui de `pubspec.yaml`, sinon le build est
   non-sélectionnable)*.
7. **Réécrire la description** *(page 2)* et **refaire la déclaration de
   confidentialité** *(page 4)*. Les textes sont prêts ci-dessus.
8. **Attacher l'achat intégré à la version**, avec sa capture d'écran.
9. **Tester sur un iPhone réel** : l'offre apparaît-elle ? l'achat
   passe-t-il en Sandbox ? « Restaurer mes achats » retrouve-t-il l'achat
   après réinstallation ? le formulaire de consentement s'affiche-t-il, et
   la ligne « Publicité personnalisée » permet-elle d'y revenir ?
10. **Envoyer à la revue.**

⚠️ La 1.0 doit être **publiée** avant que la 1.1 puisse partir : App
Store Connect n'accepte qu'une version en cours d'examen à la fois.

---

# Où en est chaque champ

| Élément | 1.0 | 1.1 |
|---|---|---|
| Nom, sous-titre, catégories | ✅ | inchangé |
| Classification par âge (4+), droits de contenu | ✅ | inchangé |
| Déclaration DSA | ✅ non-trader | ⬜ **à repasser en trader** |
| Texte promotionnel, mots-clés | ✅ | inchangés |
| Description | ✅ | ⬜ **à réécrire** (texte prêt) |
| URL d'assistance et de confidentialité | ✅ | inchangées |
| Politique de confidentialité en ligne | ✅ | ✅ refaite le 17 août |
| Droits d'auteur, coordonnées de revue, remarques | ✅ | inchangés |
| Prix (gratuit), disponibilité (175 pays) | ✅ | inchangés |
| Accord « Applications payantes » | — | ✅ signé le 18 août, activation en cours |
| Achat `com.teiki.erea.sanspub` | — | ⬜ **à créer** |
| Déclaration de confidentialité | ✅ « aucune donnée » | ⬜ **à refaire** |
| Game Center attaché à la version | ✅ | ⬜ à vérifier sur la 1.1 |
| Captures d'écran iPhone 6,9" + iPad 13" | ✅ | inchangées |
| Version dans `pubspec.yaml` | ✅ 1.0.0 | ⬜ **à passer en 1.1.0** |
| Sélection du build | ✅ build 90 | ⬜ |
| **Envoi à la revue** | ✅ **14 août 2026, 11 h 42** | ⬜ |
| Complément 2.1 (vidéo du parcours) | ✅ envoyé le 18 août, 11 h 39 | — |
| **Publication** | ⬜ manuelle, en attente d'Apple | ⬜ |
