#!/usr/bin/env python3
"""Simule un VRAI glissement sur la frise et rend le cliquetis obtenu.

Reprend l'arithmétique exacte de lib/core/timeline_scale.dart et la
mécanique de lib/ui/tape_widget.dart (facteur de réglage fin, inertie
×0,94 par frame), pour que ce qu'on entend ici soit ce qu'on entendra
dans le jeu.
"""
import os
import wave

import numpy as np

SR = 44100
TAPE_W = 3200.0
SEGMENTS = [(-3000, 0, 0.20), (0, 1500, 0.25), (1500, 1900, 0.25),
            (1900, 2026, 0.30)]


def year_to_frac(y):
    acc = 0.0
    for a, b, part in SEGMENTS:
        if y <= b:
            return acc + (y - a) / (b - a) * part
        acc += part
    return 1.0


def frac_to_year(f):
    acc = 0.0
    for a, b, part in SEGMENTS:
        if f <= acc + part:
            return round(a + (f - acc) / part * (b - a))
        acc += part
    return 2026


# ------------------------------------------------------- geste et inertie
def glissement(depart_annee, px_total=340.0, duree=0.55, inertie_px=34.0,
               pas_px=None):
    """Rend les instants (s) des crans, et la durée totale du geste.

    `pas_px=None` : un cran par dizaine d'années franchie (l'ancienne
    logique). Sinon : un cran tous les `pas_px` parcourus sur le ruban —
    un vrai cliquetis de molette, identique dans toutes les époques.
    """
    frac = year_to_frac(depart_annee)
    dt = 1 / 120.0                     # l'écran envoie ~120 événements/s
    instants = []
    dernier = frac_to_year(frac) // 10
    parcouru = 0.0
    t = 0.0

    def cran(frac_avant, frac_apres):
        """Faut-il un cran entre ces deux positions ?"""
        nonlocal dernier, parcouru
        if pas_px is None:
            d = frac_to_year(frac_apres) // 10
            if d != dernier:
                dernier = d
                return True
            return False
        parcouru += abs(frac_apres - frac_avant) * TAPE_W
        if parcouru >= pas_px:
            parcouru = 0.0
            return True
        return False

    n = int(duree / dt)
    for i in range(n):
        # profil en cloche : on part doucement, on accélère, on ralentit
        vitesse = math_sin_profil(i / n) * px_total / duree
        dx = vitesse * dt
        facteur = min(max(0.4 + abs(dx) * 0.12, 0.4), 1.0)
        avant = frac
        frac = min(max(frac - (-dx) * facteur / TAPE_W, 0.0), 1.0)
        t += dt
        if cran(avant, frac):
            instants.append(t)

    # lâcher : vitesse en px/frame, amortie de 0,94 par frame de 16,7 ms
    v = inertie_px
    while abs(v) > 0.3:
        frames = dt / 0.0167
        v *= 0.94 ** frames
        avant = frac
        frac = min(max(frac + v * frames / TAPE_W, 0.0), 1.0)
        t += dt
        if cran(avant, frac):
            instants.append(t)
    return instants, t


def math_sin_profil(u):
    return np.sin(np.pi * u) ** 0.8


# ------------------------------------------------------------- les clics
def env(n, attaque, chute, courbe=3.0):
    t = np.arange(n) / SR
    return np.clip(t / max(attaque, 1e-6), 0, 1) ** 0.5 * np.exp(-t / chute * courbe)


def clic_bois(f0=1150.0):
    """Cran de roue en bois : sec, mat, chaleureux."""
    n = int(SR * 0.030)
    t = np.arange(n) / SR
    corps = np.sin(2 * np.pi * f0 * t + 2.0 * np.sin(2 * np.pi * f0 * 3.1 * t))
    x = corps * env(n, 0.0004, 0.006)
    rng = np.random.default_rng(3)
    x += rng.standard_normal(n) * env(n, 0.0002, 0.0016) * 0.5
    return x


def clic_cliquet(f0=2100.0):
    """Cliquet métallique : plus haut, plus mordant, comme une roue crantée."""
    n = int(SR * 0.026)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f0 * t) * env(n, 0.0002, 0.0035)
    x += np.sin(2 * np.pi * f0 * 2.71 * t) * env(n, 0.0002, 0.0022) * 0.6
    rng = np.random.default_rng(7)
    x += rng.standard_normal(n) * env(n, 0.0001, 0.0012) * 0.8
    return x


def clic_molette(f0=3000.0):
    """Molette de réglage : minuscule, très haut, presque un souffle."""
    n = int(SR * 0.018)
    rng = np.random.default_rng(11)
    x = rng.standard_normal(n) * env(n, 0.0001, 0.0010)
    t = np.arange(n) / SR
    x += np.sin(2 * np.pi * f0 * t) * env(n, 0.0002, 0.0018) * 0.7
    return x


def rendre(instants, duree, clic, throttle=0.055, variation=0.06):
    """Pose les clics, avec le bridage réel et un léger désaccord.

    Le désaccord est capital : sans lui, une rafale de clics identiques
    sonne comme une machine, pas comme un mécanisme.
    """
    n = int(SR * (duree + 0.25))
    out = np.zeros(n)
    rng = np.random.default_rng(42)
    dernier = -1.0
    poses = 0
    for t in instants:
        if t - dernier < throttle:
            continue
        dernier = t
        poses += 1
        # variation de hauteur : ±6 % → rééchantillonnage grossier
        k = 1.0 + rng.uniform(-variation, variation)
        src = clic
        m = int(len(src) / k)
        idx = np.clip((np.arange(m) * k).astype(int), 0, len(src) - 1)
        v = src[idx] * rng.uniform(0.82, 1.0)
        d = int(t * SR)
        fin = min(d + m, n)
        out[d:fin] += v[:fin - d]
    return out, poses


def ecrire(chemin, x, niveau=0.9):
    m = np.max(np.abs(x)) or 1.0
    pcm = (np.clip(x / m * niveau, -1, 1) * 32767).astype('<i2')
    with wave.open(chemin, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


base = ('/tmp/claude-0/-home-user-erea/d30e4acd-923d-5095-99d9-a61e8d25e6af'
        '/scratchpad/sons')
os.makedirs(base, exist_ok=True)

# Trois zones de la frise : la densité de dizaines franchies y est très
# différente, c'est tout l'intérêt de l'échelle non linéaire.
ZONES = [('recent', 1985), ('medieval', 1300), ('antique', -2000)]
CLICS = [('bois', clic_bois()), ('cliquet', clic_cliquet()),
         ('molette', clic_molette())]

# Un cran tous les 40 px de ruban : à pleine vitesse ça donne ~15 clics/s,
# la limite au-delà de laquelle l'oreille n'entend plus qu'un bourdonnement.
PAS = 40.0

for cadence, pas in [('annees', None), ('distance', PAS)]:
    for nom_clic, clic in CLICS:
        if cadence == 'annees' and nom_clic != 'cliquet':
            continue                      # une seule référence pour comparer
        morceaux = []
        infos = []
        for nom_zone, annee in ZONES:
            instants, duree = glissement(annee, pas_px=pas)
            x, poses = rendre(instants, duree, clic, throttle=0.045)
            infos.append(f'{nom_zone}:{poses}')
            morceaux.append(np.concatenate([x, np.zeros(int(SR * 0.9))]))
        nom = (f'CADENCE-annees-{nom_clic}' if cadence == 'annees'
               else f'GLISSEMENT-{nom_clic}')
        ecrire(os.path.join(base, nom + '.wav'), np.concatenate(morceaux))
        print(f'{nom:28} clics par zone → ' + ' · '.join(infos))
