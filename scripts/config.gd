class_name RollConfig
extends RefCounted

## Isolierte Parameter für Roll & Rumble 3D
## Erlaubt einfaches Feintuning gemäß Phase 2 des Intent-Engineerings

# Kugel-Physik
const BALL_RADIUS: float = 0.6
const BALL_MASS: float = 3.0
const DRIVE_FORCE: float = 42.0
const MAX_LINEAR_SPEED: float = 16.0
const BOOST_IMPULSE: float = 26.0
const BOOST_COOLDOWN: float = 2.5
const BRAKE_DAMPING: float = 4.0

# Material-Werte (Restitution & Reibung)
const BALL_BOUNCE: float = 0.75
const BALL_FRICTION: float = 0.55
const ARENA_FRICTION: float = 0.60
const ICE_FRICTION: float = 0.05

# Arena & Spielfeld
const ARENA_RADIUS: float = 10.0
const ARENA_HEIGHT: float = 1.0
const OUT_OF_BOUNDS_Y: float = -4.0

# Phase 2: Dynamische Arenen
const SPINNER_RADIUS: float = 6.0
const SPINNER_MAX_OMEGA: float = 2.4
const SPINNER_PERIOD: float = 8.0

const SEESAW_MAX_TILT_DEG: float = 16.0
const SEESAW_STIFFNESS: float = 3.5

# Fallen & Hazards
const TRAP_SNAP_IMPULSE_Y: float = 24.0
const TRAP_TILT_IMPULSE: float = 8.0
const TRAP_COOLDOWN: float = 3.5

# Match-Regeln & Zeiten
const MATCH_DURATION_SECONDS: float = 60.0
const WARMUP_DURATION_SECONDS: float = 3.0
const RESPAWN_DELAY_SECONDS: float = 1.5

# Kamera-Parameter (Dynamische Nahansicht für packendes Spielgefühl)
const CAMERA_MIN_DISTANCE: float = 7.0
const CAMERA_MAX_DISTANCE: float = 14.0
const CAMERA_BASE_HEIGHT: float = 7.5
const CAMERA_LOOK_ANGLE_DEG: float = -45.0
const CAMERA_LERP_SPEED: float = 5.0

# Phase 3: Power-Up System Parameter
const POWERUP_SPAWN_INTERVAL_MIN: float = 10.0
const POWERUP_SPAWN_INTERVAL_MAX: float = 16.0
const POWERUP_DURATION_SECONDS: float = 7.0
const POWERUP_TOKEN_RADIUS: float = 0.55
const POWERUP_ANVIL_MASS_MULTIPLIER: float = 3.0
const POWERUP_SPIKE_IMPULSE_MULTIPLIER: float = 2.0
const POWERUP_NITRO_CHARGES: int = 3
const POWERUP_MAGNET_RADIUS: float = 5.0
const POWERUP_MAGNET_FORCE: float = 22.0

