class_name PowerUpSpawner
extends Node3D

## Spawner für periodische 3D-Power-Up-Tokens in Roll & Rumble 3D (Phase 3)
## Überwacht Token-Limits, zufällige Spawn-Positionen auf der Arena-Oberfläche
## und unterstützt das Deaktivieren via Hauptmenü / Lobby.

const PowerUpToken = preload("res://scripts/powerup_token.gd")
const RollConfig = preload("res://scripts/config.gd")

@export var enabled: bool = true
@export var max_active_tokens: int = 2

var spawn_timer: float = 5.0
var active_tokens: Array[PowerUpToken] = []

func _ready() -> void:
	reset_timer()

func _process(delta: float) -> void:
	if not enabled or not is_inside_tree():
		return
	
	# Ungültige / aufgesammelte Tokens aus Liste entfernen
	active_tokens = active_tokens.filter(func(t): return is_instance_valid(t) and not t.is_queued_for_deletion())
	
	if active_tokens.size() >= max_active_tokens:
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_random_token()
		spawn_timer = randf_range(RollConfig.POWERUP_SPAWN_INTERVAL_MIN, RollConfig.POWERUP_SPAWN_INTERVAL_MAX)

func spawn_random_token() -> PowerUpToken:
	var types = PowerUpToken.Type.values()
	var random_type = types[randi() % types.size()]
	
	# Zufällige Position auf der Arena (innerhalb von 62% des Arena-Radius für sicheren Stand)
	var angle = randf() * TAU
	var radius = randf_range(1.5, RollConfig.ARENA_RADIUS * 0.62)
	var spawn_pos = Vector3(cos(angle) * radius, 0.85, sin(angle) * radius)
	
	var token = PowerUpToken.new(random_type)
	token.position = spawn_pos
	add_child(token)
	active_tokens.append(token)
	return token

func spawn_specific_token(type: PowerUpToken.Type, pos: Vector3) -> PowerUpToken:
	var token = PowerUpToken.new(type)
	token.position = pos
	add_child(token)
	active_tokens.append(token)
	return token

func clear_tokens() -> void:
	for t in active_tokens:
		if is_instance_valid(t) and not t.is_queued_for_deletion():
			t.queue_free()
	active_tokens.clear()
	reset_timer()

func reset_timer() -> void:
	# Erster Spawn nach Rundenstart nach 4 bis 7 Sekunden
	spawn_timer = randf_range(4.5, 7.5)
