# Remplir la fiche App Store — Erea

> **État au 30 octobre 2026.** La **1.0.5** (build **195**) est en
> ligne depuis le 21 octobre 2026 à 17 h 44, sous le nom **« Erea : Quiz
> d'histoire & frise »** ; la **1.0.7** (build **210**) a été
> soumise le 30 octobre 2026 au soir. Avant elle, la 1.0.4 (build 182) a été en ligne à partir du
> 15 octobre et la 1.0.2 (build 150) à partir du 8 septembre 2026, avec
> l'achat intégré **« Erea sans publicité »**, approuvé le même jour.
>
> Confidentialité de l'app refaite le 7 septembre (six types, la pub
> oblige). Côté AdMob, consentement RGPD et message IDFA publiés le
> 3 septembre. Cinquante identifiants SKAdNetwork dans `Info.plist`.
>
> Le compte s'affiche **TOA CORP** (nom d'affichage seulement, compte
> individuel, DSA **non-trader**). Le passage du compte en compte
> organisation a été demandé à Apple en octobre 2026 ; Apple a répondu le
> 23 octobre, Jean le 29 octobre : c'est Apple qui a la main.
>
> **L'état à jour des deux boutiques est dans `docs/PUBLICATION.md`** :
> c'est lui qui fait foi. Ce document-ci décrit la fiche, champ par
> champ.

> *Historique.* La 1.0 (build 90) a été soumise le 14 août 2026, refusée
> deux fois en demande d'informations (Guideline 2.1), puis publiée le
> 3 septembre. Les réponses et la marche à suivre sont dans
> **`docs/APP_REVIEW.md`**. La monétisation, longtemps appelée « 1.1 »
> dans ce document, est sortie en **1.0.2** : publicité, achat intégré,
> description sans « sans publicité », confidentialité refaite.
>
> Leçon gardée de ce fil de messages : pour joindre une vidéo à l'App
> Review, passer par le Mac en fenêtre Safari normale. Depuis l'iPad
> (navigation privée, VPN), l'envoi échouait sans détail. Le
> « Traitement en cours » d'une vidéo dure de longues minutes, c'est
> normal, il aboutit.

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
Erea : Quiz d'histoire & frise
```

*(Saisi avec la 1.0.4 : 30 caractères, le maximum. La 1.0 et la 1.0.2
s'appelaient « Erea » tout court, qui n'occupait que 4 caractères du
champ le plus fortement indexé par la recherche App Store.)*

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

**Législation sur les services numériques (DSA)** ⬜ **toujours
non-trader.** Cette fiche a longtemps annoncé le contraire, « repassée
en trader le 18 août » : c'était faux, vérifié dans la console le
7 septembre. En octobre 2026, Jean a demandé à Apple le passage de son
compte en compte organisation ; Apple a répondu le 23 octobre, Jean le
29 octobre, et la déclaration trader attend la fin de la migration. La déclaration
se fait à deux endroits : au niveau du **compte** (Business →
Conformité) et au niveau de l'app (Informations sur l'app →
Réglementations → DSA). Le même jour, le questionnaire **DAC7**
(« Directive relative à la coopération administrative, 7e révision »,
même page) a été rempli : Erea ne fournit pas de services personnels.

Tu t'es déclaré **non-trader** le 4 août 2026, ce qui était juste : l'app
était gratuite, sans publicité et sans achat intégré.

⚠️ **Ce n'est plus vrai depuis la 1.0.2**, et il faut reprendre la
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
  Store** dans les 27 pays de l'UE. ⚠️ **TOA CORP n'est que le nom
  d'affichage du compte**, obtenu en septembre 2026 : le compte reste
  individuel, donc Apple publierait l'adresse postale du titulaire, et
  non celle d'une société. Son complément d'adresse porte le nom
  d'une société sans rapport : à nettoyer avant toute déclaration
  trader, sous peine de le voir sur la fiche App Store de 27 pays. Ce n'est pas un effet de bord, c'est
  l'objet des articles 30 et 31 du DSA : permettre au public de joindre
  un professionnel. Pas d'option pour les masquer ;
- Apple **vérifie** ces coordonnées avant de les publier ;
- ⚠️ cette fiche a longtemps affirmé que « les apps sans statut trader
  vérifié sont retirées de l'App Store européen depuis le 17 février
  2025 ». **La page d'Apple ne dit pas cela.** Elle indique seulement
  qu'un développeur déclaré non-trader voit ses acheteurs européens
  informés que les droits du consommateur ne s'appliquent pas. Le risque
  réel — retrait ou simple mention — n'est pas établi ; ne pas le
  réaffirmer sans source ;
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

## Captures d'écran ✅ *(iPhone : sept captures légendées pour la 1.0.4 · iPad : celles du 9 août 2026)*

⚠️ **Fie-toi aux dimensions affichées dans le cadre de dépôt**, elles
varient selon les appareils que l'app déclare supporter. Pour Erea,
App Store Connect demande :

| Onglet | Dimensions acceptées | Nombre |
|---|---|---|
| **iPhone** — écran de 6,9" | 1260 × 2736 px (portrait) · 2736 × 1260 px (paysage) | 1 à 10 |
| **iPhone** — écran moyen | 1206 × 2622 px (portrait), déposé pour la 1.0.4 | 1 à 10 |
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

**Les sept captures iPhone de la 1.0.4, dans l'ordre** — légendées,
rangées dans `docs/visuels-app-store/captures-iphone/` (grand écran) et
`docs/visuels-app-store/captures-iphone-moyen/` (écran moyen) :

1. L'accueil
2. Une partie en cours, la frise bien visible
3. Une révélation
4. La Roulette des drapeaux
5. Le mode Chrono
6. Les packs à thèmes
7. L'écran de fin

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
• Packs à thèmes — Égypte et Orient ancien, Asie, Amériques, Afrique, Conquête de l'espace.

PLUS DE 1800 ÉVÉNEMENTS VÉRIFIÉS

De la construction des pyramides à la première photo d'un trou noir, chaque fait est daté avec soin et accompagné d'une anecdote « Le savais-tu ? ». Les événements accessibles aux enfants sont identifiés un par un : en mode Facile, votre enfant de 8 ans ne tombera pas sur la bataille de Bouvines.

UN JEU QUI PARLE DE VOUS

Choisissez votre pays au premier lancement : si vous jouez depuis l'Afrique de l'Ouest, la moitié des questions du mode Classique portera sur l'histoire africaine. Le jeu s'adapte, sans jamais vous enfermer.

CLASSEMENTS ET PROGRESSION

Comparez-vous au monde entier via Game Center, gagnez de l'XP, débloquez des succès et remplissez votre album de collection au fil des événements rencontrés.

ACCESSIBLE À TOUS

La frise se lit à VoiceOver : l'année est annoncée à chaque déplacement, et le résultat de chaque manche est lu en entier.

SANS COMPTE, SANS INTERNET

Erea ne demande aucune inscription et fonctionne entièrement hors ligne — en voiture, dans le train, partout. Une publicité s'affiche à la sortie d'une partie sur deux : jamais pendant une manche, jamais sur le Défi du jour.

UNE PUBLICITÉ, UNE PARTIE SUR DEUX

Erea est gratuit et complet : tous les modes, tous les événements, rien de réservé à ceux qui paient. Une publicité s'affiche en quittant l'écran de fin, une partie sur deux — jamais pendant une manche, jamais avant que vous ayez vu votre score, et jamais dans le Défi du jour. Si elle vous gêne, un achat unique la retire pour toujours.

Bonne partie !
```

Ce texte est celui corrigé le 7 septembre 2026 pour la 1.0.2. Celui de
la 1.0 promettait « sans publicité », faux dès l'arrivée de la pub, et
un mode Duel qui n'existe pas : deux motifs de rejet au titre de la
règle 2.3 (*Accurate Metadata*).

## Mots-clés ✅ — **100 octets**, séparés par des virgules sans espace

Liste de la 1.0.4, saisie le 15 octobre 2026 (96 octets). « quiz »,
« frise » et « histoire » en sont sortis : ils sont déjà dans le nom,
et un mot du nom ne compte pas deux fois.

```
chronologie,culture,générale,brevet,éducatif,afrique,collège,révision,trivia,siècle,année
```

Celle de la 1.0.2, pour mémoire :
`quiz,frise,chronologie,date,culture,générale,brevet,éducatif,afrique,collège,révision,enfant`.

⚠️ Apple compte en **octets**, pas en caractères : chaque lettre accentuée
en vaut deux. La liste en vigueur fait 89 caractères mais **96 octets**
(celle de la 1.0.2 en faisait 97) — elle passe de justesse, donc si tu la
modifies, retire un mot avant d'en ajouter un. Inutile d'y remettre
« histoire », « quiz » ou « frise » : le nom et le sous-titre sont déjà
indexés.

## URL d'assistance ✅ — obligatoire

```
https://erea.toakeur.com/support.html
```

## URL marketing ✅ — facultative

```
https://erea.toakeur.com/
```

## Version

```
1.0.7
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

## Build ✅ *(version en ligne : 1.0.5, build 195)*

Sélectionne la version envoyée par Xcode Cloud, qui apparaît une
quinzaine de minutes après la fin du build. Pour la 1.0.4, les builds
176 et 180 ont été refusés à l'import (ITMS-91064, manifeste de
confidentialité) ; le 182 est passé.

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

Dans **Notes** (champ « Remarques »), colle le texte en vigueur du §0 de
[`APP_REVIEW.md`](APP_REVIEW.md) : il est tenu à jour à chaque version, et
le recopier ici le ferait diverger.

## Publication de la version ✅ *(automatique)*

Deux choix : **Publier automatiquement**, et l'app sort dès qu'Apple l'a
validée, ou **Publier manuellement**, et tu déclenches la sortie toi-même.

La 1.0.2, la 1.0.4 et la 1.0.5 ont été publiées en **automatique** : l'app sort dès
l'approbation. La 1.0 avait été réglée sur manuelle, pour coïncider avec
le Play Store.

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

## L'achat intégré ✅ *(créé le 18 août 2026, identifiant Apple 6802621891)*

**Approuvé le 8 septembre 2026**, avec la 1.0.2 à laquelle il était
rattaché. Une 1.0.1 envoyée sans lui avait dû être retirée : Apple exige
qu'un premier achat intégré parte avec une version.

⬜ **Décision en suspens : le « Partage familial »** (interrupteur en
haut de la page du produit). L'activer permet à six membres d'une
famille de profiter de l'achat sans repayer — cohérent avec « le jeu
d'histoire en famille », mais moins de ventes par foyer. Vérifier la
réversibilité du choix chez Apple avant d'activer.

Les valeurs saisies :

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

Pour un premier envoi, il fallait joindre une **capture de l'écran de
réglages** montrant l'offre, et soumettre l'achat **avec une version**
(case à cocher dans la page de la version) : sinon il reste en « Prêt à
soumettre » et n'est jamais examiné.

---

# PAGE 4 — Confidentialité de l'app ✅ *(refaite et publiée le 7 septembre 2026)*

> Six types déclarés : identifiant de l'appareil, interaction avec le
> produit, données publicitaires, emplacement approximatif, données sur
> les pannes, données de performance. L'app affiche désormais « Données
> utilisées pour vous suivre » sur sa page produit. Le reste de cette
> section garde le détail des réponses, au cas où il faudrait les
> refaire.

⚠️ **Ce fut le changement le plus lourd de la 1.0.2, et le plus risqué.**
La réponse d'alors, « Non, nous ne collectons pas de données de cette
app. », était exacte pour la 1.0. Avec AdMob elle devient **fausse**, et
une déclaration de confidentialité fausse est un motif de rejet immédiat
(règle 5.1.1), voire de retrait après publication.

**Le badge « Aucune donnée collectée » est perdu.** C'était un argument
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
https://erea.toakeur.com/confidentialite.html
```

✅ La page a été mise à jour le 17 août 2026 : elle décrit la publicité,
les données que Google recueille, le consentement européen révocable et
l'achat qui supprime tout. Elle doit être **en ligne avant** chaque
envoi : la revue la lit.

---

# Envoyer à la revue

Quand tout est vert dans la colonne de gauche, clique sur **Ajouter à la
revue**.

Compte 24 à 48 heures. En cas de refus, Apple explique précisément quoi
corriger — ce n'est jamais définitif, et un rejet au premier envoi est
banal.

---

# Sortir une nouvelle version

L'ordre compte : chaque étape dépend de la précédente.

1. **Monter la version dans `pubspec.yaml`** et pousser sur `main` :
   Xcode Cloud produit le build. La montée se fait **dès qu'une version
   est approuvée**, dans le commit même qui note l'approbation : Apple
   refuse ensuite tout nouveau build au numéro approuvé (ITMS-90186).
2. **Créer la version** dans App Store Connect, au même numéro que
   `pubspec.yaml` *(sinon le build est non sélectionnable)*.
3. **Mettre à jour ce qui change** : description, mots-clés, captures,
   notes App Review (texte en vigueur dans `docs/APP_REVIEW.md` §0).
4. **Sélectionner le build**, vérifier que Game Center est attaché.
5. **Envoyer à la revue**, publication automatique.

⚠️ App Store Connect n'accepte qu'une version en cours d'examen à la
fois.

*Historique.* La sortie de la monétisation, préparée ici sous le nom
« 1.1 », est partie en **1.0.2** : accord « Applications payantes »
signé le 18 août, achat créé le même jour, description et
confidentialité refaites le 7 septembre, approbation le 8 septembre.
La déclaration DSA, elle, est restée non-trader.

---

# Où en est chaque champ *(tableau de la 1.0.4, 15 octobre 2026)*

Depuis, la 1.0.5 (build 195) a été approuvée et mise en ligne le
21 octobre 2026 avec les notes du §0 de `docs/APP_REVIEW.md` ; la 1.0.7
(build 210) a été soumise le 30 octobre 2026. L'état à jour est
dans `docs/PUBLICATION.md`.

| Élément | 1.0.2 (en ligne à partir du 8 septembre) | 1.0.4 (envoyée le 15 octobre) |
|---|---|---|
| Nom | ✅ « Erea » | ✅ « Erea : Quiz d'histoire & frise » |
| Classification par âge (4+), droits de contenu | ✅ | inchangés |
| Déclaration DSA | ⬜ non-trader | ⬜ non-trader, passage du compte en entreprise demandé en octobre |
| Mots-clés | ✅ liste ci-dessus | ✅ sans « quiz », « frise », « histoire » |
| Description | ✅ corrigée le 7 septembre | à vérifier dans la console |
| URL d'assistance, marketing et de confidentialité | ✅ | ✅ passées sur `erea.toakeur.com` |
| Achat `com.teiki.erea.sanspub` | ✅ approuvé le 8 septembre | déjà approuvé |
| Déclaration de confidentialité | ✅ refaite le 7 septembre, six types | inchangée |
| Captures d'écran | ✅ iPhone 6,9" + iPad 13" du 9 août | ✅ iPhone légendées (écran moyen et grand écran) ; iPad : celles d'août |
| Version dans `pubspec.yaml` | ✅ 1.0.2 | ✅ 1.0.4 (`1.0.4+5`) |
| Sélection du build | ✅ build 150 | ✅ build 182 |
| Notes App Review | — | ✅ réécrites (`docs/APP_REVIEW.md` §0) |
| **Envoi à la revue** | ✅ 7 septembre au soir | ✅ **15 octobre 2026, 12 h 51** |
| **Publication** | ✅ automatique, en ligne le 8 septembre à 12 h 19 | ✅ automatique, en ligne le 15 octobre à 14 h 01 |

La 1.0 (build 90, août 2026) est racontée dans `docs/APP_REVIEW.md`.
