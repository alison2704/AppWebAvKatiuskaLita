"""
Genera los audios de relleno que faltan para el catalogo de PoliMusic.

El script BDD_PoliMusic.sql inserta 5 canciones cuyos archivos provienen de
bensound.com, pero en el proyecto solo se entrego 'bensound-adventure.mp3'.
Este script crea los 4 archivos restantes (melodias sintetizadas, distintas
entre si) con los nombres exactos que espera la base de datos, de modo que
las 5 canciones se puedan reproducir en la demostracion.

Uso:
    python generar_audios.py <carpeta_destino>

Los archivos generados son marcadamente sinteticos: sirven como relleno
para probar el reproductor, no como musica real.
"""

import math
import os
import struct
import sys
import array

import lameenc

SAMPLE_RATE = 44100
BIT_RATE = 128

NOTAS = {
    "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00,
    "A3": 220.00, "B3": 246.94,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00,
    "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99,
    "A5": 880.00, "B5": 987.77,
    "C6": 1046.50, "D6": 1174.66, "E6": 1318.51,
}

# (nota, duracion en negras)  -- None = silencio
PISTAS = {
    "bensound-dreams.mp3": {
        "bpm": 66,
        "timbre": [1.0, 0.32, 0.12],
        "melodia": [
            ("E5", 1.5), ("G5", 1.5), ("B5", 2), ("A5", 1),
            ("G5", 2), ("E5", 1), ("D5", 2), (None, 0.5),
            ("E5", 1.5), ("A5", 1.5), ("C6", 2), ("B5", 1),
            ("A5", 2), ("G5", 1), ("E5", 2.5), (None, 0.5),
        ],
    },
    "bensound-energy.mp3": {
        "bpm": 148,
        "timbre": [1.0, 0.5, 0.28, 0.14],
        "melodia": [
            ("C4", 0.5), ("C4", 0.5), ("G4", 0.5), ("C4", 0.5),
            ("E4", 0.5), ("G4", 0.5), ("C5", 1), (None, 0.25),
            ("D4", 0.5), ("D4", 0.5), ("A4", 0.5), ("D4", 0.5),
            ("F4", 0.5), ("A4", 0.5), ("D5", 1), (None, 0.25),
            ("E4", 0.5), ("G4", 0.5), ("B4", 0.5), ("E5", 0.5),
            ("G5", 0.5), ("E5", 0.5), ("B4", 0.5), ("G4", 0.5),
            ("C5", 2), (None, 0.5),
        ],
    },
    "bensound-scifi.mp3": {
        "bpm": 100,
        "timbre": [1.0, 0.18, 0.42, 0.22],
        "melodia": [
            ("A3", 1), ("D4", 0.5), ("G4", 0.5), ("C5", 1.5), ("F4", 0.5),
            ("B4", 0.5), ("E5", 1), (None, 0.5),
            ("A3", 1), ("E4", 0.5), ("A4", 0.5), ("D5", 1.5), ("G4", 0.5),
            ("C5", 0.5), ("F5", 1), (None, 0.5),
        ],
    },
    "bensound-tomorrow.mp3": {
        "bpm": 96,
        "timbre": [1.0, 0.36, 0.16],
        "melodia": [
            ("C4", 1), ("E4", 1), ("G4", 1), ("C5", 2),
            ("B4", 1), ("G4", 1), ("E4", 1), ("C4", 2),
            ("D4", 1), ("F4", 1), ("A4", 1), ("D5", 2),
            ("C5", 1), ("A4", 1), ("F4", 1), ("D4", 1), ("C4", 2),
        ],
    },
}


def sintetizar(pista):
    """Devuelve las muestras PCM (array de enteros con signo de 16 bits)."""
    segundos_por_negra = 60.0 / pista["bpm"]
    timbre = pista["timbre"]
    muestras = array.array("h")

    for nota, negras in pista["melodia"]:
        dur = negras * segundos_por_negra
        n = int(dur * SAMPLE_RATE)
        if nota is None:
            muestras.extend([0] * n)
            continue

        f0 = NOTAS[nota]
        ataque = int(0.012 * SAMPLE_RATE)
        liberacion = int(0.28 * n) or 1

        for i in range(n):
            t = i / SAMPLE_RATE
            valor = 0.0
            for k, amp in enumerate(timbre, start=1):
                valor += amp * math.sin(2 * math.pi * f0 * k * t)
            valor /= sum(timbre)

            # Envolvente suave para evitar chasquidos
            if i < ataque:
                env = i / ataque
            elif i > n - liberacion:
                env = max(0.0, (n - i) / liberacion)
            else:
                env = 1.0

            # Pequeno vibrato en la segunda mitad de la nota
            if i > n * 0.45:
                valor *= 1.0 + 0.012 * math.sin(2 * math.pi * 5.2 * t)

            muestra = int(valor * env * 21000)
            if muestra > 32767:
                muestra = 32767
            elif muestra < -32768:
                muestra = -32768
            muestras.append(muestra)

    return muestras


def a_mp3(muestras):
    encoder = lameenc.Encoder()
    encoder.set_bit_rate(BIT_RATE)
    encoder.set_in_sample_rate(SAMPLE_RATE)
    encoder.set_channels(1)
    encoder.set_quality(3)
    pcm = struct.pack("<%dh" % len(muestras), *muestras)
    datos = encoder.encode(pcm)
    datos += encoder.flush()
    return datos


def main():
    if len(sys.argv) < 2:
        print("Uso: python generar_audios.py <carpeta_destino>")
        return 1

    destino = sys.argv[1]
    if not os.path.isdir(destino):
        print("La carpeta no existe: %s" % destino)
        return 1

    for nombre, pista in PISTAS.items():
        ruta = os.path.join(destino, nombre)
        muestras = sintetizar(pista)
        datos = a_mp3(muestras)
        with open(ruta, "wb") as fh:
            fh.write(datos)
        segundos = len(muestras) / SAMPLE_RATE
        print("  %-26s %6.1f s  %8d bytes" % (nombre, segundos, len(datos)))

    return 0


if __name__ == "__main__":
    sys.exit(main())
