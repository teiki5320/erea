# AUDIT — Erea au 28 septembre 2026

> Audit complet demandé le 28 septembre : code de l'app, configuration
> Android et iOS, documents, état des boutiques. Trois lectures
> indépendantes, chaque constat vérifié à la ligne près. Rien n'a été
> modifié ; ce document liste ce qui mérite de l'être, classé par
> gravité, avec le plan proposé.
>
> **Aucun secret ici** — uniquement des chemins de fichiers et des
> références publiques.

## Vue d'ensemble

- **Santé du code** : `flutter analyze` propre, **165 tests** verts, aucun fichier orphelin, aucun asset manquant, aucun secret suivi par git (keystore et `key.properties` bien ignorés, scan des motifs de jetons vide).
- **Boutiques** : App Store en **1.0.2** depuis le 8 septembre (0 note, 0 avis). Google Play : test fermé, 1.0.3 servie aux testeurs, quatorze jours révolus le 22, **accès à la production demandable et non demandé** au 25 septembre. Fiche publique Play : 404, normal avant la production.
- **Ce qui n'a pas été fait** : la 1.0.4 prévue le 19 ; la demande de production prévue le 22.
- **Trois défauts sérieux dans le code**, tous corrigeables dans la 1.0.4 : le consentement RGPD n'est pas attendu avant l'initialisation des pubs ; sur Android, les boutons « Classement mondial » ne font rien et l'accueil promet un classement qui n'existe pas ; un joueur Android partage un lien App Store.
- **Un défaut sérieux côté iOS** : le manifeste de confidentialité (`PrivacyInfo.xcprivacy`) déclare « aucun suivi, aucune collecte », ce qui est faux depuis la publicité. Apple ne l'a pas relevé pour la 1.0.2 ; il faut le corriger avant la prochaine soumission.
- **Les documents ont vieilli plus vite que le code** : la SPEC est fausse sur le barème, le Chrono et les succès ; `APP_REVIEW.md` propose de renvoyer « telle quelle » une réponse qui affirme « aucun SDK publicitaire, aucun achat » ; le mode Duel est encore promis à trois endroits.

---

## 1. Boutiques

| | iOS · App Store | Android · Google Play |
|---|---|---|
| Version publique | `1.0.2` (build 150), en ligne depuis le 8 septembre à 12 h 19 | aucune |
| Dernier build | 161 (1.0.3, TestFlight), vert, jamais soumis | release `4 (1.0.3)`, servie aux testeurs depuis le 16 septembre |
| Notes / avis | 0 / 0 | — |
| Achat intégré | `com.teiki.erea.sanspub`, 3,99 €, approuvé | actif, 3,99 € vérifié sur le Pixel le 16 |
| Bloquant | rien | **la demande d'accès à la production** (bouton actif depuis le 22) |

**Point aveugle** : rien n'est écrit sur ce qui s'est passé dans la Play
Console après le 25 septembre (modification « captures » envoyée ?
production demandée ?). À confirmer par une capture du tableau de bord.

---

## 2. Code de l'app

### Important — à corriger dans la 1.0.4

1. **Le consentement RGPD n'est pas attendu.** `lib/core/pub.dart:53-62` : `_recolterConsentement()` lance `requestConsentInfoUpdate` qui rend la main immédiatement (rappel asynchrone). `MobileAds.initialize()` et le préchargement partent donc **avant** que le formulaire soit fermé, ce que le commentaire des lignes 50-52 interdit. Sur le Pixel le formulaire s'affiche bien, mais la première interstitielle peut être demandée avant la réponse. Correctif : un `Completer` complété dans le rappel de `loadAndShowConsentFormIfRequired`, comme `montrerSiDue` le fait déjà pour la pub.
2. **Android : « Classement mondial » est un bouton mort.** La garde existe (`lib/core/classement.dart:48-57`, table Play Games vide), mais l'interface ne se cache jamais : bloc de l'accueil `lib/ui/home_screen.dart:827-856`, ligne des réglages `lib/ui/reglages_screen.dart:92-97`. La page « Progresse » de la présentation promet « grimpe au classement mondial » (`lib/ui/onboarding_screen.dart:104-105`). Correctif : masquer les trois quand `Classement` n'a pas de tableau.
3. **Un joueur Android partage un lien App Store.** `lib/core/avis.dart:8` (`lienAppStore`) est ajouté à chaque grille partagée (`lib/ui/game/verdict_textes.dart:79-80`). Correctif : lien Play sur Android, App Store sur iOS.
4. **« Respecte le bouton silencieux de l'iPhone »** sur Android (`lib/ui/reglages_screen.dart:70-71`).
5. **Restauration des achats.** `Achat.demarrer` (`lib/core/achat.dart:49-71`) n'appelle jamais `restorePurchases` ; après réinstallation, un acheteur revoit la pub jusqu'à toucher « Restaurer ». Et « Aucun achat à restaurer » s'affiche après 1 s fixe (`reglages_screen.dart:272-280`), faux négatif sur réseau lent. Même délai fixe dans la feuille d'offre (`lib/ui/offre_sans_pub.dart:67-69`) : elle se referme avec `false` pendant que le joueur paie peut-être, et enregistre un « refus ».
6. **Double `pop` possible à la sortie de l'écran de fin.** `_quitter` (`lib/ui/game_screen.dart:691-714`) n'a pas de verrou, les boutons Rejouer/Accueil n'ont pas d'anti-rebond. Un double tap avant que la pub couvre l'écran dépile une route de trop. À reproduire sur appareil avant de corriger.
7. **Le bilan de fin attend Game Center.** Record et succès ne s'affichent qu'après `_envoyerAuClassement` et `_proposerNote` (`game_screen.dart:370`, `:404-406`) ; un joueur pressé ne les voit jamais, et le son du succès joue avant l'affichage.
8. **Game Center se connecte au lancement** (`home_screen.dart:95-98`) et à chaque retour au premier plan (`:130`), contre la règle de `classement.dart:9-11`. Risque : représenter la feuille de connexion à un joueur qui l'a refusée. À vérifier sur iPhone.

### Cosmétique — quand on passe dans le fichier

- Code mort : `GameMode.duel` (`lib/game/game_controller.dart:14`), `Store.resetAll` (n'a plus de bouton), `EventsRepository.paysParContinent`, `eraFor`, `xpGain`, `Sons.liberer`, `Achat.arreter`, paramètre `GuessView.store` jamais lu.
- Commentaires périmés : `sons.dart:5` (sept WAV, il y en a onze), `retour.dart:21`, `store.dart:137`, `rappels.dart:65-67`, `game_controller.dart:40-41`, `achat.dart:47-48`, `scoring.dart:89-90` (contredit `core_test.dart:66-72`).
- Commentaires de doc orphelins : `game_screen.dart:28`, `:800-803` ; `guess_view.dart:265-266`, `:311-316` ; `end_view.dart:407-408`.
- Bouton « Un instant… » actif sans effet (`offre_sans_pub.dart:109`), « 5 thèmes » en dur (`home_screen.dart:648`), icône de notification Android en couleur (`rappels.dart:32`, s'affiche en carré blanc).
- Pas de version de schéma pour les préférences : le reclassement des catégories a laissé des clés `best.*` orphelines, records perdus sans message.
- Fonctions géantes : `RevealView.build` ≈ 480 lignes, `_TapePainter.paint` ≈ 300, `EndView.build` ≈ 290, `_HomeScreenState.build` ≈ 180. `home_screen.dart` fait 1277 lignes.

### Tests

165 tests couvrent le cœur (barème, tirage, défi, données, achat en
cache, règle d'offre, présentation, écrans principaux, iPhone SE et
iPad, accessibilité). **Aucun test** pour : la branche Android (pas de
`debugDefaultTargetPlatformOverride`), `classement.dart`, `avis.dart`,
`rappels.dart`, le flux réel d'achat, la partie SDK de `pub.dart`, la
feuille d'offre, le partage, l'interrupteur de rappels et le choix du
pays.

---

## 3. Configuration Android et iOS

### Important

1. **`ios/Runner/PrivacyInfo.xcprivacy` est faux** : commentaire « pas de publicité, pas d'identifiant de suivi », `NSPrivacyTracking = false`, aucun type de donnée collecté. L'app embarque AdMob et demande l'ATT. La fiche Confidentialité d'App Store Connect, elle, est juste depuis le 7 septembre. À aligner avant la prochaine soumission iOS : `NSPrivacyTracking = true`, domaines de suivi de Google, types de données identiques à la fiche.
2. **Le keystore de signature** : `erea_flutter/android/erea-upload.jks` et `key.properties` sont dans l'arbre de travail, ignorés par git (vérifié : `git check-ignore` positif, `git ls-files` vide). Mais `docs/INFRA.md:244` et `:274` disent que la clé est dans `~/erea-upload.jks`, ce qui est faux, et le mot de passe est faible (nom de l'app + année). Une sauvegarde ailleurs que sur le Mac est toujours à faire (`FICHE_PLAY_STORE.md:16`).
3. **Le build release Android se rabat en silence sur la clé debug** si `key.properties` manque (`android/app/build.gradle.kts:69-73`). Google refuserait l'envoi, mais on perdrait du temps à comprendre.
4. **Builds non reproductibles** : `pubspec.lock` et `Podfile.lock` sont ignorés (`erea_flutter/.gitignore:8,22`) et Xcode Cloud clone Flutter `stable` sans version figée (`ios/ci_scripts/ci_post_clone.sh:40`). Un jour, un build cassera sans qu'aucun commit ne l'explique.

### Faible

- `TARGETED_DEVICE_FAMILY = 1,2` : l'iPad est supporté (captures iPad exigées, déjà fournies), toutes orientations sur iPad.
- Pas d'icône adaptative Android (`mipmap-anydpi-v26` absent) : l'icône est rognée en cercle sur les Pixel.
- Splash : blanc avec logo sur iOS, crème sans logo sur Android.
- `MARKETING_VERSION = 0.1.0` dans le pbxproj (sans effet, `Info.plist` lit `FLUTTER_BUILD_NAME`), commentaire ATT mal placé dans `Info.plist:36-38`, commentaire périmé `pubspec.yaml:7`.
- Paquets en retard de version majeure : `share_plus` 10 → 13, `flutter_lints` 4 → 6. Le reste est à jour ou en mineur.
- Entitlements iOS : Game Center seul. Manifeste Android : `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `AD_ID` par fusion du SDK (déclaré dans la console), 50 `SKAdNetworkItems`.

---

## 4. Documents

### Important

1. **`docs/APP_REVIEW.md:63-102`** demande de coller « telle quelle » une réponse qui affirme « no advertising SDK, no in-app purchase, never requests ATT ». Faux depuis la 1.0.2. Renvoyer ce texte à Apple serait une fausse déclaration. À réécrire avant tout échange avec l'App Review.
2. **Le mode Duel est encore promis** dans `README.md:26`, `docs/MARKETING.md:120` et `erea_flutter/SPEC.md:113-115`. Il n'existe pas, et cette promesse a déjà failli valoir un refus.
3. **`erea_flutter/SPEC.md`, censée faire foi, est fausse** sur le barème (`:56-60`, tolérance 5 % bornée 12-90 contre 30 ans uniformes dans `lib/core/scoring.dart:54-98`), sur le Chrono (`:111-112`, « 90 s au total » contre 10 s par question), sur les succès (`:139-142`). `docs/APP_REVIEW.md:97` et `:256` répètent les « 90 seconds ».
4. **`CLAUDE.md:64`** désigne l'en-tête de `FICHE_APP_STORE.md` comme « l'état à jour : 1.0, 1.1 ». Cet en-tête date du 8 septembre, la 1.1 n'a jamais existé, et `docs/PUBLICATION.md`, le vrai document d'état, n'est pas dans le tableau.
5. **`docs/FICHE_APP_STORE.md` se contredit** : DSA trader « ✅ » (`:577`, `:607`) contre non-trader (`:165-168`) ; confidentialité « à refaire » (`:616`) contre faite (`:492`) ; « passer en 1.1.0 » (`:619`) ; sortie manuelle (`:409-417`) contre automatique.
6. **Périmés en bloc** : `docs/INFRA.md` (version 1.0.0+1, 154 tests, IDFA et SKAdNetwork « manquants », produit Play « à créer », chemin du keystore), `erea_flutter/README.md` (1.0.0, 154 tests, 1738 faits, « aucun appareil physique », achat « jamais exécuté »), `docs/MARKETING.md` (« en cours d'examen », « pas d'analytics tiers » alors que la déclaration Play inclut l'analyse, badge « aucune donnée collectée » déjà perdu).
7. **`docs/PUBLICATION.md`** s'arrête au 16 septembre ; l'échéance du 22 est passée sans trace ; l'item 2 de « Ce qui reste » est déjà fait ; le paragraphe `:174-178` est mal formé.

### Faible

- `AGENTS.md` (copie exacte de `CLAUDE.md`) et `docs/erea_feedback.pdf` ne sont pas suivis par git.
- `docs/visuels-play/` fait doublon avec `docs/play/` ; `docs/visuels-app-store/` et `docs/play/captures-legendees/` ne sont cités nulle part ; `FICHE_PLAY_STORE.md:249` dit « six écrans », `:256` « les sept ».
- `docs/FICHE_APP_STORE.md:195` contient le complément d'adresse d'un tiers (« SARL GROUPE MATEVIE ») dans un dépôt présenté comme publiable.
- Testers Community (service payant, 14 €) est absent de `docs/INFRA.md`.
- Compte des faits : 1831 est juste ; 1738 traîne encore dans `README.md:60`, `erea_flutter/README.md:102`, `SPEC.md:104`, `MARKETING.md:63,124`, `APP_REVIEW.md:90`.

---

## 5. Plan proposé

### A. Cette semaine — 1.0.4, puis la production Play

Une seule version, versionCode 5, qui règle les points 1 à 5 du code
(consentement attendu, classement masqué sur Android, lien de partage
par plateforme, texte du bouton silencieux, restauration au lancement
et délais remplacés par les vrais retours de la boutique), plus le
manifeste de confidentialité iOS. Bundle sur la piste Alpha, puis
**Demander à publier en production** avec les réponses au formulaire
rédigées à partir des 1.0.3 et 1.0.4 réelles.

### B. Dans la foulée — documents

Réécrire `APP_REVIEW.md` §1 (plus de « no ads »), retirer le Duel des
trois documents, corriger SPEC (barème, Chrono, succès, Roulette),
mettre `CLAUDE.md` à jour (PUBLICATION dans le tableau, retirer
« 1.1 »), rafraîchir INFRA, README et MARKETING, supprimer `AGENTS.md`
ou le suivre, décider du sort de `docs/erea_feedback.pdf`.

### C. Quand on aura le temps — dette

Version de schéma des préférences, verrou sur `_quitter`, bilan de fin
avant Game Center, règle de connexion Game Center, code mort et
commentaires orphelins, icône adaptative Android, `pubspec.lock` suivi,
Flutter figé sur Xcode Cloud, tests Android et flux d'achat,
`share_plus` 13, `flutter_lints` 6, découpage de `home_screen.dart` et
`reveal_view.dart`.

### Décisions à prendre

1. Lancer A tout de suite, ou demander la production avec la 1.0.3 seule et livrer la 1.0.4 après ?
2. `docs/erea_feedback.pdf` : garder dans le dépôt (aucun secret) ou retirer ?
3. Sauvegarde du keystore hors du Mac : où (clé USB, gestionnaire de mots de passe, coffre) ?
