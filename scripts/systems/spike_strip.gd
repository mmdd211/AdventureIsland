extends Area2D

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
	var width := 120.0
	if collider and collider.shape is RectangleShape2D:
		width = collider.shape.size.x
	for index in range(int(width / 22.0)):
		var spike := Polygon2D.new()
		spike.polygon = PackedVector2Array([Vector2.ZERO, Vector2(11, -21), Vector2(22, 0)])
		spike.color = Color("dfe8ef")
		spike.position = Vector2(index * 22.0 - width * 0.5 + 5, 10)
		spike.z_index = 15
		add_child(spike)
