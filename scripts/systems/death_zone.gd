extends Area2D

@export var damage_amount := 18

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.queue_free()
		return
	if not body.is_in_group("player"):
		return
	body.call("take_damage", damage_amount, body.global_position + Vector2(0, 40))
	if GameState.current_hp > 0:
		body.global_position = GameState.checkpoint_position
		body.velocity = Vector2.ZERO
