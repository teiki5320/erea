# Outils de synthèse des sons

Les six sons d'Erea ne sont pas des fichiers trouvés quelque part : ils
sont **calculés**. Ces scripts les régénèrent, ce qui permet de les
retoucher sans repartir de zéro.

| Script | À quoi il sert |
|---|---|
| `synth.py` | Les briques (enveloppes, FM, cloches, réverbération) et les trois styles comparés : **A bois & feutre** (retenu), B arcade, C cristal. Écrit des démos à écouter. |
| `final.py` | Génère les six `.wav` définitifs dans `assets/sfx/`, en 22 050 Hz mono, queues rognées. ~99 Ko au total. |
| `cliquetis.py` | Simule un vrai balayage de frise — mêmes maths que `timeline_scale.dart`, même inertie que `tape_widget.dart` — et rend le cliquetis obtenu. C'est lui qui a montré que la cadence à la décennie donnait 4 crans par balayage sur les époques récentes contre 29 sur l'Antiquité. |

```bash
pip install numpy
python3 tools/final.py      # régénère assets/sfx/
```

## Pourquoi la cadence est à la DISTANCE

L'échelle de la frise est non linéaire : une décennie fait ~76 px vers
l'an 2000 mais ~2 px vers −2000. Un cran par décennie donnait donc un tic
occasionnel là où l'on joue le plus, et une mitraille dans l'Antiquité.
Un cran tous les **40 px de ruban** sonne pareil partout, et ralentit avec
l'inertie — comme une roue qui s'arrête.
