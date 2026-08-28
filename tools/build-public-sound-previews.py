from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "dist" / "local" / "public-sound-preview"
RATE = 44_100


def envelope(length: int, attack: float = 0.015, release: float = 0.12) -> np.ndarray:
    env = np.ones(length, dtype=np.float64)
    attack_n = min(length, max(1, int(RATE * attack)))
    release_n = min(length, max(1, int(RATE * release)))
    env[:attack_n] *= np.linspace(0.0, 1.0, attack_n)
    env[-release_n:] *= np.linspace(1.0, 0.0, release_n)
    return env


def retro_tone(freq: float, duration: float, volume: float = 0.55) -> np.ndarray:
    t = np.arange(int(RATE * duration), dtype=np.float64) / RATE
    phase = 2.0 * np.pi * freq * t
    sine = np.sin(phase)
    triangle = 2.0 / np.pi * np.arcsin(np.sin(phase))
    square = np.sign(np.sin(phase))
    signal = (0.72 * sine + 0.22 * triangle + 0.06 * square) * envelope(len(t), 0.012, min(0.18, duration / 2))
    signal = np.convolve(signal, np.ones(5) / 5.0, mode="same")
    signal = np.round(signal * 256.0) / 256.0
    return signal * volume


def silicon_tone(freq: float, duration: float, volume: float = 0.46, index: float = 1.3) -> np.ndarray:
    t = np.arange(int(RATE * duration), dtype=np.float64) / RATE
    carrier = np.sin(2.0 * np.pi * freq * t + index * np.sin(2.0 * np.pi * freq * 1.51 * t))
    shimmer = np.sin(2.0 * np.pi * freq * 2.02 * t) * 0.18
    return (carrier + shimmer) * envelope(len(t), 0.006, min(0.22, duration / 2)) * volume


def sweep(start: float, end: float, duration: float, volume: float = 0.45) -> np.ndarray:
    count = int(RATE * duration)
    t = np.arange(count, dtype=np.float64) / RATE
    frequencies = np.linspace(start, end, count)
    phase = 2.0 * np.pi * np.cumsum(frequencies) / RATE
    signal = np.sin(phase + 0.65 * np.sin(phase * 1.73))
    return signal * envelope(count, 0.008, min(0.2, duration / 2)) * volume


def sequence(parts: list[tuple[float, np.ndarray]], tail: float = 0.12) -> np.ndarray:
    total = max((start + len(sound) / RATE for start, sound in parts), default=0.0) + tail
    output = np.zeros(int(total * RATE), dtype=np.float64)
    for start, sound in parts:
        offset = int(start * RATE)
        end = min(len(output), offset + len(sound))
        output[offset:end] += sound[: end - offset]
    return normalize(output)


def normalize(signal: np.ndarray, peak: float = 0.72) -> np.ndarray:
    maximum = float(np.max(np.abs(signal))) if len(signal) else 0.0
    if maximum > 0:
        signal = signal * (peak / maximum)
    return np.clip(signal, -1.0, 1.0)


def write_wav(path: Path, signal: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (normalize(signal) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())


def retro_events() -> dict[str, np.ndarray]:
    tone = retro_tone
    return {
        "retro-notify.wav": sequence([(0.00, tone(440.00, 0.20)), (0.16, tone(659.25, 0.32))]),
        "retro-complete.wav": sequence([(0.00, tone(523.25, 0.23)), (0.17, tone(659.25, 0.25)), (0.35, tone(783.99, 0.38))]),
        "retro-question.wav": sequence([(0.00, tone(392.00, 0.26)), (0.23, tone(587.33, 0.38))]),
        "retro-warning.wav": sequence([(0.00, tone(440.00, 0.24)), (0.30, tone(440.00, 0.30))]),
        "retro-error.wav": sequence([(0.00, tone(329.63, 0.28, 0.62)), (0.22, tone(196.00, 0.42, 0.62))]),
        "retro-start.wav": sequence([
            (0.00, tone(261.63, 0.75, 0.34)),
            (0.32, tone(392.00, 0.72, 0.36)),
            (0.66, tone(523.25, 0.75, 0.38)),
            (1.02, tone(659.25, 0.90, 0.40)),
            (1.40, tone(783.99, 0.85, 0.36)),
        ], 0.25),
        "retro-logon.wav": sequence([(0.00, tone(392.00, 0.32)), (0.23, tone(523.25, 0.36)), (0.48, tone(659.25, 0.52))]),
        "retro-logoff.wav": sequence([(0.00, tone(659.25, 0.32)), (0.22, tone(523.25, 0.34)), (0.45, tone(392.00, 0.48))]),
        "retro-exit.wav": sequence([(0.00, tone(523.25, 0.40)), (0.28, tone(392.00, 0.46)), (0.58, tone(261.63, 0.72))], 0.22),
    }


def silicon_events() -> dict[str, np.ndarray]:
    tone = silicon_tone
    return {
        "silicon-notify.wav": sequence([(0.00, tone(880.00, 0.20)), (0.12, tone(1318.51, 0.34, 0.42))]),
        "silicon-complete.wav": sequence([(0.00, tone(659.25, 0.22)), (0.14, tone(987.77, 0.26)), (0.30, tone(1318.51, 0.46))]),
        "silicon-question.wav": sequence([(0.00, tone(523.25, 0.26)), (0.18, sweep(650.0, 1040.0, 0.42))]),
        "silicon-warning.wav": sequence([(0.00, tone(622.25, 0.20, 0.56)), (0.24, tone(622.25, 0.28, 0.56))]),
        "silicon-error.wav": sequence([(0.00, sweep(980.0, 190.0, 0.58, 0.62)), (0.20, tone(164.81, 0.42, 0.38, 2.2))]),
        "silicon-start.wav": sequence([
            (0.00, sweep(180.0, 620.0, 1.35, 0.30)),
            (0.38, tone(523.25, 0.58, 0.28)),
            (0.78, tone(783.99, 0.62, 0.30)),
            (1.18, tone(1046.50, 0.72, 0.34)),
            (1.58, tone(1567.98, 0.68, 0.28)),
        ], 0.28),
        "silicon-logon.wav": sequence([(0.00, sweep(320.0, 760.0, 0.48)), (0.28, tone(1046.50, 0.54, 0.42))]),
        "silicon-logoff.wav": sequence([(0.00, tone(1046.50, 0.34)), (0.20, sweep(760.0, 280.0, 0.55))]),
        "silicon-exit.wav": sequence([(0.00, tone(987.77, 0.34)), (0.20, tone(659.25, 0.40)), (0.46, sweep(520.0, 120.0, 0.76))], 0.24),
    }


def montage(events: dict[str, np.ndarray]) -> np.ndarray:
    ordered = ["notify", "complete", "question", "warning", "error", "start", "logon", "logoff", "exit"]
    parts: list[np.ndarray] = []
    silence = np.zeros(int(RATE * 0.55), dtype=np.float64)
    for event in ordered:
        name = next(key for key in events if f"-{event}.wav" in key)
        parts.extend([events[name], silence])
    return np.concatenate(parts)


def build_set(folder: str, events: dict[str, np.ndarray]) -> None:
    target = OUTPUT / folder
    for name, signal in events.items():
        write_wav(target / name, signal)
    write_wav(OUTPUT / f"Muestra-{folder}.wav", montage(events))


def main() -> None:
    build_set("Retro-CC0", retro_events())
    build_set("Silicon-CC0", silicon_events())
    license_text = """SONIDOS PÚBLICOS DE JANUS+

Estos sonidos fueron generados proceduralmente para JANUS+ y no contienen
grabaciones ni muestras extraídas de Microsoft Windows u otros productos.

El proyecto JANUS+ ofrece estos archivos bajo Creative Commons Zero 1.0 (CC0):
https://creativecommons.org/publicdomain/zero/1.0/

Se estudiaron como referencia bancos CC0 de Kenney y OpenGameArt, pero las
muestras entregadas en estas carpetas fueron sintetizadas desde cero.
"""
    (OUTPUT / "ORIGEN-Y-LICENCIA.txt").write_text(license_text, encoding="utf-8")
    print(OUTPUT)


if __name__ == "__main__":
    main()
