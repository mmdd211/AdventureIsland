class_name StatusEffectComponent
extends Node

signal effect_started(kind: String, duration: float)
signal effect_ended(kind: String)

@export var owner_node: Node

var effects := {}

func setup(target: Node) -> void:
	owner_node = target

func apply(kind: String, duration: float) -> bool:
	if kind.is_empty() or duration <= 0.0:
		return false
	var is_new := not effects.has(kind)
	effects[kind] = duration
	if is_new:
		effect_started.emit(kind, duration)
	return true

func has_effect(kind: String) -> bool:
	return effects.has(kind) and float(effects[kind]) > 0.0

func remaining(kind: String) -> float:
	return float(effects.get(kind, 0.0))

func clear(kind: String) -> void:
	if effects.erase(kind):
		effect_ended.emit(kind)

func clear_all() -> void:
	for kind in effects.keys().duplicate():
		clear(str(kind))

func _process(delta: float) -> void:
	if effects.is_empty():
		return
	for kind in effects.keys().duplicate():
		var remaining_time := float(effects[kind]) - delta
		if remaining_time <= 0.0:
			effects.erase(kind)
			effect_ended.emit(kind)
		else:
			effects[kind] = remaining_time
