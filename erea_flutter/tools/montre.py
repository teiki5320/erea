#!/usr/bin/env python3
"""Génère le cliquetis de la frise : l'échappement d'une montre-bracelet.

Écrit deux fichiers, `assets/sfx/tic.wav` et `assets/sfx/tac.wav`, que
l'app alterne à chaque cran.

Trois choses font la différence entre ce son et un « clic » quelconque :

1. **Un tic n'est pas un impact, c'en est trois.** Dans un échappement à
   ancre, on entend le déverrouillage, puis l'impulsion, puis la chute de
   l'ancre — trois chocs séparés de 2 et 4 millisecondes. C'est cette
   micro-texture qui fait entendre un mécanisme plutôt qu'un bip.

2. **Le caractère vient du boîtier, pas du choc.** Le choc lui-même n'est
   qu'une bouffée de bruit d'une milliseconde et demie, sans intérêt. Ce
   sont les quatre résonateurs (2750, 4300, 1180 et 620 Hz, avec leurs
   amortissements) qui font entendre un boîtier acier.

3. **Le tic et le tac diffèrent.** Les deux palettes de l'ancre n'ont ni
   la même géométrie ni le même point de contact. Le fichier précédent
   rejouait quarante fois le même échantillon, et c'est précisément ce qui
   sonnait mécanique au mauvais sens du terme.

S'y ajoute le traitement « prise de son de proximité » : coupure des
aigus à 4,8 kHz et fondu d'entrée de 2,4 ms. C'est ce qui rend un
enregistrement ASMR de montre agréable là où le même choc, brut, agresse.

    pip install numpy
    python3 tools/montre.py
"""
import math
import os
import wave

import numpy as np

SR = 44100          # fréquence de travail
SR_OUT = 22050      # fréquence des fichiers : tout est filtré sous 5 kHz
SORTIE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      'assets', 'sfx')

_rng = np.random.default_rng(23)


# ------------------------------------------------------------- filtres
def passe_bas1(x, fc):
    """Butterworth d'ordre 1, par bilinéaire. Pente douce, 6 dB/octave."""
    c = math.tan(math.pi * min(fc, SR / 2 * 0.99) / SR)
    b = c / (1 + c)
    a1 = (c - 1) / (1 + c)
    y = np.empty_like(x)
    for canal in range(x.shape[0]):
        xz = yz = 0.0
        for i in range(x.shape[1]):
            v = b * x[canal, i] + b * xz - a1 * yz
            xz, yz = x[canal, i], v
            y[canal, i] = v
    return y


def passe_bas2(x, fc):
    """Butterworth d'ordre 2 (Q = 1/√2), 12 dB/octave."""
    w0 = 2 * math.pi * min(fc, SR / 2 * 0.99) / SR
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / math.sqrt(2.0)
    a0 = 1 + alpha
    b0 = b2 = (1 - cw) / 2 / a0
    b1 = (1 - cw) / a0
    a1 = -2 * cw / a0
    a2 = (1 - alpha) / a0
    y = np.empty_like(x)
    for canal in range(x.shape[0]):
        x1 = x2 = y1 = y2 = 0.0
        for i in range(x.shape[1]):
            v = (b0 * x[canal, i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2)
            x2, x1 = x1, x[canal, i]
            y2, y1 = y1, v
            y[canal, i] = v
    return y


def resonateur(x, modes):
    """Banc de résonateurs à deux pôles : c'est lui qui fabrique le boîtier.

    Chaque mode est (fréquence, temps de décroissance, gain). Un choc
    quasi instantané entre, un objet qui sonne sort.
    """
    y = np.zeros_like(x)
    for f, t60, g in modes:
        r = 10 ** (-3.0 / (max(t60, 1e-4) * SR))
        w = 2 * math.pi * f / SR
        c1, c2, gain = 2 * r * math.cos(w), r * r, (1 - r) * g
        for canal in range(x.shape[0]):
            y1 = y2 = 0.0
            for i in range(x.shape[1]):
                v = gain * x[canal, i] + c1 * y1 - c2 * y2
                y2, y1 = y1, v
                y[canal, i] += v
    return y


# ------------------------------------------------------------- briques
def enveloppe(n, attaque, chute, courbe=2.2):
    t = np.arange(n) / SR
    na = min(max(int(SR * attaque), 1), n)
    att = np.ones(n)
    att[:na] = 0.5 - 0.5 * np.cos(np.pi * np.linspace(0, 1, na))
    return att * np.exp(-t / chute * courbe)


def choc(dur=0.0014, couleur=4200.0, largeur=0.30):
    """Le choc métal contre métal.

    Le bruit est majoritairement COMMUN aux deux canaux : tout décorréler
    donnerait une belle image au casque, mais les résonateurs graves
    partiraient en opposition de phase et le grave disparaîtrait sur le
    haut-parleur mono de l'iPhone. 30 % d'aléa propre suffisent à l'espace.
    """
    n = max(int(SR * dur), 8)
    x = (_rng.standard_normal((1, n)) * (1 - largeur)
         + _rng.standard_normal((2, n)) * largeur)
    return passe_bas1(x, couleur) * enveloppe(n, 0.00025, dur * 0.45, 3.0)


def echappement(impacts, modes, longueur, couleur, coupure, attaque_ms):
    n = int(SR * longueur)
    exc = np.zeros((2, n))
    for retard, force in impacts:
        c = choc(couleur=couleur * _rng.uniform(0.9, 1.1))
        d = int(SR * retard)
        fin = min(d + c.shape[1], n)
        if fin > d:
            exc[:, d:fin] += c[:, :fin - d] * force
    y = passe_bas2(resonateur(exc, modes), coupure)
    na = max(int(SR * attaque_ms / 1000.0), 2)
    y[:, :na] *= 0.5 - 0.5 * np.cos(np.pi * np.linspace(0, 1, na))
    return y


# ------------------------------------- l'échappement de montre-bracelet
MODES = [(2750, 0.018, 1.00), (4300, 0.010, 0.42),
         (1180, 0.030, 0.55), (620, 0.036, 0.30)]
MODES_TAC = [(f * k, t, g) for (f, t, g), k in
             zip(MODES, [1.06, 0.95, 1.09, 0.97])]

TIC = echappement([(0.0, 1.00), (0.0022, 0.55), (0.0041, 0.30)],
                  MODES, 0.10, 4200, 4800, 2.4)
TAC = echappement([(0.0, 0.92), (0.0026, 0.60), (0.0044, 0.26)],
                  MODES_TAC, 0.10, 3900, 4600, 2.4)


# -------------------------------------------------------------- écriture
def rogner(x, seuil=0.004):
    """Coupe la queue devenue inaudible, avec un petit fondu de sortie
    pour que la coupure elle-même ne fasse pas un clic."""
    fenetre = 128
    mono = np.abs(x).max(axis=0)
    n = len(mono) - len(mono) % fenetre
    if n <= 0:
        return x
    audibles = np.nonzero(mono[:n].reshape(-1, fenetre).max(axis=1) > seuil)[0]
    if len(audibles) == 0:
        return x
    y = x[:, :min(x.shape[1], (audibles[-1] + 2) * fenetre)].copy()
    q = min(int(SR * 0.006), y.shape[1])
    y[:, -q:] *= np.linspace(1, 0, q)
    return y


def reechantillonne(x, de, vers):
    n = int(x.shape[1] * vers / de)
    src = np.arange(x.shape[1])
    cible = np.linspace(0, x.shape[1] - 1, n)
    return np.stack([np.interp(cible, src, c) for c in x])


if __name__ == '__main__':
    os.makedirs(SORTIE, exist_ok=True)
    # Normalisation COMMUNE aux deux : le tac est volontairement un peu
    # plus discret que le tic, normaliser séparément effacerait l'écart.
    crete = max(np.abs(TIC).max(), np.abs(TAC).max()) or 1.0
    total = 0
    for nom, x in (('tic', TIC), ('tac', TAC)):
        y = reechantillonne(rogner(x / crete * 0.92), SR, SR_OUT)
        pcm = (np.clip(y, -1, 1) * 32767).astype('<i2').T
        chemin = os.path.join(SORTIE, nom + '.wav')
        with wave.open(chemin, 'w') as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR_OUT)
            w.writeframes(pcm.copy(order='C').tobytes())
        taille = os.path.getsize(chemin)
        total += taille
        print(f'  {nom}  {y.shape[1]/SR_OUT*1000:5.0f} ms  {taille/1024:5.1f} Ko')
    print(f'  total {total/1024:.1f} Ko')
