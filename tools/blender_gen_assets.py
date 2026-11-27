"""
Headless Blender Python script for gd-godot-roll-and-rumble.
Run via: /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/blender_gen_assets.py

Generates:
  - assets/models/custom_trophy.glb (Championship Sumo Trophy with marble base, lathe stem, chalice & curved handles)
  - assets/models/custom_bumper.glb (Arcade Pinball Bumper with chrome collar, glowing neon ring & domed cap)
"""

import math
from pathlib import Path
import bpy

MODELS_DIR = Path(__file__).resolve().parent.parent / "assets" / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def create_material(name: str, color: tuple, metallic: float = 0.7, roughness: float = 0.25, emission: tuple = None, emission_strength: float = 2.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if emission is not None and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def build_custom_trophy() -> None:
    clear_scene()
    mat_marble = create_material("TrophyMarble", (0.09, 0.10, 0.14, 1.0), metallic=0.35, roughness=0.22)
    mat_gold = create_material("TrophyGold", (1.0, 0.80, 0.16, 1.0), metallic=0.95, roughness=0.16, emission=(1.0, 0.72, 0.10, 1.0), emission_strength=0.35)
    mat_gem = create_material("TrophyGem", (0.95, 0.22, 0.15, 1.0), metallic=0.1, roughness=0.12, emission=(1.0, 0.25, 0.10, 1.0), emission_strength=1.5)

    # Stepped Marble Base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.16))
    base = bpy.context.active_object
    base.scale = (0.92, 0.92, 0.32)
    base.data.materials.append(mat_marble)

    # Gold Plaque Ring
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.42, depth=0.12, location=(0, 0, 0.38))
    plaque = bpy.context.active_object
    plaque.data.materials.append(mat_gold)

    # Turned Stem + Mid-Knuckle
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.15, depth=0.48, location=(0, 0, 0.68))
    stem = bpy.context.active_object
    stem.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_torus_add(major_radius=0.18, minor_radius=0.055, location=(0, 0, 0.68))
    knuckle = bpy.context.active_object
    knuckle.data.materials.append(mat_gold)

    # Sculpted Chalice Cup
    bpy.ops.mesh.primitive_cone_add(vertices=28, radius1=0.62, radius2=0.20, depth=0.82, location=(0, 0, 1.32), rotation=(math.pi, 0, 0))
    cup = bpy.context.active_object
    cup.data.materials.append(mat_gold)

    # Top Rim Torus
    bpy.ops.mesh.primitive_torus_add(major_radius=0.62, minor_radius=0.05, location=(0, 0, 1.72))
    rim = bpy.context.active_object
    rim.data.materials.append(mat_gold)

    # Curved Handles (-X and +X)
    for sx in (-1.0, 1.0):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.26, minor_radius=0.045, location=(sx * 0.56, 0, 1.38), rotation=(math.radians(90), 0, 0))
        h = bpy.context.active_object
        h.scale = (0.75, 1.0, 1.2)
        h.data.materials.append(mat_gold)

    # Center Ruby Accent on Plaque
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.08, location=(0, -0.42, 0.38))
    gem = bpy.context.active_object
    gem.data.materials.append(mat_gem)

    bpy.ops.export_scene.gltf(
        filepath=str(MODELS_DIR / "custom_trophy.glb"),
        export_format="GLB",
        export_apply=True,
    )


def build_custom_bumper() -> None:
    clear_scene()
    mat_chrome = create_material("BumperChrome", (0.82, 0.86, 0.92, 1.0), metallic=0.95, roughness=0.15)
    mat_neon = create_material("BumperNeon", (0.15, 0.85, 1.0, 1.0), metallic=0.2, roughness=0.2, emission=(0.15, 0.85, 1.0, 1.0), emission_strength=2.2)
    mat_cap = create_material("BumperCap", (0.95, 0.22, 0.18, 1.0), metallic=0.35, roughness=0.18, emission=(0.95, 0.22, 0.18, 1.0), emission_strength=0.4)
    mat_gold = create_material("BumperStud", (1.0, 0.82, 0.2, 1.0), metallic=0.92, roughness=0.2)

    # Chrome Base Collar
    bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=1.12, depth=0.18, location=(0, 0, 0.09))
    base = bpy.context.active_object
    base.data.materials.append(mat_chrome)

    # Glowing Neon Bounce Ring
    bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=0.96, depth=0.42, location=(0, 0, 0.36))
    ring = bpy.context.active_object
    ring.data.materials.append(mat_neon)

    # Upper Chrome Rim
    bpy.ops.mesh.primitive_torus_add(major_radius=0.96, minor_radius=0.07, location=(0, 0, 0.56))
    rim = bpy.context.active_object
    rim.data.materials.append(mat_chrome)

    # Glossy Domed Cap
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=0.86, location=(0, 0, 0.54))
    cap = bpy.context.active_object
    cap.scale = (1.0, 1.0, 0.36)
    cap.data.materials.append(mat_cap)

    # Center Gold Stud
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.22, depth=0.12, location=(0, 0, 0.83))
    stud = bpy.context.active_object
    stud.data.materials.append(mat_gold)

    bpy.ops.export_scene.gltf(
        filepath=str(MODELS_DIR / "custom_bumper.glb"),
        export_format="GLB",
        export_apply=True,
    )


if __name__ == "__main__":
    build_custom_trophy()
    build_custom_bumper()
    print("Blender custom_trophy.glb & custom_bumper.glb export complete!")
