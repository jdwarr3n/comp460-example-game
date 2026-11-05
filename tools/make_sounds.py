# Generates the game's sounds as WAV files in audio/.
# Run from the repo root: python tools/make_sounds.py [preview_file]
# Everything is synthesized here, so there's nothing to license. Loops are built from whole
# cycles of the loop length, so they repeat with no click at the seam.
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 44100
LOOP_SECONDS = 2.0
SAMPLES = int(RATE * LOOP_SECONDS)
TIME = np.arange(SAMPLES) / RATE


def tone(frequency):
    # Rounded to a whole number of cycles per loop.
    cycles = round(frequency * LOOP_SECONDS)
    return np.sin(2.0 * np.pi * cycles * TIME / LOOP_SECONDS)


def noise(low, high, seed):
    # Random in the frequency domain, so the noise itself repeats exactly.
    rng = np.random.default_rng(seed)
    spectrum = np.zeros(SAMPLES // 2 + 1, dtype=complex)
    first, last = int(low * LOOP_SECONDS), int(high * LOOP_SECONDS)
    phases = rng.uniform(0.0, 2.0 * np.pi, last - first)
    spectrum[first:last] = np.exp(1j * phases)
    result = np.fft.irfft(spectrum, SAMPLES)
    return result / np.max(np.abs(result))


def motor(base, whine, gear_rate, hiss, seed):
    hum = sum(tone(base * n) / n for n in range(1, 7))
    hum = hum / np.max(np.abs(hum))
    sound = 0.6 * hum + 0.2 * tone(whine) + hiss * noise(300, 4000, seed)
    # The gears make the level flutter.
    sound = sound * (1.0 + 0.25 * tone(gear_rate))
    return 0.6 * sound / np.max(np.abs(sound))


def ticks(rate, seed):
    # Ratchet clicks for the cable winch.
    count = round(rate * LOOP_SECONDS)
    click = np.exp(-np.arange(300) / 40.0)
    train = np.zeros(SAMPLES)
    for i in range(count):
        train[(i * SAMPLES // count + np.arange(300)) % SAMPLES] += click
    return train * noise(1500, 6000, seed)


def carriage_motor():
    return motor(140.0, 1120.0, 22.0, 0.08, 1)


def cable_motor():
    sound = motor(70.0, 420.0, 14.0, 0.05, 2) + 0.3 * ticks(16.0, 3)
    return 0.6 * sound / np.max(np.abs(sound))


def decaying(duration, seed, parts):
    # A hit: a few tones and a burst of noise, each dying away at its own rate.
    count = int(duration * RATE)
    time = np.arange(count) / RATE
    rng = np.random.default_rng(seed)
    sound = np.zeros(count)
    for frequency, level, decay in parts:
        sound += level * np.sin(2.0 * np.pi * frequency * time) * np.exp(-time / decay)
    fade = np.minimum(1.0, (count - np.arange(count)) / (0.005 * RATE))
    return sound * fade, rng, time


def hit_soft():
    # A prize landing on the felt.
    sound, rng, time = decaying(0.16, 4, [(150.0, 1.0, 0.03), (95.0, 0.7, 0.05)])
    sound += 0.25 * rng.uniform(-1.0, 1.0, len(sound)) * np.exp(-time / 0.008)
    return 0.8 * sound / np.max(np.abs(sound))


def hit_plastic():
    # Two prizes knocking together.
    sound, rng, time = decaying(0.1, 5, [(920.0, 1.0, 0.012), (1480.0, 0.6, 0.008), (310.0, 0.5, 0.02)])
    sound += 0.2 * rng.uniform(-1.0, 1.0, len(sound)) * np.exp(-time / 0.004)
    return 0.8 * sound / np.max(np.abs(sound))


def hit_metal():
    # The claw or a coin striking something.
    sound, rng, time = decaying(0.45, 6, [(1830.0, 1.0, 0.09), (2710.0, 0.6, 0.06), (4390.0, 0.4, 0.04), (6130.0, 0.2, 0.02)])
    sound += 0.2 * rng.uniform(-1.0, 1.0, len(sound)) * np.exp(-time / 0.003)
    return 0.8 * sound / np.max(np.abs(sound))


def countdown_tick():
    # A soft, rounded tick for the end of a round.
    sound, _, _ = decaying(0.12, 8, [(880.0, 1.0, 0.03), (1760.0, 0.2, 0.015)])
    attack = np.minimum(np.arange(len(sound)) / (0.004 * RATE), 1.0)
    return 0.7 * sound * attack / np.max(np.abs(sound))


def hits_preview(soft, plastic, metal):
    # Each hit at three strengths, then a pile settling.
    length = int(7.0 * RATE)
    track = np.zeros(length)

    def place(sound, seconds, level):
        start = int(seconds * RATE)
        end = min(start + len(sound), length)
        track[start:end] += level * sound[: end - start]

    for row, sound in enumerate((soft, plastic, metal)):
        for strength, level in enumerate((1.0, 0.5, 0.2)):
            place(sound, 0.1 + row * 1.3 + strength * 0.4, level)
    rng = np.random.default_rng(7)
    for _ in range(40):
        sound = (soft, plastic, plastic, metal)[rng.integers(4)]
        place(sound, 4.2 + 2.0 * rng.random() ** 2, rng.uniform(0.05, 0.4))
    return 0.9 * track / np.max(np.abs(track))


def save(path, sound):
    data = (np.clip(sound, -1.0, 1.0) * 32767.0).astype(np.int16)
    with wave.open(str(path), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(data.tobytes())


def play_for(sound, seconds):
    # A faded copy for listening outside the game.
    count = int(seconds * RATE)
    clip = np.resize(sound, count)
    fade = np.minimum(1.0, np.minimum(np.arange(count), count - np.arange(count)) / (0.15 * RATE))
    return clip * fade


def main():
    Path("audio").mkdir(exist_ok=True)
    save("audio/motor_carriage.wav", carriage_motor())
    save("audio/motor_cable.wav", cable_motor())
    soft, plastic, metal = hit_soft(), hit_plastic(), hit_metal()
    save("audio/hit_soft.wav", soft)
    save("audio/hit_plastic.wav", plastic)
    save("audio/hit_metal.wav", metal)
    tick = countdown_tick()
    save("audio/countdown_tick.wav", tick)
    if len(sys.argv) > 1:
        second = np.zeros(RATE)
        second[: len(tick)] = tick
        save(sys.argv[1], np.tile(second, 5))


if __name__ == "__main__":
    main()
