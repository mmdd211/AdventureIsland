extends CanvasLayer

const WorldMapDisplayScript := preload("res://scripts/ui/world_map_display.gd")
const WorldZones := preload("res://scripts/world/world_zones.gd")

var hp_bar: ProgressBar
var hp_value: Label
var exp_bar: ProgressBar
var exp_value: Label
var level_label: Label
var coin_label: Label
var score_label: Label
var time_label: Label
var zone_banner: PanelContainer
var zone_banner_label: Label
var zone_banner_tween: Tween
var zone_banner_timer := 0.0

func _ready() -> void:
	layer = 20
	_build_ui()
	GameState.zone_changed.connect(_show_zone_banner)
	GameState.hp_changed.connect(func(current, maximum): _refresh(current, maximum))
	GameState.exp_changed.connect(func(_current, _required, _level): _refresh(GameState.current_hp, GameState.max_hp))
	GameState.coins_changed.connect(func(_coins): _refresh(GameState.current_hp, GameState.max_hp))
	_refresh(GameState.current_hp, GameState.max_hp)

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var minimap_panel := PanelContainer.new()
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.offset_left = -294.0
	minimap_panel.offset_right = -14.0
	minimap_panel.offset_top = 14.0
	minimap_panel.offset_bottom = 110.0
	var map_style := StyleBoxFlat.new()
	map_style.bg_color = Color(0.05, 0.09, 0.14, 0.76)
	map_style.border_color = Color(1, 1, 1, 0.16)
	map_style.set_border_width_all(1)
	map_style.set_corner_radius_all(8)
	minimap_panel.add_theme_stylebox_override("panel", map_style)
	root.add_child(minimap_panel)

	var minimap := WorldMapDisplayScript.new()
	minimap.name = "ZoneMiniMap"
	minimap.compact = true
	minimap.custom_minimum_size = Vector2(266, 78)
	minimap_panel.add_child(minimap)

	zone_banner = PanelContainer.new()
	zone_banner.name = "ZoneBanner"
	zone_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	zone_banner.offset_left = -170.0
	zone_banner.offset_right = 170.0
	zone_banner.offset_top = 108.0
	zone_banner.offset_bottom = 158.0
	zone_banner.custom_minimum_size = Vector2(340, 52)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.04, 0.07, 0.12, 0.78)
	banner_style.border_color = Color("ffd700")
	banner_style.set_border_width_all(2)
	banner_style.set_corner_radius_all(8)
	zone_banner.add_theme_stylebox_override("panel", banner_style)
	zone_banner.visible = false
	zone_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(zone_banner)

	zone_banner_label = Label.new()
	zone_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zone_banner_label.add_theme_font_size_override("font_size", 26)
	zone_banner_label.add_theme_color_override("font_color", Color.WHITE)
	zone_banner_label.add_theme_color_override("font_outline_color", Color.BLACK)
	zone_banner_label.add_theme_constant_override("outline_size", 7)
	zone_banner.add_child(zone_banner_label)

	var top := PanelContainer.new()
	top.name = "StatusPanel"
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = 14.0
	top.offset_top = 14.0
	top.offset_right = 418.0
	top.offset_bottom = 92.0
	top.custom_minimum_size = Vector2(404, 78)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.16, 0.76)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	top.add_theme_stylebox_override("panel", style)
	root.add_child(top)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	top.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(240, 60)
	left.add_theme_constant_override("separation", 7)
	columns.add_child(left)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	left.add_child(hp_row)
	var hp_icon := _make_label("♥", 14, Color("e84855"))
	hp_row.add_child(hp_icon)

	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.custom_minimum_size = Vector2(136, 12)
	hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
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

	hp_value = _make_label("100 / 100", 12, Color("ffffff"))
	hp_row.add_child(hp_value)

	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 8)
	left.add_child(exp_row)
	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(150, 8)
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
	exp_value = _make_label("Lv.1 0/100", 10, Color("c8f4ff"))
	exp_row.add_child(exp_value)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 2)
	columns.add_child(right)
	level_label = _make_label("Lv.1", 15, Color("ffd700"))
	right.add_child(level_label)
	coin_label = _make_label("◉ 0", 15, Color("ffd700"))
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(coin_label)
	score_label = _make_label("SCORE 0", 10, Color("ffffff"))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(score_label)
	time_label = _make_label("00:00", 10, Color("e8f4ff"))
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

func _show_zone_banner(zone_id: String) -> void:
	if not WorldZones.METADATA.has(zone_id):
		return
	var metadata: Dictionary = WorldZones.METADATA[zone_id]
	var theme: Dictionary = metadata.get("theme", {})
	zone_banner_label.text = metadata.get("display_name", zone_id)
	var accent := Color("ffd700")
	if theme.has("accent"):
		accent = Color(str(theme.accent))
	zone_banner.get_theme_stylebox("panel").border_color = accent
	zone_banner_label.add_theme_color_override("font_color", accent.lightened(0.52))
	zone_banner.visible = true
	zone_banner.modulate.a = 0.0
	if zone_banner_tween:
		zone_banner_tween.kill()
	zone_banner_tween = create_tween()
	zone_banner_tween.tween_property(zone_banner, "modulate:a", 1.0, 0.18)
	zone_banner_tween.tween_interval(1.35)
	zone_banner_tween.tween_property(zone_banner, "modulate:a", 0.0, 0.34)
	zone_banner_tween.tween_callback(func(): zone_banner.visible = false)

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
