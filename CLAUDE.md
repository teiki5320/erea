# Travailler sur Erea

Erea est un jeu iOS de culture historique en Flutter : un événement
s'affiche sans sa date, on fait défiler une frise de 3000 av. J.-C. à
aujourd'hui pour deviner l'année. Le produit est l'application, dans
[`erea_flutter/`](erea_flutter/) ; le jeu web à la racine est le
prototype d'origine, conservé comme vitrine.

## Comment on travaille

- **Réponds toujours en français**, y compris dans le raisonnement
  visible.
- **Numérote chaque choix laissé au développeur.** Trois questions dans
  un message doivent pouvoir se répondre « 1 oui, 2 non, 3 plus tard ».
- **Tout se fait sur `main`, directement. On ne crée pas de branche.**
  Une seule version, la bonne, au même endroit. Le dépôt a déjà souffert
  d'histoires parallèles (voir plus bas) : ne recommence pas.
- **Demande plutôt que de décider seul** d'un changement de cap, et ne
  lance pas de longue exploration sans accord — les jetons sont payants.
- **Ne laisse aucune trace de tes erreurs.** Corrige proprement plutôt
  que d'empiler un correctif sur une bêtise : le code et les messages de
  commit doivent rester lisibles pour la conversation suivante.
- **Vérifie avant d'affirmer.** App Store Connect et la Play Console
  changent plusieurs fois par an : consulte la documentation d'Apple ou
  de Google, ou demande une capture, plutôt que de guider de mémoire.
- **Avant tout commit** : `flutter analyze` et `flutter test` doivent
  passer (167 tests).
- **Aucun test ne couvre la compilation iOS.** `analyze`, les tests et
  même un build Android peuvent tous passer sur un projet qui n'archive
  pas. Toucher à `ios/`, au `Podfile` ou à une dépendance native, c'est
  s'engager à surveiller le build Xcode Cloud qui suit.

⚠️ Chaque poussée sur `main` déclenche un build Xcode Cloud, sans filtre
de fichiers — même pour un document. Groupe les commits quand c'est
possible.

## Les pièges déjà payés

- **Xcode Cloud, action *Archiver*** : la préparation de la distribution
  doit rester sur **« App Store Connect »**. Sur « TestFlight (tests
  internes uniquement) », les builds n'apparaissent jamais dans la liste
  de sélection d'une version.
- **La version de `pubspec.yaml` doit être identique** à celle saisie
  dans App Store Connect, sinon le build est non sélectionnable.
- **Dès qu'une version est approuvée, monte le numéro avant la poussée
  suivante.** Apple ferme la version approuvée à tout nouveau build
  (ITMS-90186 et ITMS-90062) : chaque poussée, même de documentation,
  finit en build Xcode Cloud échoué et en deux e-mails. Le build 187 du
  16 octobre 2026 l'a montré au lendemain de la 1.0.4.
- **Les mots-clés App Store se comptent en octets**, pas en caractères :
  chaque accent en vaut deux.
- **`google_mobile_ads` ne compile pas sur iOS sans
  `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES`, posé à
  DEUX endroits** : le `post_install` du `Podfile` (cibles Pods) **et**
  `ios/Flutter/{Debug,Release}.xcconfig` (cible Runner — c'est elle qui
  construit le module et lève le diagnostic ; quatre builds ont échoué
  avec la moitié Pods seule). Ne retire ni l'un ni l'autre.
- **`ios/Runner/PrivacyInfo.xcprivacy` : `NSPrivacyTracking` à `false`
  et pas de clé `NSPrivacyTrackingDomains`.** Toute autre combinaison
  (vrai avec liste vide, vrai sans clé) est refusée à l'import par
  ITMS-91064, malgré un fichier valide : deux builds perdus le 15 octobre
  2026. Le suivi publicitaire se déclare dans la fiche Confidentialité
  d'App Store Connect et dans les types de données du manifeste. Pour
  savoir ce qui est réellement embarqué : `flutter build ios --release
  --no-codesign`, puis chercher les `PrivacyInfo.xcprivacy` dans
  `build/ios/iphoneos/Runner.app`.
- **Flutter ne descend pas dans les sous-dossiers d'assets** : chaque
  sous-dossier se déclare à part dans `pubspec.yaml`.
- **Le dépôt a contenu deux histoires git sans ancêtre commun**, nées
  d'un « Add files via upload » fait depuis l'interface web de GitHub.
  La bonne lignée est celle de `main`. N'ajoute jamais de fichiers par
  l'interface web : ça repart d'un arbre vierge.

## Où trouver quoi

| Fichier | Contenu |
|---|---|
| **`docs/PUBLICATION.md`** | **l'état à jour des deux boutiques : versions, examens, démarches en cours** |
| `docs/AUDIT.md` | l'audit du 28 septembre 2026 (rapport daté, ne se met pas à jour) |
| `erea_flutter/SPEC.md` | la spécification de référence : formules, barème, règles |
| `erea_flutter/README.md` | développer, builder, les pièges Xcode Cloud |
| `docs/FICHE_APP_STORE.md` | la fiche App Store, champ par champ |
| `docs/FICHE_PLAY_STORE.md` | le chemin jusqu'au Play Store |
| `docs/APP_REVIEW.md` | répondre à l'App Review : ses sept questions, les textes déjà envoyés, et comment re-soumettre (une demande d'infos EST un refus) |
| `docs/INFRA.md` | les services externes et où vit chaque secret |
| `docs/MARKETING.md` | positionnement, monétisation, ASO |
| `erea_flutter/ios/GAME_CENTER.md` | les six classements |
