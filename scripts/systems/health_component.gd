class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(amount: int, source_position: Vector2)
signal died

@export var max_health := 100
@export var current_health := 100
@export var invulnerable := false

func setup(current: int, maximum: int) -> void:
	max_health = maxi(1, maximum)
	current_health = clampi(current, 0, max_health)
	health_changed.emit(current_health, max_health)

func damage(amount: int, source_position := Vector2.ZERO) -> bool:
	if invulnerable or current_health <= 0 or amount <= 0:
		return false
	current_health = maxi(0, current_health - amount)
	damaged.emit(amount, source_position)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()
	return true

func heal(amount: int) -> bool:
	if current_health <= 0 or amount <= 0:
		return false
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	return true
