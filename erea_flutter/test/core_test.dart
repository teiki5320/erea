import 'package:erea/core/progression.dart';
import 'package:erea/core/rng.dart';
import 'package:erea/core/scoring.dart';
import 'package:erea/core/sons.dart';
import 'package:erea/core/timeline_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timeline_scale', () {
    test('les bornes tombent sur 0 et 1', () {
      expect(yearToFrac(minYear), 0.0);
      expect(yearToFrac(maxYear), closeTo(1.0, 1e-9));
    });

    test('les frontières de segments respectent les parts annoncées', () {
      expect(yearToFrac(0), closeTo(0.20, 1e-9));
      expect(yearToFrac(1500), closeTo(0.45, 1e-9));
      expect(yearToFrac(1900), closeTo(0.70, 1e-9));
    });

    test('yearToFrac et fracToYear sont réciproques', () {
      for (final y in [-3000, -480, 0, 800, 1492, 1789, 1900, 1969, 2026]) {
        expect(fracToYear(yearToFrac(y)), y, reason: 'année $y');
      }
    });

    test('les années hors bornes sont ramenées dans la frise', () {
      expect(yearToFrac(-5000), 0.0);
      expect(yearToFrac(3000), closeTo(1.0, 1e-9));
      expect(fracToYear(-1), minYear);
      expect(fracToYear(2), maxYear);
    });

    test('le XXe siècle occupe 30 % de la frise (précision voulue)', () {
      expect(yearToFrac(2026) - yearToFrac(1900), closeTo(0.30, 1e-9));
    });

    test('formatYear ajoute « av. J.-C. » pour les années négatives', () {
      expect(formatYear(-480), '480 av. J.-C.');
      expect(formatYear(1515), '1515');
    });

    test('eraFor découpe les grandes époques scolaires', () {
      expect(eraFor(-2000).name, 'Âge du bronze');
      expect(eraFor(-800).name, 'Âge du fer');
      expect(eraFor(-52).name, 'Antiquité');
      expect(eraFor(476).name, 'Antiquité');
      expect(eraFor(800).name, 'Moyen Âge');
      expect(eraFor(1492).name, 'Moyen Âge');
      expect(eraFor(1515).name, 'Époque moderne');
      expect(eraFor(1969).name, 'Époque contemporaine');
    });
  });

  group('scoring', () {
    test('une réponse exacte vaut 1000 (PERFECT)', () {
      expect(scoreFor(1789, 1789, Difficulty.normal), maxScore);
      expect(scoreFor(-480, -480, Difficulty.difficile), maxScore);
    });

    test('le zéro arrive à 7,6 × la tolérance, et suit donc le mode', () {
      // Il n'y a plus de fenêtre dure : l'exponentielle atteint zéro
      // d'elle-même. Facile 502 ans, Normal 229, Difficile 126.
      const bornes = {
        Difficulty.facile: 502,
        Difficulty.normal: 229,
        Difficulty.difficile: 126,
      };
      bornes.forEach((diff, zero) {
        expect(scoreFor(1500, 1500 + zero, diff), 0,
            reason: '${diff.label} : zéro attendu à $zero ans');
        expect(scoreFor(1500, 1500 + zero - 1, diff), greaterThan(0),
            reason: '${diff.label} : encore des points à ${zero - 1} ans');
      });
    });

    test('la tolérance ne dépend QUE du mode, jamais de l’époque', () {
      expect(tolerance(Difficulty.facile), closeTo(toleranceBase * 2.2, 1e-9));
      expect(tolerance(Difficulty.normal), toleranceBase);
      expect(tolerance(Difficulty.difficile),
          closeTo(toleranceBase * 0.55, 1e-9));
    });

    test('à écart égal, le score est le même à toutes les époques', () {
      // Le vrai garde-fou. Avec l'ancienne tolérance proportionnelle à
      // l'ancienneté, 50 ans d'erreur valaient 777 points avant notre ère
      // et 150 points en l'an 2000 : une partie qui tirait beaucoup
      // d'Antiquité était mécaniquement plus généreuse.
      for (final diff in Difficulty.values) {
        for (final ecart in [0, 5, 20, 50, 120]) {
          final reference = scoreFor(2000, 2000 + ecart, diff);
          for (final annee in [-3000, -500, 476, 1492, 1789, 1900, 2020]) {
            expect(scoreFor(annee, annee + ecart, diff), reference,
                reason: 'écart de $ecart ans en ${diff.label} : '
                    'l’an $annee ne doit pas rapporter plus que l’an 2000');
          }
        }
      }
    });

    test('le vert (700 pts) reste atteignable en Difficile sur du récent',
        () {
      // Avec l'ancien plancher de 5 ans, il fallait l'ANNÉE EXACTE : le
      // combo était inatteignable.
      expect(scoreFor(2000, 2002, Difficulty.difficile),
          greaterThanOrEqualTo(700));
    });

    test('la fenêtre à zéro est la même partout', () {
      // Ce test vérifiait l'inverse : 150 ans d'erreur sur un fait de
      // -2500 rapportaient encore des points en Difficile, alors que le
      // même écart sur du récent valait zéro. L'époque ne donne plus
      // aucun passe-droit.
      expect(scoreFor(-2500, -2350, Difficulty.difficile), 0);
      expect(scoreFor(2000, 2150, Difficulty.difficile), 0);
      expect(scoreFor(-2500, -2380, Difficulty.difficile),
          scoreFor(2000, 2120, Difficulty.difficile));
      expect(scoreFor(-2500, -2400, Difficulty.facile),
          scoreFor(2000, 2100, Difficulty.facile));
    });

    test('le score décroît avec l’écart et jamais en négatif', () {
      var previous = maxScore + 1;
      for (var ecart = 0; ecart < 200; ecart++) {
        final pts = scoreFor(1800, 1800 + ecart, Difficulty.normal);
        expect(pts, lessThanOrEqualTo(previous));
        expect(pts, inInclusiveRange(0, maxScore));
        previous = pts;
      }
    });

    test('le score est symétrique (trop tôt / trop tard)', () {
      expect(scoreFor(1789, 1769, Difficulty.normal),
          scoreFor(1789, 1809, Difficulty.normal));
    });

    test('à écart égal, Facile rapporte plus que Difficile', () {
      final facile = scoreFor(1789, 1809, Difficulty.facile);
      final normal = scoreFor(1789, 1809, Difficulty.normal);
      final difficile = scoreFor(1789, 1809, Difficulty.difficile);
      expect(facile, greaterThan(normal));
      expect(normal, greaterThan(difficile));
    });

    test('seule la manche 10 est doublée, jamais en Chrono', () {
      expect(roundMultiplier(0), 1);
      expect(roundMultiplier(8), 1);
      expect(roundMultiplier(9), 2);
      expect(roundMultiplier(9, chrono: true), 1);
    });

    test('le total maximal annoncé (11 000) est cohérent', () {
      var total = 0;
      for (var r = 0; r < rounds; r++) {
        total += maxScore * roundMultiplier(r);
      }
      expect(total, maxTotal);
    });
  });

  group('progression', () {
    test('le coût d’un niveau suit 400 + (n-1) x 300', () {
      expect(xpNeededFor(1), 400);
      expect(xpNeededFor(2), 700);
      expect(xpNeededFor(5), 1600);
    });

    test('levelFromXp place correctement les paliers', () {
      expect(levelFromXp(0).level, 1);
      expect(levelFromXp(399).level, 1);
      expect(levelFromXp(400).level, 2);
      expect(levelFromXp(1099).level, 2); // 400 + 700 - 1
      expect(levelFromXp(1100).level, 3);
    });

    test('l’XP restante ne dépasse jamais le coût du niveau courant', () {
      for (var xp = 0; xp < 20000; xp += 137) {
        final info = levelFromXp(xp);
        expect(info.into, inInclusiveRange(0, info.need - 1));
      }
    });

    test('titleFor renvoie le titre du palier atteint', () {
      expect(titleFor(1).titre, 'Apprenti du temps');
      expect(titleFor(8).titre, 'Historien'); // pas de palier 8 : on garde 7
      expect(titleFor(10).titre, 'Maître du temps');
      expect(titleFor(13).titre, 'Légende');
      // La progression ne s'arrête plus au niveau 13.
      expect(titleFor(25).titre, 'Oracle');
      expect(titleFor(99).titre, 'Immortel');
    });

    test('xpGain applique le multiplicateur et plafonne à 2000', () {
      expect(xpGain(8000, 1.0), 800);
      expect(xpGain(8000, 1.3), 1040);
      expect(xpGain(8000, 0.8), 640);
      expect(xpGain(100000, 1.3), 2000);
      expect(xpGain(0, 1.0), 0);
    });
  });

  group('rng (parité bit à bit avec le prototype web)', () {
    test('mulberry32 reproduit la série JS pour la graine du 26/07/2026', () {
      // Valeurs de référence produites par la fonction mulberry32 du
      // prototype web (index.html) exécutée sous Node.
      final rng = mulberry32(20260726);
      const expected = [
        0.8306827687192708,
        0.3099368861876428,
        0.972827275050804,
        0.07732103252783418,
        0.021504703210666776,
      ];
      for (final e in expected) {
        expect(rng(), closeTo(e, 1e-15));
      }
    });

    test('mulberry32 reproduit la série JS pour la graine 1', () {
      final rng = mulberry32(1);
      const expected = [
        0.6270739405881613,
        0.002735721180215478,
        0.5274470399599522,
      ];
      for (final e in expected) {
        expect(rng(), closeTo(e, 1e-15));
      }
    });

    test('les tirages restent dans [0, 1)', () {
      final rng = mulberry32(42);
      for (var i = 0; i < 5000; i++) {
        final v = rng();
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThan(1.0));
      }
    });

    test('dailySeed encode la date en AAAAMMJJ', () {
      expect(dailySeed(DateTime(2026, 7, 26)), 20260726);
      expect(dailySeed(DateTime(2026, 1, 1)), 20260101);
    });

    test('shuffled est déterministe à graine égale et conserve les éléments',
        () {
      final source = List<int>.generate(50, (i) => i);
      final a = shuffled(source, mulberry32(20260726));
      final b = shuffled(source, mulberry32(20260726));
      expect(a, b);
      expect(a, isNot(source)); // très improbable d'être identique
      expect(a.toSet(), source.toSet());
      expect(source, List<int>.generate(50, (i) => i)); // source intacte
    });
  });

  group('cliquetis de la frise', () {
    // Le cran s'entend des dizaines de fois par partie. Tant qu'il rejouait
    // un échantillon unique il sonnait artificiel : une vraie montre alterne
    // deux sons, parce que les deux palettes de l'ancre n'ont ni la même
    // géométrie ni le même point de contact.
    test('le tour de rôle alterne bien le tic et le tac', () {
      // Une longueur impaire ferait boucler le tour de rôle sur un rang
      // pair, et deux tics se suivraient sans que rien n'échoue.
      expect(Sons.nombreLecteursCran.isEven, isTrue,
          reason: 'le nombre de lecteurs doit rester pair');
      expect(Sons.nombreLecteursCran, greaterThanOrEqualTo(4),
          reason: 'il en faut assez pour superposer les crans rapprochés');

      final joues = <String>[];
      for (var tour = 0; tour < 3; tour++) {
        for (var i = 0; i < Sons.nombreLecteursCran; i++) {
          joues.add(Sons.alimenter(i));
        }
      }
      for (var i = 1; i < joues.length; i++) {
        expect(joues[i], isNot(joues[i - 1]),
            reason: 'deux crans identiques de suite au rang $i');
      }
      expect(joues.toSet(), {'sfx/tic.wav', 'sfx/tac.wav'});
    });
  });

  group('sensibilité du glissement', () {
    // La frise est non linéaire : l'Antiquité met 15 000 ans là où
    // l'époque contemporaine en met 420, un rapport de 36 que le doigt ne
    // voit pas. Le facteur de glissement doit gommer cet écart en geste
    // lent, et s'effacer en geste rapide.
    const epoques = [-2000, 800, 1700, 1980];

    test('un geste LENT déplace le même nombre d’années partout', () {
      final reference = facteurGlissement(yearToFrac(1980), 0.5) *
          densiteLocale(yearToFrac(1980));
      for (final annee in epoques) {
        final f = yearToFrac(annee);
        final ansParPx = facteurGlissement(f, 0.5) * densiteLocale(f);
        expect(ansParPx, closeTo(reference, reference * 0.01),
            reason: 'précision en $annee différente du contemporain');
      }
    });

    test('un geste RAPIDE suit le doigt, à toutes les époques', () {
      for (final annee in epoques) {
        expect(facteurGlissement(yearToFrac(annee), 10), closeTo(1.0, 1e-9),
            reason: 'la navigation ne doit pas être bridée en $annee');
      }
    });

    test('l’époque contemporaine garde son plancher historique de 0,4', () {
      expect(facteurGlissement(yearToFrac(1980), 0), closeTo(0.4, 1e-9));
    });

    test('le facteur croît continûment avec la vitesse', () {
      final f = yearToFrac(-2000);
      var precedent = -1.0;
      for (var v = 0.0; v <= 12; v += 0.25) {
        final x = facteurGlissement(f, v);
        expect(x, greaterThanOrEqualTo(precedent));
        expect(x, inInclusiveRange(0.0, 1.0));
        precedent = x;
      }
    });
  });
}
