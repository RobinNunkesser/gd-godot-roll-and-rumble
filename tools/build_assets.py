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
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEX_DIR = ROOT / "assets" / "textures"
MUSIC_DIR = ROOT / "assets" / "audio" / "music"
MUSIC_DIR.mkdir(parents=True, exist_ok=True)

_PKG_ROOT = ROOT.parents[4] / "packages" / "godot" / "godot_asset_pipeline"
if _PKG_ROOT.is_dir() and str(_PKG_ROOT) not in sys.path:
    sys.path.insert(0, str(_PKG_ROOT))

from godot_asset_pipeline import (
    add_midi_note as _add_note,
    find_soundfont,
    generate_normal_map,
    render_midi_loop,
)


def _render_midi_loop(out_name: str, bpm: int, bars_count: int, events: list, sf2: str, tpq: int = 480) -> None:
    out_ogg = render_midi_loop(MUSIC_DIR / f"{out_name}.ogg", bpm, bars_count, events, sf2, tpq)
    print("  -> Music:", out_ogg.name)


def generate_music() -> None:
    sf2 = find_soundfont()
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
    targets = [
        ("wood_deck.jpg", "wood_deck_normal.png", 2.8),
        ("metal_rim.jpg", "metal_rim_normal.png", 3.2),
        ("hazard_rotor.jpg", "hazard_rotor_normal.png", 3.5),
        ("ice_slick.jpg", "ice_slick_normal.png", 2.2),
    ]
    for src_name, dst_name, strength in targets:
        dst = TEX_DIR / dst_name
        if generate_normal_map(TEX_DIR / src_name, dst, strength=strength):
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
