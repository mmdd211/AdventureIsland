class_name KnockbackComponent
extends Node

@export var enabled := true
@export var horizontal_force := 170.0
@export var vertical_force := -150.0
@export var set_velocity := true

var body: CharacterBody2D

func setup(target: CharacterBody2D, horizontal := 170.0, vertical := -150.0, should_set_velocity := true) -> void:
	body = target
	horizontal_force = horizontal
	vertical_force = vertical
	set_velocity = should_set_velocity

func apply(source_position: Vector2, fallback_direction := 0) -> bool:
	if not enabled or body == null or not is_instance_valid(body) or bool(body.get("is_dead")):
		return false
	var away := signf(body.global_position.x - source_position.x)
	if away == 0.0:
		away = float(fallback_direction) if fallback_direction != 0.0 else 1.0
	var knockback := Vector2(away * horizontal_force, vertical_force)
	body.velocity = knockback if set_velocity else body.velocity + knockback
	return true
