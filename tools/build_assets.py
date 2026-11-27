#!/usr/bin/env python3
"""
CLI Asset Pipeline for gd-godot-roll-and-rumble:
  1. 3 Seamless Bumper-Sumo Party-Arcade Tracks via FluidSynth + FFmpeg:
       - music_lobby.ogg (118 BPM, 4 bars)
       - music_battle.ogg (142 BPM, 8 bars)
       - music_sudden_death.ogg (158 BPM, 4 bars)
  2. Tangent-Space Normal Maps from existing arena textures via numpy + ImageMagick
  3. Custom 3D Trophy & Pinball Bumper via Blender headless
"""

import os
import shutil
import struct
import subprocess
import wave
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
TEX_DIR = ROOT / "assets" / "textures"
MUSIC_DIR = ROOT / "assets" / "audio" / "music"
MUSIC_DIR.mkdir(parents=True, exist_ok=True)


def _vlq(val: int) -> bytes:
    out = [val & 0x7F]
    val >>= 7
    while val:
        out.append((val & 0x7F) | 0x80)
        val >>= 7
    return bytes(reversed(out))


def _add_note(events: list, ch: int, pitch: int, vel: int, start_tick: int, dur_tick: int) -> None:
    events.append((start_tick, bytes([0x90 | ch, pitch, vel])))
    events.append((start_tick + dur_tick, bytes([0x80 | ch, pitch, 0])))


def _render_midi_loop(out_name: str, bpm: int, bars_count: int, events: list, sf2: str, tpq: int = 480) -> None:
    events.sort(key=lambda e: e[0])
    trk_data = bytearray()
    last_t = 0
    for t, msg in events:
        trk_data.extend(_vlq(t - last_t))
        trk_data.extend(msg)
        last_t = t
    trk_data.extend(_vlq(0) + b"\xFF\x2F\x00")

    header = b"MThd" + struct.pack(">IHHH", 6, 0, 1, tpq)
    track = b"MTrk" + struct.pack(">I", len(trk_data)) + bytes(trk_data)

    tmp_mid = MUSIC_DIR / f"_tmp_{out_name}.mid"
    tmp_wav = MUSIC_DIR / f"_tmp_{out_name}.wav"
    out_ogg = MUSIC_DIR / f"{out_name}.ogg"
    tmp_mid.write_bytes(header + track)

    subprocess.run(
        ["fluidsynth", "-ni", "-R", "1", "-C", "1", "-g", "1.0", "-F", str(tmp_wav), "-r", "44100", sf2, str(tmp_mid)],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    data = tmp_wav.read_bytes()
    pos, channels, sr, pcm_bytes = 12, 2, 44100, b""
    while pos + 8 <= len(data):
        cid = data[pos:pos + 4]
        csz = struct.unpack("<I", data[pos + 4:pos + 8])[0]
        chunk = data[pos + 8:pos + 8 + csz]
        if cid == b"fmt ":
            _, channels, sr, _, _, _ = struct.unpack("<HHIIHH", chunk[:16])
        elif cid == b"data":
            pcm_bytes = chunk
        pos += 8 + csz + (csz & 1)

    raw = (np.frombuffer(pcm_bytes, dtype=np.int16).astype(np.float32) / 32767.0).reshape(-1, channels)
    loop_frames = int(round(sr * bars_count * 4 * (60.0 / float(bpm))))
    if len(raw) >= loop_frames * 2:
        raw = raw[loop_frames:loop_frames * 2]
    peak = float(np.max(np.abs(raw)))
    if peak > 1e-4:
        scaled = np.tanh((raw / peak) * 1.3) * 0.88
        out_pcm = np.clip(scaled * 32767.0, -32767, 32767).astype(np.int16)
        with wave.open(str(tmp_wav), "wb") as wf:
            wf.setnchannels(channels)
            wf.setsampwidth(2)
            wf.setframerate(sr)
            wf.writeframes(out_pcm.tobytes())

    subprocess.run(
        ["ffmpeg", "-y", "-i", str(tmp_wav), "-ac", "2", "-c:a", "vorbis", "-strict", "-2", "-b:a", "192k", str(out_ogg)],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    tmp_mid.unlink(missing_ok=True)
    tmp_wav.unlink(missing_ok=True)
    print("  -> Music:", out_ogg.name)


def generate_music() -> None:
    sf2_candidates = [
        "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls",
        "/opt/homebrew/Cellar/fluid-synth/2.5.4/share/fluid-synth/sf2/VintageDreamsWaves-v2.sf2",
    ]
    sf2 = next((p for p in sf2_candidates if os.path.exists(p)), None)
    if not (shutil.which("fluidsynth") and shutil.which("ffmpeg") and sf2):
        return

    tpq = 480
    bar_len = tpq * 4
    s16 = tpq // 4

    # 1. Lobby Theme: "Sumo Warmup Groove" (118 BPM, 4 bars, C Mixolydian)
    ev_l = [
        (0, b"\xFF\x51\x03" + struct.pack(">I", int(60_000_000 / 118))[1:]),
        (0, bytes([0xC0, 12])), (0, bytes([0xC1, 36])), (0, bytes([0xC2, 61])),  # Marimba, Slap Bass, Brass
        (0, bytes([0xB0, 91, 80])), (0, bytes([0xB2, 91, 75])), (0, bytes([0xB9, 91, 50])),
    ]
    l_bars = [(36, [48, 52, 55]), (34, [46, 50, 53]), (41, [53, 57, 60]), (43, [55, 59, 62])]
    l_mel = [(0, 0, 2), (2, 1, 2), (4, 2, 2), (6, 1, 2), (8, 0, 3), (11, 2, 3), (14, 1, 2)]
    for lp in range(2):
        off = lp * 4 * bar_len
        for bi, (root, chd) in enumerate(l_bars):
            t0 = off + bi * bar_len
            for s in [0, 3, 6, 8, 10, 14]:
                _add_note(ev_l, 1, root + (12 if s in (6, 14) else 0), 104, t0 + s * s16, s16 * 2 - 10)
            for s in [0, 6, 12]:
                for p in chd:
                    _add_note(ev_l, 2, p + 12, 82, t0 + s * s16, s16 * 2)
            for s, idx, d in l_mel:
                _add_note(ev_l, 0, chd[idx] + 24, 102, t0 + s * s16, d * s16 - 15)
            for s in range(16):
                st = t0 + s * s16
                if s in (0, 6, 8):
                    _add_note(ev_l, 9, 36, 114, st, s16 * 2)
                if s in (4, 12):
                    _add_note(ev_l, 9, 38, 104, st, s16 * 2)
                _add_note(ev_l, 9, 46 if s % 4 == 2 else 42, 74, st, s16 // 2)
    _render_midi_loop("music_lobby", 118, 4, ev_l, sf2, tpq)

    # 2. Battle Theme: "Bumper Arena Showdown" (142 BPM, 8 bars, A minor / Dorian)
    ev_b = [
        (0, b"\xFF\x51\x03" + struct.pack(">I", int(60_000_000 / 142))[1:]),
        (0, bytes([0xC0, 81])), (0, bytes([0xC1, 38])), (0, bytes([0xC2, 62])),  # Saw Lead, Synth Bass, Synth Brass
        (0, bytes([0xB0, 91, 80])), (0, bytes([0xB2, 91, 75])), (0, bytes([0xB9, 91, 55])),
    ]
    b_bars = [
        (33, [45, 48, 52]), (36, [48, 52, 55]), (38, [50, 54, 57]), (40, [52, 55, 59]),
        (33, [45, 48, 52]), (41, [53, 57, 60]), (38, [50, 54, 57]), (40, [52, 56, 59]),
    ]
    b_lead = [(0, 0, 2), (2, 2, 2), (4, 1, 2), (6, 2, 2), (8, 0, 3), (11, 1, 2), (13, 2, 3)]
    for lp in range(2):
        off = lp * 8 * bar_len
        for bi, (root, chd) in enumerate(b_bars):
            t0 = off + bi * bar_len
            if bi in (0, 4):
                _add_note(ev_b, 9, 49, 108, t0, bar_len)
            for s in range(16):
                st = t0 + s * s16
                if s % 2 == 0:
                    _add_note(ev_b, 1, root + (12 if s % 4 == 2 else 0), 114 if s % 4 == 0 else 86, st, s16 - 10)
                if s in (0, 6, 8, 10):
                    _add_note(ev_b, 9, 36, 120, st, s16 * 2)
                if s in (4, 12):
                    _add_note(ev_b, 9, 38, 114, st, s16 * 2)
                _add_note(ev_b, 9, 46 if s % 4 == 2 else 42, 78, st, s16 // 2)
            for s in [0, 6, 12]:
                for p in chd:
                    _add_note(ev_b, 2, p + 12, 92, t0 + s * s16, s16 * 2)
            for s, idx, d in b_lead:
                oct_up = 24 if (bi % 2 == 1 and s >= 8) else 12
                _add_note(ev_b, 0, chd[idx] + oct_up, 102, t0 + s * s16, d * s16 - 15)
    _render_midi_loop("music_battle", 142, 8, ev_b, sf2, tpq)

    # 3. Sudden Death Theme: "Edge Panic" (158 BPM, 4 bars, D minor)
    ev_s = [
        (0, b"\xFF\x51\x03" + struct.pack(">I", int(60_000_000 / 158))[1:]),
        (0, bytes([0xC0, 81])), (0, bytes([0xC1, 38])), (0, bytes([0xC2, 62])),
        (0, bytes([0xB0, 91, 80])), (0, bytes([0xB2, 91, 75])), (0, bytes([0xB9, 91, 50])),
    ]
    s_bars = [(38, [62, 65, 69]), (34, [58, 62, 65]), (36, [60, 64, 67]), (33, [57, 61, 64])]
    for lp in range(2):
        off = lp * 4 * bar_len
        for bi, (root, chd) in enumerate(s_bars):
            t0 = off + bi * bar_len
            for s in range(16):
                st = t0 + s * s16
                _add_note(ev_s, 1, root + (12 if s % 2 == 1 else 0), 114 if s % 4 == 0 else 88, st, s16 - 10)
                if s % 4 == 0:
                    _add_note(ev_s, 9, 36, 122, st, s16 * 2)
                if s in (4, 12):
                    _add_note(ev_s, 9, 38, 118, st, s16 * 2)
                _add_note(ev_s, 9, 42, 84 if s % 2 == 0 else 60, st, s16 // 2)
            for s in [0, 3, 6, 8, 11, 14]:
                _add_note(ev_s, 0, chd[s % len(chd)] + 12, 110, t0 + s * s16, s16 * 2)
            for s in [0, 6, 12]:
                for p in chd:
                    _add_note(ev_s, 2, p, 94, t0 + s * s16, s16 * 2)
    _render_midi_loop("music_sudden_death", 158, 4, ev_s, sf2, tpq)


def generate_normal_maps() -> None:
    if not shutil.which("magick"):
        return
    targets = [
        ("wood_deck.jpg", "wood_deck_normal.png", 2.8),
        ("metal_rim.jpg", "metal_rim_normal.png", 3.2),
        ("hazard_rotor.jpg", "hazard_rotor_normal.png", 3.5),
        ("ice_slick.jpg", "ice_slick_normal.png", 2.2),
    ]
    for src_name, dst_name, strength in targets:
        src = TEX_DIR / src_name
        dst = TEX_DIR / dst_name
        if not src.exists():
            continue
        tmp_pgm = TEX_DIR / "_tmp_gray.pgm"
        tmp_ppm = TEX_DIR / "_tmp_norm.ppm"
        subprocess.run(["magick", str(src), "-colorspace", "Gray", "-depth", "8", str(tmp_pgm)], check=True)
        raw = tmp_pgm.read_bytes()
        # Parse P5 PGM header
        idx = 0
        tokens = []
        while len(tokens) < 4:
            while idx < len(raw) and chr(raw[idx]).isspace():
                idx += 1
            if raw[idx] == ord("#"):
                while idx < len(raw) and raw[idx] != ord("\n"):
                    idx += 1
                continue
            start = idx
            while idx < len(raw) and not chr(raw[idx]).isspace():
                idx += 1
            tokens.append(raw[start:idx].decode("ascii"))
        w, h = int(tokens[1]), int(tokens[2])
        img = np.frombuffer(raw[idx + 1:], dtype=np.uint8).reshape((h, w)).astype(np.float32) / 255.0

        dx = (np.roll(img, -1, axis=1) - np.roll(img, 1, axis=1)) * strength
        dy = (np.roll(img, -1, axis=0) - np.roll(img, 1, axis=0)) * strength
        nz = np.ones_like(dx)
        norm = np.sqrt(dx * dx + dy * dy + nz * nz)
        rgb = np.stack([(-dx / norm) * 0.5 + 0.5, (-dy / norm) * 0.5 + 0.5, (nz / norm) * 0.5 + 0.5], axis=-1)
        out_u8 = np.clip(rgb * 255.0, 0, 255).astype(np.uint8)
        tmp_ppm.write_bytes(f"P6\n{w} {h}\n255\n".encode("ascii") + out_u8.tobytes())
        subprocess.run(["magick", str(tmp_ppm), str(dst)], check=True)
        tmp_pgm.unlink(missing_ok=True)
        tmp_ppm.unlink(missing_ok=True)
        print("  -> Normal Map:", dst.name)


def generate_blender_models() -> None:
    blender_bin = shutil.which("blender") or ("/Applications/Blender.app/Contents/MacOS/Blender" if os.path.exists("/Applications/Blender.app/Contents/MacOS/Blender") else None)
    script = Path(__file__).resolve().parent / "blender_gen_assets.py"
    if blender_bin and script.exists():
        subprocess.run([blender_bin, "--background", "--python", str(script)], check=True, stdout=subprocess.DEVNULL)
        print("  -> Models: custom_trophy.glb, custom_bumper.glb")


def main() -> None:
    print("[1/3] Generating 3 Roll & Rumble soundtracks via FluidSynth + FFmpeg...")
    generate_music()
    print("[2/3] Generating 4 tangent-space normal maps via numpy + ImageMagick...")
    generate_normal_maps()
    print("[3/3] Generating custom_trophy.glb & custom_bumper.glb via Blender headless...")
    generate_blender_models()
    print("Roll & Rumble asset pipeline complete!")


if __name__ == "__main__":
    main()
