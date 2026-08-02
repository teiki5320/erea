#!/usr/bin/env python3
"""Sons d'interface — mêmes briques « bois & marimba » que les verdicts.

Pour que tout l'habillage sonore ait l'air d'un seul instrument, ces
petits sons réutilisent la boîte à outils de synth.py. Trois candidats
pour l'instant :

  · appui    — le « toc » chaud d'un bouton principal ;
  · retour   — une note plus grave et plus courte (annuler, revenir) ;
  · partage  — un souffle bref, le « swoosh » d'une copie.

Sortie : des MP3 de démo dans le scratchpad. Rien n'est écrit dans
assets/ tant que le choix n'est pas fait.
"""
import os
import sys

import lameenc
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from synth import (SR, bruit, env, fm, passe_bas,  # noqa: E402
                   reverb, sinus)


def note(d):
    return int(SR * d)


# --------------------------------------------------------------- appui
def appui():
    """Un marimba très court et mat : bois qu'on effleure. Il sonne à
    chaque bouton, il ne doit jamais accrocher l'oreille."""
    n = note(0.16)
    x = fm(523.25, 2.0, 2.6, n, index_chute=0.05) * env(n, 0.002, 0.05)
    x += fm(1046.5, 2.0, 1.0, n, index_chute=0.03) * env(n, 0.002, 0.03) * 0.3
    return passe_bas(x, 6000)


# --------------------------------------------------------------- retour
def retour():
    """Plus grave, plus court : on descend d'un cran. L'oreille entend
    « je recule » sans qu'on ait à y penser."""
    n = note(0.14)
    x = fm(311.13, 2.0, 2.2, n, index_chute=0.05) * env(n, 0.002, 0.045)
    return passe_bas(x, 3800)


# --------------------------------------------------------------- partage
def partage():
    """Un souffle filtré qui monte : le geste d'envoyer quelque chose.
    Ni cloche ni note — juste de l'air, pour ne pas encombrer."""
    n = note(0.26)
    t = np.arange(n) / SR
    b = bruit(n, 0.20)
    # filtre qui s'ouvre : le souffle « part » vers l'aigu
    coupures = 900 + 3200 * (t / t[-1])
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        import math
        a = math.exp(-2 * math.pi * coupures[i] / SR)
        acc = (1 - a) * b[i] + a * acc
        y[i] = acc
    y *= env(n, 0.02, 0.10, courbe=1.4)
    return y


# ---- deux bonus, si tu veux comparer (non demandés, mais gratuits) ----
def badge():
    """Petit arpège cristallin ascendant : un succès débloqué."""
    freqs = [523.25, 659.25, 783.99, 1046.5]
    total = note(0.5)
    out = np.zeros(total)
    for k, f in enumerate(freqs):
        n = note(0.28)
        v = fm(f, 2.0, 3.0, n, index_chute=0.04) * env(n, 0.002, 0.09)
        d = note(0.05 * k)
        out[d:d + n] += v[:total - d] if d + n > total else v
    return passe_bas(reverb(out, 0.05, 5, 0.5, 0.3), 7000)


def drapeau():
    """Un « clac » net et bref : la roue de la roulette se cale."""
    n = note(0.12)
    x = sinus(180, n) * env(n, 0.0006, 0.02)
    x += bruit(n, 0.006) * 0.6
    x += fm(900, 2.0, 1.5, n, index_chute=0.02) * env(n, 0.001, 0.012) * 0.4
    return passe_bas(x, 5000)


CANDIDATS = {
    '1-appui': appui,
    '2-retour': retour,
    '6-partage': partage,
    'bonus-badge': badge,
    'bonus-drapeau': drapeau,
}

BASE = ('/tmp/claude-0/-home-user-erea/d30e4acd-923d-5095-99d9-a61e8d25e6af'
        '/scratchpad/ui_sons')


def en_mp3(x, chemin, niveau=0.85):
    x = x / (np.abs(x).max() or 1.0) * niveau
    pcm = np.clip(x, -1, 1)
    pcm = (np.stack([pcm, pcm], 1) * 32767).astype(np.int16)
    enc = lameenc.Encoder()
    enc.set_bit_rate(128)
    enc.set_in_sample_rate(SR)
    enc.set_channels(2)
    enc.set_quality(2)
    open(chemin, 'wb').write(bytes(enc.encode(pcm.tobytes()) + enc.flush()))


if __name__ == '__main__':
    os.makedirs(BASE, exist_ok=True)
    tout = []
    for nom, fn in CANDIDATS.items():
        x = fn()
        en_mp3(x, os.path.join(BASE, f'{nom}.mp3'))
        # petit repère parlé-non : un silence + le son, 3 fois, pour le fichier groupé
        for _ in range(3):
            tout.append(x / (np.abs(x).max() or 1))
            tout.append(np.zeros(note(0.35)))
        tout.append(np.zeros(note(0.5)))
        print(f'  {nom:16} {len(x)/SR*1000:5.0f} ms')
    en_mp3(np.concatenate(tout), os.path.join(BASE, 'TOUS.mp3'))
