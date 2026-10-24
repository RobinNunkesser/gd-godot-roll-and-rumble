extends SceneTree

const RollConfig = preload("res://scripts/config.gd")
const RollStateManager = preload("res://scripts/state_manager.gd")
const PlayerBall = preload("res://scripts/player_ball.gd")
const MousetrapHazard = preload("res://scripts/mousetrap.gd")
const SharedArenaCamera = preload("res://scripts/shared_camera.gd")
const MainRollGame = preload("res://scenes/main.gd")
const BaseArena = preload("res://scripts/arenas/base_arena.gd")
const ClassicRingArena = preload("res://scripts/arenas/classic_ring.gd")
const DizzySpinnerArena = preload("res://scripts/arenas/dizzy_spinner.gd")
const WobblySeesawArena = preload("res://scripts/arenas/wobbly_seesaw.gd")

func _init() -> void:
	print("\n--- Running Headless Godot 4 Unit & Gameplay Tests for Roll & Rumble 3D ---")
	var success = true
	
	success = success and _test_config()
	success = success and _test_state_manager()
	success = success and _test_player_ball()
	success = success and _test_mousetrap()
	success = success and _test_shared_camera()
	success = success and _test_arenas()
	success = success and _test_main_scene()
	
	if success:
		print("=== ALL TESTS FOR ROLL & RUMBLE 3D PASSED SUCCESSFULLY! ===\n")
		quit(0)
	else:
		printerr("=== SOME TESTS FAILED! ===")
		quit(1)

func _test_config() -> bool:
	print("[1/6] Testing RollConfig parameters...")
	assert(RollConfig.BALL_RADIUS > 0.0, "Ball radius must be positive")
	assert(RollConfig.BALL_MASS > 0.0, "Ball mass must be positive")
	assert(RollConfig.DRIVE_FORCE > 0.0, "Drive force must be positive")
	assert(RollConfig.ARENA_RADIUS >= 5.0, "Arena radius must be >= 5m")
	assert(RollConfig.MATCH_DURATION_SECONDS > 0.0, "Match duration must be positive")
	print("  -> RollConfig OK.")
	return true

func _test_state_manager() -> bool:
	print("[2/6] Testing RollStateManager...")
	var sm = RollStateManager.new()
	sm.reset_match(10.0)
	assert(sm.current_state == RollStateManager.MatchState.WARMUP, "Initial state should be WARMUP")
	assert(sm.scores[1] == 0 and sm.scores[2] == 0, "Initial scores should be 0")
	
	# Warmup abwarten
	sm.update_logic(RollConfig.WARMUP_DURATION_SECONDS + 0.1)
	assert(sm.current_state == RollStateManager.MatchState.PLAYING, "State should be PLAYING after warmup")
	
	# Spieler 1 fällt ohne Kicker -> Spieler 2 bekommt Punkt
	sm.record_player_fall(1, 0)
	assert(sm.scores[2] == 1, "Player 2 should receive 1 point when Player 1 falls")
	assert(sm.scores[1] == 0, "Player 1 should have 0 points")
	
	# Spieler 2 fällt mit Kicker-Bonus von Spieler 1 -> Spieler 1 bekommt 2 Punkte (Überleben + Smash KO)
	sm.record_player_fall(2, 1)
	assert(sm.scores[1] == 2, "Player 1 should receive 2 points (survivor + kicker)")
	
	# Timer ablaufen lassen
	sm.update_logic(10.0)
	assert(sm.current_state == RollStateManager.MatchState.MATCH_OVER, "State should be MATCH_OVER after time expiry")
	assert(sm.get_winner() == 1, "Player 1 should be the winner")
	print("  -> RollStateManager OK.")
	return true

func _test_player_ball() -> bool:
	print("[3/6] Testing PlayerBall physics & boost...")
	var ball = PlayerBall.new()
	ball.player_id = 1
	root.add_child(ball)
	ball._ready()
	
	assert(ball.mass == RollConfig.BALL_MASS, "Ball mass mismatch")
	assert(ball.is_active, "Ball should be active initially")
	assert(ball.has_node("CollisionShape3D"), "PlayerBall MUST have a CollisionShape3D")
	var col = ball.get_node("CollisionShape3D") as CollisionShape3D
	assert(col != null and col.shape is SphereShape3D, "Collision shape must be SphereShape3D")
	assert(is_equal_approx(col.shape.radius, RollConfig.BALL_RADIUS), "Collision shape radius mismatch")
	
	# Boost testen
	ball.trigger_boost(Vector2(1.0, 0.0))
	assert(ball.boost_cooldown_timer > 0.0, "Boost cooldown should be active")
	
	# Bot AI Steering & Edge-Avoidance testen
	ball.is_bot = true
	var opp = Node3D.new()
	opp.position = Vector3(2.0, 0.0, 0.0)
	root.add_child(opp)
	ball.target_opponent = opp
	ball.position = Vector3(1.0, 0.0, 0.0)
	ball._handle_bot_ai(0.016)
	
	# Edge Avoidance bei r > danger_radius testen
	ball.position = Vector3(8.5, 0.0, 0.0)
	ball._handle_bot_ai(0.016)
	opp.queue_free()
	
	# Out-of-bounds Erkennung
	ball.position.y = RollConfig.OUT_OF_BOUNDS_Y - 1.0
	ball._check_out_of_bounds()
	assert(not ball.is_active, "Ball should be inactive after falling below threshold")
	
	ball.queue_free()
	print("  -> PlayerBall & AI Steering OK.")
	return true

func _test_mousetrap() -> bool:
	print("[4/6] Testing MousetrapHazard...")
	var trap = MousetrapHazard.new()
	root.add_child(trap)
	trap._ready()
	
	assert(trap.is_ready, "Trap should be ready initially")
	
	var ball = PlayerBall.new()
	root.add_child(ball)
	ball._ready()
	
	trap._on_body_entered(ball)
	assert(not trap.is_ready, "Trap should be triggered and on cooldown")
	assert(trap.cooldown_timer > 0.0, "Trap cooldown timer active")
	
	trap.queue_free()
	ball.queue_free()
	print("  -> MousetrapHazard OK.")
	return true

func _test_shared_camera() -> bool:
	print("[5/6] Testing SharedArenaCamera...")
	var cam = SharedArenaCamera.new()
	var b1 = Node3D.new()
	b1.position = Vector3(-5, 0, 0)
	var b2 = Node3D.new()
	b2.position = Vector3(5, 0, 0)
	root.add_child(b1)
	root.add_child(b2)
	root.add_child(cam)
	cam.target_nodes = [b1, b2]
	
	cam.update_camera(0.1)
	assert(cam.position.y > 0.0, "Camera should have elevated height")
	
	cam.queue_free()
	b1.queue_free()
	b2.queue_free()
	print("  -> SharedArenaCamera OK.")
	return true

func _test_arenas() -> bool:
	print("[6/7] Testing Phase 2 dynamic arenas (Classic, Spinner, Seesaw)...")
	# 1. ClassicRingArena
	var classic = ClassicRingArena.new()
	root.add_child(classic)
	classic._ready()
	assert(classic.arena_name == "CLASSIC RING", "Classic ring name mismatch")
	assert(classic.traps.size() == 4, "Classic ring should have 4 traps")
	classic.queue_free()
	
	# 2. DizzySpinnerArena
	var spinner = DizzySpinnerArena.new()
	root.add_child(spinner)
	spinner._ready()
	assert(spinner.arena_name == "DIZZY SPINNER", "Spinner name mismatch")
	assert(spinner.inner_spinner != null, "Spinner must have inner_spinner body")
	spinner.update_arena(0.1)
	assert(absf(spinner.current_omega) > 0.0, "Spinner should calculate non-zero omega on update")
	spinner.queue_free()
	
	# 3. WobblySeesawArena
	var seesaw = WobblySeesawArena.new()
	root.add_child(seesaw)
	seesaw._ready()
	assert(seesaw.arena_name == "WOBBLY SEESAW", "Seesaw name mismatch")
	assert(seesaw.tilting_platform != null, "Seesaw must have tilting_platform body")
	var dummy_player = Node3D.new()
	dummy_player.position = Vector3(5.0, 0.0, 5.0)
	root.add_child(dummy_player)
	seesaw.update_arena(0.1, [dummy_player])
	dummy_player.queue_free()
	seesaw.queue_free()
	print("  -> Dynamic Arenas OK.")
	return true

func _test_main_scene() -> bool:
	print("[7/7] Testing MainRollGame full orchestration...")
	var main_game = MainRollGame.new()
	root.add_child(main_game)
	main_game._ready()
	
	assert(main_game.player1 != null, "Player 1 should be instantiated")
	assert(main_game.player2 != null, "Player 2 should be instantiated")
	assert(main_game.camera != null, "Camera should be instantiated")
	assert(main_game.player2.is_bot, "Player 2 should default to AI bot for single-player")
	
	# Arena-Auswahl im Lobby-Modus testen
	assert(main_game.current_arena is ClassicRingArena, "Default arena should be ClassicRingArena")
	main_game.cycle_arena()
	assert(main_game.current_arena is DizzySpinnerArena, "Arena should cycle to DizzySpinnerArena")
	main_game.cycle_arena()
	assert(main_game.current_arena is WobblySeesawArena, "Arena should cycle to WobblySeesawArena")
	main_game.cycle_arena()
	assert(main_game.current_arena is ClassicRingArena, "Arena should cycle back to ClassicRingArena")
	
	# Bot Toggle testen
	main_game.toggle_p2_bot()
	assert(not main_game.player2.is_bot, "Player 2 should toggle to Human")
	main_game.toggle_p2_bot()
	assert(main_game.player2.is_bot, "Player 2 should toggle back to AI bot")
	
	# Lobby Slot Cycling & Start Match
	assert(main_game.state_manager.current_state == RollStateManager.MatchState.LOBBY, "Initial state should be LOBBY")
	main_game.cycle_player_slot(2) # Player 3 cycle
	assert(main_game.player3.control_type == PlayerBall.ControlType.HUMAN_KB1, "P3 should cycle from OFF to HUMAN_KB1")
	main_game.start_match_from_lobby()
	assert(main_game.state_manager.current_state == RollStateManager.MatchState.WARMUP, "State should be WARMUP after start")
	
	main_game._process(0.016)
	main_game.queue_free()
	print("  -> MainRollGame & 4-Player Lobby & Arena Switching OK.")
	return true
