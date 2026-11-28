class_name MainRollGame
extends Node3D

const RollConfig = preload("res://scripts/config.gd")
const RollStateManager = preload("res://scripts/state_manager.gd")
const PlayerBall = preload("res://scripts/player_ball.gd")
const MousetrapHazard = preload("res://scripts/mousetrap.gd")
const SharedArenaCamera = preload("res://scripts/shared_camera.gd")
const BaseArena = preload("res://scripts/arenas/base_arena.gd")
const PureRingArena = preload("res://scripts/arenas/pure_ring.gd")
const ClassicRingArena = preload("res://scripts/arenas/classic_ring.gd")
const DizzySpinnerArena = preload("res://scripts/arenas/dizzy_spinner.gd")
const WobblySeesawArena = preload("res://scripts/arenas/wobbly_seesaw.gd")
const BumperPinballArena = preload("res://scripts/arenas/bumper_pinball.gd")
const IceSlickArena = preload("res://scripts/arenas/ice_slick.gd")
const RollSoundManager = preload("res://scripts/sound_manager.gd")
const RollImpactParticles = preload("res://scripts/impact_particles.gd")
const PowerUpSpawner = preload("res://scripts/powerup_spawner.gd")
const PowerUpToken = preload("res://scripts/powerup_token.gd")
const LeaderboardManager = preload("res://scripts/leaderboard_manager.gd")
const Trophy3D = preload("res://scripts/trophy_3d.gd")
const ArcadeNav = preload("res://addons/arcade_ui/arcade_nav.gd")
const ArcadeTheme = preload("res://addons/arcade_ui/arcade_theme.gd")
const ArcadePauseOverlay = preload("res://addons/arcade_ui/arcade_pause_overlay.gd")
const ArcadeTouchOverlay = preload("res://addons/arcade_ui/arcade_touch_overlay.gd")
const ArcadePlayerCard = preload("res://addons/arcade_ui/arcade_player_card.gd")
const ArcadeMenuShell = preload("res://addons/arcade_ui/arcade_menu_shell.gd")
const ArcadeDefaults = preload("res://addons/arcade_ui/arcade_defaults.gd")
const ArcadeMatchOverOverlay = preload("res://addons/arcade_ui/arcade_match_over_overlay.gd")
const ArcadeLeaderboard = preload("res://addons/arcade_ui/arcade_leaderboard.gd")
const ArcadeNameModal = preload("res://addons/arcade_ui/arcade_name_modal.gd")

var state_manager: RollStateManager
var leaderboard: LeaderboardManager
var current_arena: BaseArena
var selected_arena_type: BaseArena.ArenaType = BaseArena.ArenaType.PURE_RING
var sound_manager: RollSoundManager
var impact_particles: RollImpactParticles
var powerup_spawner: PowerUpSpawner
var active_trophy: Trophy3D
var powerups_enabled: bool = true

var player1: PlayerBall
var player2: PlayerBall
var player3: PlayerBall
var player4: PlayerBall
var players: Array[PlayerBall] = []
var camera: SharedArenaCamera

var ui_lobby_panel: Control
var ui_pause_overlay: ArcadePauseOverlay
var ui_match_over_overlay: ArcadeMatchOverOverlay
var ui_touch_overlay: ArcadeTouchOverlay
var ui_slot_btns: Array[Button] = []
var ui_slot_cards: Array[ArcadePlayerCard] = []
var player_names: Array[String] = ["P1", "P2", "P3", "P4"]
var couch_lb: ArcadeLeaderboard
var ui_name_modal: ArcadeNameModal
var ui_lb_table_lbl: Label
var ui_arena_btn: Button
var ui_lobby_start_btn: Button
var ui_arena_card: Panel
var ui_arena_title_label: Label
var ui_arena_desc_label: Label

var ui_options_card: Panel
var ui_mode_label: Label
var ui_mode_toggle_btn: Button
var ui_powerup_label: Label
var ui_powerup_toggle_btn: Button
var ui_leaderboard_btn: Button

var ui_leaderboard_modal: Control
var ui_leaderboard_content_label: Label
var ui_leaderboard_close_btn: Button
var ui_leaderboard_reset_btn: Button

var ui_slot_labels: Array[Label] = []
var ui_timer_label: Label
var ui_series_label: Label
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
	leaderboard = LeaderboardManager.new()
	
	state_manager = RollStateManager.new()
	state_manager.state_changed.connect(_on_state_changed)
	state_manager.score_updated.connect(_on_score_updated)
	state_manager.timer_updated.connect(_on_timer_updated)
	state_manager.series_score_updated.connect(_on_series_score_updated)
	state_manager.round_finished.connect(_on_round_finished)
	state_manager.tournament_finished.connect(_on_tournament_finished)
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
	
	# 4. 4 Spieler-Kugeln mit smarten Gamepad-Auto-Defaults
	var slot_defaults := ArcadeDefaults.detect_slot_modes(4)
	var p1_ctrl: PlayerBall.ControlType = (PlayerBall.ControlType.GAMEPAD_0 + slot_defaults[0]["device"]) as PlayerBall.ControlType if slot_defaults[0]["kind"] == "gamepad" else PlayerBall.ControlType.HUMAN_KB1
	var p2_ctrl: PlayerBall.ControlType = (PlayerBall.ControlType.GAMEPAD_0 + slot_defaults[1]["device"]) as PlayerBall.ControlType if slot_defaults[1]["kind"] == "gamepad" else PlayerBall.ControlType.AI_BOT
	var p3_ctrl: PlayerBall.ControlType = (PlayerBall.ControlType.GAMEPAD_0 + slot_defaults[2]["device"]) as PlayerBall.ControlType if slot_defaults[2]["kind"] == "gamepad" else PlayerBall.ControlType.OFF
	var p4_ctrl: PlayerBall.ControlType = (PlayerBall.ControlType.GAMEPAD_0 + slot_defaults[3]["device"]) as PlayerBall.ControlType if slot_defaults[3]["kind"] == "gamepad" else PlayerBall.ControlType.OFF
	var p_configs = [
		{"id": 1, "name": "Player1_Red", "color": Color(0.95, 0.25, 0.25), "pos": Vector3(-5.0, RollConfig.BALL_RADIUS + 0.1, 0.0), "ctrl": p1_ctrl},
		{"id": 2, "name": "Player2_Blue", "color": Color(0.2, 0.55, 0.95), "pos": Vector3(5.0, RollConfig.BALL_RADIUS + 0.1, 0.0), "ctrl": p2_ctrl},
		{"id": 3, "name": "Player3_Yellow", "color": Color(0.95, 0.85, 0.15), "pos": Vector3(0.0, RollConfig.BALL_RADIUS + 0.1, -5.0), "ctrl": p3_ctrl},
		{"id": 4, "name": "Player4_Green", "color": Color(0.25, 0.85, 0.35), "pos": Vector3(0.0, RollConfig.BALL_RADIUS + 0.1, 5.0), "ctrl": p4_ctrl}
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
	
	# 5. Shared Camera
	camera = SharedArenaCamera.new()
	camera.name = "SharedCamera"
	camera.position = Vector3(0, RollConfig.CAMERA_BASE_HEIGHT, RollConfig.CAMERA_MIN_DISTANCE)
	camera.target_nodes = players
	camera.current = true
	add_child(camera)
	
	# 6. Aktive Arena laden
	_load_arena(selected_arena_type)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "UI"
	
	# --- In-Game HUD ---
	ui_hud_container = Control.new()
	ui_hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui_hud_container)
	
	# Tournament Series Tracker Banner oben
	ui_series_label = Label.new()
	ui_series_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_series_label.position = Vector2(240, 6)
	ui_series_label.size = Vector2(800, 26)
	ui_series_label.add_theme_font_size_override("font_size", 18)
	ui_series_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	ui_hud_container.add_child(ui_series_label)
	
	# Timer
	ui_timer_label = Label.new()
	ui_timer_label.text = "60.0"
	ui_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_timer_label.position = Vector2(540, 32)
	ui_timer_label.size = Vector2(200, 48)
	ui_timer_label.add_theme_font_size_override("font_size", 34)
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
	
	# Status / Countdown / Winner Banner
	ui_status_label = Label.new()
	ui_status_label.text = "READY..."
	ui_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_status_label.position = Vector2(200, 240)
	ui_status_label.size = Vector2(880, 160)
	ui_status_label.add_theme_font_size_override("font_size", 42)
	ui_hud_container.add_child(ui_status_label)
	
	var in_game_hint = Label.new()
	in_game_hint.text = "[R]: Neustart  |  [ESC]: Zurück zur Lobby  |  [B]: P2 Bot Toggle"
	in_game_hint.position = Vector2(40, 670)
	in_game_hint.add_theme_font_size_override("font_size", 16)
	in_game_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.75))
	ui_hud_container.add_child(in_game_hint)
	
	# --- Pre-Match Hauptmenü (ClanBomber-Stil via ArcadeMenuShell) ---
	var shell := ArcadeMenuShell.new("ROLL & RUMBLE 3D")
	shell.auto_lobby_music = false
	shell.apply_theme_preset(ArcadeTheme.Preset.RETRO_GOLD)
	shell.start_requested.connect(start_match_from_lobby)
	shell.master_volume_changed.connect(func(v: float) -> void:
		if sound_manager:
			sound_manager.set_master_volume(v)
	)
	shell.music_volume_changed.connect(func(v: float) -> void:
		if sound_manager:
			sound_manager.set_music_volume(v)
	)
	shell.sfx_volume_changed.connect(func(v: float) -> void:
		if sound_manager:
			sound_manager.set_sfx_volume(v)
	)
	shell.touch_toggled.connect(func() -> void:
		if ui_touch_overlay:
			ui_touch_overlay.toggle_touch_overlay()
	)
	ui_lobby_panel = shell

	# Subpage: PLAYERS
	couch_lb = ArcadeLeaderboard.new("roll_and_rumble")
	ui_slot_labels.clear()
	ui_slot_btns.clear()
	ui_slot_cards.clear()
	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 16)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.players_box.add_child(cards_row)
	for i in range(4):
		var card := ArcadePlayerCard.new(i, p_colors[i], false)
		card.custom_minimum_size = Vector2(205, 310)
		card.control_cycled.connect(cycle_player_slot)
		card.name_clicked.connect(_on_slot_name_clicked)
		cards_row.add_child(card)
		card.set_title(p_names[i], p_colors[i])
		card.set_player_name(player_names[i])
		ui_slot_cards.append(card)
		ui_slot_labels.append(card.status_label)
		card.ctrl_btn.text = "STEUERUNG"
		ui_slot_btns.append(card.ctrl_btn)

	var detect_btn := Button.new()
	detect_btn.text = "🎮 CONTROLLER ERKENNEN"
	detect_btn.custom_minimum_size = Vector2(320, 42)
	detect_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detect_btn.pressed.connect(_apply_auto_defaults)
	shell.players_box.add_child(detect_btn)

	# Subpage: ARENA
	ui_arena_title_label = Label.new()
	ui_arena_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_arena_title_label.add_theme_font_size_override("font_size", 26)
	ui_arena_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	shell.arena_box.add_child(ui_arena_title_label)

	ui_arena_desc_label = Label.new()
	ui_arena_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_arena_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui_arena_desc_label.add_theme_font_size_override("font_size", 17)
	ui_arena_desc_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	shell.arena_box.add_child(ui_arena_desc_label)

	ui_arena_btn = Button.new()
	ui_arena_btn.text = "ARENA WECHSELN"
	ui_arena_btn.custom_minimum_size = Vector2(320, 48)
	ui_arena_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui_arena_btn.pressed.connect(cycle_arena)
	shell.arena_box.add_child(ui_arena_btn)
	shell.wire_subpage_focus(ArcadeMenuShell.Page.ARENA, [ui_arena_btn])

	# Subpage: MATCH & REGELN
	ui_mode_label = Label.new()
	ui_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_mode_label.add_theme_font_size_override("font_size", 20)
	shell.match_box.add_child(ui_mode_label)

	ui_mode_toggle_btn = Button.new()
	ui_mode_toggle_btn.text = "MODUS WECHSELN"
	ui_mode_toggle_btn.custom_minimum_size = Vector2(320, 46)
	ui_mode_toggle_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui_mode_toggle_btn.pressed.connect(cycle_match_mode)
	shell.match_box.add_child(ui_mode_toggle_btn)

	ui_powerup_label = Label.new()
	ui_powerup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_powerup_label.add_theme_font_size_override("font_size", 20)
	shell.match_box.add_child(ui_powerup_label)

	ui_powerup_toggle_btn = Button.new()
	ui_powerup_toggle_btn.custom_minimum_size = Vector2(320, 46)
	ui_powerup_toggle_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui_powerup_toggle_btn.pressed.connect(toggle_powerups)
	shell.match_box.add_child(ui_powerup_toggle_btn)
	shell.wire_subpage_focus(ArcadeMenuShell.Page.MATCH, [ui_mode_toggle_btn, ui_powerup_toggle_btn])

	# Subpage: EXTRA (Bestenliste)
	shell.enable_extra_page("BESTENLISTE")
	var lb_scroll := ScrollContainer.new()
	lb_scroll.custom_minimum_size = Vector2(680, 220)
	lb_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lb_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.extra_box.add_child(lb_scroll)
	var lb_box := VBoxContainer.new()
	lb_box.name = "LbBox"
	lb_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lb_box.add_theme_constant_override("separation", 6)
	lb_scroll.add_child(lb_box)
	couch_lb.populate_view(lb_box, "KOs")

	var lb_row := HBoxContainer.new()
	lb_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lb_row.add_theme_constant_override("separation", 12)
	shell.extra_box.add_child(lb_row)

	ui_leaderboard_btn = Button.new()
	ui_leaderboard_btn.text = "DETAIL-STATISTIK"
	ui_leaderboard_btn.custom_minimum_size = Vector2(220, 42)
	ui_leaderboard_btn.pressed.connect(func() -> void: toggle_leaderboard(true))
	lb_row.add_child(ui_leaderboard_btn)

	var lb_reset_btn := Button.new()
	lb_reset_btn.text = "ZURÜCKSETZEN"
	lb_reset_btn.custom_minimum_size = Vector2(220, 42)
	lb_reset_btn.pressed.connect(func() -> void:
		couch_lb.reset_all()
		couch_lb.populate_view(lb_box, "KOs")
	)
	lb_row.add_child(lb_reset_btn)
	ArcadeNav.wire_row_focus([ui_leaderboard_btn, lb_reset_btn], true)
	shell.wire_subpage_focus(ArcadeMenuShell.Page.EXTRA, [ui_leaderboard_btn])

	canvas.add_child(ui_lobby_panel)
	call_deferred("_setup_lobby_focus")

	ui_pause_overlay = ArcadePauseOverlay.new()
	ui_pause_overlay.restarted.connect(func() -> void:
		if state_manager:
			state_manager.reset_match()
	)
	ui_pause_overlay.returned_to_lobby.connect(return_to_lobby)
	ui_pause_overlay.master_volume_changed.connect(func(v: float) -> void:
		if sound_manager:
			sound_manager.set_master_volume(v)
	)
	ui_pause_overlay.music_volume_changed.connect(func(v: float) -> void:
		if sound_manager:
			sound_manager.set_music_volume(v)
	)
	ui_pause_overlay.sfx_volume_changed.connect(func(v: float) -> void:
		if sound_manager:
			sound_manager.set_sfx_volume(v)
	)
	canvas.add_child(ui_pause_overlay)

	ui_match_over_overlay = ArcadeMatchOverOverlay.new()
	ui_match_over_overlay.rematch_pressed.connect(func() -> void:
		_clear_trophy()
		if state_manager:
			state_manager.start_series(_get_active_player_ids())
	)
	ui_match_over_overlay.lobby_pressed.connect(return_to_lobby)
	canvas.add_child(ui_match_over_overlay)

	ui_name_modal = ArcadeNameModal.new()
	ui_name_modal.name_confirmed.connect(func(slot_idx: int, new_name: String) -> void:
		player_names[slot_idx] = new_name
		if slot_idx < ui_slot_cards.size():
			ui_slot_cards[slot_idx].set_player_name(new_name)
		if couch_lb:
			couch_lb.add_recent_name(new_name)
	)
	canvas.add_child(ui_name_modal)

	ui_touch_overlay = ArcadeTouchOverlay.new()
	ui_touch_overlay.primary_label = "BOOST"
	ui_touch_overlay.pause_pressed.connect(func() -> void:
		if ui_pause_overlay:
			ui_pause_overlay.open()
	)
	ui_touch_overlay.primary_pressed.connect(func() -> void:
		if player1:
			player1.external_boost_pressed = true
	)
	add_child(ui_touch_overlay)
	ui_pause_overlay.set_touch_mode(ui_touch_overlay.is_touch_active)
	
	# --- Modale Bestenliste (Overlay) ---
	ui_leaderboard_modal = Control.new()
	ui_leaderboard_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_leaderboard_modal.visible = false
	
	var lb_bg = ColorRect.new()
	lb_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	lb_bg.color = Color(0.04, 0.06, 0.1, 0.94)
	ui_leaderboard_modal.add_child(lb_bg)
	
	var lb_panel = Panel.new()
	lb_panel.position = Vector2(140, 60)
	lb_panel.size = Vector2(1000, 600)
	ui_leaderboard_modal.add_child(lb_panel)
	
	var lb_title = Label.new()
	lb_title.text = "🏆 ROLL & RUMBLE 3D — EWIGE BESTENLISTE 🏆"
	lb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb_title.position = Vector2(20, 20)
	lb_title.size = Vector2(960, 45)
	lb_title.add_theme_font_size_override("font_size", 28)
	lb_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lb_panel.add_child(lb_title)
	
	ui_leaderboard_content_label = Label.new()
	ui_leaderboard_content_label.position = Vector2(40, 80)
	ui_leaderboard_content_label.size = Vector2(920, 420)
	ui_leaderboard_content_label.add_theme_font_size_override("font_size", 18)
	ui_leaderboard_content_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	lb_panel.add_child(ui_leaderboard_content_label)
	
	ui_leaderboard_close_btn = Button.new()
	ui_leaderboard_close_btn.position = Vector2(620, 520)
	ui_leaderboard_close_btn.size = Vector2(340, 48)
	ui_leaderboard_close_btn.text = "SCHLIESSEN"
	ui_leaderboard_close_btn.add_theme_font_size_override("font_size", 18)
	ui_leaderboard_close_btn.pressed.connect(func(): toggle_leaderboard(false))
	lb_panel.add_child(ui_leaderboard_close_btn)
	
	ui_leaderboard_reset_btn = Button.new()
	ui_leaderboard_reset_btn.position = Vector2(40, 520)
	ui_leaderboard_reset_btn.size = Vector2(260, 48)
	ui_leaderboard_reset_btn.text = "Statistiken zurücksetzen"
	ui_leaderboard_reset_btn.add_theme_font_size_override("font_size", 16)
	ui_leaderboard_reset_btn.pressed.connect(_on_leaderboard_reset_pressed)
	lb_panel.add_child(ui_leaderboard_reset_btn)
	
	canvas.add_child(ui_leaderboard_modal)
	add_child(canvas)
	
	_update_lobby_ui()
	_update_menu_summary()
	_update_arena_ui()
	_update_menu_summary()
	_update_powerup_ui()
	_update_mode_ui()
	_update_menu_summary()

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
	_update_menu_summary()

func toggle_p2_bot() -> void:
	if player2:
		if player2.control_type == PlayerBall.ControlType.AI_BOT:
			player2.set_control_type(PlayerBall.ControlType.HUMAN_KB2)
		else:
			player2.set_control_type(PlayerBall.ControlType.AI_BOT)
		_update_lobby_ui()
	_update_menu_summary()

func _on_slot_name_clicked(slot_idx: int) -> void:
	if ui_name_modal:
		var rec: Array = couch_lb.data.get("recent_names", []) if couch_lb else []
		ui_name_modal.open(slot_idx, player_names[slot_idx], rec)

func _apply_auto_defaults() -> void:
	var slot_defaults := ArcadeDefaults.detect_slot_modes(4)
	for i in range(4):
		if slot_defaults[i]["kind"] == "gamepad":
			players[i].set_control_type((PlayerBall.ControlType.GAMEPAD_0 + slot_defaults[i]["device"]) as PlayerBall.ControlType)
		elif i == 0:
			players[i].set_control_type(PlayerBall.ControlType.HUMAN_KB1)
		elif i == 1:
			players[i].set_control_type(PlayerBall.ControlType.AI_BOT)
		else:
			players[i].set_control_type(PlayerBall.ControlType.OFF)
	_update_lobby_ui()
	_update_menu_summary()

func _setup_lobby_focus() -> void:
	if not (ui_lobby_panel is ArcadeMenuShell):
		return
	var shell := ui_lobby_panel as ArcadeMenuShell
	ArcadeNav.wire_row_focus(ui_slot_btns, true)
	var name_btns: Array = []
	for c in ui_slot_cards:
		name_btns.append(c.name_btn)
	ArcadeNav.wire_row_focus(name_btns, true)
	var back_p := shell.get_back_button(ArcadeMenuShell.Page.PLAYERS)
	for i in range(ui_slot_cards.size()):
		var c := ui_slot_cards[i]
		c.name_btn.focus_neighbor_bottom = c.name_btn.get_path_to(c.ctrl_btn)
		c.ctrl_btn.focus_neighbor_top = c.ctrl_btn.get_path_to(c.name_btn)
		if is_instance_valid(back_p):
			c.name_btn.focus_neighbor_top = c.name_btn.get_path_to(back_p)
			c.ctrl_btn.focus_neighbor_bottom = c.ctrl_btn.get_path_to(back_p)
	if is_instance_valid(back_p) and not ui_slot_cards.is_empty():
		back_p.focus_neighbor_top = back_p.get_path_to(ui_slot_cards[0].ctrl_btn)
		back_p.focus_neighbor_bottom = back_p.get_path_to(ui_slot_cards[0].name_btn)
		shell._page_first_focus[ArcadeMenuShell.Page.PLAYERS] = ui_slot_cards[0].name_btn
	_update_menu_summary()

func _update_menu_summary() -> void:
	if not (ui_lobby_panel is ArcadeMenuShell):
		return
	var humans := 0
	var bots := 0
	for p in players:
		if p.control_type == PlayerBall.ControlType.AI_BOT:
			bots += 1
		elif p.control_type != PlayerBall.ControlType.OFF:
			humans += 1
	var arena_txt := current_arena.arena_name if current_arena else "Arena"
	var mode_txt := state_manager.get_mode_name() if state_manager else "Einzelmatch"
	(ui_lobby_panel as ArcadeMenuShell).set_summary("%d Mensch(en) + %d KI-Bot(s)   •   %s   •   %s" % [humans, bots, arena_txt, mode_txt])

func _unhandled_input(event: InputEvent) -> void:
	if ui_pause_overlay and ui_pause_overlay.visible:
		return
	if state_manager.current_state == RollStateManager.MatchState.LOBBY:
		if ui_leaderboard_modal and ui_leaderboard_modal.visible:
			if ArcadeNav.is_back(event) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L):
				toggle_leaderboard(false)
				return
		if ArcadeNav.is_start(event) and not (event is InputEventKey and event.keycode == KEY_ESCAPE):
			start_match_from_lobby()
			return
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			if ArcadeNav.activate_focused(get_viewport()):
				return
	else:
		if ArcadeNav.is_start(event):
			if ui_pause_overlay:
				ui_pause_overlay.open()
			else:
				return_to_lobby()
			return
		if ArcadeNav.is_confirm(event):
			if state_manager.current_state == RollStateManager.MatchState.ROUND_OVER:
				state_manager.start_next_round()
				return
			elif state_manager.current_state == RollStateManager.MatchState.MATCH_OVER:
				return_to_lobby()
				return

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
			elif event.keycode == KEY_T:
				cycle_arena()
			elif event.keycode == KEY_P:
				toggle_powerups()
			elif event.keycode == KEY_M:
				cycle_match_mode()
			elif event.keycode == KEY_L:
				toggle_leaderboard()
		else:
			if event.keycode == KEY_B:
				toggle_p2_bot()

func cycle_arena() -> void:
	var total_types = BaseArena.ArenaType.values().size()
	selected_arena_type = ((int(selected_arena_type) + 1) % total_types) as BaseArena.ArenaType
	_load_arena(selected_arena_type)
	_update_arena_ui()
	_update_menu_summary()

func cycle_match_mode() -> void:
	state_manager.cycle_match_mode()
	_update_mode_ui()
	_update_menu_summary()

func _update_mode_ui() -> void:
	if not ui_mode_label:
		return
	ui_mode_label.text = "🏆 %s" % state_manager.get_mode_name()
	if state_manager.current_match_mode == RollStateManager.MatchMode.SINGLE_MATCH:
		ui_mode_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	else:
		ui_mode_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

func toggle_leaderboard(show: Variant = null) -> void:
	if not ui_leaderboard_modal:
		return
	if show == null:
		ui_leaderboard_modal.visible = not ui_leaderboard_modal.visible
	else:
		ui_leaderboard_modal.visible = bool(show)
	
	if ui_leaderboard_modal.visible:
		_update_leaderboard_content()

func _update_leaderboard_content() -> void:
	if ui_leaderboard_content_label and leaderboard:
		ui_leaderboard_content_label.text = leaderboard.get_formatted_summary()

func _on_leaderboard_reset_pressed() -> void:
	if leaderboard:
		leaderboard.reset_all_stats()
		_update_leaderboard_content()

func _load_arena(type: BaseArena.ArenaType) -> void:
	if current_arena:
		current_arena.queue_free()
		remove_child(current_arena)
		current_arena = null
	
	match type:
		BaseArena.ArenaType.PURE_RING:
			current_arena = PureRingArena.new()
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
			current_arena = PureRingArena.new()
	
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
	
	_clear_trophy()
	ui_lobby_panel.visible = false
	ui_hud_container.visible = true
	
	state_manager.start_series(active_ids)

func return_to_lobby() -> void:
	_clear_trophy()
	if camera:
		camera.target_nodes = players
	for p in players:
		p.freeze = true
	state_manager.enter_lobby(_get_active_player_ids())
	ui_lobby_panel.visible = true
	_update_lobby_ui()
	_update_menu_summary()
	_update_arena_ui()
	_update_menu_summary()
	_update_mode_ui()
	_update_menu_summary()
	if ui_lobby_panel is ArcadeMenuShell:
		(ui_lobby_panel as ArcadeMenuShell).show_page(ArcadeMenuShell.Page.MAIN)
	_update_menu_summary()

func restart_game() -> void:
	_clear_trophy()
	if camera:
		camera.target_nodes = players
	state_manager.reset_match()

func _clear_trophy() -> void:
	if is_instance_valid(active_trophy):
		active_trophy.queue_free()
		active_trophy = null

func _get_active_player_ids() -> Array:
	var ids: Array = []
	for p in players:
		if p.control_type != PlayerBall.ControlType.OFF:
			ids.append(p.player_id)
	return ids

func _process(delta: float) -> void:
	if ui_touch_overlay and player1:
		player1.external_input_vec = ui_touch_overlay.input_vector if ui_touch_overlay.is_gameplay_active else Vector2.ZERO
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
	elif state_manager.current_state == RollStateManager.MatchState.ROUND_OVER:
		var sec = int(ceil(state_manager.round_transition_timer))
		var r_win = state_manager.get_winner()
		ui_status_label.text = "RUNDE %d BEENDET!\n🏆 SPIELER %d GEWINNT DIE RUNDE! 🏆\nNächste Runde in %d s... [SPACE]" % [
			state_manager.current_round_number,
			r_win,
			sec
		]
	
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
			if ui_match_over_overlay:
				ui_match_over_overlay.visible = false
			if sound_manager:
				sound_manager.play_music("lobby")
			if ui_touch_overlay:
				ui_touch_overlay.set_gameplay_active(false)
			ui_status_label.visible = false
			_clear_trophy()
			if powerup_spawner:
				powerup_spawner.clear_tokens()
				powerup_spawner.enabled = false
			for p in players:
				p.freeze = true
				p.clear_powerup()
		RollStateManager.MatchState.WARMUP:
			if ui_match_over_overlay:
				ui_match_over_overlay.visible = false
			if sound_manager:
				sound_manager.play_music("battle")
			ui_status_label.visible = true
			ui_status_label.text = "3"
			_clear_trophy()
			if camera:
				camera.target_nodes = players
			if powerup_spawner:
				powerup_spawner.clear_tokens()
				powerup_spawner.enabled = false
			
			# Arena zurücksetzen & Spieler an Spawn-Positionen aufstellen
			if current_arena:
				current_arena.reset_arena()
			var spawn_spots = current_arena.get_spawn_positions(players.size()) if current_arena else []
			for i in range(players.size()):
				var p = players[i]
				if p.control_type != PlayerBall.ControlType.OFF:
					var spot = spawn_spots[i] if i < spawn_spots.size() else p.initial_spawn_point
					p.respawn(spot)
					p.freeze = true
				p.clear_powerup()
		RollStateManager.MatchState.PLAYING:
			if ui_touch_overlay:
				ui_touch_overlay.set_gameplay_active(true)
			ui_status_label.visible = false
			if powerup_spawner:
				powerup_spawner.enabled = powerups_enabled
				powerup_spawner.reset_timer()
			for p in players:
				if p.control_type != PlayerBall.ControlType.OFF:
					p.freeze = false
		RollStateManager.MatchState.SUDDEN_DEATH:
			if sound_manager:
				sound_manager.play_music("sudden_death")
			ui_status_label.visible = true
			ui_status_label.text = "🔥 SUDDEN DEATH! 🔥"
		RollStateManager.MatchState.ROUND_OVER:
			if ui_touch_overlay:
				ui_touch_overlay.set_gameplay_active(false)
			ui_status_label.visible = true
			if sound_manager:
				sound_manager.play_round_win()
			if camera:
				camera.add_trauma(0.35)
			if powerup_spawner:
				powerup_spawner.clear_tokens()
				powerup_spawner.enabled = false
			for p in players:
				p.freeze = true
				p.clear_powerup()
		RollStateManager.MatchState.MATCH_OVER:
			if ui_touch_overlay:
				ui_touch_overlay.set_gameplay_active(false)
			if sound_manager:
				sound_manager.play_music("none")
			ui_status_label.visible = true
			if powerup_spawner:
				powerup_spawner.clear_tokens()
				powerup_spawner.enabled = false
			for p in players:
				p.freeze = true
				p.clear_powerup()

func _on_round_finished(round_winner_id: int, current_round: int) -> void:
	pass

func _on_tournament_finished(champion_id: int) -> void:
	if sound_manager:
		sound_manager.play_fanfare()
	if camera:
		camera.add_trauma(0.65)
	
	# 3D Pokal-Zeremonie spawnen
	_clear_trophy()
	active_trophy = Trophy3D.new()
	var spawn_pos = Vector3(0, 1.2, 0)
	if champion_id > 0 and champion_id <= players.size():
		var winner_ball = players[champion_id - 1]
		spawn_pos = winner_ball.position + Vector3(0, 1.4, 0)
		if camera:
			camera.target_nodes = [winner_ball]
	active_trophy.position = spawn_pos
	add_child(active_trophy)
	
	if impact_particles:
		impact_particles.spawn_sparks(spawn_pos, 12.0)
	
	var winner_name := player_names[champion_id - 1] if (champion_id > 0 and champion_id <= player_names.size()) else ""
	if couch_lb:
		var active_h: Array[String] = []
		for i in range(players.size()):
			if players[i].control_type != PlayerBall.ControlType.OFF and players[i].control_type != PlayerBall.ControlType.AI_BOT:
				active_h.append(player_names[i])
		var winners_h: Array[String] = []
		if winner_name != "" and players[champion_id - 1].control_type != PlayerBall.ControlType.AI_BOT:
			winners_h.append(winner_name)
		var is_cup := state_manager != null and state_manager.current_match_mode != RollStateManager.MatchMode.SINGLE_MATCH
		couch_lb.record_match(active_h, winners_h, is_cup)
		var lb_box_node := ui_lobby_panel.find_child("LbBox", true, false) as VBoxContainer if ui_lobby_panel else null
		if lb_box_node:
			couch_lb.populate_view(lb_box_node, "KOs")
	var winner_txt := "👑 CHAMPION: %s! 👑" % winner_name if winner_name != "" else "🤝 UNENTSCHIEDEN! 🤝"
	ui_status_label.text = winner_txt
	ui_status_label.visible = false
	if ui_match_over_overlay:
		var score_txt := ui_series_label.text if ui_series_label else ""
		ui_match_over_overlay.open(winner_txt, score_txt, "▶ REMATCH")

func _on_series_score_updated(series_scores: Dictionary) -> void:
	if not ui_series_label:
		return
	if state_manager.current_match_mode == RollStateManager.MatchMode.SINGLE_MATCH:
		ui_series_label.text = "★ EINZELMATCH (60.0s)"
		return
	var parts: Array[String] = []
	for p in players:
		if p.control_type != PlayerBall.ControlType.OFF:
			var w_count = series_scores.get(p.player_id, 0)
			parts.append("P%d: %d 🏆" % [p.player_id, w_count])
	var target_wins = state_manager.get_required_wins()
	ui_series_label.text = "★ %s (Ziel: %d Siege) — %s — RUNDE %d" % [
		state_manager.get_mode_name(),
		target_wins,
		"  |  ".join(parts),
		state_manager.current_round_number
	]

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
		ui_powerup_label.text = "⚡ POWER-UPS: AKTIV"
		ui_powerup_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
		ui_powerup_toggle_btn.text = "DEAKTIVIEREN [P]"
	else:
		ui_powerup_label.text = "🚫 POWER-UPS: AUS"
		ui_powerup_label.add_theme_color_override("font_color", Color(0.9, 0.45, 0.45))
		ui_powerup_toggle_btn.text = "AKTIVIEREN [P]"
