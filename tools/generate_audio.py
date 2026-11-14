"""Generate the small original sounds used by the Godot prototype."""

from math import exp, pi, sin
from pathlib import Path
from random import Random
from wave import open as wave_open


RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
RNG = Random(17)


def write(name, duration, sample):
    with wave_open(str(OUT / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        frames = bytearray()
        for i in range(int(duration * RATE)):
            value = max(-1.0, min(1.0, sample(i / RATE)))
            frames.extend(int(value * 24000).to_bytes(2, "little", signed=True))
        wav.writeframes(frames)


def music(t):
    # Eight bars at 120 BPM; the first and last bars share the same chord.
    chords = ((110, 130.81, 164.81), (98, 123.47, 146.83),
              (87.31, 110, 130.81), (110, 130.81, 164.81))
    chord = chords[int(t // 4) % 4]
    pulse = 0.60 + 0.12 * sin(2 * pi * 0.25 * t)
    drone = sum(sin(2 * pi * f * t) + 0.16 * sin(2 * pi * 2 * f * t) for f in chord) / 3
    beat = t % 0.5
    bell = sin(2 * pi * chord[1] * 4 * t) * exp(-10 * beat) if int(t * 2) % 4 == 0 else 0
    return 0.13 * drone * pulse + 0.07 * bell


def sword(t):
    return (RNG.random() * 2 - 1) * exp(-18 * t) * sin(pi * min(1, t / 0.025)) * 0.75


def hit(t):
    thud = sin(2 * pi * (125 - 75 * t) * t) * exp(-22 * t)
    crack = (RNG.random() * 2 - 1) * exp(-45 * t)
    return 0.62 * thud + 0.22 * crack


def death(t):
    fall = sin(2 * pi * (270 * t - 120 * t * t)) * exp(-2.5 * t)
    echo = sin(2 * pi * 55 * t) * exp(-3 * t)
    return 0.35 * fall + 0.18 * echo


write("abyss_theme.wav", 16.0, music)
write("sword_swish.wav", 0.25, sword)
write("enemy_hit.wav", 0.28, hit)
write("knight_death.wav", 0.85, death)
