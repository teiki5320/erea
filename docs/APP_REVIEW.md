# Répondre à l'App Review — Erea

> Écrit le 20 août 2026, à partir du message d'Apple du 15 août et de la
> documentation d'App Store Connect.

## Où on en est, exactement

> **30 octobre 2026 — 1.0.7 en préparation.** La 1.0.5 (build 195),
> envoyée le 21 octobre, a été approuvée et mise en ligne le jour même ;
> la 1.0.4 du 15 octobre aussi. Tout ce qui suit
> le §0 est une **archive d'août**, gardée telle qu'elle a été envoyée
> pour la 1.0. Ces textes sont **faux aujourd'hui** : ils affirment
> « aucun SDK publicitaire, aucun achat intégré, aucune demande ATT »
> (faux depuis la 1.0.2) et décrivent un Chrono de « 90 seconds »
> (c'est 10 secondes par question). Ne plus les recopier. Le texte en
> vigueur est celui du §0 : les notes de la 1.0.5, avec le paragraphe
> « What's new » de la 1.0.7.

## §0 — Notes en vigueur (1.0.7, à coller dans « Remarques » à la soumission)

```
Erea is a single-player history quiz in French. An event is shown without its date and the player drags a timeline (3000 BC to today) to guess the year.

NO ACCOUNT: no registration, no login, no user accounts. No demo account or credentials are needed. Every mode is reachable from the home screen.
NO USER-GENERATED CONTENT: players cannot post or exchange content. The only outgoing message is "Donner mon avis" in Settings, which opens the Mail app addressed to erea@toakeur.com.
GAMEPLAY IS OFFLINE: all questions ship in the bundle; the game is fully playable in airplane mode.

THIRD-PARTY SERVICES:
- Google AdMob (Google Mobile Ads SDK) for interstitial ads, with Google's UMP SDK for consent. An interstitial may appear when leaving the end-of-game screen, on every other game; never during a round and never on the Daily Challenge.
- Apple Game Center for optional leaderboards.
- StoreKit for the in-app purchase below.
No backend, no account system, no analytics of our own.

SYSTEM PROMPTS: the GDPR consent form (European users) and the App Tracking Transparency request, shown at first launch; Game Center sign-in when the home screen opens (it shows the player's world ranks). Notification permission is asked only for the optional evening reminder: after a completed Daily Challenge once the player has a streak of 2 days or more, or when the reminder is turned on in Settings. Declining any of them leaves the game fully playable. Consent can be changed later in Settings > "Publicité personnalisée".

IN-APP PURCHASE: one non-consumable, "Erea sans publicité" (com.teiki.erea.sanspub), which removes ads permanently. All modes and all questions remain free; nothing else is unlocked. It is offered in Settings, on the end-of-game screen and after an ad. "Restaurer mes achats" is in Settings, and purchases are also restored automatically at launch.

MODES: Classic (10 rounds, category and difficulty selectable), Daily Challenge (same 10 questions for everyone, one attempt per day), Chrono (10 seconds per question), Flag Roulette (one country per game), Theme Packs.

WHAT'S NEW IN 1.0.7: the optional evening reminder now shows the player's exact streak, once, on the evening the streak is at stake; in Chrono mode the question is hidden while the timer is paused; ads are no longer requested when Google's consent status cannot be obtained; a duplicate question was removed; the result screen now fits small iPhones at the largest text sizes; the evening reminder is no longer switched back on after the player turned it off; Settings now link to the privacy policy; a new Album screen lists the events already discovered; the Classic mode is shown first on the home screen; interface emoji were replaced by drawn icons. No change to the in-app purchase, tracking or the consent form itself.
```

> **Où en est la 1.0 :** re-soumise le 20 août 2026 (build **90**
> inchangé), puis **deuxième demande d'informations le 21 août**, portant
> cette fois sur une seule question — les flammes. Réponse au §3. Comme le
> 15 août, c'est un **refus formel** : répondre, puis re-soumettre.

La version **1.0.0 (build 90)**, soumise le 14 août 2026 à 11 h 42
(identifiant `ac15df9e-b4e0-40e6-8834-6cb24d3fbc0d`), avait été
**refusée** le 15 août — état affiché *2.1.0 Performance: App
Completeness*, message **Guideline 2.1 – Information Needed – New App
Submission**.

Il n'y a **aucun bug reproché** : c'est la demande d'information standard
adressée aux nouvelles apps. Apple réclame **sept éléments**. La réponse
envoyée le 18 août à 11 h 39 n'en couvrait qu'**un** (la vidéo) et une
partie du troisième — d'où l'absence de suite.

⚠️ **Répondre ne relance pas l'examen.** Tant que l'élément refusé n'est
ni modifié ni retiré, la soumission reste en « Problèmes non résolus » et
le bouton *Soumettre à nouveau* demeure grisé. C'est écrit noir sur blanc
dans [Manage a submission with unresolved
issues](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/manage-a-submission-with-unresolved-issues/).

## La marche à suivre

> *Procédure de la 1.0, en août 2026, face à une demande d'informations.
> Pour une simple mise à jour, rien de tout cela : le §0 se colle dans
> « Remarques » et l'on suit « Sortir une nouvelle version » dans
> `FICHE_APP_STORE.md`. Le §1 et le §2 cités ci-dessous sont des archives.*

1. **Répondre** dans le fil avec le texte du §1 ci-dessous (limite 4 000
   caractères), en rejoignant `Erea.mov` si le fil ne le conserve pas.
   C'est la page **« Vérification de l'app »**, celle des messages, bouton
   *Répondre à l'équipe de vérification des apps*.
2. Coller le texte du §2 dans **Distribution → App iOS Version 1.0.0 →
   champ « Remarques »**, tout en bas de la page de la version (4 000
   caractères ; le §2 en fait environ 1 400). C'est ce qu'Apple appelle
   « App Review Information → Notes » dans son message anglais — à ne pas
   confondre avec la page « Vérification de l'app » de l'étape 1. Le champ
   contient déjà un texte court : le §2 le **remplace**. Puis
   **Enregistrer**.
3. Cliquer **Modifier** en face de l'élément refusé. Contrairement à ce
   que laisse croire la documentation anglaise (*Edit* → *Add for Review*
   → *Resubmit to App Review*), ce lien ouvre simplement **la page de la
   version** : il n'y a ni « Ajouter pour vérification », ni « Soumettre à
   nouveau » à cet endroit.
4. Sur cette page, apporter la modification — typiquement le champ
   **Remarques** — puis **Enregistrer**, et enfin cliquer le bouton bleu
   **« Mettre à jour la vérification »** en haut à droite. C'est **lui**
   qui renvoie l'élément à l'examen.

Sur la page de soumission, le bouton *Soumettre à nouveau à l'équipe de
vérification* reste grisé du début à la fin : ce n'est pas par lui que
passe la re-soumission, malgré son nom.

⚠️ **Un élément ne peut être édité qu'une seule fois avant
re-soumission**, et un élément retiré ne peut plus être réajouté à la même
soumission. Pas de manipulation à l'aveugle.

---

## §1 — Réponse aux sept points *(archive du 20 août, ne plus recopier)*

> **Envoyé le 20 août 2026.** Le point 2 est parti incomplet — un message
> de suivi, reproduit après le bloc, a fourni la liste des appareils. Le
> texte ci-dessous est la version corrigée de l'époque : il décrit une app
> sans publicité ni achat, il est faux depuis la 1.0.2.

```
Hello,

Thank you for the detailed request. Here is all of the information, point by point.

1. SCREEN RECORDING
A screen recording captured on a physical iPhone running the latest iOS is attached to this thread (Erea.mov, sent on August 18). It begins with launching the app from the home screen and shows the typical user flow: starting a Classic game, scrolling the timeline to guess the year, validating an answer, the reveal animation, the end-of-game screen, the Daily Challenge, the Chrono mode, the Flag Roulette and the settings screen.

None of the four listed cases exist in this version:
- No account registration, login or account deletion — the app has no accounts of any kind.
- No paid content, no in-app purchase and no subscription. This build contains no purchase framework at all.
- No user-generated content, therefore no reporting or blocking mechanism.
- No prompt requesting sensitive data. The app never requests location, contacts, camera, photos or App Tracking Transparency. The only two system prompts are the optional Game Center sign-in (for leaderboards) and the optional notification permission for the evening reminder. Both are optional: declining either leaves the app fully playable.

2. DEVICES AND OS TESTED
- iPhone 16 Plus (physical device) — this is the device used for the attached screen recording (Erea.mov)
- iPad Pro 13-inch (M4) (physical device)
Both running the latest public release of iOS and iPadOS. Minimum deployment target: iOS 15.0. The app supports both iPhone and iPad.

3. FUNCTION, TARGET AUDIENCE AND VALUE
Erea is a single-player history quiz. An historical event is shown without its date; the player drags a timeline running from 3000 BC to today to guess the year, and scores according to how close the guess is. The database holds 1,738 verified events across four themes (power and wars, sciences and exploration, culture and beliefs, daily life and sport), each graded by difficulty so that younger players meet well-known facts first.

Target audience: families and school-age players, plus adults who enjoy general-knowledge games. Content is in French only.

The problem it solves: history is usually memorised as isolated dates. By making the player place events on a shared timeline, the game builds a sense of chronology and of what happened at the same time elsewhere in the world. It is playable entirely offline, in short sessions, with no account and no data collection.

4. SETUP AND ACCESS INSTRUCTIONS
No setup is required. There are no login credentials, no demo account and no sample files, because the app has no accounts and no server. Every feature is reachable from the home screen without any condition: Classic game (category and difficulty selectable), Daily Challenge (one attempt per day), Chrono mode (90 seconds), Flag Roulette (one country per game), collection, achievements and settings. All content ships inside the app bundle and works in airplane mode.

5. EXTERNAL SERVICES
One only: Apple Game Center, used for the six optional leaderboards. Sign-in is lazy — it is never requested at launch — and any failure is silent, so the game stays fully playable when Game Center is disabled, including by parental controls.

There is no backend server, no database, no analytics, no advertising SDK, no payment processor, no authentication service, no AI service and no third-party data provider. The app makes no network request of its own.

6. REGIONAL DIFFERENCES
None. The app behaves identically in every region and no feature is gated by country. Content is French-language only; the historical database is worldwide and includes a dedicated Africa and Middle East pack.

7. REGULATED INDUSTRY OR PROTECTED MATERIAL
Neither. The app does not operate in a regulated industry. The event texts were written for this app; the interface fonts (Nunito, Baloo 2) are used under the SIL Open Font License, whose licence file ships in the bundle. No third-party protected material is included.

Thank you for your time reviewing Erea.
```

### Message de suivi du 20 août *(point 2 manquant)*

```
Hello,

Following up on my previous reply: point 2 was accidentally left incomplete. Here is the full list.

2. DEVICES AND OS TESTED
- iPhone 16 Plus (physical device) — this is the device used for the attached screen recording (Erea.mov)
- iPad Pro 13-inch (M4) (physical device)

Both running the latest public release of iOS and iPadOS. Minimum deployment target: iOS 15.0. The app supports both iPhone and iPad.

Every other point of my previous reply stands unchanged.

Thank you.
```

> **Leçon pour la 1.1** : le fil accepte autant de messages qu'on veut et
> un envoi ne consomme pas l'édition unique de l'élément refusé — mais
> relire avant d'envoyer coûte moins cher qu'un aller-retour. Ce
> message-ci est d'ailleurs parti collé trois fois : sans conséquence, et
> surtout sans message d'excuse derrière.

---

## §3 — Deuxième demande, 21 août 2026 : « comment obtient-on les flammes ? »

Examinée sur **iPad Air 11 pouces (M3)**, version 1.0.0 (90). Une seule
question, sous *Guideline 2.1 — Information Needed* :

> *Would it be possible to confirm how users can obtain flames?*

C'est le contrôle habituel sur les **monnaies virtuelles** : tout ce qui
ressemble à une devise doit s'expliquer, et s'il s'achète, passer par
l'achat intégré.

⚠️ **Répondre suffit-il, ou faut-il re-soumettre ?** Le texte du message
ne le dit pas : le 15 août, une demande d'informations formulée de la même
façon s'accompagnait pourtant d'un **refus**. Seul l'**état affiché en
haut de la page « Soumission iOS »** tranche :

| État en haut de page | Ce qu'il faut faire |
|---|---|
| 🟡 « En attente de vérification » | répondre dans le fil suffit |
| 🔴 « Problèmes non résolus » + élément « Refusé » | répondre, **puis** Modifier → Ajouter pour vérification → Soumettre à nouveau |

Le signe décisif : un bouton *Soumettre à nouveau* **grisé** signale un
élément refusé à débloquer. Dans tous les cas, répondre d'abord — la
réponse est demandée explicitement et ne consomme aucune édition.

**Vérifié le 21 août : c'est bien un refus.** État « Problèmes non
résolus », élément *Refusé — 2.1.0 Performance: App Completeness*, bouton
grisé. Le « before we can *continue* our review » du message ne dit donc
**rien** de l'état réel : les deux demandes d'informations, celle du
15 août comme celle du 21, sont des refus formels qui exigent la
re-soumission. **Ne jamais déduire l'état du texte du message.**

À noter : Apple a joint à l'élément refusé une **capture d'écran**
(`Screenshot-0821-134031.png`, téléchargeable depuis la ligne de
l'élément) montrant l'écran qui a motivé la question. Le réflexe utile :
la télécharger avant de rédiger, elle désigne précisément ce que
l'examinateur avait sous les yeux.

La flamme apparaît à **trois** endroits du code, d'où une réponse qui les
couvre tous plutôt que le seul qui vient à l'esprit :

| Où | Quoi | Fichier |
|---|---|---|
| Accueil, « 🔥 N » | Série de jours consécutifs avec un Défi du jour **terminé** | `lib/ui/home_screen.dart` · `Store.effectiveStreak` |
| Bandeau en partie | Combo : 3 réponses ≥ 700 points d'affilée → ×1,5 d'**XP** sur la manche suivante, jamais sur les points | `lib/ui/game_screen.dart` · `GameController.combo` |
| Étiquette de difficulté | Emoji décoratif de « Difficile », et icône du badge « Tête brûlée » | `lib/core/scoring.dart` · `lib/game/badges.dart` |

**La capture jointe désigne la première**, d'une flèche rouge : la
pastille jaune de l'accueil, affichant **« 🔥 0 »** sur une installation
neuve. D'où la réponse ci-dessous, centrée sur celle-là — les deux autres
n'y figurent qu'en une phrase, pour éviter une troisième question.

```
Hello,

Thank you for the screenshot — it points at the flame counter on the home screen, so here is precisely what it is and how it is obtained.

WHAT IT IS
"🔥 0" is the Daily Challenge streak counter: the number of consecutive days on which the player has finished the Daily Challenge. It reads 0 in your screenshot because the app had just been installed and no Daily Challenge had been completed yet.

HOW IT IS OBTAINED
Only by playing, and in one single way. From the home screen, tap "Défi du jour", then "Jouer !", and play the 10 rounds through to the end:
- the counter turns to 🔥 1 as soon as that day's challenge is finished;
- it increases by 1 for each further consecutive day;
- starting a challenge and quitting it uses up that day's single attempt, but does not increase the counter;
- it resets to 0 as soon as one day is skipped.

WHAT IT IS NOT
It is not a virtual currency and has no monetary value. Flames cannot be bought, obtained through any payment, traded, gifted, converted or spent, and they unlock nothing — the entire game is available from the first launch. This version contains no in-app purchase of any kind. The count is stored locally on the device, and may optionally be submitted to the Game Center leaderboard "erea.streak".

For completeness, the same emoji appears in two unrelated, decorative places: a bonus banner shown during a game after three consecutive accurate answers, which multiplies that round's experience points by 1.5 and never the score; and as the icon of the "Difficile" difficulty level and of the "Tête brûlée" achievement badge. Neither can be purchased either.

Thank you for your time reviewing Erea.
```

### Ce que la capture apprend sur le produit

À l'installation, l'accueil affiche une pastille dorée portant **« 🔥 0 »**
et rien d'autre. Aucune légende, aucune info-bulle, et un compteur à zéro
qui n'indique ni ce qu'il compte ni comment le faire monter — c'est-à-dire
exactement la silhouette d'un solde de jetons. Un examinateur d'Apple s'y
est trompé ; un joueur qui installe le jeu se pose la même question.

✅ **Corrigé pour la 1.1** le 21 août 2026 : la pastille répond au tap.
Une feuille « Ta série 🔥 » dit ce qu'elle compte, comment la faire monter
et ce qui l'éteint, et l'étiquette d'accessibilité annonce un bouton.
Aucun changement dans la 1.0, dont le build 90 est en examen — la
correction part avec la 1.1 (`_expliquerSerie`, verrouillé par un test).
Le gain est double : une question de moins à chaque soumission, et un
accueil qui s'explique tout seul.

> **Leçon pour la 1.1** : ajouter d'emblée aux Remarques une ligne sur
> tout élément qui pourrait passer pour une devise — flammes, XP, niveaux,
> badges. La question tombera de toute façon, et elle coûte un jour
> d'examen à chaque fois.

---

## §2 — Champ « Remarques » de la page de version *(archive d'août, remplacée par le §0)*

*Distribution → App iOS Version 1.0.0 → tout en bas, sous les coordonnées
de contact. Remplace le texte court qui s'y trouve déjà.*

```
Erea is a single-player, offline history quiz in French. An event is shown without its date and the player drags a timeline (3000 BC to today) to guess the year.

NO ACCOUNT: the app has no registration, no login and no user accounts. Nothing is gated.
NO USER-GENERATED CONTENT: no posting, no comments, no sharing of user content.
NO SETUP: no credentials, no demo account, no sample files are needed. Every mode is reachable from the home screen and works in airplane mode.
OFFLINE: all content ships in the bundle. The app makes no network request of its own.

EXTERNAL SERVICES: Apple Game Center only (six optional leaderboards, lazy sign-in, silent failure). No backend, no analytics, no third-party data provider, no AI service.

SYSTEM PROMPTS: two, both optional — Game Center sign-in (leaderboards) and notification permission (optional evening reminder). Declining either leaves the app fully playable.

REGIONS: identical behaviour worldwide, no country gating. French-language content.

MODES: Classic (10 rounds, category and difficulty selectable), Daily Challenge (same questions for everyone, one attempt per day), Chrono (90 seconds), Flag Roulette (one country per game).
```

> **À la 1.1**, deux paragraphes seront à ajouter à ces notes : l'annonce
> de la publicité interstitielle (AdMob, jamais pendant une manche ni sur
> le Défi du jour) et le chemin exact pour atteindre l'achat « Erea sans
> publicité ». Le point 1 d'Apple exige que la vidéo montre le parcours
> d'achat — la prochaine capture devra donc l'inclure.

## Ce que le message d'Apple apprend pour la suite

Le même message liste les rejets les plus fréquents. Trois nous
concernent directement à la 1.1 :

- **2.1 – Bugs et plantages** : les apps sont examinées sur appareils
  physiques. Tester sur chaque plateforme supportée avant d'envoyer.
- **2.3.3 – Captures d'écran** : elles doivent montrer l'app en usage
  réel, pas un écran-titre ni un écran de démarrage.
- **3.1.2 – Abonnements** : sans objet, l'achat d'Erea est unique et
  définitif, pas un abonnement.
