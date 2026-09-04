extends Node

const SETTINGS_PATH := "user://adventure_island_settings.json"

const REBINDABLE_ACTIONS := [
	"move_left", "move_right", "jump", "attack", "dash",
	"pause", "debug_toggle", "toggle_map",
]

@export var music_volume := 0.85
@export var sfx_volume := 0.90
@export var fullscreen := true
@export var shake_enabled := true
@export var hit_stop_enabled := true
@export var keybinds := {}

func _ready() -> void:
	load_settings()
	apply_settings()
	apply_keybinds()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_bus("Music", music_volume)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_bus("SFX", sfx_volume)
	save_settings()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func set_shake_enabled(value: bool) -> void:
	shake_enabled = value
	GameFeel.shake_enabled = value
	save_settings()

func set_hit_stop_enabled(value: bool) -> void:
	hit_stop_enabled = value
	GameFeel.hit_stop_enabled = value
	save_settings()

func set_action_key(action: String, event: InputEventKey) -> bool:
	if not REBINDABLE_ACTIONS.has(action) or not InputMap.has_action(action):
		return false
	var key := event.duplicate() as InputEventKey
	if key.physical_keycode == KEY_NONE and key.keycode == KEY_NONE:
		return false
	for existing in InputMap.action_get_events(action).duplicate():
		if existing is InputEventKey:
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, key)
	keybinds[action] = {
		"physical_keycode": int(key.physical_keycode),
		"keycode": int(key.keycode),
		"modifiers": int(key.modifiers_mask),
	}
	save_settings()
	return true

func get_action_key(action: String) -> String:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key:
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			if code != KEY_NONE:
				return OS.get_keycode_string(code)
	return "未设置"

func reset_action_key(action: String) -> bool:
	if not REBINDABLE_ACTIONS.has(action) or not InputMap.has_action(action):
		return false
	keybinds.erase(action)
	apply_action_keybind(action)
	save_settings()
	return true

func apply_keybinds() -> void:
	for action in REBINDABLE_ACTIONS:
		apply_action_keybind(action)

func apply_action_keybind(action: String) -> void:
	if not InputMap.has_action(action) or not keybinds.has(action):
		return
	var data: Dictionary = keybinds[action]
	var key := InputEventKey.new()
	key.physical_keycode = int(data.get("physical_keycode", KEY_NONE)) as Key
	key.keycode = int(data.get("keycode", KEY_NONE)) as Key
	key.modifiers_mask = int(data.get("modifiers", 0)) as KeyModifierMask
	if key.physical_keycode == KEY_NONE and key.keycode == KEY_NONE:
		return
	for existing in InputMap.action_get_events(action).duplicate():
		if existing is InputEventKey:
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, key)

func apply_settings() -> void:
	_apply_audio_bus("Music", music_volume)
	_apply_audio_bus("SFX", sfx_volume)
	set_fullscreen(fullscreen)
	GameFeel.shake_enabled = shake_enabled
	GameFeel.hit_stop_enabled = hit_stop_enabled

func _apply_audio_bus(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, volume)))
		AudioServer.set_bus_mute(index, volume <= 0.001)

func save_settings() -> void:
	var data := {
		"version": 1,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"shake_enabled": shake_enabled,
		"hit_stop_enabled": hit_stop_enabled,
		"keybinds": keybinds,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	music_volume = clampf(float(parsed.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(parsed.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(parsed.get("fullscreen", fullscreen))
	shake_enabled = bool(parsed.get("shake_enabled", shake_enabled))
	hit_stop_enabled = bool(parsed.get("hit_stop_enabled", hit_stop_enabled))
	var saved_keybinds: Dictionary = parsed.get("keybinds", {})
	keybinds = saved_keybinds.duplicate(true)
