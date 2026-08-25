extends Node

const SAMPLE_RATE := 22050

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music := ""
var _streams := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -8.0
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	_sfx_player.volume_db = -4.0
	add_child(_sfx_player)

func _exit_tree() -> void:
	stop_music()
	_sfx_player.stop()
	_music_player.stream = null
	_sfx_player.stream = null
	_streams.clear()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func _on_music_finished() -> void:
	if _current_music != "" and _music_player.stream != null:
		_music_player.play()

func play_sfx(effect_name: String) -> void:
	if not _streams.has(effect_name):
		_streams[effect_name] = _create_sfx(effect_name)
	_sfx_player.stream = _streams[effect_name]
	_sfx_player.pitch_scale = randf_range(0.96, 1.04)
	_sfx_player.play()

func play_music(music_name: String) -> void:
	if _current_music == music_name and _music_player.playing:
		return
	if not _streams.has(music_name):
		_streams[music_name] = _create_music(music_name)
	_music_player.stream = _streams[music_name]
	_music_player.play()
	_current_music = music_name

func stop_music() -> void:
	_music_player.stop()
	_current_music = ""

func _sample_value(phase: float, wave: String) -> float:
	match wave:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"saw":
			return fmod(phase / TAU, 1.0) * 2.0 - 1.0
		"noise":
			return randf_range(-1.0, 1.0)
		_:
			return sin(phase)

func _create_sfx(effect_name: String) -> AudioStreamWAV:
	match effect_name:
		"jump":
			return _make_wave(520.0, 0.14, "square", 1.55, 0.20)
		"double_jump":
			return _make_wave(680.0, 0.13, "square", 1.45, 0.18)
		"land":
			return _make_wave(150.0, 0.09, "triangle", 0.65, 0.16)
		"step":
			return _make_wave(220.0, 0.04, "noise", 0.85, 0.05)
		"dash":
			return _make_wave(760.0, 0.18, "saw", 0.42, 0.16)
		"attack":
			return _make_wave(430.0, 0.10, "square", 0.72, 0.15)
		"hit":
			return _make_wave(190.0, 0.13, "square", 1.25, 0.22)
		"block":
			return _make_wave(820.0, 0.08, "square", 0.90, 0.14)
		"hurt":
			return _make_wave(260.0, 0.22, "saw", 0.48, 0.22)
		"coin":
			return _make_wave(880.0, 0.10, "square", 1.35, 0.16)
		"heart":
			return _make_wave(620.0, 0.16, "triangle", 1.25, 0.18)
		"level_up":
			return _make_wave(520.0, 0.35, "square", 1.90, 0.18)
		"checkpoint":
			return _make_wave(640.0, 0.24, "triangle", 1.50, 0.16)
		"enemy_death":
			return _make_wave(320.0, 0.22, "saw", 0.35, 0.18)
		"portal":
			return _make_wave(480.0, 0.45, "triangle", 2.10, 0.18)
		_:
			return _make_wave(440.0, 0.08, "triangle", 1.0, 0.12)

func _make_wave(start_frequency: float, duration: float, wave: String, end_multiplier: float, volume: float) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	var phase := 0.0
	for frame in range(frame_count):
		var t := float(frame) / float(frame_count)
		var frequency := lerpf(start_frequency, start_frequency * end_multiplier, t)
		phase += TAU * frequency / SAMPLE_RATE
		var envelope := (1.0 - t) * (1.0 - t)
		var value := _sample_value(phase, wave) * envelope * volume
		var integer := int(clampf(value, -1.0, 1.0) * 32000.0)
		data.encode_s16(frame * 4, integer)
		data.encode_s16(frame * 4 + 2, integer)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = data
	return stream

func _create_music(music_name: String) -> AudioStreamWAV:
	match music_name:
		"title":
			return _make_song([220.0, 261.63, 329.63, 261.63], 9.0, 0.055, false)
		"danger":
			return _make_song([196.0, 233.08, 293.66, 220.0], 8.0, 0.070, true)
		_:
			return _make_song([261.63, 329.63, 392.0, 329.63], 11.0, 0.060, false)

func _make_song(chords: Array, duration: float, volume: float, tense: bool) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	var melody := [0.0, 4.0, 7.0, 12.0, 7.0, 4.0]
	for frame in range(frame_count):
		var t := float(frame) / SAMPLE_RATE
		var section := int(t / (duration / chords.size())) % chords.size()
		var root: float = chords[section]
		var bass_phase := TAU * root * 0.5 * t
		var chord_phase := TAU * root * t
		var lead_frequency := root * pow(2.0, melody[ int(t * 3.0) % melody.size() ] / 12.0)
		var lead_phase := TAU * lead_frequency * t
		var value := sin(bass_phase) * 0.24
		value += (sin(chord_phase) + sin(chord_phase * 1.5)) * 0.08
		value += _sample_value(lead_phase, "square") * 0.06
		if tense and fmod(t, 0.5) < 0.06:
			value += randf_range(-0.10, 0.10)
		var fade := minf(1.0, float(frame) / 2000.0) * minf(1.0, float(frame_count - frame) / 2000.0)
		var integer := int(clampf(value * fade * volume * 18.0, -1.0, 1.0) * 26000.0)
		data.encode_s16(frame * 4, integer)
		data.encode_s16(frame * 4 + 2, integer)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.loop_begin = 0
	stream.loop_end = 0
	stream.data = data
	return stream
