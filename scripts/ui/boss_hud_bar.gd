extends CanvasLayer

const Palette := preload("res://scripts/systems/pixel_palette.gd")

var root: Control
var name_label: Label
var form_label: Label
var fill: ColorRect
var damage_fill: ColorRect
var evolve_label: Label
var shown_health := 1.0

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func bind(boss_name: String, region_id: String) -> void:
	name_label.text = boss_name
	visible = true

func set_form(form_name: String, form_index: int, form_total: int) -> void:
	form_label.text = "%d/%d · %s" % [form_index + 1, form_total, form_name]
	fill.color = Color("ffd166") if form_index == 0 else Color("ff6a70")

func set_health(current: float, maximum: float) -> void:
	shown_health = clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	fill.size.x = 504.0 * shown_health

func show_evolution(message: String) -> void:
	evolve_label.text = message
	evolve_label.visible = true

func hide_evolution() -> void:
	evolve_label.visible = false

func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -290.0
	panel.offset_right = 290.0
	panel.offset_top = 12.0
	panel.offset_bottom = 83.0
	var style := PixelUI.panel_style(Color(Palette.OUTLINE_SOFT, 0.92), Palette.YELLOW_LIGHT, 5)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)
	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	name_label = Label.new()
	form_label = Label.new()
	for label in [name_label, form_label]:
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(Palette.WHITE))
		label.add_theme_color_override("font_outline_color", Color(Palette.OUTLINE))
		label.add_theme_constant_override("outline_size", 4)
	title.add_child(name_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(22, 0)
	title.add_child(spacer)
	title.add_child(form_label)
	content.add_child(title)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(520, 21)
	content.add_child(bar)
	var background := ColorRect.new()
	background.color = Color(Palette.OUTLINE, 0.80)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(background)
	damage_fill = ColorRect.new()
	damage_fill.color = Color("9b2431")
	damage_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(damage_fill)
	fill = ColorRect.new()
	fill.color = Color("ffd166")
	fill.position = Vector2(3, 3)
	fill.size = Vector2(514, 15)
	bar.add_child(fill)

	evolve_label = Label.new()
	evolve_label.set_anchors_preset(Control.PRESET_CENTER)
	evolve_label.add_theme_font_size_override("font_size", 30)
	evolve_label.add_theme_color_override("font_color", Color(Palette.WHITE))
	evolve_label.add_theme_color_override("font_outline_color", Color(Palette.OUTLINE))
	evolve_label.add_theme_constant_override("outline_size", 8)
	evolve_label.visible = false
	root.add_child(evolve_label)
