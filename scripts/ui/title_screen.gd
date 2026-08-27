extends Control

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const VIEW_W := 1280.0
const VIEW_H := 720.0
const TITLE_BASE_Y := 132.0

var _time := 0.0
var _clouds: Array = []
var _slimes: Array = []
var _sun_glow: ColorRect
var _title: Label
var _title_shadow: Label

func _ready() -> void:
	AudioManager.play_music("title")
	_build_scene()
	var start_button := get_node("Content/Menu/StartButton") as Button
	var quit_button := get_node("Content/Menu/QuitButton") as Button
	start_button.pressed.connect(_start_game)
	quit_button.pressed.connect(func(): get_tree().quit())
	start_button.grab_focus()
	# UI 建好后再把关卡 BGM 的波形合成排到空闲帧，
	# 用异步分块合成，标题屏停留期间就把音乐准备好。
	AudioManager.call_deferred("preload_music_async", "level")

func _process(delta: float) -> void:
	_time += delta
	_animate_clouds(delta)
	_animate_sun()
	_animate_title()
	_animate_slimes()

func _build_scene() -> void:
	_build_sky()
	_build_mountains()
	_build_ground()
	_build_content()
	_build_bottom_hint()

func _build_sky() -> void:
	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.texture = _make_gradient_texture(Palette.SKY_TOP, Palette.SKY_BOTTOM)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	_sun_glow = ColorRect.new()
	_sun_glow.color = Color(Palette.YELLOW_LIGHT, 0.42)
	_sun_glow.position = Vector2(908, 58)
	_sun_glow.size = Vector2(184, 184)
	sky.add_child(_sun_glow)

	var sun := ColorRect.new()
	sun.color = Palette.YELLOW
	sun.position = Vector2(938, 88)
	sun.size = Vector2(124, 124)
	sky.add_child(sun)
	_add_clouds(sky)

func _add_clouds(sky: Control) -> void:
	var seedlings := [
		[90.0, 96.0, 1.15, 13.0],
		[420.0, 172.0, 0.8, 21.0],
		[700.0, 84.0, 0.95, 17.0],
		[980.0, 226.0, 0.62, 25.0],
		[1150.0, 140.0, 0.88, 11.0],
	]
	for seedling in seedlings:
		var cloud := _make_cloud(seedling[2])
		cloud.position = Vector2(seedling[0], seedling[1])
		sky.add_child(cloud)
		_clouds.append({"node": cloud, "speed": seedling[3]})

func _make_cloud(scale_factor: float) -> Control:
	var cloud := Control.new()
	cloud.scale = Vector2(scale_factor, scale_factor)
	var main := ColorRect.new()
	main.color = Palette.CLOUD
	main.position = Vector2.ZERO
	main.size = Vector2(150, 38)
	cloud.add_child(main)
	var top := ColorRect.new()
	top.color = Palette.CLOUD
	top.position = Vector2(34, -18)
	top.size = Vector2(74, 22)
	cloud.add_child(top)
	var shade := ColorRect.new()
	shade.color = Palette.CLOUD_SHADE
	shade.position = Vector2(0, 30)
	shade.size = Vector2(150, 8)
	cloud.add_child(shade)
	return cloud

func _build_mountains() -> void:
	var sky := get_node("Sky") as Control
	# 两座台阶式像素雪山 + 一排树林剪影，让地平线有远近层次。
	_add_pixel_mountain(sky, Vector2(210, 552), 150.0, 190.0, Palette.MOUNTAIN, true)
	_add_pixel_mountain(sky, Vector2(1060, 552), 120.0, 150.0, Palette.MOUNTAIN_DARK, true)
	_add_tree(sky, Vector2(96, 544))
	_add_tree(sky, Vector2(348, 544))
	_add_tree(sky, Vector2(918, 544))
	_add_tree(sky, Vector2(1178, 544))

func _add_pixel_mountain(parent: Control, base_center: Vector2, half_width: float, height: float, body_color: Color, with_snow: bool) -> void:
	var rows := int(height / 10.0)
	for row in rows:
		var t := float(row) / float(rows)
		var row_width := half_width * t * 2.0
		var rect := ColorRect.new()
		rect.color = body_color
		rect.position = Vector2(base_center.x - row_width * 0.5, base_center.y - height + float(row) * 10.0)
		rect.size = Vector2(row_width, 10.0)
		parent.add_child(rect)
	if with_snow:
		var cap := ColorRect.new()
		cap.color = Palette.SNOW
		cap.position = Vector2(base_center.x - half_width * 0.22, base_center.y - height)
		cap.size = Vector2(half_width * 0.44, 22.0)
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

func _build_ground() -> void:
	var sky := get_node("Sky") as Control
	var dirt := ColorRect.new()
	dirt.color = Palette.DIRT
	dirt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dirt.offset_top = -148.0
	sky.add_child(dirt)

	var grass := ColorRect.new()
	grass.color = Palette.GRASS
	grass.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grass.offset_top = -172.0
	grass.offset_bottom = -104.0
	sky.add_child(grass)

	var grass_top := ColorRect.new()
	grass_top.color = Palette.GRASS_LIGHT
	grass_top.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grass_top.offset_top = -178.0
	grass_top.offset_bottom = -164.0
	sky.add_child(grass_top)

	# 草齿：沿草线等距小竖条，像素草地读起来更活。
	for x in range(0, int(VIEW_W), 26):
		var blade := ColorRect.new()
		blade.color = Palette.GRASS_LIGHT
		blade.position = Vector2(float(x) + 6.0, VIEW_H - 186.0)
		blade.size = Vector2(6.0, 8.0)
		sky.add_child(blade)

	var dirt_shade := ColorRect.new()
	dirt_shade.color = Palette.DIRT_DARK
	dirt_shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dirt_shade.offset_top = -60.0
	sky.add_child(dirt_shade)

	_build_flowers(sky)
	_build_slimes(sky)

func _build_flowers(parent: Control) -> void:
	var spots := [176.0, 610.0, 772.0, 1216.0]
	for spot in spots:
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

func _build_slimes(parent: Control) -> void:
	var slime_tex: Texture2D = PixelStyleManager.make_enemy_texture("slime")
	var slime_size := Vector2(slime_tex.get_width(), slime_tex.get_height()) * 3.2
	var spots := [300.0, 640.0, 950.0]
	for i in spots.size():
		var slime := TextureRect.new()
		slime.texture = slime_tex
		slime.stretch_mode = TextureRect.STRETCH_SCALE
		slime.size = slime_size
		slime.position = Vector2(spots[i], VIEW_H - 172.0 - slime_size.y)
		parent.add_child(slime)
		_slimes.append({"node": slime, "base_y": slime.position.y, "phase": float(i) * 2.1})

	var coin := TextureRect.new()
	coin.texture = PixelStyleManager.make_coin_texture()
	coin.stretch_mode = TextureRect.STRETCH_SCALE
	coin.size = Vector2(30.0, 30.0)
	coin.position = Vector2(475.0, VIEW_H - 222.0)
	coin.name = "DecorCoin"
	parent.add_child(coin)
	_slimes.append({"node": coin, "base_y": coin.position.y, "phase": 1.3})

func _build_content() -> void:
	# 普通容器而非 VBox：标题浮动动画直接改 position，不被容器重排。
	var content := Control.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	_title_shadow = Label.new()
	_title_shadow.name = "TitleShadow"
	_title_shadow.text = "冒险岛物语"
	_title_shadow.add_theme_font_size_override("font_size", 76)
	_title_shadow.add_theme_color_override("font_color", Palette.OUTLINE)
	_title_shadow.size = Vector2(VIEW_W, 96)
	_title_shadow.position = Vector2(0, TITLE_BASE_Y + 5.0)
	_title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_title_shadow)

	_title = Label.new()
	_title.name = "TitleLabel"
	_title.text = "冒险岛物语"
	_title.add_theme_font_size_override("font_size", 76)
	_title.add_theme_color_override("font_color", Palette.WHITE)
	_title.add_theme_color_override("font_outline_color", Palette.GRASS_DARK)
	_title.add_theme_constant_override("outline_size", 16)
	_title.size = Vector2(VIEW_W, 96)
	_title.position = Vector2(0, TITLE_BASE_Y)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_title)

	var subtitle := Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "横版冒险 · 六区域主题世界"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("173a52"))
	subtitle.add_theme_color_override("font_outline_color", Palette.WHITE)
	subtitle.add_theme_constant_override("outline_size", 6)
	subtitle.size = Vector2(VIEW_W, 32)
	subtitle.position = Vector2(0, 246.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)

	var menu := VBoxContainer.new()
	menu.name = "Menu"
	menu.position = Vector2((VIEW_W - 240.0) * 0.5, 336.0)
	menu.size = Vector2(240, 156)
	menu.add_theme_constant_override("separation", 18)
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(menu)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "开始冒险"
	start.custom_minimum_size = Vector2(240, 56)
	_style_menu_button(start, true)
	menu.add_child(start)

	var quit := Button.new()
	quit.name = "QuitButton"
	quit.text = "离开"
	quit.custom_minimum_size = Vector2(240, 46)
	_style_menu_button(quit, false)
	menu.add_child(quit)

func _style_menu_button(button: Button, primary: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Palette.GRASS if primary else Palette.WOOD
	normal.border_color = Palette.DIRT_OUTLINE
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	normal.shadow_color = Color(Palette.OUTLINE, 0.35)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 3)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Palette.GRASS_LIGHT if primary else Palette.WOOD_LIGHT

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Palette.GRASS_DARK if primary else Palette.WOOD_DARK
	pressed.shadow_size = 0
	pressed.shadow_offset = Vector2.ZERO

	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Palette.YELLOW
	focus.set_border_width_all(4)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Palette.WHITE)
	button.add_theme_color_override("font_hover_color", Palette.WHITE)
	button.add_theme_color_override("font_pressed_color", Palette.CLOUD_SHADE)
	button.add_theme_color_override("font_focus_color", Palette.WHITE)
	button.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	button.add_theme_constant_override("outline_size", 5)

func _build_bottom_hint() -> void:
	var bottom_margin := MarginContainer.new()
	bottom_margin.name = "BottomMargin"
	bottom_margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_margin.offset_top = -76.0
	bottom_margin.offset_bottom = -22.0
	bottom_margin.add_theme_constant_override("margin_bottom", 30)
	bottom_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_margin)

	var controls := Label.new()
	controls.name = "ControlsLabel"
	controls.text = "A/D 移动   W/空格 跳跃   J 攻击   K/Shift 冲刺"
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_color", Palette.WHITE)
	controls.add_theme_color_override("font_outline_color", Palette.OUTLINE_SOFT)
	controls.add_theme_constant_override("outline_size", 5)
	controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_margin.add_child(controls)

func _animate_clouds(delta: float) -> void:
	for entry in _clouds:
		var cloud: Control = entry["node"]
		cloud.position.x += entry["speed"] * delta
		if cloud.position.x > VIEW_W + 40.0:
			cloud.position.x = -220.0

func _animate_sun() -> void:
	if _sun_glow:
		_sun_glow.modulate.a = 0.8 + sin(_time * 1.3) * 0.2

func _animate_title() -> void:
	var bob := sin(_time * 1.7) * 7.0
	_title.position.y = TITLE_BASE_Y + bob
	_title_shadow.position.y = TITLE_BASE_Y + bob + 5.0

func _animate_slimes() -> void:
	for entry in _slimes:
		var node: Control = entry["node"]
		var bounce := absf(sin(_time * 3.4 + entry["phase"]))
		node.position.y = entry["base_y"] - bounce * 16.0
		node.pivot_offset = node.size * 0.5
		node.scale = Vector2(1.0 + bounce * 0.04, 1.0 - bounce * 0.04)

func _make_gradient_texture(top: Color, bottom: Color) -> Texture2D:
	var img := Image.create(2, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var c := top.lerp(bottom, float(y) / 63.0)
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	return ImageTexture.create_from_image(img)

func _start_game() -> void:
	GameState.reset_run()
	# 标记走加载界面路径：world_map 会在加载层下分阶段搭建世界。
	GameState.pending_loading_screen = true
	get_tree().change_scene_to_file("res://scenes/levels/world_map.tscn")
