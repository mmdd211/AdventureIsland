class_name PixelUI

const Palette := preload("res://scripts/systems/pixel_palette.gd")


static func _panel_style(bg_color: Color, border_color: Color, corner_radius := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.border_width_bottom = 6
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(Palette.OUTLINE, 0.28)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 4)
	return style


static func style_button(button: Button, primary := false) -> void:
	var base := Palette.GRASS if primary else Palette.WOOD
	var hover := Palette.GRASS_LIGHT if primary else Palette.WOOD_LIGHT
	var pressed := Palette.GRASS_DARK if primary else Palette.WOOD_DARK
	var normal := _panel_style(base, Palette.DIRT_OUTLINE, 6)
	normal.set_border_width_all(3)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 3)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 10.0

	var hover_style := normal.duplicate() as StyleBoxFlat
	hover_style.bg_color = hover
	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = pressed
	pressed_style.shadow_size = 0
	pressed_style.shadow_offset = Vector2.ZERO
	var focus_style := normal.duplicate() as StyleBoxFlat
	focus_style.border_color = Palette.YELLOW
	focus_style.set_border_width_all(4)
	focus_style.border_width_bottom = 6

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Palette.WHITE)
	button.add_theme_color_override("font_hover_color", Palette.WHITE)
	button.add_theme_color_override("font_pressed_color", Palette.CLOUD_SHADE)
	button.add_theme_color_override("font_focus_color", Palette.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(Palette.WHITE, 0.62))
	button.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	button.add_theme_color_override("font_disabled_outline_color", Palette.OUTLINE)
	button.add_theme_constant_override("outline_size", 5)

static func icon_button(text: String, texture: Texture2D, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = texture
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(300, 44)
	style_button(button, primary)
	button.pressed.connect(action)
	return button
