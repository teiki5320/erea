# Outils de synthèse des sons

Les sons d'Erea ne sont pas des fichiers trouvés quelque part : ils sont
**calculés**. Ces scripts les régénèrent, ce qui permet de les retoucher
sans repartir de zéro.

| Script | À quoi il sert |
|---|---|
| `synth.py` | Les briques (enveloppes, FM, cloches, réverbération) et les trois styles comparés : **A bois & feutre** (retenu), B arcade, C cristal. Écrit des démos à écouter. |
| `final.py` | Génère les cinq sons de verdict (`pop`, `bien`, `moyen`, `rate`, `parfait`) dans `assets/sfx/`, en 22 050 Hz mono, queues rognées. ~98 Ko. |
| `montre.py` | Génère le cliquetis de la frise : `tic.wav` et `tac.wav`, l'échappement d'une montre-bracelet mécanique. 5,3 Ko. |
| `cliquetis.py` | Simule un vrai balayage de frise — mêmes maths que `timeline_scale.dart`, même inertie que `tape_widget.dart` — et rend le cliquetis obtenu. C'est lui qui a montré que la cadence à la décennie donnait 4 crans par balayage sur les époques récentes contre 29 sur l'Antiquité. |

```bash
pip install numpy
python3 tools/final.py      # les cinq verdicts
python3 tools/montre.py     # le cliquetis de la frise
```

## Pourquoi DEUX fichiers pour le cliquetis

Le cran de la frise s'entend des dizaines de fois par partie. Tant qu'il
rejouait un échantillon unique, il sonnait artificiel — et c'est le
reproche qui revenait à chaque essai.

Une montre n'émet jamais deux fois le même son : les deux palettes de
l'ancre n'ont ni la même géométrie ni le même point de contact, d'où le
« tic-tac » et non le « tic-tic ». `montre.py` produit donc deux
échantillons aux résonances décalées, et `Sons.cran()` les alterne grâce
à un tour de rôle sur un nombre PAIR de lecteurs (rangs pairs = tic,
impairs = tac).

Le reste du réalisme tient à deux détails :

- **un tic n'est pas un impact, c'en est trois** — déverrouillage,
  impulsion, chute de l'ancre, à 0, 2,2 et 4,1 ms ;
- **le caractère vient du boîtier** — le choc n'est qu'une bouffée de
  bruit d'1,4 ms ; ce sont les quatre résonateurs (2750, 4300, 1180 et
  620 Hz) qui font entendre de l'acier.

## Pourquoi la cadence est à la DISTANCE

L'échelle de la frise est non linéaire : une décennie fait ~76 px vers
l'an 2000 mais ~2 px vers −2000. Un cran par décennie donnait donc un tic
occasionnel là où l'on joue le plus, et une mitraille dans l'Antiquité.
Un cran tous les **40 px de ruban** sonne pareil partout, et ralentit avec
l'inertie — comme une roue qui s'arrête.
