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
| Signature de release câblée sur une clé hors dépôt | ✅ prête, **la clé reste à créer** |
| Autorisation de notification Android 13 demandée | ✅ dans `lib/core/rappels.dart` |
| Icône 512 × 512 et bandeau 1024 × 500 | ✅ dans `docs/play/` |
| Titre, descriptions | ✅ rédigés plus bas |
| Clé de signature | ⬜ **à créer, c'est le premier verrou** |
| Compte Google Play Console | ⬜ |
| Captures d'écran Android | ⬜ |
| Trois questionnaires | ⬜ |
| Classements Play Games | ⬜ *(facultatif, voir §7)* |

---

## 1. La clé de signature — à faire en premier

`android/app/build.gradle.kts` lit `android/key.properties`, que git
ignore. Tant que ce fichier n'existe pas, la release est signée avec les
clés de debug : l'app se lance, mais Google la refuse. C'est voulu — un
build publiable exige la vraie clé.

```bash
keytool -genkey -v -keystore ~/erea-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias erea
```

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

## 2. Le compte Google Play Console

25 $ une seule fois, puis une **vérification d'identité** qui prend
plusieurs jours. À lancer tôt : tout le reste peut avancer pendant.

La déclaration de statut professionnel s'y refait, comme le DSA côté
Apple. Une app gratuite, sans publicité ni achat, se déclare en
particulier. Le jour où « Erea + » arrive, il faut repasser la
déclaration.

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

SANS PUBLICITÉ, SANS COMPTE, SANS INTERNET

Erea ne collecte aucune donnée, n'affiche aucune publicité et ne demande aucune inscription. Le jeu fonctionne entièrement hors ligne — en voiture, dans le train, partout.

Bonne partie !
```

⚠️ Cette description est celle de l'App Store, **moins le paragraphe sur
les classements mondiaux** : Game Center n'existe pas sur Android, et
Play Games n'est pas branché (§7). Si tu l'actives, remets le paragraphe
en remplaçant « Game Center » par « Google Play Jeux ». Annoncer un
classement absent est le genre de détail qui vaut un signalement.

## 4. Les visuels

| Élément | Exigence Google | État |
|---|---|---|
| Icône | PNG 32 bits **avec** alpha, 512 × 512, moins de 1024 Ko | ✅ `docs/play/icone-512.png` (92 Ko) |
| Graphique de mise en avant | JPEG ou PNG 24 bits **sans** alpha, 1024 × 500 | ✅ `docs/play/bandeau-1024x500.png` |
| Captures téléphone | au moins 2, entre 320 et 3840 px | ⬜ |

⚠️ **Les captures iOS ne se recyclent pas telles quelles.** Google
impose que la plus grande dimension ne dépasse pas le double de la plus
petite. Les captures iPhone 6,9" font 1260 × 2736, soit un rapport de
2,17 : hors clou. Il faut des captures prises sur un appareil ou un
émulateur Android — et viser **au moins quatre captures d'au moins
1080 px** en 16:9 ou 9:16, seuil d'éligibilité aux mises en avant.

Les six écrans à montrer sont les mêmes que sur l'App Store : partie en
cours avec la frise, révélation réussie, défi du jour, écran de fin,
Chrono, Roulette des drapeaux. Les captures se réordonnent après coup,
sans nouvelle version.

## 5. Les trois questionnaires

1. **Classification du contenu (IARC)** — l'équivalent du 4+ d'Apple.
   Mêmes réponses : ni violence, ni contenu sensible, ni jeu d'argent.
   La Roulette des drapeaux tire un pays au sort, ce n'est pas un jeu de
   hasard au sens de la question, qui vise les casinos et les coffres à
   butin.
2. **Sécurité des données** — l'équivalent de la fiche Confidentialité.
   Réponse identique et vérifiable : **aucune donnée collectée, aucune
   donnée partagée**. Ni analytics, ni traceur, ni serveur.
3. **Public cible et contenu** — c'est celui qui n'a pas d'équivalent
   Apple, et le seul à prendre au sérieux. Déclarer une tranche d'âge
   incluant les moins de 13 ans fait entrer l'app dans la **politique
   Familles**, avec ses obligations propres (contenu, publicité, SDK
   tiers, lien de confidentialité obligatoire). Erea n'a ni pub ni
   collecte, donc rien ne coince — mais la déclaration engage, et Google
   vérifie.

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

Pour les activer : créer le projet Play Games dans la Play Console,
recréer les six classements avec les mêmes identifiants qu'iOS
(`erea.daily`, `erea.streak`, `erea.classic.facile` / `.normal` /
`.difficile`, `erea.chrono`), puis décommenter les deux `meta-data` en y
mettant l'identifiant numérique obtenu.

⚠️ Décommenter avec un identifiant vide ou faux **fait planter l'app au
démarrage de Play Games**. C'est tout ou rien.

## Les pièges, résumés

- La clé de signature ne se remplace pas : sauvegarde-la hors machine,
  et active Play App Signing.
- Les captures iOS sont hors format pour Google (rapport supérieur à 2).
- La `meta-data` Play Games se décommente seulement avec un vrai
  identifiant.
- La description ne doit pas promettre de classement tant que Play Games
  n'est pas branché.
- Le questionnaire « Public cible » engage sur la politique Familles.
