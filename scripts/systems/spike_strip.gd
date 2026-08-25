extends Area2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

@export var damage_amount := 16
@export var damage_interval := 0.65

var timer := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_damage_body)
	_build_visual()

func _physics_process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		for body in get_overlapping_bodies():
			_damage_body(body)

func _damage_body(body: Node2D) -> void:
	if timer > 0.0 or not body.is_in_group("player"):
		return
	timer = damage_interval
	body.call("take_damage", damage_amount, global_position + Vector2(0, 50))

func _build_visual() -> void:
	var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider == null:
		for child in get_children():
			if child is CollisionShape2D:
				collider = child
				break
	var width := 120.0
	if collider and collider.shape is RectangleShape2D:
		var rectangle := collider.shape as RectangleShape2D
		width = rectangle.size.x
		rectangle.size = Vector2(width, 21.0)
		collider.position = Vector2(0, -0.5)
	var spike_count := maxi(2, int(round(width / 22.0)))
	var spacing := width / float(spike_count)
	for index in range(spike_count):
		var left := -width * 0.5 + spacing * float(index)
		var shadow := Polygon2D.new()
		shadow.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(spacing * 0.5, -19.0),
			Vector2(spacing, 0.0),
		])
		shadow.color = Palette.STONE_DARK
		shadow.position = Vector2(left, 11)
		shadow.z_index = 14
		add_child(shadow)

		var spike := Polygon2D.new()
		spike.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(spacing * 0.5, -21.0),
			Vector2(spacing, 0.0),
		])
		spike.color = Palette.STONE_LIGHT
		spike.position = Vector2(left, 10)
		spike.z_index = 15
		add_child(spike)
		var highlight := Polygon2D.new()
		highlight.polygon = PackedVector2Array([
			Vector2(spacing * 0.24, -4.0),
			Vector2(spacing * 0.5, -19.0),
			Vector2(spacing * 0.62, -4.0),
		])
		highlight.color = Palette.WHITE
		highlight.position = Vector2(left, 10)
		highlight.z_index = 16
		add_child(highlight)
