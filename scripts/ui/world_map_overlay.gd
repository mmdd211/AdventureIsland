extends CanvasLayer

const WorldMapDisplayScript := preload("res://scripts/ui/world_map_display.gd")
const Palette := preload("res://scripts/systems/pixel_palette.gd")
const PixelUI := preload("res://scripts/ui/pixel_ui.gd")

var root: Control
var map_display: Control
var close_button: Button

func _ready() -> void:
	layer = 29
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func open_map() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	if close_button:
		close_button.grab_focus()

func close_map() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false

func _build_ui() -> void:
	root = Control.new()
	root.name = "MapRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.68)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	var style := PixelUI.panel_style(Color(Palette.WHITE, 0.97), Palette.OUTLINE, 8)
	style.border_width_top = 4
	style.border_width_bottom = 8
	style.shadow_size = 7
	style.content_margin_left = 26.0
	style.content_margin_right = 26.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 22.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var title := Label.new()
	title.text = "冒险岛世界地图"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Palette.GRASS_DARK)
	title.add_theme_color_override("font_outline_color", Palette.WHITE)
	title.add_theme_constant_override("outline_size", 8)
	content.add_child(title)

	map_display = WorldMapDisplayScript.new()
	map_display.compact = false
	map_display.custom_minimum_size = Vector2(940, 460)
	map_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(map_display)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "关闭地图"
	close_button.custom_minimum_size = Vector2(220, 44)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	PixelUI.style_button(close_button, true)
	close_button.pressed.connect(close_map)
	content.add_child(close_button)
