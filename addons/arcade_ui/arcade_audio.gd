class_name ArcadeAudio
extends Node

## Standard-UI-Audio-Manager für godot-arcade-ui (Menü-SFX + optionale Lobby-Musik).

const AUDIO_BASE := "res://addons/arcade_ui/assets/audio/"

var sfx_enabled: bool = true
var music_enabled: bool = true

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = _resolve_bus(&"SFX")
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _resolve_bus(&"Music")
	_music_player.volume_db = -8.0
	_music_player.finished.connect(func() -> void:
		if music_enabled and _music_player.stream != null:
			_music_player.play()
	)
	add_child(_music_player)

	for key in ["ui_move", "ui_confirm", "ui_back", "ui_pause", "ui_victory", "ui_lobby"]:
		var path := "%s%s.ogg" % [AUDIO_BASE, key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path)

static func ensure_buses() -> void:
	for bus_name in [&"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")

static func _resolve_bus(preferred: StringName) -> StringName:
	return preferred if AudioServer.get_bus_index(preferred) >= 0 else &"Master"

func play_sfx(key: String) -> void:
	if not sfx_enabled or DisplayServer.get_name() == "headless":
		return
	var stream_key := key if key.begins_with("ui_") else "ui_" + key
	var stream: AudioStream = _streams.get(stream_key)
	if stream and _sfx_player:
		_sfx_player.stream = stream
		_sfx_player.play()

func start_lobby_music() -> void:
	if not music_enabled or DisplayServer.get_name() == "headless":
		return
	var stream: AudioStream = _streams.get("ui_lobby")
	if stream and _music_player and not _music_player.playing:
		_music_player.stream = stream
		_music_player.play()

func stop_lobby_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()
