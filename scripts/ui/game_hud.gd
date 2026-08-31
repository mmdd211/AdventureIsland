extends CanvasLayer

const WorldMapDisplayScript := preload("res://scripts/ui/world_map_display.gd")
const WorldMaps := preload("res://scripts/world/world_maps.gd")
const Palette := preload("res://scripts/systems/pixel_palette.gd")
const PixelUI := preload("res://scripts/ui/pixel_ui.gd")

var hp_bar: ProgressBar
var hp_value: Label
var exp_bar: ProgressBar
var exp_value: Label
var level_label: Label
var coin_label: Label
var coin_icon: TextureRect
var weapon_icon: TextureRect
var armor_icon: TextureRect
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
	GameState.equipment_changed.connect(_refresh_equipment_icons)
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
	minimap_panel.offset_left = -314.0
	minimap_panel.offset_right = -14.0
	minimap_panel.offset_top = 14.0
	minimap_panel.offset_bottom = 118.0
	var map_style := PixelUI.panel_style(Color(Palette.OUTLINE_SOFT, 0.90), Palette.YELLOW_LIGHT)
	minimap_panel.add_theme_stylebox_override("panel", map_style)
	root.add_child(minimap_panel)

	var minimap := WorldMapDisplayScript.new()
	minimap.name = "ZoneMiniMap"
	minimap.compact = true
	minimap.custom_minimum_size = Vector2(286, 84)
	minimap_panel.add_child(minimap)

	zone_banner = PanelContainer.new()
	zone_banner.name = "ZoneBanner"
	zone_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	zone_banner.offset_left = -190.0
	zone_banner.offset_right = 190.0
	zone_banner.offset_top = 108.0
	zone_banner.offset_bottom = 164.0
	zone_banner.custom_minimum_size = Vector2(380, 56)
	var banner_style := PixelUI.panel_style(Color(Palette.WHITE, 0.94), Palette.OUTLINE)
	zone_banner.add_theme_stylebox_override("panel", banner_style)
	zone_banner.visible = false
	zone_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(zone_banner)

	zone_banner_label = Label.new()
	zone_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zone_banner_label.add_theme_font_size_override("font_size", 26)
	zone_banner_label.add_theme_color_override("font_color", Color(Palette.GRASS_DARK))
	zone_banner_label.add_theme_color_override("font_outline_color", Palette.WHITE)
	zone_banner_label.add_theme_constant_override("outline_size", 7)
	zone_banner.add_child(zone_banner_label)

	var top := PanelContainer.new()
	top.name = "StatusPanel"
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = 0.0
	top.offset_top = 0.0
	var style := PixelUI.panel_style(Color(Palette.WHITE, 0.90), Palette.OUTLINE)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	top.add_theme_stylebox_override("panel", style)
	root.add_child(top)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	top.add_child(stack)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	stack.add_child(hp_row)
	var hp_icon := _make_label("♥", 15, Color("d8404d"))
	hp_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_icon.custom_minimum_size = Vector2(18, 17)
	hp_row.add_child(hp_icon)

	hp_bar = PixelUI.make_bar(Vector2(148, 16), Color("b52f3b"), Color("ff7b84"))
	hp_bar.name = "HPBar"
	hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_row.add_child(hp_bar)

	hp_value = _make_label("100 / 100", 11, Palette.OUTLINE)
	hp_row.add_child(hp_value)

	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 8)
	stack.add_child(exp_row)
	var exp_icon := _make_label("★", 14, Color("2c8fb8"))
	exp_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_icon.custom_minimum_size = Vector2(18, 17)
	exp_row.add_child(exp_icon)
	exp_bar = PixelUI.make_bar(Vector2(148, 16), Color("2c8fb8"), Color("a5ecff"))
	exp_bar.max_value = 100
	exp_row.add_child(exp_bar)
	exp_value = _make_label("Lv.1 0/100", 11, Palette.OUTLINE_SOFT)
	exp_row.add_child(exp_value)

	var data_row := HBoxContainer.new()
	data_row.add_theme_constant_override("separation", 8)
	stack.add_child(data_row)

	level_label = _make_label("Lv.1", 12, Palette.GRASS_DARK)
	data_row.add_child(level_label)

	coin_icon = TextureRect.new()
	coin_icon.texture = PixelStyleManager.make_coin_texture()
	coin_icon.stretch_mode = TextureRect.STRETCH_SCALE
	coin_icon.custom_minimum_size = Vector2(17, 17)
	data_row.add_child(coin_icon)

	coin_label = _make_label("0", 13, Palette.DIRT_OUTLINE)
	data_row.add_child(coin_label)

	score_label = _make_label("SCORE 0", 10, Palette.OUTLINE_SOFT)
	data_row.add_child(score_label)

	time_label = _make_label("00:00", 11, Palette.OUTLINE_SOFT)
	data_row.add_child(time_label)

	var equipment_row := HBoxContainer.new()
	equipment_row.alignment = BoxContainer.ALIGNMENT_END
	equipment_row.add_theme_constant_override("separation", 6)
	stack.add_child(equipment_row)

	weapon_icon = TextureRect.new()
	weapon_icon.texture = PixelStyleManager.make_equipment_texture(GameState.equipped_weapon_id)
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_icon.custom_minimum_size = Vector2(16, 16)
	equipment_row.add_child(weapon_icon)
	armor_icon = TextureRect.new()
	armor_icon.texture = PixelStyleManager.make_equipment_texture(GameState.equipped_armor_id)
	armor_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	armor_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	armor_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	armor_icon.custom_minimum_size = Vector2(16, 16)
	equipment_row.add_child(armor_icon)
	_refresh_equipment_icons()

func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(Palette.WHITE, 0.92))
	label.add_theme_constant_override("outline_size", 4)
	return label

func _process(_delta: float) -> void:
	time_label.text = GameState.get_formatted_time(GameState.elapsed_time)
	_refresh(GameState.current_hp, GameState.max_hp)

func _show_zone_banner(zone_id: String) -> void:
	var maps := load("res://scripts/world/world_maps.gd")
	if WorldMaps.ORDER.find(zone_id) < 0:
		return
	var metadata: Dictionary = maps.map_metadata(str(zone_id))
	var theme: Dictionary = metadata.get("theme", {})
	zone_banner_label.text = "%s · %s" % [metadata.get("region_name", ""), metadata.get("display_name", "")]
	var accent := Color("ffd700")
	if theme.has("accent"):
		accent = Color(str(theme.accent))
	zone_banner.get_theme_stylebox("panel").border_color = accent
	zone_banner_label.add_theme_color_override("font_color", accent.darkened(0.28))
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
	coin_label.text = "%d / %d" % [GameState.collected_coin_pickups, GameState.total_coin_pickups]
	score_label.text = "SCORE %d" % GameState.score

func _refresh_equipment_icons() -> void:
	if weapon_icon == null or armor_icon == null:
		return
	weapon_icon.texture = PixelStyleManager.make_equipment_texture(GameState.equipped_weapon_id)
	armor_icon.texture = PixelStyleManager.make_equipment_texture(GameState.equipped_armor_id)
