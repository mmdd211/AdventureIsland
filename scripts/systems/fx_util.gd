class_name FxUtil
extends RefCounted

## 公共视觉特效工具：统一 player / enemy 的浮动文字、粒子、圆环、斩击弧线。

static func spawn_floating_text(parent: Node, text: String, world_position: Vector2, color: Color, font_size: int = 22) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 200
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	parent.add_child(label)
	label.global_position = world_position + Vector2(-14.0, -12.0)
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 54.0, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

static func spawn_enemy_text(parent: Node, text: String, world_position: Vector2, color: Color) -> void:
	spawn_floating_text(parent, text, world_position, color, 17)

static func spawn_particles(parent: Node, world_position: Vector2, config: Dictionary) -> void:
	var particles := CPUParticles2D.new()
	particles.amount = config.get("amount", 12)
	particles.lifetime = config.get("lifetime", 0.34)
	particles.one_shot = config.get("one_shot", true)
	particles.explosiveness = config.get("explosiveness", 1.0)
	particles.spread = config.get("spread", 70.0)
	particles.direction = config.get("direction", Vector2.UP)
	particles.initial_velocity_min = config.get("velocity_min", 35.0)
	particles.initial_velocity_max = config.get("velocity_max", 80.0)
	particles.gravity = config.get("gravity", Vector2(0, 320))
	particles.color = config.get("color", Color("d9c79c"))
	particles.z_index = config.get("z_index", 90)
	particles.position = world_position
	parent.add_child(particles)
	particles.emitting = true
	var cleanup_time: float = config.get("cleanup_time", 0.8)
	parent.get_tree().create_timer(cleanup_time).timeout.connect(particles.queue_free)

static func spawn_ring(parent: Node, local_position: Vector2, color: Color, radius: float = 18.0, duration: float = 0.24) -> void:
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = color
	ring.closed = true
	ring.z_index = 80
	var points := PackedVector2Array()
	for index in range(16):
		points.append(Vector2.from_angle(TAU * float(index) / 16.0) * radius)
	ring.points = points
	ring.position = local_position
	parent.add_child(ring)
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.4, 1.4), duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(ring.queue_free)

static func spawn_slash_arc(parent: Node, facing: int, stage: int, color: Color, reach_bonus: float) -> void:
	var arc := Line2D.new()
	arc.width = (12.0 if stage == 1 else 17.0) + reach_bonus * 0.08
	arc.default_color = Color(color.lightened(0.2), 0.88)
	arc.z_index = 80
	var points := PackedVector2Array()
	var radius := (44.0 if stage == 1 else 62.0) + reach_bonus
	for index in range(9):
		var angle := lerpf(-1.15, 1.15, float(index) / 8.0)
		points.append(Vector2(cos(angle), sin(angle)) * radius * facing)
	arc.points = points
	parent.add_child(arc)
	var tween := parent.create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.16)
	tween.tween_callback(arc.queue_free)

static func spawn_star_impact(parent: Node, world_position: Vector2) -> void:
	var ring := Line2D.new()
	ring.closed = true
	ring.width = 5.0
	ring.default_color = Color("68d8ff")
	ring.z_index = 90
	var points := PackedVector2Array()
	for index in range(12):
		points.append(Vector2.from_angle(TAU * float(index) / 12.0) * 36.0)
	ring.points = points
	parent.add_child(ring)
	ring.global_position = world_position
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.4, 1.8), 0.25)
	tween.tween_property(ring, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(ring.queue_free)
