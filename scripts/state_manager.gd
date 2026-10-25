class_name RollStateManager
extends RefCounted

const RollConfig = preload("res://scripts/config.gd")
const LeaderboardManager = preload("res://scripts/leaderboard_manager.gd")

## State Machine, Tournament Series & Score Manager für Roll & Rumble 3D (Option B)

enum MatchState {
	LOBBY,
	WARMUP,
	PLAYING,
	SUDDEN_DEATH,
	ROUND_OVER,     ## Pause zwischen Runden in einer Turnierserie
	MATCH_OVER      ## Turniersieg / Match beendet
}

enum MatchMode {
	SINGLE_MATCH,   ## 1 Sieg entscheidet
	BEST_OF_3,      ## 2 Siege erforderlich
	BEST_OF_5,      ## 3 Siege erforderlich
	FIRST_TO_5      ## 5 Siege erforderlich
}

signal state_changed(new_state: MatchState)
signal score_updated(player_id: int, new_score: int)
signal timer_updated(time_remaining: float)
signal player_knocked_out(victim_id: int, kicker_id: int)
signal match_finished(winner_id: int)
signal series_score_updated(series_scores: Dictionary)
signal round_finished(round_winner_id: int, current_round: int)
signal tournament_finished(champion_id: int)

var current_state: MatchState = MatchState.LOBBY
var current_match_mode: MatchMode = MatchMode.SINGLE_MATCH

var time_remaining: float = RollConfig.MATCH_DURATION_SECONDS
var warmup_timer: float = RollConfig.WARMUP_DURATION_SECONDS
var round_transition_timer: float = 0.0

var scores: Dictionary = {1: 0, 2: 0}
var series_scores: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var current_round_number: int = 1
var active_players: Array = [1, 2]

func enter_lobby(players: Array = [1, 2]) -> void:
	active_players = players.duplicate()
	scores.clear()
	series_scores.clear()
	for pid in active_players:
		scores[pid] = 0
		series_scores[pid] = 0
		score_updated.emit(pid, 0)
	current_round_number = 1
	current_state = MatchState.LOBBY
	series_score_updated.emit(series_scores)
	state_changed.emit(current_state)

func set_match_mode(mode: MatchMode) -> void:
	current_match_mode = mode

func cycle_match_mode() -> MatchMode:
	var total = MatchMode.values().size()
	current_match_mode = ((int(current_match_mode) + 1) % total) as MatchMode
	return current_match_mode

func get_required_wins() -> int:
	match current_match_mode:
		MatchMode.SINGLE_MATCH: return 1
		MatchMode.BEST_OF_3: return 2
		MatchMode.BEST_OF_5: return 3
		MatchMode.FIRST_TO_5: return 5
	return 1

func get_mode_name(mode: MatchMode = current_match_mode) -> String:
	match mode:
		MatchMode.SINGLE_MATCH: return "EINZELMATCH (1 Runde)"
		MatchMode.BEST_OF_3: return "BEST OF 3 (Ziel: 2 Siege)"
		MatchMode.BEST_OF_5: return "BEST OF 5 (Ziel: 3 Siege)"
		MatchMode.FIRST_TO_5: return "FIRST TO 5 (Ziel: 5 Siege)"
	return "UNKNOWN"

func start_match(players: Array = active_players, duration: float = RollConfig.MATCH_DURATION_SECONDS) -> void:
	active_players = players.duplicate()
	scores.clear()
	for pid in active_players:
		scores[pid] = 0
		if not series_scores.has(pid):
			series_scores[pid] = 0
		score_updated.emit(pid, 0)
	time_remaining = duration
	warmup_timer = RollConfig.WARMUP_DURATION_SECONDS
	current_state = MatchState.WARMUP
	state_changed.emit(current_state)
	timer_updated.emit(time_remaining)
	series_score_updated.emit(series_scores)

func start_series(players: Array = active_players, duration: float = RollConfig.MATCH_DURATION_SECONDS) -> void:
	series_scores.clear()
	for pid in players:
		series_scores[pid] = 0
	current_round_number = 1
	start_match(players, duration)

func start_next_round(duration: float = RollConfig.MATCH_DURATION_SECONDS) -> void:
	current_round_number += 1
	start_match(active_players, duration)

func reset_match(duration: float = RollConfig.MATCH_DURATION_SECONDS) -> void:
	start_series(active_players, duration)

func update_logic(delta: float) -> void:
	match current_state:
		MatchState.LOBBY:
			pass
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
		MatchState.ROUND_OVER:
			round_transition_timer -= delta
			if round_transition_timer <= 0.0:
				start_next_round()
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
		if LeaderboardManager.instance:
			LeaderboardManager.instance.record_knockout(last_hitter_id)
	
	player_knocked_out.emit(victim_id, last_hitter_id)
	
	# Im Sudden Death führt der erste Fall sofort zur Beendigung der Runde
	if current_state == MatchState.SUDDEN_DEATH:
		_conclude_round(get_winner())

func _handle_timer_expiry() -> void:
	var best_score = -1
	var leaders: Array = []
	for pid in scores.keys():
		if scores[pid] > best_score:
			best_score = scores[pid]
			leaders = [pid]
		elif scores[pid] == best_score:
			leaders.append(pid)
	
	if leaders.size() > 1:
		current_state = MatchState.SUDDEN_DEATH
		state_changed.emit(current_state)
	else:
		_conclude_round(get_winner())

func _conclude_round(winner_id: int) -> void:
	if winner_id > 0:
		series_scores[winner_id] = int(series_scores.get(winner_id, 0)) + 1
		if LeaderboardManager.instance:
			LeaderboardManager.instance.record_round_win(winner_id)
	series_score_updated.emit(series_scores)
	round_finished.emit(winner_id, current_round_number)
	
	var req = get_required_wins()
	var champ = 0
	for pid in series_scores.keys():
		if series_scores[pid] >= req:
			champ = pid
			break
	
	if champ > 0 or current_match_mode == MatchMode.SINGLE_MATCH:
		current_state = MatchState.MATCH_OVER
		state_changed.emit(current_state)
		var final_winner = champ if champ > 0 else winner_id
		if LeaderboardManager.instance and final_winner > 0:
			LeaderboardManager.instance.record_tournament_win(final_winner, get_mode_name(), series_scores)
		tournament_finished.emit(final_winner)
		match_finished.emit(final_winner)
	else:
		current_state = MatchState.ROUND_OVER
		round_transition_timer = 4.0
		state_changed.emit(current_state)

func get_winner() -> int:
	var best_score = -1
	var winner_id = 0
	var is_draw = false
	for pid in scores.keys():
		if scores[pid] > best_score:
			best_score = scores[pid]
			winner_id = pid
			is_draw = false
		elif scores[pid] == best_score:
			is_draw = true
	return 0 if is_draw else winner_id

func get_tournament_champion() -> int:
	var req = get_required_wins()
	for pid in series_scores.keys():
		if series_scores[pid] >= req:
			return pid
	return get_winner()
