extends Control

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const VIEW_W := 1280.0
const VIEW_H := 720.0
const TITLE_BASE_Y := 132.0

var _time := 0.0
var _clouds: Array = []
var _slimes: Array = []
var _rebinding_action := ""

func _ready() -> void:
	AudioManager.play_music("title")
	LocalizationSystem.language_changed.connect(_on_language_changed)
	_apply_localized_text()
	_connect_buttons()
	_spawn_scenery()
	_refresh_keybind_buttons()
	# UI 建好后再把关卡 BGM 的波形合成排到空闲帧。
	AudioManager.call_deferred("preload_music_async", "level")

func _process(delta: float) -> void:
	_time += delta
	_animate_clouds(delta)
	_animate_sun()
	_animate_title()
	_animate_slimes()

func _unhandled_key_input(event: InputEvent) -> void:
	if _rebinding_action.is_empty():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_ESCAPE:
		_rebinding_action = ""
	else:
		SettingsSystem.set_action_key(_rebinding_action, key)
		_rebinding_action = ""
	_refresh_keybind_buttons()
	get_viewport().set_input_as_handled()

func _on_language_changed(_language: String) -> void:
	get_tree().reload_current_scene.call_deferred()

func _apply_localized_text() -> void:
	%TitleShadow.text = LocalizationSystem.tr_key("app_title")
	%TitleLabel.text = LocalizationSystem.tr_key("app_title")
	%SubtitleLabel.text = LocalizationSystem.tr_key("app_subtitle")
	%StartButton.text = LocalizationSystem.tr_key("start")
	%QuitButton.text = LocalizationSystem.tr_key("quit")
	%SettingsButton.text = LocalizationSystem.tr_key("settings")
	%ContinueButton.text = LocalizationSystem.tr_key("continue")
	# 菜单按钮字号沿用旧版 24px（Theme 默认 21px 面向局内小按钮）。
	for menu_button in [%StartButton, %ContinueButton, %QuitButton, %SettingsButton]:
		menu_button.add_theme_font_size_override("font_size", 24)
	%SettingsTitle.text = LocalizationSystem.tr_key("settings")
	%ControlsTitle.text = LocalizationSystem.tr_key("controls_title")
	%LanguageLabel.text = LocalizationSystem.tr_key("language")
	%MusicLabel.text = LocalizationSystem.tr_key("music_volume")
	%SfxLabel.text = LocalizationSystem.tr_key("sfx_volume")
	%FullscreenLabel.text = LocalizationSystem.tr_key("fullscreen")
	%ShakeLabel.text = LocalizationSystem.tr_key("screen_shake")
	%HitStopLabel.text = LocalizationSystem.tr_key("hit_stop")
	%CloseSettingsButton.text = LocalizationSystem.tr_key("close")
	# 按存档是否存在显示继续按钮；ContinueButton 在场景里默认隐藏。
	%ContinueButton.visible = SaveSystem.has_save()

func _connect_buttons() -> void:
	%StartButton.pressed.connect(_start_game)
	%ContinueButton.pressed.connect(_continue_game)
	%SettingsButton.pressed.connect(_toggle_settings)
	%QuitButton.pressed.connect(func(): get_tree().quit())
	%CloseSettingsButton.pressed.connect(func(): %SettingsPanel.visible = false)
	%StartButton.grab_focus()
	_connect_settings()

func _connect_settings() -> void:
	%MusicSlider.value = SettingsSystem.music_volume
	%MusicSlider.value_changed.connect(SettingsSystem.set_music_volume)
	%SfxSlider.value = SettingsSystem.sfx_volume
	%SfxSlider.value_changed.connect(SettingsSystem.set_sfx_volume)
	%FullscreenCheck.button_pressed = SettingsSystem.fullscreen
	%FullscreenCheck.toggled.connect(SettingsSystem.set_fullscreen)
	%ShakeCheck.button_pressed = SettingsSystem.shake_enabled
	%ShakeCheck.toggled.connect(SettingsSystem.set_shake_enabled)
	%HitStopCheck.button_pressed = SettingsSystem.hit_stop_enabled
	%HitStopCheck.toggled.connect(SettingsSystem.set_hit_stop_enabled)
	%LanguageOption.add_item("中文")
	%LanguageOption.set_item_metadata(0, "zh")
	%LanguageOption.add_item("English")
	%LanguageOption.set_item_metadata(1, "en")
	%LanguageOption.selected = 0 if LocalizationSystem.language == "zh" else 1
	%LanguageOption.item_selected.connect(func(index: int):
		LocalizationSystem.set_language(str(%LanguageOption.get_item_metadata(index)))
	)
	for action in SettingsSystem.REBINDABLE_ACTIONS:
		_add_setting_keybind(%KeybindsBox, action)

func _spawn_scenery() -> void:
	# 按屏幕高度逐像素生成天空渐变，避免低分辨率 GradientTexture2D 被拉伸出色带。
	%Gradient.texture = _make_gradient_texture(Palette.SKY_TOP, Palette.SKY_BOTTOM)
	for cloud in [%Cloud1, %Cloud2, %Cloud3, %Cloud4, %Cloud5]:
		_clouds.append({"node": cloud, "speed": float(cloud.get_meta("speed", 14.0))})
	_add_pixel_mountain(%Scenery, Vector2(210, 552), 150.0, 190.0, Palette.MOUNTAIN, true)
	_add_pixel_mountain(%Scenery, Vector2(1060, 552), 120.0, 150.0, Palette.MOUNTAIN_DARK, true)
	for tree_position in [Vector2(96, 544), Vector2(348, 544), Vector2(918, 544), Vector2(1178, 544)]:
		_add_tree(%Scenery, tree_position)
	_spawn_ground_details(%Scenery)
	_spawn_decor(%Decor)

func _add_pixel_mountain(parent: Control, base_center: Vector2, half_width: float, height: float, body_color: Color, with_snow: bool) -> void:
	var rows := int(height / 10.0)
	for row in rows:
		var t := float(row) / float(rows)
		var row_width := half_width * t * 2.0
		var rect := ColorRect.new()
		rect.color = body_color
		rect.position = Vector2(base_center.x - row_width * 0.5, base_center.y - height + float(row) * 10.0)
		rect.size = Vector2(row_width, 10.0)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(rect)
	if with_snow:
		var cap := ColorRect.new()
		cap.color = Palette.SNOW
		cap.position = Vector2(base_center.x - half_width * 0.22, base_center.y - height)
		cap.size = Vector2(half_width * 0.44, 22.0)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(cap)

func _add_tree(parent: Control, base_position: Vector2) -> void:
	var trunk := ColorRect.new()
	trunk.color = Palette.TRUNK
	trunk.position = base_position + Vector2(-6, -34)
	trunk.size = Vector2(12, 34)
	parent.add_child(trunk)
	var canopy_layers := [
		[-28.0, 56.0, Palette.TREE_DARK],
		[-40.0, 40.0, Palette.TREE],
		[-50.0, 22.0, Palette.TREE],
	]
	for layer in canopy_layers:
		var leaf := ColorRect.new()
		leaf.color = layer[2]
		leaf.position = base_position + Vector2(-layer[1] * 0.5, layer[0])
		leaf.size = Vector2(layer[1], 15.0)
		parent.add_child(leaf)

func _make_gradient_texture(top: Color, bottom: Color) -> Texture2D:
	var img := Image.create(2, int(VIEW_H), false, Image.FORMAT_RGBA8)
	for y in int(VIEW_H):
		var c := top.lerp(bottom, float(y) / float(VIEW_H - 1.0))
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	return ImageTexture.create_from_image(img)

func _spawn_ground_details(parent: Control) -> void:
	for x in range(0, int(VIEW_W), 26):
		var blade := ColorRect.new()
		blade.color = Palette.GRASS_LIGHT
		blade.position = Vector2(float(x) + 6.0, VIEW_H - 186.0)
		blade.size = Vector2(6.0, 8.0)
		blade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(blade)
	for spot in [176.0, 610.0, 772.0, 1216.0]:
		var stem := ColorRect.new()
		stem.color = Palette.GRASS_DARK
		stem.position = Vector2(spot, VIEW_H - 186.0)
		stem.size = Vector2(4.0, 14.0)
		parent.add_child(stem)
		var petal := ColorRect.new()
		petal.color = Palette.RED if int(spot) % 2 == 0 else Palette.YELLOW
		petal.position = Vector2(spot - 3.0, VIEW_H - 196.0)
		petal.size = Vector2(10.0, 10.0)
		parent.add_child(petal)

func _spawn_decor(parent: Control) -> void:
	var slime_tex: Texture2D = PixelStyleManager.make_enemy_texture("slime")
	var slime_size := Vector2(slime_tex.get_width(), slime_tex.get_height()) * 3.2
	for i in 3:
		var slime := TextureRect.new()
		slime.texture = slime_tex
		slime.stretch_mode = TextureRect.STRETCH_SCALE
		slime.size = slime_size
		slime.position = Vector2([300.0, 640.0, 950.0][i], VIEW_H - 172.0 - slime_size.y)
		slime.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(slime)
		_slimes.append({"node": slime, "base_y": slime.position.y, "phase": float(i) * 2.1})

	var coin := TextureRect.new()
	coin.texture = PixelStyleManager.make_coin_texture()
	coin.stretch_mode = TextureRect.STRETCH_SCALE
	coin.size = Vector2(30.0, 30.0)
	coin.position = Vector2(475.0, VIEW_H - 222.0)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(coin)
	_slimes.append({"node": coin, "base_y": coin.position.y, "phase": 1.3})

func _add_setting_keybind(parent: VBoxContainer, action: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := Label.new()
	label.text = LocalizationSystem.action_label(action)
	label.custom_minimum_size = Vector2(140, 36)
	label.add_theme_color_override("font_color", Palette.OUTLINE)
	label.add_theme_font_size_override("font_size", 17)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var button := Button.new()
	button.name = "Keybind_%s" % action
	button.add_to_group("keybind_buttons")
	button.custom_minimum_size = Vector2(200, 36)
	button.set_meta("action", action)
	button.pressed.connect(func(): _start_rebind(action))
	row.add_child(button)
	var reset := Button.new()
	reset.text = LocalizationSystem.tr_key("reset")
	reset.custom_minimum_size = Vector2(76, 36)
	reset.pressed.connect(func():
		SettingsSystem.reset_action_key(action)
		_refresh_keybind_buttons()
	)
	row.add_child(reset)
	_refresh_keybind_button(button)

func _start_rebind(action: String) -> void:
	_rebinding_action = action
	_refresh_keybind_buttons()

func _refresh_keybind_buttons() -> void:
	for button in get_tree().get_nodes_in_group("keybind_buttons"):
		_refresh_keybind_button(button as Button)

func _refresh_keybind_button(button: Button) -> void:
	if button == null:
		return
	var action := str(button.get_meta("action", ""))
	var waiting_text := LocalizationSystem.tr_key("press_key")
	button.text = waiting_text if action == _rebinding_action else SettingsSystem.get_action_key(action)

func _animate_clouds(delta: float) -> void:
	for entry in _clouds:
		var cloud: Control = entry["node"]
		cloud.position.x += entry["speed"] * delta
		if cloud.position.x > VIEW_W + 40.0:
			cloud.position.x = -220.0

func _animate_sun() -> void:
	%SunGlow.modulate.a = 0.8 + sin(_time * 1.3) * 0.2

func _animate_title() -> void:
	var bob := sin(_time * 1.7) * 7.0
	%TitleLabel.position.y = TITLE_BASE_Y + bob
	%TitleShadow.position.y = TITLE_BASE_Y + bob + 5.0

func _animate_slimes() -> void:
	for entry in _slimes:
		var node: Control = entry["node"]
		var bounce := absf(sin(_time * 3.4 + entry["phase"]))
		node.position.y = entry["base_y"] - bounce * 16.0
		node.pivot_offset = node.size * 0.5
		node.scale = Vector2(1.0 + bounce * 0.04, 1.0 - bounce * 0.04)

func _start_game() -> void:
	GameState.reset_run()
	# 标记走加载界面路径：world_map 会在加载层下分阶段搭建世界。
	GameState.pending_loading_screen = true
	get_tree().change_scene_to_file("res://scenes/levels/world_map.tscn")

func _toggle_settings() -> void:
	%SettingsPanel.visible = not %SettingsPanel.visible

func _continue_game() -> void:
	var loaded := SaveSystem.load_game()
	if not loaded:
		# 存档损坏或版本不匹配时回退新开局，避免按钮看起来完全失效。
		push_warning("TitleScreen: save file exists but failed to load, starting a new run.")
	GameState.pending_loading_screen = true
	GameState.pending_restore_save = loaded
	get_tree().change_scene_to_file("res://scenes/levels/world_map.tscn")
