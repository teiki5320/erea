# Activer le classement mondial (Game Center)

Le code est en place et se tait tant que Game Center n'est pas activé :
`lib/core/classement.dart` tente une connexion paresseuse, échoue en
silence, et le jeu reste entièrement jouable. **Rien n'est branché dans la
signature du projet** : les builds actuels passent exactement comme avant.

Trois étapes, dans cet ordre.

## 1. Activer la capacité sur l'App ID *(portail développeur)*

Certificates, Identifiers & Profiles → Identifiers → `com.teiki.erea` →
cocher **Game Center** → Save.

Tant que ce n'est pas fait, l'étape 3 fera **échouer la signature** du
build. C'est pour ça qu'elle vient en dernier.

## 2. Créer les trois classements *(App Store Connect)*

App Store Connect → Erea → **Game Center** → Leaderboards.

| ID (à respecter à la lettre) | Type | Plage | Contenu |
|---|---|---|---|
| `erea.daily` | **Récurrent, 24 h** | 0 – 11000 | Score du défi du jour |
| `erea.streak` | Classique (all-time) | 0 – 3650 | Série de jours consécutifs |
| `erea.classic.normal` | Classique | 0 – 11000 | Record en Normal |
| `erea.classic.facile` | Classique | 0 – 11000 | Record en Facile |
| `erea.classic.difficile` | Classique | 0 – 11000 | Record en Difficile |

Format : **Entier**, tri **décroissant** (le plus grand gagne).

`erea.daily` DOIT être récurrent sur 24 h : sans remise à zéro
quotidienne, deux versions de l'app — donc deux séries de questions
différentes — se retrouveraient dans le même tableau.

Un classement récurrent n'apparaît qu'après le premier score envoyé.

Ne pas oublier d'**attacher** les classements à la version avant de la
soumettre à la revue.

## 3. Brancher l'entitlement *(une ligne, une fois l'étape 1 faite)*

Le fichier `ios/Runner/Runner.entitlements` existe déjà. Il suffit de le
déclarer dans les trois configurations du target Runner
(`ios/Runner.xcodeproj/project.pbxproj`) :

```
CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;
```

ou, dans Xcode : Runner → Signing & Capabilities → **+ Capability** →
Game Center (Xcode écrit la même chose tout seul).

## Vérifier

Les classements ne fonctionnent pas en simulateur. Il faut un appareil
réel connecté à un compte Game Center (un compte **sandbox** suffit) ou
une build TestFlight.

## Ce qui est déjà tenu côté code

- Connexion **paresseuse** : jamais au lancement, seulement à la fin d'un
  défi ou au tap sur « Classement mondial ». Apple refuse les fenêtres
  Game Center intrusives, et ça perturbe un enfant.
- **Aucun blocage** : Game Center désactivé par le contrôle parental →
  l'appel échoue, le jeu continue.
- **Bornes anti-absurde** : un total hors barème n'est pas envoyé.
- **Un tableau par difficulté** : les barèmes ne sont pas comparables
  entre eux (tolérance ×2,2 contre ×0,55), les mélanger n'aurait aucun
  sens.
