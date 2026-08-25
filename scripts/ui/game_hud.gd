extends CanvasLayer

var hp_bar: ProgressBar
var hp_value: Label
var exp_bar: ProgressBar
var exp_value: Label
var level_label: Label
var coin_label: Label
var score_label: Label
var time_label: Label

func _ready() -> void:
	layer = 20
	_build_ui()
	GameState.hp_changed.connect(func(current, maximum): _refresh(current, maximum))
	GameState.exp_changed.connect(func(_current, _required, _level): _refresh(GameState.current_hp, GameState.max_hp))
	GameState.coins_changed.connect(func(_coins): _refresh(GameState.current_hp, GameState.max_hp))
	_refresh(GameState.current_hp, GameState.max_hp)

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14.0
	top.offset_right = -14.0
	top.offset_top = 12.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.16, 0.78)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	top.add_theme_stylebox_override("panel", style)
	root.add_child(top)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	top.add_child(columns)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 5)
	columns.add_child(left)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(hp_row)
	var hp_icon := _make_label("♥", 18, Color("e84855"))
	hp_row.add_child(hp_icon)

	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.custom_minimum_size = Vector2(280, 16)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0, 0, 0, 0.62)
	hp_bg.set_corner_radius_all(5)
	hp_bg.content_margin_left = 2.0
	hp_bg.content_margin_right = 2.0
	hp_bg.content_margin_top = 2.0
	hp_bg.content_margin_bottom = 2.0
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("e84855")
	hp_fill.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_row.add_child(hp_bar)

	var hp_value_row := HBoxContainer.new()
	hp_value_row.add_theme_constant_override("separation", 8)
	left.add_child(hp_value_row)
	hp_value = _make_label("100 / 100", 13, Color("ffffff"))
	hp_value_row.add_child(hp_value)

	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 8)
	exp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(exp_row)
	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(220, 9)
	exp_bar.max_value = 100
	exp_bar.show_percentage = false
	var exp_bg := StyleBoxFlat.new()
	exp_bg.bg_color = Color(0, 0, 0, 0.55)
	exp_bg.set_corner_radius_all(4)
	var exp_fill := StyleBoxFlat.new()
	exp_fill.bg_color = Color("61d6ff")
	exp_fill.set_corner_radius_all(4)
	exp_bar.add_theme_stylebox_override("background", exp_bg)
	exp_bar.add_theme_stylebox_override("fill", exp_fill)
	exp_row.add_child(exp_bar)
	exp_value = _make_label("Lv.1 0/100", 12, Color("c8f4ff"))
	exp_row.add_child(exp_value)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 2)
	columns.add_child(right)
	level_label = _make_label("Lv.1", 18, Color("ffd700"))
	right.add_child(level_label)
	coin_label = _make_label("◉ 0", 18, Color("ffd700"))
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(coin_label)
	score_label = _make_label("SCORE 0", 12, Color("ffffff"))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(score_label)
	time_label = _make_label("00:00", 12, Color("e8f4ff"))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(time_label)

func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	return label

func _process(_delta: float) -> void:
	time_label.text = GameState.get_formatted_time(GameState.elapsed_time)
	_refresh(GameState.current_hp, GameState.max_hp)

func _refresh(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_value.text = "%d / %d" % [current_hp, max_hp]
	exp_bar.max_value = GameState.required_exp
	exp_bar.value = GameState.current_exp
	exp_value.text = "Lv.%d  %d/%d" % [GameState.current_level, GameState.current_exp, GameState.required_exp]
	level_label.text = "Lv.%d" % GameState.current_level
	coin_label.text = "◉ %d/%d" % [GameState.collected_coin_pickups, GameState.total_coin_pickups]
	score_label.text = "SCORE %d" % GameState.score
