# Répondre à l'App Review — Erea

> Écrit le 20 août 2026, à partir du message d'Apple du 15 août et de la
> documentation d'App Store Connect.

## Où on en est, exactement

La version **1.0.0 (build 90)**, soumise le 14 août 2026 à 11 h 42
(identifiant `ac15df9e-b4e0-40e6-8834-6cb24d3fbc0d`), est **refusée** —
état affiché *2.1.0 Performance: App Completeness*, message
**Guideline 2.1 – Information Needed – New App Submission**.

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
3. Cliquer **Modifier** en face de l'élément refusé, puis **Ajouter pour
   vérification**.
4. Cliquer **Soumettre à nouveau à l'équipe de vérification** : le bouton
   se dégrise une fois l'étape 3 faite.

⚠️ **Un élément ne peut être édité qu'une seule fois avant
re-soumission**, et un élément retiré ne peut plus être réajouté à la même
soumission. Pas de manipulation à l'aveugle.

---

## §1 — Réponse aux sept points *(à coller telle quelle)*

> ⚠️ **Une seule valeur à compléter avant l'envoi** : la liste des
> appareils du point 2. Le reste est vérifié sur le dépôt.

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
[À COMPLÉTER — modèles et versions, par exemple : iPhone 14 (iOS 18.6), iPad Air 5th generation (iPadOS 18.6)]
Minimum deployment target: iOS 15.0. The app supports both iPhone and iPad.

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

---

## §2 — Champ « Remarques » de la page de version *(à coller, et à garder pour la 1.1)*

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
