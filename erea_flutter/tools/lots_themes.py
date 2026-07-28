#!/usr/bin/env python3
"""Découpe events.json en lots pour la passe de reclassement thématique.

Même principe que `lots_difficulte.py` : les agents lisent des fichiers
plutôt que de recevoir 1 700 faits dans un prompt.

L'entrelacement est encore plus important ici que pour la difficulté. Un
lot « tout arts » pousserait le correcteur à trouver des nuances entre
des faits qui vont tous au même endroit, et un lot « tout monde » lui
ferait oublier que les cinq thèmes existent. Chaque lot doit ressembler
à la base entière.

Usage :
    python3 tools/lots_themes.py --taille 85 --sortie <dir>
"""
import argparse
import collections
import json
import os

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(RACINE, 'assets', 'events.json')


def lots(evenements, taille):
    tries = sorted(evenements, key=lambda e: (e['cat'], e['annee'], e['id']))
    n = max(1, -(-len(tries) // taille))
    paquets = [[] for _ in range(n)]
    for i, e in enumerate(tries):
        paquets[i % n].append(e)
    return paquets


def alleger(e):
    """Ce dont le correcteur a besoin. On passe l'ancienne catégorie et le
    pays existant : le premier pour information, le second pour qu'il ne
    défasse pas un travail déjà fait."""
    out = {
        'id': e['id'],
        'annee': e['annee'],
        'titre': e['titre'],
        'desc': e['desc'],
        'ancienne_categorie': e['cat'],
    }
    if e.get('pays'):
        out['pays_actuel'] = e['pays']
    if e.get('continent'):
        out['continent_actuel'] = e['continent']
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--taille', type=int, default=85)
    ap.add_argument('--sortie', required=True)
    a = ap.parse_args()

    with open(BASE, encoding='utf-8') as f:
        ev = json.load(f)
    os.makedirs(a.sortie, exist_ok=True)
    paquets = lots(ev, a.taille)
    for i, p in enumerate(paquets):
        with open(os.path.join(a.sortie, f'lot_{i:02d}.json'), 'w',
                  encoding='utf-8') as f:
            json.dump([alleger(e) for e in p], f, ensure_ascii=False, indent=1)
    print(f'{len(ev)} faits -> {len(paquets)} lots de ~{len(paquets[0])}')
    for i, p in enumerate(paquets):
        c = collections.Counter(e['cat'] for e in p)
        deja = sum(1 for e in p if e.get('pays'))
        print(f'  lot_{i:02d}  {len(p):3} faits  {len(c)} anciennes catégories  '
              f'{deja:3} ont déjà un pays')


if __name__ == '__main__':
    main()
