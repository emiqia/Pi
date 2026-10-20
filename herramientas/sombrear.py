"""Sombrea una hoja de sprites de Pi dibujada con sus 5 colores base.

Uso:  python3 herramientas/sombrear.py entrada.png salida.png [vista_previa.png]

Luz desde arriba a la izquierda. Cada color se reemplaza por una rampa de tonos con
"hue shifting" (sombras hacia azul/morado, luces hacia cálido o claro).
La orbe y las burbujas se sombrean como esferas.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png_util import leer_png, escribir_png


def hx(s):
    s = s.lstrip('#')
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


# Los 5 colores base que usa Martín para Pi.
CLASE = {
    (0, 0, 0): 'negro',
    (255, 255, 255): 'blanco',
    (0x8f, 0x56, 0x3b): 'cafe',
    (0x5b, 0x6e, 0xe1): 'azul',
    (0xcb, 0xdb, 0xfc): 'celeste',
    (0x22, 0x20, 0x34): 'sombra_cara',  # sombra del sombrero sobre la cara, pintada a mano por Martín
    (0x66, 0x39, 0x31): 'cafe_lejos',  # pie o pierna de atrás: más oscuro para dar profundidad
}
# Rampas de tonos. 'sombra_cara' se respeta tal como la dibujó Martín.
SOMBRA_CARA = hx('222034')
PAL = {
    'negro':  {'luz': hx('34304a'), 'media': hx('201d2c'), 'base': hx('131118'), 'sombra': hx('060509')},
    'blanco': {'luz': hx('ffffff'), 'media': hx('f4f5fa'), 'base': hx('e3e7f3'), 'sombra': hx('b4bbd9'), 'profunda': hx('8a90b8')},
    'cafe_lejos': {'luz': hx('7d4636'), 'media': hx('703f31'), 'base': hx('663931'), 'sombra': hx('46251f'), 'profunda': hx('2e1719')},
    'cafe':   {'luz': hx('d9955a'), 'media': hx('b2703f'), 'base': hx('8f563b'), 'sombra': hx('5e3328'), 'profunda': hx('3b1f20')},
    'sombra_cara': {'luz': SOMBRA_CARA, 'media': SOMBRA_CARA, 'base': SOMBRA_CARA, 'sombra': SOMBRA_CARA},
    'azul':   {'brillo': hx('f2f7ff'), 'luz': hx('a3bdff'), 'media': hx('7890f2'), 'base': hx('5b6ee1'), 'sombra': hx('3c45a8'), 'profunda': hx('272a6e')},
}
ORBE = ('azul', 'celeste')


def sombrear(px, w, h):
    clase = [[None if px[y][x][3] == 0 else CLASE.get(px[y][x][:3], 'negro') for x in range(w)] for y in range(h)]

    def c(x, y):
        return clase[y][x] if 0 <= x < w and 0 <= y < h else None

    def borde(x, y, dx, dy, k, solo_transparente):
        """¿Hay un borde a k píxeles o menos en la dirección (dx, dy)?"""
        yo = clase[y][x]
        for i in range(1, k + 1):
            otro = c(x + dx*i, y + dy*i)
            if otro is None:
                return True
            if not solo_transparente and otro != yo and not (yo in ORBE and otro in ORBE):
                return True
        return False

    def tono_forma(x, y, cl, solo_transp):
        if borde(x, y, 0, -1, 1, solo_transp) or borde(x, y, -1, 0, 1, solo_transp):
            return 'luz'
        if borde(x, y, 0, 1, 1, solo_transp) or borde(x, y, 1, 0, 1, solo_transp):
            return 'sombra'
        if borde(x, y, 0, -1, 2, solo_transp) or borde(x, y, -1, -1, 2, solo_transp):
            return 'media'
        if 'profunda' in PAL[cl] and (borde(x, y, 0, 1, 2, solo_transp) or borde(x, y, 1, 1, 2, solo_transp)):
            return 'sombra'
        return 'base'

    # Zonas conectadas de la orbe y las burbujas, para sombrearlas como esferas.
    comp = [[-1] * w for _ in range(h)]
    esferas = []
    for y in range(h):
        for x in range(w):
            if clase[y][x] in ORBE and comp[y][x] < 0:
                pila = [(x, y)]
                comp[y][x] = len(esferas)
                pts = []
                while pila:
                    a, b = pila.pop()
                    pts.append((a, b))
                    for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        na, nb = a + da, b + db
                        if 0 <= na < w and 0 <= nb < h and comp[nb][na] < 0 and clase[nb][na] in ORBE:
                            comp[nb][na] = len(esferas)
                            pila.append((na, nb))
                cx = sum(p[0] for p in pts) / len(pts)
                cy = sum(p[1] for p in pts) / len(pts)
                r = max(1.0, max(math.hypot(p[0] - cx, p[1] - cy) for p in pts))
                esferas.append((cx, cy, r, len(pts)))

    luz = (-0.7071, -0.7071)
    out = [[(0, 0, 0, 0)] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            cl = clase[y][x]
            if cl is None:
                continue
            if cl in ORBE:
                cx, cy, r, n = esferas[comp[y][x]]
                if n <= 4:  # burbujas diminutas: solo luz
                    out[y][x] = PAL['azul']['brillo' if cl == 'celeste' else 'luz']
                    continue
                t = ((x - cx) * luz[0] + (y - cy) * luz[1]) / r
                if cl == 'celeste' or t > 0.55:
                    tono = 'brillo' if t > 0.75 or cl == 'celeste' else 'luz'
                elif t > 0.2:
                    tono = 'media'
                elif t > -0.35:
                    tono = 'base'
                elif t > -0.7:
                    tono = 'sombra'
                else:
                    tono = 'profunda'
                out[y][x] = PAL['azul'][tono]
            elif cl == 'negro':
                # El cuerpo negro solo se sombrea según su silueta, no según la cara o el báculo.
                out[y][x] = PAL['negro'][tono_forma(x, y, cl, True)]
            else:
                out[y][x] = PAL[cl][tono_forma(x, y, cl, False)]
    return out


def vista_previa(original, sombreado, ruta, escala=3):
    """Original arriba y sombreado abajo, ampliados, sobre fondo gris."""
    h = len(original)
    w = len(original[0])
    fondo = (60, 64, 80, 255)
    sep = 6
    prev = [[fondo] * (w * escala) for _ in range(h * 2 * escala + sep)]
    for i, img in enumerate((original, sombreado)):
        for y in range(h):
            for x in range(w):
                p = img[y][x]
                if p[3]:
                    for a in range(escala):
                        for b in range(escala):
                            prev[i * (h * escala + sep) + y * escala + a][x * escala + b] = p
    escribir_png(ruta, prev)


if __name__ == '__main__':
    entrada, salida = sys.argv[1], sys.argv[2]
    w, h, px = leer_png(entrada)
    out = sombrear(px, w, h)
    escribir_png(salida, out)
    if len(sys.argv) > 3:
        vista_previa(px, out, sys.argv[3])
    print(salida, '-', len({p for f in out for p in f if p[3]}), 'colores')
