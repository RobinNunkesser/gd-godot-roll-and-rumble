class_name RollSoundManager
extends Node

## Prozedurale 16-Bit Audio-Synthese für Arcade-Soundeffekte (ohne externe WAV-Abhängigkeiten)
## Bietet Audio-Player-Pooling für unterbrechungsfreie Mehrfach-Kollisionen.

var stream_bounce: AudioStreamWAV
var stream_smash: AudioStreamWAV
var stream_snap: AudioStreamWAV
var stream_boost: AudioStreamWAV
var stream_fall: AudioStreamWAV

var _players: Array[AudioStreamPlayer] = []
var _pool_size: int = 8
var _current_player_idx: int = 0

func _init() -> void:
	name = "SoundManager"
	_synthesize_all_sounds()

func _ready() -> void:
	_setup_player_pool()

func _setup_player_pool() -> void:
	for i in range(_pool_size):
		var p = AudioStreamPlayer.new()
		p.name = "AudioPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func _get_available_player() -> AudioStreamPlayer:
	if _players.is_empty():
		return null
	var p = _players[_current_player_idx]
	_current_player_idx = (_current_player_idx + 1) % _players.size()
	return p

## 1. Ramm- und Kollisionsgeräusch (dynamisch nach Wucht)
func play_impact(force: float) -> void:
	if not is_inside_tree():
		return
	var p = _get_available_player()
	if not p:
		return
	
	if force > 6.0:
		p.stream = stream_smash
		p.volume_db = clampf(-8.0 + (force - 6.0) * 0.8, -8.0, 3.0)
	else:
		p.stream = stream_bounce
		p.volume_db = clampf(-18.0 + force * 1.5, -20.0, -4.0)
	
	p.pitch_scale = randf_range(0.92, 1.08)
	p.play()

## 2. Mausefallen-Schnappgeräusch
func play_trap_snap() -> void:
	if not is_inside_tree():
		return
	var p = _get_available_player()
	if p:
		p.stream = stream_snap
		p.volume_db = 0.0
		p.pitch_scale = randf_range(0.95, 1.05)
		p.play()

## 3. Turbo-Boost Geräusch
func play_boost() -> void:
	if not is_inside_tree():
		return
	var p = _get_available_player()
	if p:
		p.stream = stream_boost
		p.volume_db = -3.0
		p.pitch_scale = randf_range(0.96, 1.04)
		p.play()

## 4. Runterfall-Geräusch
func play_fall() -> void:
	if not is_inside_tree():
		return
	var p = _get_available_player()
	if p:
		p.stream = stream_fall
		p.volume_db = -2.0
		p.pitch_scale = randf_range(0.95, 1.05)
		p.play()

func _synthesize_all_sounds() -> void:
	stream_bounce = _generate_bounce_wav()
	stream_smash = _generate_smash_wav()
	stream_snap = _generate_snap_wav()
	stream_boost = _generate_boost_wav()
	stream_fall = _generate_fall_wav()

func _generate_bounce_wav() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.12
	var total_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(mix_rate)
		var progress = t / duration
		var freq = lerpf(380.0, 160.0, progress)
		var env = exp(-progress * 7.0)
		var sample = sin(t * freq * TAU) * env * 18000.0
		data.encode_s16(i * 2, int(sample))
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_smash_wav() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.20
	var total_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(mix_rate)
		var progress = t / duration
		var freq = lerpf(170.0, 42.0, progress)
		var env = exp(-progress * 6.0)
		var sine_val = sin(t * freq * TAU)
		var noise = randf_range(-1.0, 1.0) * exp(-progress * 12.0)
		var sample = (sine_val * 0.65 + noise * 0.35) * env * 22000.0
		data.encode_s16(i * 2, int(sample))
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_snap_wav() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.09
	var total_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(mix_rate)
		var progress = t / duration
		var freq = lerpf(880.0, 190.0, progress)
		var env = exp(-progress * 14.0)
		var noise = randf_range(-1.0, 1.0)
		var click = sin(t * freq * TAU)
		var sample = (click * 0.6 + noise * 0.4) * env * 24000.0
		data.encode_s16(i * 2, int(sample))
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_boost_wav() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.16
	var total_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(mix_rate)
		var progress = t / duration
		var freq = lerpf(120.0, 520.0, progress) # Aufsteigender Turbo-Sound
		var env = sin(progress * PI)
		var sample = sin(t * freq * TAU) * env * 19000.0
		data.encode_s16(i * 2, int(sample))
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_fall_wav() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.45
	var total_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(mix_rate)
		var progress = t / duration
		var freq = lerpf(600.0, 80.0, progress * progress) # Fallender Pfeifton
		var env = (1.0 - progress) * 0.8
		var sample = sin(t * freq * TAU) * env * 18000.0
		data.encode_s16(i * 2, int(sample))
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav
