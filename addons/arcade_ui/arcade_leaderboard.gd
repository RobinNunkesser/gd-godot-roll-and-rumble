class_name ArcadeLeaderboard
extends RefCounted

## Gemeinsame lokale, namensbasierte Bestenliste für alle Couch-Multiplayer-Spiele.
## Speichert Siege, Cups/Turniere, gespielte Matches und Punkte pro Spielername in user://couch_leaderboard_<game_id>.json.

var game_id: String = "default"
var save_path: String = ""

var data: Dictionary = {
	"recent_names": ["P1", "P2", "P3", "P4"],
	"profiles": {}
}

func _init(id: String = "default") -> void:
	game_id = id
	save_path = "user://couch_leaderboard_%s.json" % game_id
	load_data()

func load_data() -> void:
	if save_path == "" or not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if not f:
		return
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) == OK and json.data is Dictionary:
		var loaded := json.data as Dictionary
		if loaded.has("recent_names") and loaded["recent_names"] is Array:
			data["recent_names"] = []
			for n in loaded["recent_names"]:
				var s := str(n).strip_edges()
				if s != "" and not data["recent_names"].has(s):
					data["recent_names"].append(s)
		if loaded.has("profiles") and loaded["profiles"] is Dictionary:
			data["profiles"] = loaded["profiles"].duplicate(true)

func save_data() -> void:
	if save_path == "":
		return
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func add_recent_name(player_name: String) -> void:
	var clean := player_name.strip_edges().substr(0, 12)
	if clean == "":
		return
	var rec: Array = data["recent_names"]
	rec.erase(clean)
	rec.push_front(clean)
	if rec.size() > 8:
		rec.resize(8)
	save_data()

func _ensure_profile(player_name: String) -> Dictionary:
	var profiles: Dictionary = data["profiles"]
	if not profiles.has(player_name):
		profiles[player_name] = {"wins": 0, "cups": 0, "matches": 0, "score": 0}
	return profiles[player_name]

func record_match(active_names: Array[String], winner_names: Array[String], is_cup_win: bool = false, score_by_name: Dictionary = {}) -> void:
	for raw_name in active_names:
		var n := raw_name.strip_edges().substr(0, 12)
		if n == "":
			continue
		add_recent_name(n)
		var p := _ensure_profile(n)
		p["matches"] = int(p.get("matches", 0)) + 1
		if score_by_name.has(raw_name):
			p["score"] = int(p.get("score", 0)) + int(score_by_name[raw_name])
	for raw_w in winner_names:
		var w := raw_w.strip_edges().substr(0, 12)
		if w == "":
			continue
		var pw := _ensure_profile(w)
		pw["wins"] = int(pw.get("wins", 0)) + 1
		if is_cup_win:
			pw["cups"] = int(pw.get("cups", 0)) + 1
	save_data()

func get_top_entries(limit: int = 10) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var profiles: Dictionary = data["profiles"]
	for n in profiles.keys():
		var p: Dictionary = profiles[n]
		list.append({
			"name": str(n),
			"wins": int(p.get("wins", 0)),
			"cups": int(p.get("cups", 0)),
			"matches": int(p.get("matches", 0)),
			"score": int(p.get("score", 0)),
		})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["cups"] != b["cups"]:
			return a["cups"] > b["cups"]
		if a["wins"] != b["wins"]:
			return a["wins"] > b["wins"]
		return a["score"] > b["score"]
	)
	if list.size() > limit:
		list.resize(limit)
	return list

func format_table(score_label: String = "Pkt", limit: int = 8) -> String:
	var entries := get_top_entries(limit)
	if entries.is_empty():
		return "Noch keine Einträge — spielt ein Match!"
	var lines: Array[String] = []
	lines.append("%-3s %-13s %5s %5s %6s %6s" % ["#", "NAME", "SIEGE", "CUPS", "SPIELE", score_label.to_upper()])
	lines.append("--------------------------------------------------")
	for i in range(entries.size()):
		var e := entries[i]
		lines.append("%-3d %-13s %5d %5d %6d %6d" % [i + 1, e["name"], e["wins"], e["cups"], e["matches"], e["score"]])
	return "\n".join(lines)

func reset_all() -> void:
	data["profiles"] = {}
	save_data()

func populate_view(container: VBoxContainer, score_label: String = "Pkt", limit: int = 8) -> void:
	for child in container.get_children():
		child.queue_free()

	var entries := get_top_entries(limit)
	if entries.is_empty():
		var empty_panel := PanelContainer.new()
		var sb_empty := StyleBoxFlat.new()
		sb_empty.bg_color = Color(0.10, 0.13, 0.22, 0.80)
		sb_empty.border_color = Color(0.28, 0.34, 0.50, 0.65)
		sb_empty.set_border_width_all(1)
		sb_empty.set_corner_radius_all(8)
		sb_empty.set_content_margin_all(18)
		empty_panel.add_theme_stylebox_override("panel", sb_empty)
		var empty_lbl := Label.new()
		empty_lbl.text = "Noch keine Einträge — spielt ein Match!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.70, 0.78, 0.90))
		empty_panel.add_child(empty_lbl)
		container.add_child(empty_panel)
		return

	container.add_child(_make_table_row(["#", "SPIELER", "SIEGE", "CUPS", "SPIELE", score_label.to_upper()], true, -1))
	for i in range(entries.size()):
		var e := entries[i]
		var rank_txt: String = str(["🥇", "🥈", "🥉"][i]) if i < 3 else "#%d" % (i + 1)
		container.add_child(_make_table_row([
			rank_txt,
			str(e["name"]),
			str(e["wins"]),
			str(e["cups"]),
			str(e["matches"]),
			str(e["score"]),
		], false, i))

static func _make_table_row(cols: Array[String], is_header: bool, rank_idx: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	if is_header:
		sb.bg_color = Color(0.16, 0.20, 0.33, 0.96)
		sb.border_color = Color(1.0, 0.78, 0.2, 0.75)
		sb.border_width_bottom = 2
	else:
		sb.bg_color = Color(0.09, 0.12, 0.20, 0.92) if rank_idx % 2 == 0 else Color(0.12, 0.16, 0.26, 0.92)
		sb.border_color = Color(0.22, 0.28, 0.42, 0.45)
		sb.border_width_bottom = 1
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8 if is_header else 6
	sb.content_margin_bottom = 8 if is_header else 6
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var widths := [52, 0, 74, 74, 80, 96]
	var rank_colors := [Color(1.0, 0.85, 0.25), Color(0.84, 0.88, 0.96), Color(0.90, 0.58, 0.32)]
	for i in range(cols.size()):
		var lbl := Label.new()
		lbl.text = cols[i]
		if widths[i] > 0:
			lbl.custom_minimum_size = Vector2(widths[i], 0)
		else:
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 1 else (HORIZONTAL_ALIGNMENT_CENTER if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
		lbl.add_theme_font_size_override("font_size", 15 if is_header else 16)
		if is_header:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28))
		elif rank_idx >= 0 and rank_idx < 3 and i <= 1:
			lbl.add_theme_color_override("font_color", rank_colors[rank_idx])
		else:
			lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
		hbox.add_child(lbl)
	return panel
