extends Control

const Palette := preload("res://scripts/systems/pixel_palette.gd")

func _ready() -> void:
	AudioManager.play_music("title")
	_build_ui()
	var start_button := get_node("Content/Menu/StartButton") as Button
	var quit_button := get_node("Content/Menu/QuitButton") as Button
	start_button.pressed.connect(_start_game)
	quit_button.pressed.connect(func(): get_tree().quit())
	start_button.grab_focus()

func _build_ui() -> void:
	var sky := ColorRect.new()
	sky.name = "Sky"
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Palette.SKY_TOP
	add_child(sky)

	var sun := ColorRect.new()
	sun.color = Palette.YELLOW_LIGHT
	sun.position = Vector2(940, 90)
	sun.size = Vector2(120, 120)
	sky.add_child(sun)

	var hills := ColorRect.new()
	hills.color = Palette.GRASS_DARK
	hills.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hills.offset_top = -220.0
	sky.add_child(hills)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "冒险岛物语"
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Palette.OUTLINE)
	title.add_theme_color_override("font_outline_color", Palette.WHITE)
	title.add_theme_constant_override("outline_size", 14)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "横版冒险 · 完整小关卡"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("173a52"))
	subtitle.add_theme_color_override("font_outline_color", Palette.WHITE)
	subtitle.add_theme_constant_override("outline_size", 5)
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)

	var menu := VBoxContainer.new()
	menu.name = "Menu"
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_theme_constant_override("separation", 16)
	content.add_child(menu)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "开始冒险"
	start.custom_minimum_size = Vector2(220, 52)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_child(start)

	var quit := Button.new()
	quit.name = "QuitButton"
	quit.text = "离开"
	quit.custom_minimum_size = Vector2(220, 52)
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_child(quit)

	var bottom_margin := MarginContainer.new()
	bottom_margin.name = "BottomMargin"
	bottom_margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_margin.offset_top = -72.0
	bottom_margin.offset_bottom = -24.0
	bottom_margin.add_theme_constant_override("margin_bottom", 30)
	bottom_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_margin)

	var controls := Label.new()
	controls.name = "ControlsLabel"
	controls.text = "A/D 移动   W/空格 跳跃   J 攻击   K/Shift 冲刺"
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_color", Color("173a25"))
	controls.add_theme_color_override("font_outline_color", Palette.CLOUD_SHADE)
	controls.add_theme_constant_override("outline_size", 5)
	controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_margin.add_child(controls)

func _start_game() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/levels/world01.tscn")
