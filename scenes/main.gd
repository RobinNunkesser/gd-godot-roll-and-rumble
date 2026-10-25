class_name MainRollGame
extends Node3D

const RollConfig = preload("res://scripts/config.gd")
const RollStateManager = preload("res://scripts/state_manager.gd")
const PlayerBall = preload("res://scripts/player_ball.gd")
const MousetrapHazard = preload("res://scripts/mousetrap.gd")
const SharedArenaCamera = preload("res://scripts/shared_camera.gd")
const BaseArena = preload("res://scripts/arenas/base_arena.gd")
const ClassicRingArena = preload("res://scripts/arenas/classic_ring.gd")
const DizzySpinnerArena = preload("res://scripts/arenas/dizzy_spinner.gd")
const WobblySeesawArena = preload("res://scripts/arenas/wobbly_seesaw.gd")
const BumperPinballArena = preload("res://scripts/arenas/bumper_pinball.gd")
const IceSlickArena = preload("res://scripts/arenas/ice_slick.gd")
const RollSoundManager = preload("res://scripts/sound_manager.gd")
const RollImpactParticles = preload("res://scripts/impact_particles.gd")
const PowerUpSpawner = preload("res://scripts/powerup_spawner.gd")
const PowerUpToken = preload("res://scripts/powerup_token.gd")

var state_manager: RollStateManager
var current_arena: BaseArena
var selected_arena_type: BaseArena.ArenaType = BaseArena.ArenaType.CLASSIC_RING
var sound_manager: RollSoundManager
var impact_particles: RollImpactParticles
var powerup_spawner: PowerUpSpawner
var powerups_enabled: bool = true
var player1: PlayerBall
var player2: PlayerBall
var player3: PlayerBall
var player4: PlayerBall
var players: Array[PlayerBall] = []
var camera: SharedArenaCamera

var ui_lobby_panel: Control
var ui_arena_card: Panel
var ui_arena_title_label: Label
var ui_arena_desc_label: Label
var ui_powerup_card: Panel
var ui_powerup_label: Label
var ui_powerup_toggle_btn: Button
var ui_slot_labels: Array[Label] = []
var ui_timer_label: Label
var ui_score_labels: Dictionary = {}
var ui_status_label: Label
var ui_hud_container: Control

const SLOT_CONTROL_OPTIONS = [
	PlayerBall.ControlType.HUMAN_KB1,
	PlayerBall.ControlType.HUMAN_KB2,
	PlayerBall.ControlType.GAMEPAD_0,
	PlayerBall.ControlType.GAMEPAD_1,
	PlayerBall.ControlType.GAMEPAD_2,
	PlayerBall.ControlType.GAMEPAD_3,
	PlayerBall.ControlType.AI_BOT,
	PlayerBall.ControlType.OFF
]

func _ready() -> void:
	state_manager = RollStateManager.new()
	state_manager.state_changed.connect(_on_state_changed)
	state_manager.score_updated.connect(_on_score_updated)
	state_manager.timer_updated.connect(_on_timer_updated)
	state_manager.match_finished.connect(_on_match_finished)
	
	_build_scene()
	_build_ui()
	
	state_manager.enter_lobby(_get_active_player_ids())

func _build_scene() -> void:
	# 1. Umwelt, Skybox & Lighting (Global für alle Arenen)
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var skybox_path = "res://assets/textures/skybox_celestial.jpg"
	if ResourceLoader.exists(skybox_path):
		var pano_mat = PanoramaSkyMaterial.new()
		pano_mat.panorama = load(skybox_path)
		sky.sky_material = pano_mat
	else:
		var proc_sky = ProceduralSkyMaterial.new()
		proc_sky.sky_top_color = Color(0.2, 0.35, 0.6)
		proc_sky.sky_horizon_color = Color(0.65, 0.72, 0.82)
		proc_sky.ground_bottom_color = Color(0.12, 0.14, 0.18)
		proc_sky.ground_horizon_color = Color(0.35, 0.4, 0.48)
		sky.sky_material = proc_sky
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.15
	
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)
	
	var light = DirectionalLight3D.new()
	light.name = "SunLight"
	light.position = Vector3(10, 20, 10)
	light.rotation_degrees = Vector3(-50, 45, 0)
	light.shadow_enabled = true
	add_child(light)
	
	# 2. Audio & Visual Juice Systems
	sound_manager = RollSoundManager.new()
	add_child(sound_manager)
	
	impact_particles = RollImpactParticles.new()
	add_child(impact_particles)
	
	# 3. Phase 3: Power-Up Spawner
	powerup_spawner = PowerUpSpawner.new()
	powerup_spawner.name = "PowerUpSpawner"
	powerup_spawner.enabled = powerups_enabled
	add_child(powerup_spawner)
	
	# 4. 4 Spieler-Kugeln
	var p_configs = [
		{"id": 1, "name": "Player1_Red", "color": Color(0.95, 0.25, 0.25), "pos": Vector3(-5.0, RollConfig.BALL_RADIUS + 0.1, 0.0), "ctrl": PlayerBall.ControlType.HUMAN_KB1},
		{"id": 2, "name": "Player2_Blue", "color": Color(0.2, 0.55, 0.95), "pos": Vector3(5.0, RollConfig.BALL_RADIUS + 0.1, 0.0), "ctrl": PlayerBall.ControlType.AI_BOT},
		{"id": 3, "name": "Player3_Yellow", "color": Color(0.95, 0.85, 0.15), "pos": Vector3(0.0, RollConfig.BALL_RADIUS + 0.1, -5.0), "ctrl": PlayerBall.ControlType.OFF},
		{"id": 4, "name": "Player4_Green", "color": Color(0.25, 0.85, 0.35), "pos": Vector3(0.0, RollConfig.BALL_RADIUS + 0.1, 5.0), "ctrl": PlayerBall.ControlType.OFF}
	]
	
	players.clear()
	for cfg in p_configs:
		var p = PlayerBall.new()
		p.name = cfg["name"]
		p.player_id = cfg["id"]
		p.ball_color = cfg["color"]
		p.position = cfg["pos"]
		p.set_control_type(cfg["ctrl"])
		p.fell_off.connect(_on_player_fell_off)
		p.impact_occurred.connect(_on_ball_impact)
		p.boost_triggered.connect(_on_ball_boost)
		add_child(p)
		players.append(p)
	
	player1 = players[0]
	player2 = players[1]
	player3 = players[2]
	player4 = players[3]
	
	for p in players:
		p.potential_targets = players
	player1.target_opponent = player2
	player2.target_opponent = player1
	
	# 4. Shared Camera
	camera = SharedArenaCamera.new()
	camera.name = "SharedCamera"
	camera.position = Vector3(0, RollConfig.CAMERA_BASE_HEIGHT, RollConfig.CAMERA_MIN_DISTANCE)
	camera.target_nodes = players
	camera.current = true
	add_child(camera)
	
	# 5. Aktive Arena laden
	_load_arena(selected_arena_type)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "UI"
	
	# --- In-Game HUD ---
	ui_hud_container = Control.new()
	ui_hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui_hud_container)
	
	# Timer
	ui_timer_label = Label.new()
	ui_timer_label.text = "60.0"
	ui_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_timer_label.position = Vector2(540, 20)
	ui_timer_label.size = Vector2(200, 50)
	ui_timer_label.add_theme_font_size_override("font_size", 36)
	ui_hud_container.add_child(ui_timer_label)
	
	# Player Scores (P1 Red, P2 Blue, P3 Yellow, P4 Green)
	var score_positions = [
		Vector2(40, 20), Vector2(980, 20),
		Vector2(40, 60), Vector2(980, 60)
	]
	var p_names = ["P1 (Red)", "P2 (Blue)", "P3 (Yellow)", "P4 (Green)"]
	var p_colors = [Color(1.0, 0.3, 0.3), Color(0.3, 0.6, 1.0), Color(0.95, 0.85, 0.2), Color(0.3, 0.9, 0.4)]
	
	ui_score_labels.clear()
	for i in range(4):
		var lbl = Label.new()
		lbl.text = "%s: 0" % p_names[i]
		lbl.position = score_positions[i]
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", p_colors[i])
		ui_hud_container.add_child(lbl)
		ui_score_labels[i + 1] = lbl
	
	# Status / Countdown Banner
	ui_status_label = Label.new()
	ui_status_label.text = "READY..."
	ui_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_status_label.position = Vector2(340, 280)
	ui_status_label.size = Vector2(600, 100)
	ui_status_label.add_theme_font_size_override("font_size", 48)
	ui_hud_container.add_child(ui_status_label)
	
	var in_game_hint = Label.new()
	in_game_hint.text = "[R]: Neustart  |  [ESC]: Zurück zur Lobby  |  [B]: P2 Bot Toggle"
	in_game_hint.position = Vector2(40, 670)
	in_game_hint.add_theme_font_size_override("font_size", 16)
	in_game_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.75))
	ui_hud_container.add_child(in_game_hint)
	
	# --- Pre-Match Lobby Panel ---
	ui_lobby_panel = Control.new()
	ui_lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.05, 0.08, 0.14, 0.88)
	ui_lobby_panel.add_child(bg_overlay)
	
	var title = Label.new()
	title.text = "ROLL & RUMBLE 3D — LOBBY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(240, 40)
	title.size = Vector2(800, 60)
	title.add_theme_font_size_override("font_size", 40)
	ui_lobby_panel.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Slots: [1]-[4]  |  Arena wechseln: [T]/[A]  |  [P] Power-Ups: AN/AUS  |  Start mit [SPACE / ENTER]"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(140, 100)
	subtitle.size = Vector2(1000, 30)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	ui_lobby_panel.add_child(subtitle)
	
	ui_slot_labels.clear()
	var col_width = 260
	var start_x = 80
	for i in range(4):
		var card = Panel.new()
		card.position = Vector2(start_x + i * (col_width + 20), 150)
		card.size = Vector2(col_width, 340)
		ui_lobby_panel.add_child(card)
		
		var p_title = Label.new()
		p_title.text = p_names[i]
		p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p_title.position = Vector2(10, 15)
		p_title.size = Vector2(col_width - 20, 35)
		p_title.add_theme_font_size_override("font_size", 24)
		p_title.add_theme_color_override("font_color", p_colors[i])
		card.add_child(p_title)
		
		var slot_lbl = Label.new()
		slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_lbl.position = Vector2(10, 80)
		slot_lbl.size = Vector2(col_width - 20, 140)
		slot_lbl.add_theme_font_size_override("font_size", 22)
		slot_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		card.add_child(slot_lbl)
		ui_slot_labels.append(slot_lbl)
		
		var key_hint = Label.new()
		key_hint.text = "Taste [%d] drücken\nzum Wechseln" % (i + 1)
		key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_hint.position = Vector2(10, 260)
		key_hint.size = Vector2(col_width - 20, 60)
		key_hint.add_theme_font_size_override("font_size", 16)
		key_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		card.add_child(key_hint)
	
	# Power-Up Toggle Bar in Lobby (Option A: Deaktivierbar im Hauptmenü)
	ui_powerup_card = Panel.new()
	ui_powerup_card.position = Vector2(80, 505)
	ui_powerup_card.size = Vector2(1100, 50)
	ui_lobby_panel.add_child(ui_powerup_card)
	
	ui_powerup_label = Label.new()
	ui_powerup_label.position = Vector2(20, 10)
	ui_powerup_label.size = Vector2(780, 30)
	ui_powerup_label.add_theme_font_size_override("font_size", 18)
	ui_powerup_card.add_child(ui_powerup_label)
	
	ui_powerup_toggle_btn = Button.new()
	ui_powerup_toggle_btn.position = Vector2(820, 7)
	ui_powerup_toggle_btn.size = Vector2(260, 36)
	ui_powerup_toggle_btn.add_theme_font_size_override("font_size", 16)
	ui_powerup_toggle_btn.pressed.connect(toggle_powerups)
	ui_powerup_card.add_child(ui_powerup_toggle_btn)
	
	# Arena Selection Card in Lobby
	ui_arena_card = Panel.new()
	ui_arena_card.position = Vector2(80, 565)
	ui_arena_card.size = Vector2(1100, 95)
	ui_lobby_panel.add_child(ui_arena_card)
	
	ui_arena_title_label = Label.new()
	ui_arena_title_label.position = Vector2(20, 10)
	ui_arena_title_label.size = Vector2(1060, 32)
	ui_arena_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_arena_title_label.add_theme_font_size_override("font_size", 22)
	ui_arena_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	ui_arena_card.add_child(ui_arena_title_label)
	
	ui_arena_desc_label = Label.new()
	ui_arena_desc_label.position = Vector2(20, 48)
	ui_arena_desc_label.size = Vector2(1060, 38)
	ui_arena_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_arena_desc_label.add_theme_font_size_override("font_size", 16)
	ui_arena_desc_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	ui_arena_card.add_child(ui_arena_desc_label)
	
	_update_lobby_ui()
	_update_arena_ui()
	_update_powerup_ui()
	canvas.add_child(ui_lobby_panel)
	add_child(canvas)

func _update_lobby_ui() -> void:
	for i in range(players.size()):
		var p = players[i]
		var txt = _get_control_type_name(p.control_type)
		ui_slot_labels[i].text = txt
		
		# Score Label Sichtbarkeit
		if ui_score_labels.has(p.player_id):
			ui_score_labels[p.player_id].visible = (p.control_type != PlayerBall.ControlType.OFF)

func _get_control_type_name(ct: PlayerBall.ControlType) -> String:
	match ct:
		PlayerBall.ControlType.OFF:
			return "[ INAKTIV ]\n(OFF)"
		PlayerBall.ControlType.HUMAN_KB1:
			return "SPIELER\n(Tastatur 1: WASD + Space)"
		PlayerBall.ControlType.HUMAN_KB2:
			return "SPIELER\n(Tastatur 2: Pfeile + Enter)"
		PlayerBall.ControlType.GAMEPAD_0:
			return "SPIELER\n(Gamepad 1: Stick + A)"
		PlayerBall.ControlType.GAMEPAD_1:
			return "SPIELER\n(Gamepad 2: Stick + A)"
		PlayerBall.ControlType.GAMEPAD_2:
			return "SPIELER\n(Gamepad 3: Stick + A)"
		PlayerBall.ControlType.GAMEPAD_3:
			return "SPIELER\n(Gamepad 4: Stick + A)"
		PlayerBall.ControlType.AI_BOT:
			return "KI-BOT\n(Autonomes Steering)"
	return "UNKNOWN"

func cycle_player_slot(index: int) -> void:
	if index < 0 or index >= players.size():
		return
	var p = players[index]
	var cur_idx = SLOT_CONTROL_OPTIONS.find(p.control_type)
	var next_idx = (cur_idx + 1) % SLOT_CONTROL_OPTIONS.size()
	p.set_control_type(SLOT_CONTROL_OPTIONS[next_idx])
	_update_lobby_ui()

func toggle_p2_bot() -> void:
	if player2:
		if player2.control_type == PlayerBall.ControlType.AI_BOT:
			player2.set_control_type(PlayerBall.ControlType.HUMAN_KB2)
		else:
			player2.set_control_type(PlayerBall.ControlType.AI_BOT)
		_update_lobby_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state_manager.current_state == RollStateManager.MatchState.LOBBY:
			if event.keycode == KEY_1:
				cycle_player_slot(0)
			elif event.keycode == KEY_2:
				cycle_player_slot(1)
			elif event.keycode == KEY_3:
				cycle_player_slot(2)
			elif event.keycode == KEY_4:
				cycle_player_slot(3)
			elif event.keycode == KEY_T or event.keycode == KEY_A or event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
				cycle_arena()
			elif event.keycode == KEY_P:
				toggle_powerups()
			elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				start_match_from_lobby()
		else:
			if event.keycode == KEY_ESCAPE:
				return_to_lobby()
			elif event.keycode == KEY_B:
				toggle_p2_bot()

func cycle_arena() -> void:
	var total_types = BaseArena.ArenaType.values().size()
	selected_arena_type = ((int(selected_arena_type) + 1) % total_types) as BaseArena.ArenaType
	_load_arena(selected_arena_type)
	_update_arena_ui()

func _load_arena(type: BaseArena.ArenaType) -> void:
	if current_arena:
		current_arena.queue_free()
		remove_child(current_arena)
		current_arena = null
	
	match type:
		BaseArena.ArenaType.CLASSIC_RING:
			current_arena = ClassicRingArena.new()
		BaseArena.ArenaType.DIZZY_SPINNER:
			current_arena = DizzySpinnerArena.new()
		BaseArena.ArenaType.WOBBLY_SEESAW:
			current_arena = WobblySeesawArena.new()
		BaseArena.ArenaType.BUMPER_PINBALL:
			current_arena = BumperPinballArena.new()
		BaseArena.ArenaType.ICE_SLICK:
			current_arena = IceSlickArena.new()
		_:
			current_arena = ClassicRingArena.new()
	
	current_arena.name = "ActiveArena"
	add_child(current_arena)
	
	# Juiciness: Fallen-Auslösung erzeugt Kamera-Trauma
	if "traps" in current_arena:
		for trap in current_arena.traps:
			if is_instance_valid(trap) and trap.has_signal("triggered"):
				trap.triggered.connect(_on_trap_triggered)
	
	# Juiciness: Flipper-Bumper-Impulse
	if "bumpers" in current_arena:
		for b in current_arena.bumpers:
			if is_instance_valid(b) and b.has_signal("bumper_hit"):
				b.bumper_hit.connect(_on_bumper_hit)
	
	# Spawn-Punkte für Spieler aktualisieren
	var spawn_spots = current_arena.get_spawn_positions(players.size())
	for i in range(players.size()):
		if i < spawn_spots.size():
			players[i].initial_spawn_point = spawn_spots[i]
			if state_manager.current_state == RollStateManager.MatchState.LOBBY:
				players[i].respawn(spawn_spots[i])
				players[i].freeze = true

func _update_arena_ui() -> void:
	if current_arena and ui_arena_title_label and ui_arena_desc_label:
		ui_arena_title_label.text = "★ ARENA: ◄ %s ► ★   [Taste T oder A zum Wechseln]" % current_arena.arena_name
		ui_arena_desc_label.text = current_arena.arena_description

func start_match_from_lobby() -> void:
	var active_ids = _get_active_player_ids()
	if active_ids.size() < 2:
		ui_status_label.text = "Mindestens 2 Spieler erforderlich!"
		return
	
	ui_lobby_panel.visible = false
	ui_hud_container.visible = true
	
	if current_arena:
		current_arena.reset_arena()
	
	var spawn_spots = current_arena.get_spawn_positions(players.size()) if current_arena else []
	for i in range(players.size()):
		var p = players[i]
		if p.control_type != PlayerBall.ControlType.OFF:
			var spot = spawn_spots[i] if i < spawn_spots.size() else p.initial_spawn_point
			p.respawn(spot)
			p.freeze = true
	
	state_manager.start_match(active_ids)

func return_to_lobby() -> void:
	for p in players:
		p.freeze = true
	state_manager.enter_lobby(_get_active_player_ids())
	ui_lobby_panel.visible = true
	_update_lobby_ui()
	_update_arena_ui()

func restart_game() -> void:
	if current_arena:
		current_arena.reset_arena()
	var spawn_spots = current_arena.get_spawn_positions(players.size()) if current_arena else []
	for i in range(players.size()):
		var p = players[i]
		if p.control_type != PlayerBall.ControlType.OFF:
			var spot = spawn_spots[i] if i < spawn_spots.size() else p.initial_spawn_point
			p.respawn(spot)
			p.freeze = true
	state_manager.reset_match()

func _get_active_player_ids() -> Array:
	var ids: Array = []
	for p in players:
		if p.control_type != PlayerBall.ControlType.OFF:
			ids.append(p.player_id)
	return ids

func _process(delta: float) -> void:
	if state_manager:
		state_manager.update_logic(delta)
	
	if current_arena:
		current_arena.update_arena(delta, players)
	
	if state_manager.current_state == RollStateManager.MatchState.WARMUP:
		var sec = int(ceil(state_manager.warmup_timer))
		if sec > 0:
			ui_status_label.text = str(sec)
		else:
			ui_status_label.text = "RUMBLE!"
	
	if Input.is_action_just_pressed("restart") and state_manager.current_state != RollStateManager.MatchState.LOBBY:
		restart_game()

func _on_player_fell_off(victim_id: int, kicker_id: int) -> void:
	if sound_manager:
		sound_manager.play_fall()
	state_manager.record_player_fall(victim_id, kicker_id)

func _on_state_changed(new_state: RollStateManager.MatchState) -> void:
	if not ui_status_label:
		return
	match new_state:
		RollStateManager.MatchState.LOBBY:
			ui_status_label.visible = false
			if powerup_spawner:
				powerup_spawner.clear_tokens()
				powerup_spawner.enabled = false
			for p in players:
				p.freeze = true
				p.clear_powerup()
		RollStateManager.MatchState.WARMUP:
			ui_status_label.visible = true
			ui_status_label.text = "3"
			if powerup_spawner:
				powerup_spawner.clear_tokens()
				powerup_spawner.enabled = false
			for p in players:
				if p.control_type != PlayerBall.ControlType.OFF:
					p.freeze = true
				p.clear_powerup()
		RollStateManager.MatchState.PLAYING:
			ui_status_label.visible = false
			if powerup_spawner:
				powerup_spawner.enabled = powerups_enabled
				powerup_spawner.reset_timer()
			# Unfreeze all active players!
			for p in players:
				if p.control_type != PlayerBall.ControlType.OFF:
					p.freeze = false
		RollStateManager.MatchState.SUDDEN_DEATH:
			ui_status_label.visible = true
			ui_status_label.text = "🔥 SUDDEN DEATH! 🔥"
		RollStateManager.MatchState.MATCH_OVER:
			ui_status_label.visible = true
			if powerup_spawner:
				powerup_spawner.clear_tokens()
				powerup_spawner.enabled = false
			for p in players:
				p.clear_powerup()
			var w = state_manager.get_winner()
			if w > 0:
				ui_status_label.text = "🏆 PLAYER %d WINS! 🏆" % w
			else:
				ui_status_label.text = "DRAW! Press [R] to rematch"

func _on_score_updated(player_id: int, new_score: int) -> void:
	if ui_score_labels.has(player_id):
		var p_name = "P%d" % player_id
		if player_id <= players.size():
			var p = players[player_id - 1]
			var mode_tag = "AI" if p.is_bot else "Human"
			ui_score_labels[player_id].text = "%s (%s): %d" % [p_name, mode_tag, new_score]
		else:
			ui_score_labels[player_id].text = "%s: %d" % [p_name, new_score]

func _on_timer_updated(time_remaining: float) -> void:
	if ui_timer_label:
		ui_timer_label.text = "%.1f" % time_remaining

func _on_match_finished(_winner_id: int) -> void:
	pass

func _on_ball_impact(force: float, pos: Vector3) -> void:
	if camera:
		camera.add_trauma(clampf(force * 0.04, 0.1, 0.55))
	if sound_manager:
		sound_manager.play_impact(force)
	if impact_particles:
		impact_particles.spawn_sparks(pos, force)

func _on_ball_boost(pos: Vector3, dir: Vector3) -> void:
	if sound_manager:
		sound_manager.play_boost()
	if impact_particles:
		impact_particles.spawn_boost_burst(pos, dir)

func _on_trap_triggered(victim: PlayerBall) -> void:
	if camera:
		camera.add_trauma(0.5)
	if sound_manager:
		sound_manager.play_trap_snap()
	if impact_particles and is_instance_valid(victim):
		var vpos = victim.global_position if victim.is_inside_tree() else victim.position
		impact_particles.spawn_sparks(vpos, 8.0)

func _on_bumper_hit(_ball: PlayerBall, hit_pos: Vector3) -> void:
	if camera:
		camera.add_trauma(0.35)
	if sound_manager:
		sound_manager.play_impact(8.5)
	if impact_particles:
		impact_particles.spawn_sparks(hit_pos, 7.0)

func toggle_powerups() -> void:
	powerups_enabled = !powerups_enabled
	if powerup_spawner:
		powerup_spawner.enabled = powerups_enabled
	_update_powerup_ui()

func _update_powerup_ui() -> void:
	if not ui_powerup_label or not ui_powerup_toggle_btn:
		return
	if powerups_enabled:
		ui_powerup_label.text = "⚡ POWER-UPS: AKTIV (6 Archetypen: Amboss, Stachel, Nitro, Geist, Eis, Magnet)"
		ui_powerup_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
		ui_powerup_toggle_btn.text = "DEAKTIVIEREN [P]"
	else:
		ui_powerup_label.text = "🚫 POWER-UPS: DEAKTIVIERT (Klassisches pures Sumo-Rumble)"
		ui_powerup_label.add_theme_color_override("font_color", Color(0.9, 0.45, 0.45))
		ui_powerup_toggle_btn.text = "AKTIVIEREN [P]"





