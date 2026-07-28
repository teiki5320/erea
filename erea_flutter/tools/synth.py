#!/usr/bin/env python3
"""Synthèse des sons d'Erea — trois styles à comparer.

Ce que les premiers sons n'avaient pas et qui change tout :
  - un TIMBRE (harmoniques, FM, partiels inharmoniques) au lieu d'une sinus nue
  - une ENVELOPPE en plusieurs temps (attaque douce, corps, queue)
  - une RÉVERBÉRATION courte, qui pose le son dans un espace
  - un vibrato/glissando léger, qui empêche le son d'être « mort »
"""
import math
import os
import struct
import wave

import numpy as np

SR = 44100


# ----------------------------------------------------------------- briques
def env(n, attaque=0.004, chute=0.25, courbe=2.5):
    """Attaque douce puis décroissance exponentielle."""
    t = np.arange(n) / SR
    a = np.clip(t / max(attaque, 1e-6), 0, 1) ** 0.6
    d = np.exp(-t / chute * courbe)
    return a * d


def sinus(freq, n, phase=0.0, vibrato=0.0, vib_hz=5.0, glisse=1.0):
    t = np.arange(n) / SR
    f = freq * np.linspace(1.0, glisse, n)
    if vibrato:
        f = f * (1 + vibrato * np.sin(2 * np.pi * vib_hz * t))
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def fm(porteuse, rapport, index, n, chute=0.25, index_chute=0.08):
    """Synthèse FM : c'est ce qui donne le bois, le métal, la cloche."""
    t = np.arange(n) / SR
    mod = np.sin(2 * np.pi * porteuse * rapport * t)
    idx = index * np.exp(-t / index_chute)
    return np.sin(2 * np.pi * porteuse * t + idx * mod)


def cloche(freq, n, partiels=((1, 1.0), (2.76, .55), (5.4, .32), (8.9, .18))):
    """Partiels INHARMONIQUES : le propre d'une cloche, d'un carillon."""
    out = np.zeros(n)
    for rapport, amp in partiels:
        out += amp * sinus(freq * rapport, n) * env(n, 0.002, 0.35 / rapport**0.4)
    return out / len(partiels)


def carre_doux(freq, n, harmoniques=7, glisse=1.0):
    """Carré additif limité en harmoniques = arcade sans agressivité."""
    out = np.zeros(n)
    for k in range(1, harmoniques * 2, 2):
        out += sinus(freq * k, n, glisse=glisse) / k
    return out * 0.6


def bruit(n, chute=0.02):
    rng = np.random.default_rng(12)
    return rng.standard_normal(n) * env(n, 0.0005, chute)


def passe_bas(x, coupure=4000.0):
    """Filtre à un pôle : arrondit les angles, enlève le côté strident."""
    a = math.exp(-2 * math.pi * coupure / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def reverb(x, taille=0.055, retours=6, amort=0.55, melange=0.22):
    """Réverbération minimale : quelques échos amortis. Ça « pose » le son."""
    out = x.astype(np.float64).copy()
    d = int(SR * taille)
    for k in range(1, retours + 1):
        g = amort ** k
        dec = d * k
        if dec >= len(out):
            break
        out[dec:] += x[: len(out) - dec] * g * melange
    return out


def finir(x, gain=0.85):
    """Normalise puis adoucit les crêtes (tanh) — pas de saturation sale."""
    m = np.max(np.abs(x)) or 1.0
    x = np.tanh(x / m * 1.5) / 1.5
    return x * gain


def ecrire(nom, x, dossier):
    x = finir(x)
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    chemin = os.path.join(dossier, nom + '.wav')
    with wave.open(chemin, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return chemin, os.path.getsize(chemin)


def note(dur):
    return int(SR * dur)


# ------------------------------------------------------------------ styles
def style_bois():
    """A · Bois & feutre — marimba, kalimba. Chaud, familial, jamais criard."""
    s = {}
    n = note(0.075)
    s['tick'] = passe_bas(fm(880, 3.0, 2.2, n, index_chute=0.012)
                          * env(n, 0.001, 0.045) + bruit(n, 0.006) * 0.25, 5200)

    n = note(0.30)
    s['valider'] = passe_bas(
        fm(392, 2.0, 3.0, n, index_chute=0.05) * env(n, 0.003, 0.10)
        + fm(784, 2.0, 1.5, n, index_chute=0.03) * env(n, 0.003, 0.07) * 0.5,
        6000)

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

    s['reussi'] = marimba([523.25, 659.25, 783.99], [0.09, 0.09, 0.30])
    s['moyen'] = marimba([440.00, 523.25], [0.10, 0.28])
    s['rate'] = marimba([349.23, 293.66], [0.12, 0.34])
    s['parfait'] = marimba([523.25, 659.25, 783.99, 1046.50, 1318.51],
                           [0.075, 0.075, 0.075, 0.075, 0.42])
    return s


def style_arcade():
    """B · Arcade — chiptune assumé, punchy, « jeu vidéo » assumé."""
    s = {}
    n = note(0.045)
    s['tick'] = passe_bas(carre_doux(1400, n, 5) * env(n, 0.0008, 0.018), 6000)

    n = note(0.16)
    s['valider'] = passe_bas(
        carre_doux(440, n, 6, glisse=1.9) * env(n, 0.001, 0.06), 5500)

    def bip(freqs, durees, glisses=None):
        glisses = glisses or [1.0] * len(freqs)
        total = note(sum(durees) + 0.35)
        out = np.zeros(total)
        pos = 0
        for f, d, g in zip(freqs, durees, glisses):
            n = note(d + 0.12)
            v = carre_doux(f, n, 6, glisse=g) * env(n, 0.0015, d * 0.75, 2.0)
            fin = min(pos + n, total)
            out[pos:fin] += v[:fin - pos]
            pos += note(d)
        return passe_bas(reverb(out, 0.030, 4, 0.4, 0.14), 5200)

    s['reussi'] = bip([523.25, 659.25, 783.99], [0.065, 0.065, 0.22])
    s['moyen'] = bip([440.00, 493.88], [0.075, 0.20])
    s['rate'] = bip([311.13, 233.08], [0.09, 0.26], [1.0, 0.82])
    s['parfait'] = bip([523.25, 659.25, 783.99, 1046.50],
                       [0.055, 0.055, 0.055, 0.34], [1, 1, 1, 1.02])
    return s


def style_cristal():
    """C · Cristal — carillons, partiels inharmoniques, queue qui scintille."""
    s = {}
    n = note(0.09)
    s['tick'] = passe_bas(cloche(2093, n, ((1, 1.0), (2.8, .4))) *
                          env(n, 0.001, 0.03), 9000)

    n = note(0.45)
    s['valider'] = reverb(cloche(659.25, n) * env(n, 0.002, 0.14), 0.05, 5, .5, .3)

    def carillon(freqs, durees):
        total = note(sum(durees) + 1.0)
        out = np.zeros(total)
        pos = 0
        for f, d in zip(freqs, durees):
            n = note(0.9)
            v = cloche(f, n) * env(n, 0.002, 0.30)
            fin = min(pos + n, total)
            out[pos:fin] += v[:fin - pos]
            pos += note(d)
        return reverb(out, 0.065, 7, 0.6, 0.34)

    s['reussi'] = carillon([659.25, 987.77, 1318.51], [0.10, 0.10, 0.45])
    s['moyen'] = carillon([587.33, 739.99], [0.11, 0.40])
    s['rate'] = carillon([392.00, 311.13], [0.13, 0.45])
    s['parfait'] = carillon([659.25, 987.77, 1318.51, 1975.53],
                            [0.085, 0.085, 0.085, 0.60])
    return s


ORDRE = ['tick', 'tick', 'tick', 'valider', 'reussi', 'moyen', 'rate', 'parfait']
STYLES = {'A-bois': style_bois, 'B-arcade': style_arcade, 'C-cristal': style_cristal}

base = '/tmp/claude-0/-home-user-erea/d30e4acd-923d-5095-99d9-a61e8d25e6af/scratchpad/sons'
for nom, fn in STYLES.items():
    d = os.path.join(base, nom)
    os.makedirs(d, exist_ok=True)
    sons = fn()
    total = 0
    for k, v in sons.items():
        _, taille = ecrire(k, v, d)
        total += taille
    # Démo enchaînée, pour écouter d'un seul coup
    demo = []
    for k in ORDRE:
        x = finir(sons[k])
        silence = np.zeros(note(0.20 if k == 'tick' else 0.75))
        demo.append(np.concatenate([x, silence]))
    ecrire(f'DEMO-{nom}', np.concatenate(demo), base)
    print(f'{nom:12} 6 sons, {total/1024:5.1f} Ko embarqués')
print(f'\nDémos dans {base}')
