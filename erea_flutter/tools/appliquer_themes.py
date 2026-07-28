#!/usr/bin/env python3
"""Applique les verdicts du reclassement thématique à events.json.

Écrit trois champs par fait : `cat` (le thème), `pays` et `continent`.

Comme `appliquer_difficulte.py`, tout est vérifié AVANT la moindre
écriture : un identifiant inconnu, un thème hors liste ou un continent
incohérent fait échouer l'ensemble plutôt que de corrompre la base à
moitié.

Usage :
    python3 tools/appliquer_themes.py verdicts/*.json            # aperçu
    python3 tools/appliquer_themes.py verdicts/*.json --ecrire
"""
import argparse
import collections
import json
import os

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(RACINE, 'assets', 'events.json')

# « Croyances » n'a récolté que 4 % de la base, très loin des 150 faits
# qu'il faut pour tenir 15 parties. Une religion étant d'abord un fait
# culturel, le thème est fondu dans « Culture », qui devient
# « Culture & croyances ». Le champ reste `arts` côté données pour ne pas
# invalider les sauvegardes des joueurs.
FUSION = {'croyances': 'arts'}

THEMES = {'pouvoir', 'sciences', 'arts', 'quotidien'}
CONTINENTS = {'europe', 'asie', 'afrique', 'ameriques', 'oceanie'}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('verdicts', nargs='+')
    ap.add_argument('--ecrire', action='store_true')
    a = ap.parse_args()

    with open(BASE, encoding='utf-8') as f:
        ev = json.load(f)
    par_id = {e['id']: e for e in ev}

    verdicts, doublons = {}, []
    for chemin in a.verdicts:
        with open(chemin, encoding='utf-8') as f:
            for v in json.load(f):
                if v['id'] in verdicts:
                    doublons.append(v['id'])
                v['theme'] = FUSION.get(v['theme'], v['theme'])
                verdicts[v['id']] = v

    erreurs = []
    if doublons:
        erreurs.append(f'{len(doublons)} identifiants notés deux fois : '
                       f'{sorted(set(doublons))[:8]}')
    inconnus = [i for i in verdicts if i not in par_id]
    if inconnus:
        erreurs.append(f'{len(inconnus)} identifiants inconnus : {inconnus[:8]}')
    hors = [v['id'] for v in verdicts.values() if v['theme'] not in THEMES]
    if hors:
        erreurs.append(f'{len(hors)} thèmes hors liste : {hors[:8]}')
    # Un pays sans continent sortirait de la roulette mais d'aucun groupe.
    boiteux = [v['id'] for v in verdicts.values()
               if v['pays'] and v['continent'] not in CONTINENTS]
    if boiteux:
        erreurs.append(f'{len(boiteux)} pays sans continent valide : '
                       f'{boiteux[:8]}')
    manquants = [e['id'] for e in ev if e['id'] not in verdicts]
    if manquants:
        erreurs.append(f'{len(manquants)} faits sans verdict : {manquants[:8]}')
    if erreurs:
        for e in erreurs:
            print('ERREUR :', e)
        raise SystemExit(1)

    avant_cat = collections.Counter(e['cat'] for e in ev)
    apres_cat = collections.Counter(v['theme'] for v in verdicts.values())
    avant_pays = sum(1 for e in ev if e.get('pays'))
    apres_pays = sum(1 for v in verdicts.values() if v['pays'])

    print(f'{len(verdicts)} faits reclassés sur {len(ev)}\n')
    print('anciennes catégories :', dict(avant_cat.most_common()))
    print('\nnouvelles catégories :')
    for k, n in apres_cat.most_common():
        etat = 'OK' if n >= 150 else 'SOUS LE PLANCHER DE 15 PARTIES'
        print(f'   {k:10} {n:5} ({n / len(ev) * 100:4.1f} %)  '
              f'{n // 10:3} parties  {etat}')

    print(f'\npays renseigné : {avant_pays} -> {apres_pays} '
          f'({apres_pays / len(ev) * 100:.0f} % de la base)')
    pays = collections.Counter(v['pays'] for v in verdicts.values() if v['pays'])
    jouables = [p for p, n in pays.items() if n >= 10]
    print(f'pays distincts : {len(pays)}   dont {len(jouables)} jouables '
          f'(≥ 10 faits, seuil de la roulette)')
    print('   top :', ', '.join(f'{p} {n}' for p, n in pays.most_common(6)))

    if not a.ecrire:
        print('\n(aperçu seulement — relance avec --ecrire pour appliquer)')
        return

    for e in ev:
        v = verdicts[e['id']]
        e['cat'] = v['theme']
        if v['pays']:
            e['pays'] = v['pays']
            e['continent'] = v['continent']
        else:
            e.pop('pays', None)
            e.pop('continent', None)
    with open(BASE, 'w', encoding='utf-8') as f:
        json.dump(ev, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(f'\nécrit : {BASE}')


if __name__ == '__main__':
    main()
