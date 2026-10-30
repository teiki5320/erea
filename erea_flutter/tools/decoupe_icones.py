"""Découpe une planche d'icônes « sticker » en PNG transparents.

Usage : decoupe_icones.py planche.png colonnes lignes dossier nom1 nom2 ...
Chaque icône est la silhouette du sticker (icône + liseré blanc) trouvée
dans sa case de la grille ; les petites étincelles détachées sont
écartées. Sortie : PNG carré 256 px, fond transparent.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

TAILLE = 256


def main():
    src, cols, rows, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), Path(sys.argv[4])
    noms = sys.argv[5:]
    assert len(noms) == cols * rows, f"{len(noms)} noms pour {cols * rows} cases"
    out.mkdir(parents=True, exist_ok=True)
    img = Image.open(src).convert("RGB")
    a = np.asarray(img).astype(np.int16)
    h, w, _ = a.shape
    bord = np.concatenate([a[:6].reshape(-1, 3), a[-6:].reshape(-1, 3),
                           a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
    fond = np.median(bord, axis=0)
    ecart = np.abs(a - fond).max(axis=2)
    masque = ecart > 10
    masque = ndimage.binary_closing(masque, iterations=2)
    etiquettes, n = ndimage.label(masque, structure=np.ones((3, 3)))
    tailles = ndimage.sum(masque, etiquettes, range(1, n + 1))
    centres = ndimage.center_of_mass(masque, etiquettes, range(1, n + 1))
    cw, ch = w / cols, h / rows
    for k, nom in enumerate(noms):
        c, r = k % cols, k // cols
        dans = [i for i, (cy, cx) in enumerate(centres)
                if c * cw <= cx < (c + 1) * cw and r * ch <= cy < (r + 1) * ch]
        if not dans:
            print(f"!! {nom} : rien trouvé dans la case {c},{r}")
            continue
        plus_grand = max(tailles[i] for i in dans)
        garde = [i + 1 for i in dans if tailles[i] >= 0.03 * plus_grand]
        m = np.isin(etiquettes, garde)
        m = ndimage.binary_fill_holes(m)
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        alpha = Image.fromarray((m[y0:y1, x0:x1] * 255).astype(np.uint8))
        alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
        piece = img.crop((x0, y0, x1, y1)).convert("RGBA")
        piece.putalpha(alpha)
        cote = max(x1 - x0, y1 - y0)
        carre = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
        carre.paste(piece, ((cote - (x1 - x0)) // 2, (cote - (y1 - y0)) // 2))
        carre.resize((TAILLE, TAILLE), Image.LANCZOS).save(out / f"{nom}.png", optimize=True)
        print(f"{nom} : {x1 - x0}x{y1 - y0}")


if __name__ == "__main__":
    main()
