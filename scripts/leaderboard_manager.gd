class_name LeaderboardManager
extends RefCounted

## Lokale Bestenliste & Statistik-Speicher für Roll & Rumble 3D
## Verwaltet Siege, Turniertitel, KOs und Match-Historie via user://roll_leaderboard.json
## mit transparentem RAM-Fallback bei Lese-/Schreibbeschränkungen.

const SAVE_PATH: String = "user://roll_leaderboard.json"

static var instance: LeaderboardManager

var stats: Dictionary = {
	"total_rounds_played": 0,
	"total_tournaments_completed": 0,
	"player_stats": {
		"1": {"name": "P1 (Rot)", "round_wins": 0, "tournaments_won": 0, "knockouts": 0, "powerups": 0},
		"2": {"name": "P2 (Blau)", "round_wins": 0, "tournaments_won": 0, "knockouts": 0, "powerups": 0},
		"3": {"name": "P3 (Gelb)", "round_wins": 0, "tournaments_won": 0, "knockouts": 0, "powerups": 0},
		"4": {"name": "P4 (Grün)", "round_wins": 0, "tournaments_won": 0, "knockouts": 0, "powerups": 0}
	},
	"recent_tournaments": []
}

func _init() -> void:
	instance = self
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err == OK and json.data is Dictionary:
		var loaded = json.data as Dictionary
		if loaded.has("total_rounds_played"):
			stats["total_rounds_played"] = int(loaded["total_rounds_played"])
		if loaded.has("total_tournaments_completed"):
			stats["total_tournaments_completed"] = int(loaded["total_tournaments_completed"])
		if loaded.has("player_stats") and loaded["player_stats"] is Dictionary:
			for pid_str in loaded["player_stats"].keys():
				if stats["player_stats"].has(pid_str):
					var p_data = loaded["player_stats"][pid_str]
					if p_data is Dictionary:
						for k in p_data.keys():
							stats["player_stats"][pid_str][k] = p_data[k]
		if loaded.has("recent_tournaments") and loaded["recent_tournaments"] is Array:
			stats["recent_tournaments"] = loaded["recent_tournaments"]

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(stats, "\t")
		file.store_string(json_str)
		file.close()

func record_knockout(kicker_id: int) -> void:
	var key = str(kicker_id)
	if stats["player_stats"].has(key):
		stats["player_stats"][key]["knockouts"] = int(stats["player_stats"][key]["knockouts"]) + 1
		save_data()

func record_powerup_collected(player_id: int) -> void:
	var key = str(player_id)
	if stats["player_stats"].has(key):
		stats["player_stats"][key]["powerups"] = int(stats["player_stats"][key]["powerups"]) + 1
		save_data()

func record_round_win(winner_id: int, arena_name: String = "") -> void:
	stats["total_rounds_played"] = int(stats["total_rounds_played"]) + 1
	var key = str(winner_id)
	if stats["player_stats"].has(key):
		stats["player_stats"][key]["round_wins"] = int(stats["player_stats"][key]["round_wins"]) + 1
	save_data()

func record_tournament_win(champion_id: int, mode_name: String, final_series_scores: Dictionary) -> void:
	stats["total_tournaments_completed"] = int(stats["total_tournaments_completed"]) + 1
	var key = str(champion_id)
	if stats["player_stats"].has(key):
		stats["player_stats"][key]["tournaments_won"] = int(stats["player_stats"][key]["tournaments_won"]) + 1
	
	var entry = {
		"champion_id": champion_id,
		"mode": mode_name,
		"scores": final_series_scores.duplicate(),
		"timestamp": Time.get_datetime_string_from_system()
	}
	stats["recent_tournaments"].push_front(entry)
	if stats["recent_tournaments"].size() > 10:
		stats["recent_tournaments"].resize(10)
	save_data()

func reset_all_stats() -> void:
	stats["total_rounds_played"] = 0
	stats["total_tournaments_completed"] = 0
	stats["recent_tournaments"].clear()
	for pid_str in stats["player_stats"].keys():
		stats["player_stats"][pid_str]["round_wins"] = 0
		stats["player_stats"][pid_str]["tournaments_won"] = 0
		stats["player_stats"][pid_str]["knockouts"] = 0
		stats["player_stats"][pid_str]["powerups"] = 0
	save_data()

func get_formatted_summary() -> String:
	var lines: Array[String] = []
	lines.append("=== ROLL & RUMBLE 3D — EWIGE BESTENLISTE ===")
	lines.append("Gespielte Runden gesamt: %d  |  Abgeschlossene Turniere: %d" % [
		stats["total_rounds_played"],
		stats["total_tournaments_completed"]
	])
	lines.append("---------------------------------------------------------------")
	lines.append("SPIELER       | TURNIERTITEL 🏆 | RUNDENSIEGE | SMASH K.O.s | POWER-UPS")
	lines.append("---------------------------------------------------------------")
	for i in range(1, 5):
		var k = str(i)
		var p = stats["player_stats"][k]
		lines.append("%-13s | %-15d | %-11d | %-11d | %-9d" % [
			p["name"],
			p["tournaments_won"],
			p["round_wins"],
			p["knockouts"],
			p["powerups"]
		])
	lines.append("---------------------------------------------------------------")
	if stats["recent_tournaments"].size() > 0:
		var last = stats["recent_tournaments"][0]
		lines.append("Letzter Champion: Spieler %d (%s)" % [last["champion_id"], last["mode"]])
	return "\n".join(lines)
