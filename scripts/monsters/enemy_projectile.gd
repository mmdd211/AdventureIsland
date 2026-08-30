extends Area2D

var direction := Vector2.RIGHT
var speed := 320.0
var damage := 8
var lifetime := 2.0
var age := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	age += delta
	if age >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.call("take_damage", damage, global_position)
	queue_free()
