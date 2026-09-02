# Publier Erea sur le Play Store

> Écrit le 9 août 2026. **Rien n'est publié côté Android** : ce document
> est la marche à suivre, et l'état de ce qui est déjà prêt.
>
> Le pendant iOS est `docs/FICHE_APP_STORE.md`. Les deux boutiques ne se
> ressemblent pas : Google pose trois questionnaires là où Apple en pose
> un, et sa politique Familles est plus exigeante que la classification
> 4+ obtenue sur l'App Store.

## Où on en est

| | |
|---|---|
| Identifiant `com.teiki.erea`, identique à iOS | ✅ dans `android/app/build.gradle.kts` |
| Clé de signature | ✅ créée le 14 août 2026 (`~/erea-upload.jks` + `key.properties`, hors dépôt) — **à sauvegarder ailleurs que sur le Mac** |
| App Bundle signé qui se construit | ✅ reconstruit le 20 août 2026 : 58,5 Mo, certificat `CN=Toa` — voir §1 |
| Autorisation de notification Android 13 demandée | ✅ dans `lib/core/rappels.dart` |
| Icône 512 × 512 et bandeau 1024 × 500 | ✅ dans `docs/play/` |
| Captures d'écran Android (1080 × 2160) | ✅ sept dans `docs/play/captures/` |
| Titre, descriptions | ✅ rédigés plus bas |
| Compte Google Play Console | ✅ créé le 20 août 2026, type **personnel** — voir §2 |
| Application créée dans la console | ✅ 3 septembre 2026 — nom `Erea`, package `com.teiki.erea`, type Jeu, sans frais |
| **12 testeurs pendant 14 jours** | ⬜ **le chemin critique : rien ne l'accélère, à lancer en premier** |
| Appareil Android physique (exigé par la validation) | ✅ Pixel 8a commandé le 20 août 2026 |
| Trois questionnaires | ⬜ *(le §5 a changé avec la pub ; le public cible est tranché : 13 ans et plus)* |
| Phrase « votre enfant de 8 ans » à retirer de la description Play | ⬜ *(voir §5)* |
| Classements Play Games | ⬜ *(facultatif, voir §7)* |

---

## 1. La clé de signature ✅ *(créée le 14 août 2026)*

Fait — la marche ci-dessous reste pour mémoire, au cas où il faudrait la
recréer sur une autre machine. `android/app/build.gradle.kts` lit
`android/key.properties`, que git ignore. Tant que ce fichier n'existe
pas, la release est signée avec les clés de debug : l'app se lance, mais
Google la refuse. C'est voulu — un build publiable exige la vraie clé.

```bash
keytool -genkey -v -keystore ~/erea-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias erea
```

**Vérifier qu'un bundle est signé avec elle**, et non avec la clé de
debug — le contrôle qui évite un refus au téléversement :

```bash
keytool -J-Duser.language=en -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Doit répondre `Owner: CN=Toa, O=Toa, L=Paris, C=FR`, empreinte SHA‑1
`5A:8A:57:C8:47:67:CB:B3:1B:78:33:98:C4:18:F8:14:98:9B:BA:E0`, valide
jusqu'en 2053. Si le propriétaire est `CN=Android Debug`, c'est que
`key.properties` n'a pas été lu et Google refusera l'envoi.

*(L'option `-J-Duser.language=en` n'est pas un caprice : en français,
`keytool` plante sur un défaut de formatage au lieu d'afficher le
certificat.)*

Puis `erea_flutter/android/key.properties`, **jamais commité** :

```properties
storePassword=…
keyPassword=…
keyAlias=erea
storeFile=/chemin/absolu/vers/erea-upload.jks
```

⚠️ **Cette clé ne se remplace pas.** La perdre, c'est perdre la
possibilité de mettre à jour l'app — définitivement, pour tous ceux qui
l'ont installée. Sauvegarde-la ailleurs que sur la machine de
développement, et note les mots de passe au même endroit.

Active **Play App Signing** au premier envoi : Google conserve alors la
clé de distribution et celle-ci ne sert plus qu'à l'envoi. C'est le
filet de sécurité qui rattrape une perte de clé — le seul.

## 2. Le compte Google Play Console ✅ *(personnel, créé le 20 août 2026)*

Le choix est fait : **compte personnel**, en connaissance de la
contrepartie — les 12 testeurs ci-dessous. Le tableau reste pour mémoire.

**La conversion vers un compte d'organisation existe** (vérifié le
2 septembre 2026 ; cette fiche a longtemps prétendu le contraire) : le
propriétaire crée un profil de paiement de type organisation, le fait
vérifier, puis le rattache au compte — *Compte développeur → À propos de
vous → Modifier les détails → Créer ou sélectionner un profil de
paiement*. Il faut une société immatriculée, un numéro D-U-N-S et un
**site web officiel** à son nom. L'inverse, lui, n'existe pas : d'une
organisation on ne revient pas à un compte personnel.

⚠️ **Mais convertir ne dispense probablement pas des douze testeurs.**
L'exigence vise « les comptes **personnels créés après le 13 novembre
2023** » : elle tient au type ET à la date de création, et la conversion
ne change que le type. Ce qui advient après conversion n'est documenté
nulle part — ni levée, ni maintien. Monter une société pour gagner
quatorze jours reviendrait donc à payer un coût certain contre un
résultat que personne ne garantit.

📎 [Choose a developer account type](https://support.google.com/googleplay/android-developer/answer/13634885)
· [Keeping your developer account information up to date](https://support.google.com/googleplay/android-developer/answer/13634888)

| | Compte **personnel** | Compte **organisation** |
|---|---|---|
| Ce qu'il faut | une pièce d'identité | une société active **et** un numéro D-U-N-S |
| Test avant publication | **12 testeurs pendant 14 jours consécutifs** | aucun |
| Retour en arrière | conversion possible vers organisation | impossible |
| Coordonnées publiques | nom du développeur | nom, e-mail et téléphone de la société |

**Les 12 testeurs sont donc le chemin critique du Play Store**, et le
seul délai que rien n'accélère : douze **personnes distinctes**, chacune
avec un compte Google et un appareil Android, inscrites au test fermé
**sans interruption pendant quatorze jours**. Une interruption remet le
compteur à zéro. Sans elles, l'app ne peut pas passer en production —
jamais. L'obligation ne pèse que sur les comptes personnels créés après
le 13 novembre 2023. À lancer avant tout le reste : tout le reste peut
avancer pendant.

### La vérification d'appareil, concrètement

Depuis 2024, tout compte **personnel** doit prouver l'accès à un appareil
Android **physique** avant de pouvoir publier. Un émulateur ne passe pas :
c'est le but de la règle — Google veut que le développeur puisse tester
son app en vrai.

| Ce qu'il faut | Détail |
|---|---|
| L'appareil | physique, **non rooté**, **Android 10** minimum |
| L'outil | l'app **Play Console** installée sur ce téléphone, connectée au compte développeur |
| La durée | moins d'une minute |
| Réutilisable | le même appareil peut vérifier plusieurs comptes |

Le **Pixel 8a**, commandé le 20 août 2026, coche tout. Il servira aussi à
tester la publicité et l'achat de la 1.1, que l'émulateur rend mal.

📎 [Device verification requirements for new developer
accounts](https://support.google.com/googleplay/android-developer/answer/14316361?hl=en)

Restent, si ce n'est pas déjà fait à la création du compte, la
**vérification d'identité** — plusieurs jours — et le numéro de téléphone
à confirmer par SMS.

La déclaration de statut professionnel s'y refait, comme le DSA côté
Apple. Une app gratuite, sans publicité ni achat, se déclare en
particulier — **ce n'est plus le cas d'Erea** : la publicité et l'achat
« sans publicité » orientent vers le statut professionnel, avec les
coordonnées publiques que ça implique. À trancher en même temps que la
déclaration DSA côté Apple, pour ne pas se contredire d'une boutique à
l'autre.

## 3. Le texte de la fiche

**Titre** — 30 caractères

```
Erea — Devine l'année !
```

**Description courte** — 80 caractères, c'est elle qu'on lit sous le
titre

```
Un événement, une frise du temps à faire glisser : en quelle année ?
```

**Description longue** — 4 000 caractères

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

PROGRESSION

Gagnez de l'XP, débloquez des succès et remplissez votre album de collection au fil des événements rencontrés.

SANS COMPTE, SANS INTERNET

Aucune inscription, aucun serveur : votre progression reste sur votre appareil, et le jeu fonctionne entièrement hors ligne — en voiture, dans le train, partout.

UNE PUBLICITÉ, UNE PARTIE SUR DEUX

Erea est gratuit et complet : tous les modes, tous les événements, rien de réservé à ceux qui paient. Une publicité s'affiche en quittant l'écran de fin, une partie sur deux — jamais pendant une manche, jamais avant que vous ayez vu votre score, et jamais dans le Défi du jour. Si elle vous gêne, un achat unique la retire pour toujours.

Bonne partie !
```

⚠️ Cette description est celle de l'App Store, **moins le paragraphe sur
les classements mondiaux** : Game Center n'existe pas sur Android, et
Play Games n'est pas branché (§7). Si tu l'actives, remets le paragraphe
en remplaçant « Game Center » par « Google Play Jeux ». Annoncer un
classement absent est le genre de détail qui vaut un signalement.

⚠️ **Une phrase à retirer avant d'envoyer cette fiche à Google** : « votre
enfant de 8 ans ne tombera pas sur la bataille de Bouvines », dans le
paragraphe « PLUS DE 1700 ÉVÉNEMENTS VÉRIFIÉS ». Le public cible déclaré
est **13 ans et plus** (§5) ; une fiche qui s'adresse aux enfants de
8 ans contredit cette déclaration, et c'est la fiche que Google lit pour
vérifier. Côté App Store la phrase reste : Apple ne pose pas cette
question.

## 4. Les visuels

| Élément | Exigence Google | État |
|---|---|---|
| Icône | PNG 32 bits **avec** alpha, 512 × 512, moins de 1024 Ko | ✅ `docs/play/icone-512.png` (92 Ko) |
| Graphique de mise en avant | JPEG ou PNG 24 bits **sans** alpha, 1024 × 500 | ✅ `docs/play/bandeau-1024x500.png` |
| Captures téléphone | au moins 2, entre 320 et 3840 px | ✅ sept dans `docs/play/captures/` |

⚠️ **Les captures iOS ne se recyclent pas telles quelles.** Google
impose que la plus grande dimension ne dépasse pas le double de la plus
petite. Les captures iPhone 6,9" font 1260 × 2736, soit un rapport de
2,17 : hors clou. Celles de `docs/play/captures/` font 1080 × 2160,
rapport exactement 2,000 — et dépassent les 1080 px qui ouvrent droit
aux mises en avant.

### Les refaire

`erea_flutter/tool/captures_play.js` pilote la **version web** de l'app
dans Chromium et capture les six écrans :

```bash
cd erea_flutter
flutter build web --release
(cd build/web && python3 -m http.server 8099 &)
node tool/captures_play.js            # les sept
node tool/captures_play.js 7-fin      # ou une seule
```

Pourquoi le web plutôt qu'un émulateur : aucune installation d'Android
Studio, et le rendu est celui de Flutter. Le script règle au passage
cinq pièges — CanvasKit servi depuis le SDK plutôt que depuis Google,
police de secours servie depuis le système (sans elle, tous les emoji du
jeu sont des rectangles et la roulette est illisible), arbre de
sémantique ouvert pour pouvoir cliquer les textes, service worker bloqué
pour ne pas resservir un cache, et une densité choisie pour tomber sur
1080 × 2160 pile.

⚠️ **La capture de révélation est la seule faible.** La frise part de
1580 et le script ne sait pas viser : il enchaîne les manches et retient
le meilleur score rencontré, ce qui plafonne à quelques dizaines de
points. Une révélation vraiment réussie — un **PERFECT 🎯** — vaudrait
bien mieux en vitrine : à prendre à la main, en jouant, sur un appareil.

## 4 bis. Ce que contient réellement le build

Mesuré sur l'APK produit le 11 août 2026, pas déduit du code :

| | |
|---|---|
| Poids téléchargé | **~20 Mo** (APK arm64 ; 17,5 Mo en armeabi-v7a). Très loin des seuils de Google |
| `targetSdk` / `compileSdk` | 36 · `minSdk` 24 (Android 7) |
| `versionName` | 1.0.0, comme iOS |

**Permissions réellement embarquées**, plugins compris, relevées sur le
manifeste fusionné :

```
POST_NOTIFICATIONS · RECEIVE_BOOT_COMPLETED · VIBRATE
INTERNET · ACCESS_NETWORK_STATE · WAKE_LOCK · FOREGROUND_SERVICE
ACCESS_ADSERVICES_AD_ID · ACCESS_ADSERVICES_ATTRIBUTION
ACCESS_ADSERVICES_TOPICS
+ DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION (interne à AndroidX)
```

Les trois premières servent au rappel du soir. **Les sept suivantes
viennent d'AdMob**, et trois d'entre elles — les `ADSERVICES` — sont
explicitement du ciblage publicitaire.

⚠️ **Ce que la publicité a coûté, en une ligne : jusqu'au 15 août 2026,
l'app n'avait même pas la permission `INTERNET`.** « Aucune donnée
collectée » n'était pas une promesse mais une propriété vérifiable du
paquet. Ce n'est plus vrai, et la déclaration « Sécurité des données »
doit désormais décrire ce que collecte la régie : identifiants
publicitaires, données d'utilisation approximatives, diagnostics. Google
publie la liste à déclarer pour AdMob — s'y référer plutôt que de
deviner.

## 5. Les trois questionnaires

1. **Classification du contenu (IARC)** — l'équivalent du 4+ d'Apple.
   Mêmes réponses : ni violence, ni contenu sensible, ni jeu d'argent.
   La Roulette des drapeaux tire un pays au sort, ce n'est pas un jeu de
   hasard au sens de la question, qui vise les casinos et les coffres à
   butin.
2. **Sécurité des données** — l'équivalent de la fiche Confidentialité
   d'Apple, et **plus rien à voir avec ce qu'il aurait fallu déclarer en
   1.0**. Il faut désormais cocher *données collectées* et *données
   partagées avec des tiers* (Google), pour les mêmes catégories que côté
   Apple : identifiant publicitaire, interactions dans l'app, position
   approximative dérivée de l'IP, diagnostics. La liste à déclarer pour
   AdMob est publiée par Google — s'y référer plutôt que de deviner, et
   remplir les deux questionnaires (Apple et Google) **le même jour**,
   pour ne pas se contredire.
3. **Public cible et contenu** ✅ *(tranché le 19 août 2026 :
   **13 ans et plus**)* — c'est celui qui n'a pas d'équivalent Apple, et
   le plus engageant des trois. Déclarer une tranche incluant les moins
   de 13 ans ferait entrer l'app dans la **politique Familles**, qui
   imposerait de désactiver la publicité personnalisée
   (`tagForChildDirectedTreatment` / `tagForUnderAgeOfConsent` dans la
   requête AdMob) — pour un revenu publicitaire nettement moindre.

   **Le choix est donc 13 ans et plus**, hors politique Familles. Rien à
   changer dans `lib/core/pub.dart` : la publicité reste personnalisée,
   sous consentement UMP. Ne pas revenir sur ce choix sans mesurer ce
   qu'il coûte en code ET en recettes.

   ⚠️ **Ce que ce choix oblige à faire ailleurs.** Google recoupe la
   déclaration avec la fiche : titre, description et visuels ne doivent
   pas donner l'impression de viser les enfants, sans quoi la Play
   Console requalifie l'app d'office. Or la description longue du §3 dit
   « votre enfant de 8 ans ne tombera pas sur la bataille de Bouvines ».
   ⬜ **Cette phrase est à retirer de la version Play** avant d'envoyer
   la fiche — la version App Store, elle, peut la garder : Apple ne pose
   pas cette question et le 4+ est déjà obtenu.

## 6. Le build

```bash
cd erea_flutter
flutter build appbundle --release   # -> build/app/outputs/bundle/release/app-release.aab
```

C'est un **App Bundle** (`.aab`) qu'il faut envoyer : l'APK n'est plus
accepté pour une nouvelle app. Le `targetSdk` vient de Flutter
(`flutter.targetSdkVersion`) ; Google relève chaque année le niveau
minimum exigé, donc un SDK Flutter à jour évite le refus.

À vérifier avant l'envoi, sur un appareil Android réel : le jeu n'a
jamais tourné en release signée.

## 7. Les classements Play Games *(facultatif)*

`games_services` couvre Play Games, mais **rien n'est configuré** :
aucun projet côté Google, et la `meta-data APP_ID` est commentée dans
`android/app/src/main/AndroidManifest.xml`. En l'état, l'appel échoue en
silence et le jeu reste entièrement jouable, classements masqués — c'est
le comportement voulu par `lib/core/classement.dart`.

⚠️ **Piège principal : les identifiants ne se choisissent pas.** Là où
Game Center accepte les nôtres (`erea.daily`…), la Play Console **génère**
un identifiant opaque et immuable par classement, du genre
`CgkI8ZaR1c4XEAIQAQ`. Réutiliser les identifiants iOS ne produit aucune
erreur visible : les scores partent dans le vide et les classements
restent vides sans que rien ne le signale.

`lib/core/classement.dart` porte donc une table `_playGames` qui traduit
nos identifiants vers ceux de Google. Tant qu'elle est vide, Android
n'envoie ni n'affiche rien — le jeu reste jouable, classements masqués.

Les étapes, dans l'ordre :

1. Créer le projet Play Games dans la Play Console et y créer les **six
   classements** (mêmes types et plages que sur Game Center, voir
   `erea_flutter/ios/GAME_CENTER.md`) ; `erea.daily` doit y être
   **récurrent sur 24 h**.
2. Recopier les six identifiants générés dans la table `_playGames`.
3. Décommenter les deux `meta-data` de `AndroidManifest.xml` en y mettant
   l'identifiant **numérique du projet** (différent de ceux des
   classements), via une ressource string.
4. Remettre le paragraphe « classements » dans la description longue.

⚠️ Décommenter les `meta-data` avec un identifiant vide ou faux **fait
planter l'app au démarrage de Play Games**. C'est tout ou rien — d'où
l'étape 3 en dernier.

## Les pièges, résumés

- La clé de signature ne se remplace pas : sauvegarde-la hors machine,
  et active Play App Signing.
- Les captures iOS sont hors format pour Google (rapport supérieur à 2).
- La `meta-data` Play Games se décommente seulement avec un vrai
  identifiant.
- La description ne doit pas promettre de classement tant que Play Games
  n'est pas branché.
- Le questionnaire « Public cible » engage sur la politique Familles.
