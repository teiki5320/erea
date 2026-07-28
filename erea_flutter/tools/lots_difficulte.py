#!/usr/bin/env python3
"""Découpe events.json en lots de notation pour la passe de difficulté.

La notation est faite par des agents : chacun lit un lot et rend un
niveau par fait. Passer les faits dans le prompt gonflerait démesurément
l'appel ; on écrit donc des fichiers que les agents vont lire eux-mêmes.

Usage :
    python3 tools/lots_difficulte.py --niveaux 1 2 --taille 76 --sortie <dir>
"""
import argparse
import json
import os

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(RACINE, 'assets', 'events.json')


def charger():
    with open(BASE, encoding='utf-8') as f:
        return json.load(f)


def lots(evenements, taille):
    """Découpe en mélangeant les époques et les catégories.

    Un lot « tout le XIXe » ou « tout sciences » ferait dériver le
    correcteur vers une échelle locale : il noterait les faits les uns
    par rapport aux autres au lieu de les noter dans l'absolu. On
    entrelace donc pour que chaque lot ressemble à la base entière.
    """
    tries = sorted(evenements, key=lambda e: (e['cat'], e['annee'], e['id']))
    n = max(1, -(-len(tries) // taille))  # nombre de lots, arrondi au-dessus
    paquets = [[] for _ in range(n)]
    for i, e in enumerate(tries):
        paquets[i % n].append(e)
    return paquets


def alleger(e):
    """Ce dont le correcteur a besoin, et rien de plus."""
    return {
        'id': e['id'],
        'annee': e['annee'],
        'titre': e['titre'],
        'desc': e['desc'],
        'cat': e['cat'],
        'niveau_actuel': e['niveau'],
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--niveaux', type=int, nargs='+', required=True)
    ap.add_argument('--taille', type=int, default=76)
    ap.add_argument('--sortie', required=True)
    a = ap.parse_args()

    ev = [e for e in charger() if e['niveau'] in a.niveaux]
    os.makedirs(a.sortie, exist_ok=True)
    paquets = lots(ev, a.taille)
    for i, p in enumerate(paquets):
        chemin = os.path.join(a.sortie, f'lot_{i:02d}.json')
        with open(chemin, 'w', encoding='utf-8') as f:
            json.dump([alleger(e) for e in p], f, ensure_ascii=False, indent=1)
    print(f'{len(ev)} faits -> {len(paquets)} lots de ~{len(paquets[0])} '
          f'dans {a.sortie}')
    for i, p in enumerate(paquets):
        cats = sorted({e['cat'] for e in p})
        print(f'  lot_{i:02d}  {len(p):3} faits  '
              f'{min(e["annee"] for e in p):>6} a {max(e["annee"] for e in p):>4}  '
              f'{len(cats)} categories')


if __name__ == '__main__':
    main()
