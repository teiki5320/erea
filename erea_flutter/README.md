# Erea — application Flutter

L'application Erea, en Flutter — **c'est le produit**. Le jeu web à la
racine du dépôt en est le prototype d'origine, conservé pour mémoire.

État : **version 1.0.0** soumise à l'App Store le 14 août (build 90),
publicité et achat intégré branchés pour la 1.1.
152 tests, `flutter analyze` propre.

## Démarrer

Les dossiers de plateformes (`ios/`, `android/`, `web/`) sont versionnés :
ils portent la configuration de publication (bundle id, team, orientations,
icônes). Rien à générer.

```bash
cd erea_flutter
flutter pub get
flutter analyze
flutter test
flutter run
```

## Publier sur iOS

```bash
flutter build ipa --release   # -> build/ios/ipa/erea.ipa
```

L'archive est signée pour l'App Store avec la team `K597U7X3FZ`.
L'upload se fait ensuite via Transporter ou l'Organizer de Xcode.

| Réglage | Valeur |
|---|---|
| Bundle identifier | `com.teiki.erea` |
| Nom affiché | Erea |
| Version | `1.0.0` (depuis `pubspec.yaml`) |
| Numéro de build | attribué par Xcode Cloud, qui l'incrémente seul |
| iOS minimum | 15.0 |
| Langue | français (`CFBundleDevelopmentRegion` + `CFBundleLocalizations`) |
| Orientations | portrait sur iPhone, portrait + paysage sur iPad |
| Chiffrement | `ITSAppUsesNonExemptEncryption = false` |

⚠️ Le numéro de version de `pubspec.yaml` doit être **identique** à celui
saisi dans App Store Connect, sinon le build n'apparaît pas dans la liste
de sélection de la version. Le suffixe après le `+` est écrasé par Xcode
Cloud.

### Xcode Cloud

`ios/ci_scripts/ci_post_clone.sh` installe Flutter, génère
`Generated.xcconfig` et fait le `pod install` avant l'archive ;
`ci_pre_xcodebuild.sh` vérifie l'invariant juste avant `xcodebuild`. Le
workflow « erea » surveille `main` : **toute** poussée déclenche un
build, sans filtre de fichiers.

⚠️ Dans l'action *Archiver*, la **préparation de la distribution** doit
rester sur **« App Store Connect »**. Sur « TestFlight (tests internes
uniquement) », les builds partent bien sur TestFlight mais restent
invisibles au moment de sélectionner un build pour une version — piège
qui coûte facilement une demi-journée.

⚠️ Le `post_install` du `Podfile` lève
`CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES` sur toutes les
cibles de pods. Sans lui, `google_mobile_ads` 9.1.0 ne compile pas :
deux de ses en-têtes publics importent `GoogleMobileAds_Beta.h`, qui vit
dans les `PrivateHeaders/` du xcframework de Google, donc hors du module
map. Rien ne le montre ici — ni `flutter analyze`, ni les tests, ni le
build Android : seule l'archive iOS échoue, et on l'apprend par Xcode
Cloud (builds 94 et 95).

## Ce qui est déjà implémenté

- **`assets/events.json`** — toute la base d'événements vérifiée (dates,
  anecdotes, niveaux, packs). C'est l'actif principal du projet.
- **`lib/core/`** — les règles du jeu, portées à l'identique du web :
  échelle non linéaire de la frise, barème (tolérance, fenêtre de 200 ans,
  manche finale ×2), courbe d'XP et titres, PRNG mulberry32 compatible bit à
  bit avec le web (le défi du jour tire la même série pour tous les joueurs
  de l'app à une date donnée ; la base ayant grandi, ce n'est plus la même
  série que le site).
- **`lib/data/`** — chargement de la base, filtres catégorie/pack/difficulté,
  anti-répétition, persistance (XP, records, défi du jour) via
  `shared_preferences`.
- **`lib/game/game_controller.dart`** — la machine à états d'une partie.
- **`lib/ui/`** — accueil « Focus », écran de jeu avec le **ruban défilant**
  (CustomPainter + inertie), révélation animée, écran de fin.
- **`assets/fonts/`** — Baloo 2 et Nunito embarquées : aucun accès réseau
  dans l'app, elle fonctionne entièrement hors ligne.
- **`lib/core/region.dart`** — détection du pays (choix explicite, sinon
  réglage de l'appareil) et mélange régional : depuis l'Afrique de
  l'Ouest, le Classique tire la moitié de ses questions dans le pack
  Afrique.
- **`lib/core/classement.dart`** — Game Center : connexion paresseuse et
  partagée, six tableaux, échec silencieux.
- **`lib/core/avis.dart`** — demande de note, une seule fois et après une
  réussite.
- **`test/`** — 152 tests : règles du jeu, intégrité des 1 738
  événements, persistance et défi du jour, interface jusqu'à une partie
  complète, mise en page iPad et iPhone SE en très grande police, règle
  d'affichage de la publicité, promesse de l'achat.

## Publicité (AdMob)

Une **interstitielle à la sortie de l'écran de fin**, une partie sur
deux. Jamais pendant une manche, jamais entre deux manches, jamais avant
que le joueur ait vu son score — et **jamais dans le Défi du jour**, qui
est le rituel de rétention. La règle vit dans `lib/core/pub.dart`, isolée
du SDK pour être testable (`test/pub_test.dart`).

Les identifiants du compte AdMob vivent à trois endroits, à changer
ensemble :

| Quoi | Où | État |
|---|---|---|
| Bloc interstitiel Android | `lib/core/pub.dart` | réel |
| Bloc interstitiel iOS | `lib/core/pub.dart` | ⚠️ **démonstration** |
| `APPLICATION_ID` | `android/app/src/main/AndroidManifest.xml` | réel |
| `GADApplicationIdentifier` | `ios/Runner/Info.plist` | ⚠️ **démonstration** |

⚠️ **Les deux lignes iOS ne rapportent donc rien** : le bloc
interstitiel iOS reste à créer dans AdMob, puis à reporter ici.

⚠️ Le SDK lit l'identifiant d'app au démarrage du processus et **fait
planter l'app s'il est absent** : ces deux clés natives ne sont donc pas
commentables tant que `google_mobile_ads` est une dépendance.

Le consentement européen passe par le formulaire UMP de Google, réclamé
avant tout chargement. Sur iOS, `NSUserTrackingUsageDescription` porte le
texte d'App Tracking Transparency : sans lui, la publicité reste non
personnalisée.

## L'achat « Erea sans pub »

Un produit **non consommable**, `com.teiki.erea.sanspub`, à créer à
l'identique dans App Store Connect et dans la Play Console. Il n'ouvre
rien : il enlève la publicité, et c'est tout — aucun événement, aucun
mode, aucune fonction n'est réservé à ceux qui paient.

`lib/core/achat.dart` écoute la boutique et met `Store.sansPub` à jour,
y compris pour un achat fait sur un autre appareil. L'offre et le bouton
**« Restaurer mes achats »** vivent en tête des réglages ; ce bouton est
obligatoire, Apple refuse les apps qui n'en ont pas.

⚠️ Le prix affiché vient toujours de la boutique, jamais d'une constante
du code : il dépend du pays, de la devise et des taxes.

⚠️ Rien n'est testable avant que l'accord **« Applications payantes »**
soit signé dans App Store Connect, coordonnées bancaires et fiscales
comprises.

## Ce qui n'est pas fait

- **Android** : l'App Bundle se signe et se construit (la clé vit hors
  du dépôt, dans `android/key.properties`), mais la publication est
  suspendue à deux questions ouvertes : les 12 testeurs pendant 14 jours
  exigés d'un compte personnel, et l'absence d'appareil physique. Play
  Games n'est pas configuré : les classements sont muets, le jeu reste
  jouable — la table d'identifiants attend dans `lib/core/classement.dart`.
  Tout le chemin est dans `docs/FICHE_PLAY_STORE.md`.
- **L'achat n'a jamais été exécuté** : l'accord « Applications payantes »
  n'est pas signé et le produit n'existe pas encore dans App Store
  Connect, donc la boutique reste muette et l'offre ne s'affiche pas.

`SPEC.md` est la spécification de référence : toutes les formules et
règles validées par le prototype web y sont consignées.
