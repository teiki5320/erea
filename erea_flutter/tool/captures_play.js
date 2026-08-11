// Capture les écrans du Play Store depuis la version web de l'app.
//
// Les captures iOS ne se recyclent pas : Google refuse qu'une dimension
// dépasse le double de l'autre, et l'iPhone 6,9" est à 2,17. On produit
// donc du 1080 x 2160, rapport exactement 2.
//
// Pourquoi le web plutôt que flutter_test : sous flutter_test aucune
// police emoji n'est chargée, et le jeu en est truffé — la roulette n'y
// serait qu'une grille de rectangles. Ici, Flutter web réclame de
// lui-même une police de secours dès qu'un glyphe lui manque, et on la
// lui sert depuis le système : rien à modifier dans le build.
//
// Prérequis :
//   flutter build web --release
//   cd build/web && python3 -m http.server 8099 &
//
//   node tool/captures_play.js
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

// Chemins déduits de l'emplacement du script : il doit tourner sur
// n'importe quelle machine, pas seulement celle qui l'a écrit.
const APP = path.resolve(__dirname, '..');
const WEB = path.join(APP, 'build', 'web');
const SORTIE = path.resolve(APP, '..', 'docs', 'play', 'captures');
const ADRESSE = 'http://localhost:8099/index.html';

// 400 x 800 points a 2,7 : exactement 1080 x 2160 pixels. Le compte doit
// tomber juste — a 411 points la largeur donnait 1079, soit un rapport de
// 2,002 que Google refuse.
const VUE = { width: 400, height: 800 };
const DENSITE = 2.7;

const pause = (ms) => new Promise((r) => setTimeout(r, ms));

async function preparer(contexte) {
  // CanvasKit vient de gstatic, injoignable d'ici : on le sert depuis le
  // SDK. Roboto n'est pas utilisée par l'app, on s'en passe.
  await contexte.route('**/flutter-canvaskit/**', (r) => {
    const u = new URL(r.request().url());
    const f = path.join(WEB, 'canvaskit', u.pathname.split('/').slice(3).join('/'));
    r.fulfill({
      path: f,
      contentType: f.endsWith('.wasm') ? 'application/wasm' : 'text/javascript',
    }).catch(() => r.abort());
  });
  // Flutter web repère les glyphes manquants et va chercher la police
  // Noto correspondante chez gstatic. On la lui sert depuis le système :
  // sans elle, tous les emoji du jeu sont des rectangles.
  await contexte.route('**/fonts.gstatic.com/**', (r) => {
    // Deux demandes distinctes partent chez gstatic : Roboto, police par
    // défaut des textes qui n'en déclarent pas (les graduations de la
    // frise), et un secours de glyphe pour les emoji, au nom haché. Les
    // confondre donne des graduations aux métriques d'emoji : « 1 5 0 0 ».
    const latine = r.request().url().includes('/s/roboto/');
    r.fulfill({
      path: latine
        ? '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
        : '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
      contentType: 'font/ttf',
    }).catch(() => r.abort());
  });
}

/// Attend que l'app soit peinte, puis ouvre l'arbre de sémantique : sans
/// lui le rendu n'est qu'un canvas, sans rien à cliquer par son texte.
async function attendrePrete(page) {
  await pause(9000);
  await page.evaluate(() => {
    document.querySelector('flt-semantics-placeholder')?.click();
  });
  await pause(1500);
}

async function cliquer(page, texte, attente = 1800) {
  const cible = page.getByText(texte, { exact: false }).first();
  // Un événement à longue description repousse les commandes sous la
  // ligne de flottaison. Flutter ne construit pas les widgets hors écran,
  // donc leur nœud de sémantique n'existe pas non plus : attendre ne sert
  // à rien, il faut faire défiler pour les faire naître.
  for (let essai = 0; essai < 8 && !(await cible.count()); essai++) {
    await page.mouse.move(VUE.width / 2, VUE.height / 2);
    await page.mouse.wheel(0, 260);
    await pause(600);
  }
  try {
    await cible.waitFor({ state: 'attached', timeout: 15000 });
  } catch (e) {
    throw new Error('introuvable : « ' + texte + ' »');
  }
  const boite = await cible.boundingBox();
  if (boite) {
    await page.mouse.click(boite.x + boite.width / 2, boite.y + boite.height / 2);
  } else {
    await cible.click({ force: true });
  }
  await pause(attente);
}

async function passerOnboarding(page) {
  for (let i = 0; i < 4; i++) {
    try {
      await cliquer(page, 'Suivant', 1200);
    } catch (_) {
      break;
    }
  }
  for (const fin of ['Commencer', 'est parti', 'Jouer']) {
    try {
      await cliquer(page, fin, 3000);
      return;
    } catch (_) {}
  }
}

(async () => {
  fs.mkdirSync(SORTIE, { recursive: true });
  const navigateur = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium',
  });
  // UN seul contexte : le passage de l'onboarding est mémorisé, et les
  // rechargements suivants tombent droit sur l'accueil.
  const contexte = await navigateur.newContext({
    viewport: VUE,
    deviceScaleFactor: DENSITE,
    // Le service worker resservirait l'ancien FontManifest depuis son
    // cache, sans la police emoji qu'on vient d'y ajouter.
    serviceWorkers: 'block',
  });
  await preparer(contexte);

  const page = await contexte.newPage();
  await page.goto(ADRESSE, { waitUntil: 'load', timeout: 60000 });
  await attendrePrete(page);
  await passerOnboarding(page);

  const scenarios = [
    ['1-accueil', async () => {}],
    ['2-partie', async (p) => {
      await cliquer(p, 'Classique');
      await cliquer(p, 'est parti', 2500);
    }],
    // La frise part de 1580 et on ne sait pas viser : marquer suppose un
    // événement tombé dans la fenêtre de 200 ans du barème. On enchaîne
    // manches et parties en gardant la meilleure révélation vue, et on
    // s'arrête dès qu'un score est franchement montrable — une capture
    // « Trop loin, +0 pts » ne vend rien.
    ['3-revelation', async (p) => {
      const cible = path.join(SORTIE, '3-revelation.png');
      let meilleur = -1;
      for (let partie = 1; partie <= 6 && meilleur < 400; partie++) {
        if (partie > 1) {
          await p.reload({ waitUntil: 'load', timeout: 60000 });
          await attendrePrete(p);
        }
        await cliquer(p, 'Classique');
        await cliquer(p, 'est parti', 2500);
        for (let manche = 1; manche <= 9 && meilleur < 400; manche++) {
          await cliquer(p, '+', 900);
          await cliquer(p, 'Je place ici', 3200);
          const texte = await p.evaluate(() => document.body.innerText || '');
          const trouve = /\+\s*(\d+)\s*pts/.exec(texte);
          const points = trouve ? Number(trouve[1]) : 0;
          if (points > meilleur) {
            meilleur = points;
            await p.screenshot({ path: cible });
            console.log('     ' + points + ' pts retenus (partie ' + partie +
                        ', manche ' + manche + ')');
          }
          if (meilleur < 400) await cliquer(p, 'Manche suivante', 2600);
        }
      }
      return true; // déjà capturée : la boucle ne doit pas l'écraser
    }],
    ['4-roulette', async (p) => {
      await cliquer(p, 'Roulette', 2500);
    }],
    ['5-chrono', async (p) => {
      await cliquer(p, 'Chrono', 2500);
    }],
    ['6-packs', async (p) => {
      await cliquer(p, 'Packs', 2500);
    }],
    // L'écran de fin porte la grille emoji qu'on partage : c'est le
    // ressort viral du jeu, il mérite sa capture. Seul moyen d'y arriver :
    // jouer les dix manches.
    ['7-fin', async (p) => {
      await cliquer(p, 'Classique');
      await cliquer(p, 'est parti', 2500);
      for (let manche = 1; manche <= 10; manche++) {
        await cliquer(p, '+', 900);
        await cliquer(p, 'Je place ici', 3000);
        await cliquer(p, manche < 10 ? 'Manche suivante' : 'Voir mes résultats',
                      manche < 10 ? 2400 : 4000);
      }
    }],
  ];

  // Un argument ne rejoue que les captures dont le nom le contient :
  //   node tool/captures_play.js 7-fin
  const filtre = process.argv[2];
  const aFaire = filtre
    ? scenarios.filter(([nom]) => nom.includes(filtre))
    : scenarios;

  for (const [nom, parcours] of aFaire) {
    try {
      await page.reload({ waitUntil: 'load', timeout: 60000 });
      await attendrePrete(page);
      const dejaPrise = await parcours(page);
      if (!dejaPrise) {
        await page.screenshot({ path: path.join(SORTIE, nom + '.png') });
      }
      console.log('  ->', nom + '.png');
    } catch (e) {
      console.log('  !!', nom, String(e).split('\n')[0].slice(0, 110));
    }
  }

  await navigateur.close();
})();
