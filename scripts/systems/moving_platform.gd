extends AnimatableBody2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

@export var travel := Vector2(160, 0)
@export var period := 3.0
@export var phase := 0.0

var start_position: Vector2
var time_value := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = true
	start_position = position
	time_value = phase
	_build_visual()

func _physics_process(delta: float) -> void:
	time_value += delta
	var wave := sin(TAU * time_value / maxf(0.2, period))
	position = start_position + travel * wave * 0.5

func setup(size_value: Vector2) -> void:
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = size_value
	shape.shape = rectangle
	add_child(shape)

func _build_visual() -> void:
	var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var size_value := Vector2(140, 18)
	if collider and collider.shape is RectangleShape2D:
		size_value = collider.shape.size
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.color = Palette.DIRT
	visual.position = -size_value * 0.5
	visual.size = size_value
	add_child(visual)
