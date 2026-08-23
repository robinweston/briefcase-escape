#!/usr/bin/env python3
"""Generate the original procedural sound-effect candidates used by the gallery."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


RATE = 44_100
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "audio" / "sfx"


def envelope(t: float, duration: float, attack: float = 0.01, release: float = 0.08) -> float:
    return min(1.0, t / max(attack, 0.0001), (duration - t) / max(release, 0.0001))


def tone(
    duration: float,
    start_hz: float,
    end_hz: float | None = None,
    waveform: str = "sine",
    volume: float = 0.55,
    attack: float = 0.01,
    release: float = 0.08,
) -> list[float]:
    end_hz = start_hz if end_hz is None else end_hz
    samples: list[float] = []
    phase = 0.0
    for index in range(round(duration * RATE)):
        t = index / RATE
        progress = t / duration
        hz = start_hz + (end_hz - start_hz) * progress
        phase += math.tau * hz / RATE
        if waveform == "square":
            value = 1.0 if math.sin(phase) >= 0.0 else -1.0
        elif waveform == "triangle":
            value = 2.0 / math.pi * math.asin(math.sin(phase))
        else:
            value = math.sin(phase)
        samples.append(value * volume * envelope(t, duration, attack, release))
    return samples


def noise(duration: float, volume: float = 0.25, seed: int = 1, release: float = 0.08) -> list[float]:
    rng = random.Random(seed)
    previous = 0.0
    samples: list[float] = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        raw = rng.uniform(-1.0, 1.0)
        previous = previous * 0.62 + raw * 0.38
        samples.append(previous * volume * envelope(t, duration, 0.002, release))
    return samples


def silence(duration: float) -> list[float]:
    return [0.0] * round(duration * RATE)


def mix(*tracks: list[float]) -> list[float]:
    result = [0.0] * max(map(len, tracks))
    for track in tracks:
        for index, value in enumerate(track):
            result[index] += value
    peak = max(1.0, max(abs(value) for value in result) / 0.92)
    return [value / peak for value in result]


def sequence(*parts: list[float]) -> list[float]:
    result: list[float] = []
    for part in parts:
        result.extend(part)
    return result


def delayed(track: list[float], seconds: float) -> list[float]:
    return silence(seconds) + track


def notes(values: list[float], length: float, waveform: str = "sine", gap: float = 0.025) -> list[float]:
    result: list[float] = []
    for value in values:
        result.extend(tone(length, value, waveform=waveform, release=min(0.06, length * 0.45)))
        result.extend(silence(gap))
    return result


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = b"".join(struct.pack("<h", round(max(-1.0, min(1.0, sample)) * 32767)) for sample in samples)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm)


def candidates() -> dict[str, list[list[float]]]:
    return {
        "game_start": [
            notes([392, 523, 659], 0.12, "triangle", 0.025),
            notes([262, 330, 392, 523], 0.08, "square", 0.015),
            mix(tone(0.65, 220, 660, "sine", 0.42, 0.03, 0.16), delayed(tone(0.35, 880, 990, "triangle", 0.22), 0.28)),
        ],
        "disguise_on": [
            mix(tone(0.42, 760, 190, "sine", 0.48, 0.01, 0.12), noise(0.32, 0.15, 20, 0.16)),
            notes([784, 523, 330], 0.075, "square", 0.012),
            mix(tone(0.5, 980, 150, "triangle", 0.4, 0.01, 0.13), delayed(tone(0.22, 220, 110, "sine", 0.5), 0.24)),
        ],
        "disguise_off": [
            mix(tone(0.38, 180, 720, "sine", 0.48, 0.01, 0.1), noise(0.24, 0.12, 21, 0.13)),
            notes([330, 523, 784], 0.07, "square", 0.012),
            mix(tone(0.47, 140, 920, "triangle", 0.4, 0.01, 0.12), delayed(tone(0.18, 660, 1100, "sine", 0.35), 0.23)),
        ],
        "potion_pickup": [
            notes([659, 880, 1175], 0.08, "sine", 0.01),
            notes([523, 784, 1047, 1568], 0.045, "square", 0.008),
            mix(notes([440, 660, 990], 0.105, "triangle", 0.012), delayed(tone(0.3, 1250, 1900, "sine", 0.22), 0.12)),
        ],
        "worker_alert": [
            mix(tone(0.38, 520, 980, "triangle", 0.45, 0.005, 0.1), delayed(tone(0.22, 980, 720, "sine", 0.32), 0.24)),
            sequence(tone(0.11, 880, waveform="square", volume=0.34), silence(0.035), tone(0.17, 1175, waveform="square", volume=0.38)),
            mix(tone(0.62, 180, 740, "sine", 0.5, 0.01, 0.13), tone(0.62, 235, 910, "triangle", 0.24, 0.01, 0.13)),
        ],
        "briefcase_pickup": [
            mix(noise(0.16, 0.3, 31, 0.1), delayed(tone(0.25, 240, 390, "sine", 0.36), 0.05)),
            sequence(tone(0.07, 196, 294, "square", 0.28), silence(0.025), tone(0.11, 392, 523, "square", 0.32)),
            mix(tone(0.42, 110, 360, "triangle", 0.5, 0.008, 0.12), noise(0.25, 0.18, 32, 0.16)),
        ],
        "briefcase_drop": [
            mix(noise(0.18, 0.34, 41, 0.12), tone(0.2, 160, 75, "sine", 0.48, 0.003, 0.13)),
            sequence(tone(0.055, 330, 180, "square", 0.28), silence(0.02), tone(0.09, 150, 95, "square", 0.32)),
            mix(tone(0.34, 135, 52, "triangle", 0.55, 0.003, 0.18), noise(0.28, 0.23, 42, 0.2)),
        ],
        "caught": [
            mix(tone(0.72, 620, 95, "sine", 0.48, 0.005, 0.18), delayed(tone(0.45, 240, 70, "triangle", 0.34), 0.18)),
            notes([784, 587, 392, 196], 0.105, "square", 0.018),
            mix(tone(0.9, 480, 55, "triangle", 0.5, 0.005, 0.24), noise(0.72, 0.18, 50, 0.3)),
        ],
        "level_complete": [
            notes([523, 659, 784, 1047], 0.15, "sine", 0.025),
            notes([523, 659, 784, 1047, 1319], 0.085, "square", 0.012),
            mix(notes([392, 523, 659, 784], 0.17, "triangle", 0.02), delayed(tone(0.75, 1047, 1319, "sine", 0.35, 0.02, 0.3), 0.5)),
        ],
        "pause": [
            notes([440, 330], 0.09, "sine", 0.018),
            notes([523, 392], 0.06, "square", 0.012),
            mix(tone(0.3, 520, 260, "triangle", 0.4), delayed(tone(0.18, 260, 195, "sine", 0.3), 0.13)),
        ],
        "resume": [
            notes([330, 440], 0.09, "sine", 0.018),
            notes([392, 523], 0.06, "square", 0.012),
            mix(tone(0.3, 260, 520, "triangle", 0.4), delayed(tone(0.18, 520, 659, "sine", 0.3), 0.13)),
        ],
    }


def main() -> None:
    for action, options in candidates().items():
        for index, samples in enumerate(options, start=1):
            write_wav(OUTPUT / f"{action}_{index}.wav", samples)
    print(f"Generated {sum(len(group) for group in candidates().values())} sounds in {OUTPUT}")


if __name__ == "__main__":
    main()
