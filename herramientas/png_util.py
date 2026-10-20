"""Lectura y escritura de PNG RGBA sin dependencias externas."""
import struct
import zlib


def leer_png(ruta):
    """Devuelve (ancho, alto, píxeles) con píxeles[y][x] = (r, g, b, a)."""
    f = open(ruta, 'rb').read()
    i = 8
    idat = b''
    while i < len(f):
        largo, = struct.unpack('>I', f[i:i+4])
        tipo = f[i+4:i+8]
        datos = f[i+8:i+8+largo]
        if tipo == b'IHDR':
            w, h, prof, color = struct.unpack('>IIBB', datos[:10])
        if tipo == b'IDAT':
            idat += datos
        i += 12 + largo
    assert prof == 8 and color == 6, 'solo PNG RGBA de 8 bits'

    raw = zlib.decompress(idat)
    s = w * 4
    prev = bytearray(s)
    p = 0
    px = []
    for _ in range(h):
        filtro = raw[p]
        p += 1
        linea = bytearray(raw[p:p+s])
        p += s
        for x in range(s):
            a = linea[x-4] if x >= 4 else 0
            b = prev[x]
            c = prev[x-4] if x >= 4 else 0
            if filtro == 1:
                linea[x] = (linea[x] + a) & 255
            elif filtro == 2:
                linea[x] = (linea[x] + b) & 255
            elif filtro == 3:
                linea[x] = (linea[x] + (a + b) // 2) & 255
            elif filtro == 4:
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                linea[x] = (linea[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        px.append([tuple(linea[x*4:x*4+4]) for x in range(w)])
        prev = linea
    return w, h, px


def escribir_png(ruta, px):
    h = len(px)
    w = len(px[0])
    raw = b''.join(b'\0' + bytes(v for p in fila for v in p) for fila in px)

    def chunk(tipo, datos):
        return struct.pack('>I', len(datos)) + tipo + datos + struct.pack('>I', zlib.crc32(tipo + datos))

    open(ruta, 'wb').write(b'\x89PNG\r\n\x1a\n'
                           + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
                           + chunk(b'IDAT', zlib.compress(raw, 9))
                           + chunk(b'IEND', b''))
