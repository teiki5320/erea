#!/usr/bin/env python3
"""Applique les verdicts de la passe de difficulté à events.json.

Lit un ou plusieurs fichiers de verdicts (JSON : [{id, niveau, raison}, …]),
vérifie leur cohérence, puis réécrit la base. Rien n'est modifié tant que
la vérification n'est pas passée : un identifiant inconnu ou un niveau
hors bornes fait échouer l'ensemble plutôt que de corrompre la base à
moitié.

Usage :
    python3 tools/appliquer_difficulte.py verdicts/*.json            # aperçu
    python3 tools/appliquer_difficulte.py verdicts/*.json --ecrire   # applique
"""
import argparse
import collections
import json
import os

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(RACINE, 'assets', 'events.json')


def charger_verdicts(chemins):
    verdicts, doublons = {}, []
    for c in chemins:
        with open(c, encoding='utf-8') as f:
            for v in json.load(f):
                if v['id'] in verdicts:
                    doublons.append(v['id'])
                verdicts[v['id']] = v
    return verdicts, doublons


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('verdicts', nargs='+')
    ap.add_argument('--ecrire', action='store_true')
    a = ap.parse_args()

    with open(BASE, encoding='utf-8') as f:
        ev = json.load(f)
    par_id = {e['id']: e for e in ev}

    verdicts, doublons = charger_verdicts(a.verdicts)

    # --- vérifications, toutes avant la moindre écriture
    erreurs = []
    if doublons:
        erreurs.append(f'{len(doublons)} identifiants notés deux fois : '
                       f'{sorted(set(doublons))[:10]}')
    inconnus = [i for i in verdicts if i not in par_id]
    if inconnus:
        erreurs.append(f'{len(inconnus)} identifiants inconnus : {inconnus[:10]}')
    hors = [v['id'] for v in verdicts.values() if v['niveau'] not in (1, 2, 3)]
    if hors:
        erreurs.append(f'{len(hors)} niveaux hors de 1..3 : {hors[:10]}')
    sans_raison = [v['id'] for v in verdicts.values()
                   if par_id.get(v['id'], {}).get('niveau') != v['niveau']
                   and not (v.get('raison') or '').strip()]
    if sans_raison:
        erreurs.append(f'{len(sans_raison)} changements sans justification : '
                       f'{sans_raison[:10]}')
    if erreurs:
        for e in erreurs:
            print('ERREUR :', e)
        raise SystemExit(1)

    # --- bilan
    mouvements = collections.Counter()
    for i, v in verdicts.items():
        avant = par_id[i]['niveau']
        if avant != v['niveau']:
            mouvements[(avant, v['niveau'])] += 1

    apres = collections.Counter()
    for e in ev:
        apres[verdicts[e['id']]['niveau'] if e['id'] in verdicts
              else e['niveau']] += 1
    avant = collections.Counter(e['niveau'] for e in ev)

    print(f'{len(verdicts)} faits notés sur {len(ev)}')
    print('\nmouvements :')
    for (de, vers), n in sorted(mouvements.items()):
        fleche = 'monte' if vers < de else 'descend'
        print(f'   niveau {de} -> {vers}  {n:4}  ({fleche})')
    print(f'   inchangés         {len(verdicts) - sum(mouvements.values()):4}')
    print('\nniveaux :')
    for n in (1, 2, 3):
        print(f'   niveau {n} : {avant[n]:4} -> {apres[n]:4}  '
              f'({apres[n] - avant[n]:+d})')

    # Facile tire 10 manches ; il faut de quoi tenir 15 parties sans répétition.
    print(f'\nFacile en 10/0 : {apres[1] // 10} parties avant répétition '
          f'(plancher visé : 15, soit 150 faits en niveau 1)')

    if not a.ecrire:
        print('\n(aperçu seulement — relance avec --ecrire pour appliquer)')
        return

    for e in ev:
        if e['id'] in verdicts:
            e['niveau'] = verdicts[e['id']]['niveau']
    with open(BASE, 'w', encoding='utf-8') as f:
        json.dump(ev, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(f'\nécrit : {BASE}')


if __name__ == '__main__':
    main()
