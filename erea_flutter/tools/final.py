#!/usr/bin/env python3
"""Génère les sons définitifs d'Erea — style « bois & feutre ».

Sortie : assets/sfx/*.wav en 22 050 Hz mono. La moitié du débit suffit
largement (tout est filtré sous 7 kHz) et divise le poids par deux.
"""
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from synth import (SR, cloche, env, finir, fm, bruit, passe_bas,  # noqa: E402
                   reverb, sinus)

SORTIE = '/home/user/erea/erea_flutter/assets/sfx'
SR_OUT = 22050


def note(d):
    return int(SR * d)


def marimba(freqs, durees):
    total = note(sum(durees) + 0.5)
    out = np.zeros(total)
    pos = 0
    for f, d in zip(freqs, durees):
        n = note(0.42)
        v = fm(f, 2.0, 3.4, n, index_chute=0.055) * env(n, 0.003, 0.16)
        v += fm(f * 2, 2.0, 1.2, n, index_chute=0.03) * env(n, 0.003, 0.09) * 0.35
        fin = min(pos + n, total)
        out[pos:fin] += v[:fin - pos]
        pos += note(d)
    return passe_bas(reverb(out, 0.045, 5, 0.5, 0.28), 6500)


# Le cran du glissement n'est plus ici : c'est `montre.py` qui le génère
# (tic.wav / tac.wav), depuis le passage à l'échappement de montre
# mécanique. Le clic de bois qui vivait dans ce fichier rejouait le même
# échantillon à chaque cran, et c'est précisément ce qui sonnait faux.

SONS = {
    'pop': passe_bas(
        fm(392, 2.0, 3.0, note(0.30), index_chute=0.05) * env(note(0.30), 0.003, 0.10)
        + fm(784, 2.0, 1.5, note(0.30), index_chute=0.03)
        * env(note(0.30), 0.003, 0.07) * 0.5, 6000),
    'bien': marimba([523.25, 659.25, 783.99], [0.09, 0.09, 0.30]),
    'moyen': marimba([440.00, 523.25], [0.10, 0.28]),
    'rate': marimba([349.23, 293.66], [0.12, 0.34]),
    'parfait': marimba([523.25, 659.25, 783.99, 1046.50, 1318.51],
                       [0.075, 0.075, 0.075, 0.075, 0.42]),
}


def rogner(x, seuil=0.004):
    """Coupe la queue devenue inaudible : c'est là que part le poids."""
    fenetre = 256
    n = len(x) - len(x) % fenetre
    if n <= 0:
        return x
    niveaux = np.abs(x[:n]).reshape(-1, fenetre).max(axis=1)
    audibles = np.nonzero(niveaux > seuil)[0]
    if len(audibles) == 0:
        return x
    fin = min(len(x), (audibles[-1] + 2) * fenetre)
    y = x[:fin].copy()
    # petit fondu de sortie, sinon la coupure ferait un clic
    q = min(int(SR * 0.008), len(y))
    y[-q:] *= np.linspace(1, 0, q)
    return y


def reechantillonne(x, de, vers):
    n = int(len(x) * vers / de)
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


os.makedirs(SORTIE, exist_ok=True)
total = 0
for nom, x in SONS.items():
    x = rogner(finir(x, 0.92))
    x = reechantillonne(x, SR, SR_OUT)
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    chemin = os.path.join(SORTIE, nom + '.wav')
    with wave.open(chemin, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR_OUT)
        w.writeframes(pcm.tobytes())
    taille = os.path.getsize(chemin)
    total += taille
    print(f'  {nom:8} {len(x)/SR_OUT*1000:6.0f} ms  {taille/1024:5.1f} Ko')
print(f'  {"TOTAL":8} {" ":10} {total/1024:5.1f} Ko')
