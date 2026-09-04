class_name SpriteEffect
extends RefCounted

const SHADER := preload("res://assets/shaders/canvas_sprite.gdshader")

static func apply(canvas_item: CanvasItem) -> ShaderMaterial:
	var existing := canvas_item.material as ShaderMaterial
	if existing and existing.shader == SHADER:
		return existing
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("flash_color", Color(3.0, 3.0, 3.0, 1.0))
	canvas_item.material = material
	return material

static func flash(canvas_item: CanvasItem, duration := 0.09, color := Color(3.0, 3.0, 3.0, 1.0)) -> void:
	var material := apply(canvas_item)
	material.set_shader_parameter("flash_color", color)
	material.set_shader_parameter("flash_strength", 1.0)
	var tween := canvas_item.create_tween()
	tween.tween_method(func(value): material.set_shader_parameter("flash_strength", value), 1.0, 0.0, duration)

static func set_outline(canvas_item: CanvasItem, color: Color, width := 1.0) -> void:
	var material := apply(canvas_item)
	material.set_shader_parameter("outline_color", color)
	material.set_shader_parameter("outline_width", width)
