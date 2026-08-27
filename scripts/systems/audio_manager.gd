extends Node

const SAMPLE_RATE := 22050
const LEVEL_BGM_BPM := 132

signal music_preload_progress(music_name: String, progress: float)

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music := ""
var _streams := {}
# 正在异步合成的音乐，避免重复合成同一首。
var _music_pending := {}

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
	await _wait_for_pending_music(music_name)
	if not _streams.has(music_name):
		_streams[music_name] = _create_music(music_name)
	_music_player.stream = _streams[music_name]
	_music_player.play()
	_current_music = music_name

func stop_music() -> void:
	_music_player.stop()
	_current_music = ""

func preload_music(music_name: String) -> void:
	if _streams.has(music_name):
		return
	await _wait_for_pending_music(music_name)
	if _streams.has(music_name):
		return
	_streams[music_name] = _create_music(music_name)

func preload_music_async(music_name: String) -> void:
	# 异步分块预载：每 4000 帧让出一帧并汇报进度，加载界面的进度条可以实时前进。
	if _streams.has(music_name):
		music_preload_progress.emit(music_name, 1.0)
		return
	await _wait_for_pending_music(music_name)
	if _streams.has(music_name):
		music_preload_progress.emit(music_name, 1.0)
		return
	if music_name != "level":
		_streams[music_name] = _create_music(music_name)
		music_preload_progress.emit(music_name, 1.0)
		return
	_music_pending[music_name] = true
	var stream := await _create_upbeat_level_theme_async()
	_streams[music_name] = stream
	_music_pending.erase(music_name)
	music_preload_progress.emit(music_name, 1.0)

func _wait_for_pending_music(music_name: String) -> void:
	while _music_pending.has(music_name):
		await get_tree().process_frame

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
			return _make_upbeat_level_theme()

func _make_upbeat_level_theme() -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * 8.0)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	_write_upbeat_frames(data, 0, frame_count, frame_count)
	return _finish_upbeat_stream(data)

func _create_upbeat_level_theme_async() -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * 8.0)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	var chunk := 4000
	var cursor := 0
	while cursor < frame_count:
		var end := mini(cursor + chunk, frame_count)
		_write_upbeat_frames(data, cursor, end, frame_count)
		cursor = end
		music_preload_progress.emit("level", float(cursor) / float(frame_count))
		await get_tree().process_frame
	return _finish_upbeat_stream(data)

func _write_upbeat_frames(data: PackedByteArray, from_frame: int, to_frame: int, frame_count: int) -> void:
	var duration := 8.0
	var melody_semitones := [0, 2, 7, 9, 7, 4, 2, 4, 7, 9, 11, 9, 7, 4, 2, 0]
	var bass_semitones := [0, 0, 7, 7, 5, 5, 12, 12]
	var beat_steps := int(duration / (60.0 / float(LEVEL_BGM_BPM)) * 2.0)
	for frame in range(from_frame, to_frame):
		var t := float(frame) / SAMPLE_RATE
		var step := int(t * float(beat_steps) / duration)
		var beat_position := fmod(t * float(beat_steps) / duration, 1.0)
		var melody_index := step % melody_semitones.size()
		var bass_index := int(step / 2) % bass_semitones.size()
		var melody_frequency := 523.25 * pow(2.0, melody_semitones[melody_index] / 12.0)
		var bass_frequency := 196.0 * pow(2.0, bass_semitones[bass_index] / 12.0)
		var melody_phase := TAU * melody_frequency * t
		var bass_phase := TAU * bass_frequency * t
		var value := _sample_value(melody_phase, "square") * 0.045
		value += sin(TAU * melody_frequency * 2.0 * t) * 0.018
		value += sin(bass_phase) * 0.16
		value += sin(harmony_phase(step, beat_position)) * 0.09
		if step % 4 == 2 and beat_position < 0.14:
			value += randf_range(-0.10, 0.10) * (1.0 - beat_position / 0.14)
		if step % 2 == 1:
			value *= 0.88
		var fade := minf(1.0, float(frame) / 1500.0) * minf(1.0, float(frame_count - frame) / 1500.0)
		var integer := int(clampf(value * fade, -1.0, 1.0) * 25000.0)
		data.encode_s16(frame * 4, integer)
		data.encode_s16(frame * 4 + 2, integer)

func _finish_upbeat_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.set_meta("style", "upbeat_chiptune")
	stream.set_meta("tempo_bpm", LEVEL_BGM_BPM)
	stream.data = data
	return stream

func harmony_phase(step: int, beat_position: float) -> float:
	var frequencies := [392.0, 440.0, 523.25, 659.25]
	var frequency: float = frequencies[step % frequencies.size()]
	return TAU * frequency * beat_position * (60.0 / float(LEVEL_BGM_BPM)) * 0.5

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
