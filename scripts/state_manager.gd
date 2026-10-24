class_name RollStateManager
extends RefCounted

const RollConfig = preload("res://scripts/config.gd")

## State Machine & Score Manager für Roll & Rumble 3D

enum MatchState {
	WARMUP,
	PLAYING,
	SUDDEN_DEATH,
	MATCH_OVER
}

signal state_changed(new_state: MatchState)
signal score_updated(player_id: int, new_score: int)
signal timer_updated(time_remaining: float)
signal player_knocked_out(victim_id: int, kicker_id: int)
signal match_finished(winner_id: int)

var current_state: MatchState = MatchState.WARMUP
var time_remaining: float = RollConfig.MATCH_DURATION_SECONDS
var warmup_timer: float = RollConfig.WARMUP_DURATION_SECONDS
var scores: Dictionary = {1: 0, 2: 0}

func reset_match(duration: float = RollConfig.MATCH_DURATION_SECONDS) -> void:
	scores = {1: 0, 2: 0}
	time_remaining = duration
	warmup_timer = RollConfig.WARMUP_DURATION_SECONDS
	current_state = MatchState.WARMUP
	state_changed.emit(current_state)
	score_updated.emit(1, 0)
	score_updated.emit(2, 0)
	timer_updated.emit(time_remaining)

func update_logic(delta: float) -> void:
	match current_state:
		MatchState.WARMUP:
			warmup_timer -= delta
			if warmup_timer <= 0.0:
				current_state = MatchState.PLAYING
				state_changed.emit(current_state)
		MatchState.PLAYING:
			time_remaining -= delta
			timer_updated.emit(maxf(0.0, time_remaining))
			if time_remaining <= 0.0:
				time_remaining = 0.0
				_handle_timer_expiry()
		MatchState.SUDDEN_DEATH:
			pass
		MatchState.MATCH_OVER:
			pass

func record_player_fall(victim_id: int, last_hitter_id: int = 0) -> void:
	if current_state != MatchState.PLAYING and current_state != MatchState.SUDDEN_DEATH:
		return
	
	# Alle anderen lebenden Spieler erhalten einen Punkt
	for pid in scores.keys():
		if pid != victim_id:
			scores[pid] += 1
			score_updated.emit(pid, scores[pid])
	
	# Direkter Kicker-Bonus (wenn innerhalb von 1.5s aktiv gerammt)
	if last_hitter_id > 0 and last_hitter_id != victim_id and scores.has(last_hitter_id):
		scores[last_hitter_id] += 1
		score_updated.emit(last_hitter_id, scores[last_hitter_id])
	
	player_knocked_out.emit(victim_id, last_hitter_id)
	
	# Im Sudden Death führt der erste Fall sofort zum Sieg
	if current_state == MatchState.SUDDEN_DEATH:
		current_state = MatchState.MATCH_OVER
		state_changed.emit(current_state)
		match_finished.emit(get_winner())

func _handle_timer_expiry() -> void:
	if scores[1] == scores[2]:
		current_state = MatchState.SUDDEN_DEATH
		state_changed.emit(current_state)
	else:
		current_state = MatchState.MATCH_OVER
		state_changed.emit(current_state)
		match_finished.emit(get_winner())

func get_winner() -> int:
	if scores[1] > scores[2]:
		return 1
	elif scores[2] > scores[1]:
		return 2
	return 0 # Gleichstand
