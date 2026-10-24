class_name BaseArena
extends Node3D

const RollConfig = preload("res://scripts/config.gd")

enum ArenaType {
	CLASSIC_RING,
	DIZZY_SPINNER,
	WOBBLY_SEESAW
}

var arena_name: String = "Base Arena"
var arena_description: String = "Standard Arena"

func get_spawn_positions(count: int) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var dist = RollConfig.ARENA_RADIUS * 0.55
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU
		spots.append(Vector3(cos(angle) * dist, RollConfig.BALL_RADIUS + 0.1, sin(angle) * dist))
	return spots

func reset_arena() -> void:
	pass

func update_arena(_delta: float, _players: Array = []) -> void:
	pass
