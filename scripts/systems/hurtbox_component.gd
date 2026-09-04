class_name HurtboxComponent
extends Node

signal damaged(amount: int, source_position: Vector2)

var owner_node: Node

func setup(target: Node) -> void:
	owner_node = target

func receive_hit(amount: int, source_position := Vector2.ZERO) -> bool:
	if amount <= 0 or owner_node == null or not is_instance_valid(owner_node):
		return false
	if not owner_node.has_method("take_damage"):
		return false
	owner_node.call("take_damage", amount, source_position)
	damaged.emit(amount, source_position)
	return true
