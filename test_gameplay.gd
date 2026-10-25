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
const BumperPinballArena = preload("res://scripts/arenas/bumper_pinball.gd")
const IceSlickArena = preload("res://scripts/arenas/ice_slick.gd")
const PinballBumper = preload("res://scripts/pinball_bumper.gd")
const RollSoundManager = preload("res://scripts/sound_manager.gd")
const RollImpactParticles = preload("res://scripts/impact_particles.gd")
const PowerUpToken = preload("res://scripts/powerup_token.gd")
const PowerUpSpawner = preload("res://scripts/powerup_spawner.gd")

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
	success = success and _test_juice_systems()
	success = success and _test_powerups()
	
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
	
	# Juiciness & Trauma Test
	assert(cam.trauma == 0.0, "Initial camera trauma should be 0")
	cam.add_trauma(0.5)
	assert(cam.trauma == 0.5, "Trauma should be 0.5 after add_trauma")
	cam.update_camera(0.1)
	assert(cam.trauma < 0.5, "Trauma should decay over time")
	
	cam.queue_free()
	b1.queue_free()
	b2.queue_free()
	print("  -> SharedArenaCamera & Trauma Shake OK.")
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
	
	# 4. BumperPinballArena & PinballBumper
	var pinball = BumperPinballArena.new()
	root.add_child(pinball)
	pinball._ready()
	assert(pinball.arena_name == "PINBALL BUMPERS", "Pinball arena name mismatch")
	assert(pinball.bumpers.size() == 5, "Pinball should have 5 bumpers")
	
	var bumper = pinball.bumpers[0]
	var test_ball = PlayerBall.new()
	root.add_child(test_ball)
	test_ball._ready()
	bumper._on_body_entered(test_ball)
	assert(bumper._squash_timer > 0.0, "Bumper squash timer should activate on hit")
	test_ball.queue_free()
	pinball.queue_free()
	
	# 5. IceSlickArena
	var ice = IceSlickArena.new()
	root.add_child(ice)
	ice._ready()
	assert(ice.arena_name == "ICE SLICK", "Ice slick name mismatch")
	assert(ice.ice_pillars.size() == 4, "Ice arena should have 4 pillars")
	ice.queue_free()
	
	print("  -> Dynamic Arenas (5 Total: Classic, Spinner, Seesaw, Pinball, Ice) OK.")
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
	
	# Arena-Auswahl im Lobby-Modus (5 Arenen zyklisch durchschalten)
	assert(main_game.current_arena is ClassicRingArena, "Default arena should be ClassicRingArena")
	main_game.cycle_arena()
	assert(main_game.current_arena is DizzySpinnerArena, "Arena should cycle to DizzySpinnerArena")
	main_game.cycle_arena()
	assert(main_game.current_arena is WobblySeesawArena, "Arena should cycle to WobblySeesawArena")
	main_game.cycle_arena()
	assert(main_game.current_arena is BumperPinballArena, "Arena should cycle to BumperPinballArena")
	main_game.cycle_arena()
	assert(main_game.current_arena is IceSlickArena, "Arena should cycle to IceSlickArena")
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
	
	assert(main_game.sound_manager != null, "Sound manager should be instantiated")
	assert(main_game.impact_particles != null, "Impact particles should be instantiated")
	
	# Power-Up Toggle im Hauptmenü / Lobby testen (Option A)
	assert(main_game.powerups_enabled, "Power-ups should be enabled by default")
	main_game.toggle_powerups()
	assert(not main_game.powerups_enabled, "Power-ups should be toggleable OFF in lobby")
	assert(not main_game.powerup_spawner.enabled, "PowerUpSpawner should sync disabled state")
	main_game.toggle_powerups()
	assert(main_game.powerups_enabled, "Power-ups should be toggleable ON in lobby")
	assert(main_game.powerup_spawner.enabled, "PowerUpSpawner should sync enabled state")
	
	main_game._process(0.016)
	main_game.queue_free()
	print("  -> MainRollGame & 4-Player Lobby & Arena Switching OK.")
	return true

func _test_juice_systems() -> bool:
	print("[8/9] Testing RollSoundManager & RollImpactParticles...")
	var sm = RollSoundManager.new()
	root.add_child(sm)
	sm._ready()
	assert(sm.stream_bounce != null, "Bounce stream should be synthesized")
	assert(sm.stream_smash != null, "Smash stream should be synthesized")
	assert(sm.stream_snap != null, "Snap stream should be synthesized")
	assert(sm.stream_boost != null, "Boost stream should be synthesized")
	assert(sm.stream_powerup != null, "Powerup stream should be synthesized")
	sm.play_impact(8.5)
	sm.play_trap_snap()
	sm.play_boost()
	sm.play_fall()
	sm.play_powerup()
	sm.queue_free()
	
	var ip = RollImpactParticles.new()
	root.add_child(ip)
	ip._ready()
	assert(ip._spark_pool.size() == 6, "Spark pool size mismatch")
	assert(ip._boost_pool.size() == 4, "Boost pool size mismatch")
	ip.spawn_sparks(Vector3.ZERO, 5.0)
	ip.spawn_boost_burst(Vector3.ZERO, Vector3.FORWARD)
	ip.queue_free()
	print("  -> SoundManager & ImpactParticles OK.")
	return true

func _test_powerups() -> bool:
	print("[9/9] Testing Phase 3 Power-Up System (6 Archetypes, Spawner & Ball Integration)...")
	# 1. PowerUpToken Visuals & Types
	for t in PowerUpToken.Type.values():
		var token = PowerUpToken.new(t)
		root.add_child(token)
		token._ready()
		assert(token.powerup_type == t, "Token type mismatch")
		assert(token.has_node("CollisionShape3D"), "Token must have CollisionShape3D")
		assert(token.has_node("TokenMeshPivot"), "Token must have mesh pivot")
		token._process(0.016)
		token.queue_free()
	
	# 2. PowerUpSpawner
	var spawner = PowerUpSpawner.new()
	root.add_child(spawner)
	spawner._ready()
	assert(spawner.enabled, "Spawner should be enabled by default")
	var spawned_t = spawner.spawn_specific_token(PowerUpToken.Type.NITRO_JET, Vector3(0, 0.85, 0))
	assert(spawned_t != null, "Spawner should spawn specific token")
	assert(spawner.active_tokens.size() == 1, "Spawner should track active token")
	spawner.clear_tokens()
	assert(spawner.active_tokens.size() == 0, "Tokens should be cleared")
	spawner.queue_free()
	
	# 3. PlayerBall Transformations & Physics Multipliers
	var ball = PlayerBall.new()
	ball.player_id = 1
	root.add_child(ball)
	ball._ready()
	
	# Anvil: 3x Mass
	ball.apply_powerup(PowerUpToken.Type.ANVIL, 5.0)
	assert(ball.active_powerup == PowerUpToken.Type.ANVIL, "Ball should have ANVIL active")
	assert(is_equal_approx(ball.mass, RollConfig.BALL_MASS * RollConfig.POWERUP_ANVIL_MASS_MULTIPLIER), "Anvil mass mismatch")
	
	# Spike Wheel
	ball.apply_powerup(PowerUpToken.Type.SPIKE_WHEEL, 5.0)
	assert(ball.active_powerup == PowerUpToken.Type.SPIKE_WHEEL, "Ball should have SPIKE_WHEEL active")
	assert(is_equal_approx(ball.mass, RollConfig.BALL_MASS), "Mass should revert to normal")
	
	# Nitro Jet
	ball.apply_powerup(PowerUpToken.Type.NITRO_JET, 5.0)
	assert(ball.nitro_charges == RollConfig.POWERUP_NITRO_CHARGES, "Nitro charges should be granted")
	ball.trigger_boost(Vector2(1.0, 0.0))
	assert(ball.nitro_charges == RollConfig.POWERUP_NITRO_CHARGES - 1, "Nitro charge should be consumed")
	assert(ball.boost_cooldown_timer == 0.0, "Nitro boost should bypass cooldown")
	
	# Ghost Phase
	ball.apply_powerup(PowerUpToken.Type.GHOST_PHASE, 5.0)
	assert(ball.collision_layer == 4, "Ghost phase should set layer to 4")
	assert(ball.collision_mask == 1, "Ghost phase should keep floor mask 1")
	
	# Ice Trail & Gravity Magnet
	ball.apply_powerup(PowerUpToken.Type.ICE_TRAIL, 5.0)
	assert(ball.active_powerup == PowerUpToken.Type.ICE_TRAIL, "Ice trail active mismatch")
	ball.apply_powerup(PowerUpToken.Type.GRAVITY_MAGNET, 5.0)
	assert(ball.active_powerup == PowerUpToken.Type.GRAVITY_MAGNET, "Magnet active mismatch")
	
	# Clear Powerup
	ball.clear_powerup()
	assert(ball.active_powerup == -1, "Active powerup should be -1 after clear")
	assert(is_equal_approx(ball.mass, RollConfig.BALL_MASS), "Mass should be default after clear")
	assert(ball.collision_layer == 1, "Collision layer should be 1 after clear")
	
	ball.queue_free()
	print("  -> PowerUpToken, Spawner, Ball Archetypes & Sound Integration OK.")
	return true
