"""Genera el mapa de normales de una hoja de sprites de Pi, para la iluminación dinámica de Godot.

Uso:  python3 herramientas/normales.py entrada.png salida_n.png

Se usa el PNG original (con los 5 colores base) como entrada: el volumen se calcula
a partir de la silueta y de cada zona de color (cara, báculo, orbe).
Convención OpenGL (verde = apunta hacia arriba), la que usa Godot.
Tarda un par de minutos por hoja.
"""
import math
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png_util import leer_png, escribir_png

CLASE = {
    (0, 0, 0): 'negro',
    (255, 255, 255): 'blanco',
    (0x8f, 0x56, 0x3b): 'cafe',
    (0x5b, 0x6e, 0xe1): 'azul',
    (0xcb, 0xdb, 0xfc): 'azul',
    (0x22, 0x20, 0x34): 'blanco',  # sombra pintada sobre la cara: tiene el mismo volumen que la cara
    (0x66, 0x39, 0x31): 'cafe_lejos',  # pie de atrás: volumen propio, separado del de adelante
}


def normales(px, w, h):
    cl = [[None if px[y][x][3] == 0 else CLASE.get(px[y][x][:3], 'negro') for x in range(w)] for y in range(h)]
    vecinos = ((1, 0), (-1, 0), (0, 1), (0, -1))

    def distancia(mismo):
        """Distancia de cada píxel opaco al borde de su zona."""
        d = [[0] * w for _ in range(h)]
        cola = deque()
        for y in range(h):
            for x in range(w):
                if cl[y][x] is None:
                    continue
                if any(not (0 <= x + a < w and 0 <= y + b < h) or not mismo(cl[y][x], cl[y + b][x + a])
                       for a, b in vecinos):
                    d[y][x] = 1
                    cola.append((x, y))
        while cola:
            x, y = cola.popleft()
            for a, b in vecinos:
                nx, ny = x + a, y + b
                if (0 <= nx < w and 0 <= ny < h and cl[ny][nx] is not None and d[ny][nx] == 0
                        and mismo(cl[y][x], cl[ny][nx])):
                    d[ny][nx] = d[y][x] + 1
                    cola.append((nx, ny))
        return d

    silueta = distancia(lambda a, b: b is not None)
    zona = distancia(lambda a, b: a == b)

    # Altura: volumen general del cuerpo + abultamiento propio de cara, báculo y orbe.
    alto = [[0.0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if cl[y][x] is None:
                continue
            s = math.sqrt(min(silueta[y][x], 7) / 7.0) * 5.0
            z = math.sqrt(min(zona[y][x], 4) / 4.0) * (3.0 if cl[y][x] != 'negro' else 0.0)
            alto[y][x] = s + z

    def H(x, y):
        return alto[y][x] if 0 <= x < w and 0 <= y < h and cl[y][x] is not None else 0.0

    suave = [[sum(H(x + a, y + b) for a in (-1, 0, 1) for b in (-1, 0, 1)) / 9.0 if cl[y][x] else 0.0
              for x in range(w)] for y in range(h)]

    def Hs(x, y):
        return suave[y][x] if 0 <= x < w and 0 <= y < h else 0.0

    out = [[(128, 128, 255, 0)] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if cl[y][x] is None:
                continue
            gx = (Hs(x + 1, y) - Hs(x - 1, y)) / 2.0
            gy = (Hs(x, y + 1) - Hs(x, y - 1)) / 2.0
            nx, ny, nz = -gx, gy, 1.0
            n = math.sqrt(nx*nx + ny*ny + nz*nz)
            out[y][x] = (round((nx/n*0.5 + 0.5) * 255), round((ny/n*0.5 + 0.5) * 255),
                         round((nz/n*0.5 + 0.5) * 255), 255)
    return out


if __name__ == '__main__':
    w, h, px = leer_png(sys.argv[1])
    escribir_png(sys.argv[2], normales(px, w, h))
    print(sys.argv[2], '- listo')
