extends StaticBody2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const RESPAWN_TIME := 2.6

var triggered := false
var collider: CollisionShape2D
var visual: ColorRect

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_build_platform()

func _build_platform() -> void:
	collider = CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(110, 16)
	collider.shape = rectangle
	add_child(collider)

	visual = ColorRect.new()
	visual.name = "Visual"
	visual.color = Palette.WOOD_LIGHT
	visual.position = Vector2(-55, -8)
	visual.size = Vector2(110, 16)
	add_child(visual)

	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 1
	var sensor_shape := CollisionShape2D.new()
	var sensor_rectangle := RectangleShape2D.new()
	sensor_rectangle.size = Vector2(110, 30)
	sensor_shape.shape = sensor_rectangle
	sensor.add_child(sensor_shape)
	sensor.body_entered.connect(_on_body_entered)
	add_child(sensor)

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.65, 0.45), 0.08)
	tween.tween_property(self, "rotation_degrees", 1.5, 0.06)
	tween.tween_property(self, "rotation_degrees", -1.5, 0.06)
	tween.tween_callback(collapse)

func collapse() -> void:
	collider.set_deferred("disabled", true)
	visible = false
	get_tree().create_timer(RESPAWN_TIME).timeout.connect(respawn)

func respawn() -> void:
	if not is_inside_tree():
		return
	triggered = false
	rotation_degrees = 0.0
	modulate = Color.WHITE
	visible = true
	collider.set_deferred("disabled", false)
