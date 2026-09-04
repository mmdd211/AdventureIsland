class_name HitboxComponent
extends Node

signal hit_target(target: Node, amount: int)

@export var area_path: NodePath
@export var damage := 1
@export var target_group := "player"
@export var one_shot_per_sweep := true
@export var apply_knockback := true

var area: Area2D
var source: Node2D
var _hit_nodes: Array[Node] = []

func setup(hit_area: Area2D, hit_source: Node2D, group := "player", hit_damage := 1, is_one_shot := true) -> void:
	area = hit_area
	source = hit_source
	target_group = group
	damage = hit_damage
	one_shot_per_sweep = is_one_shot

func set_damage(value: int) -> void:
	damage = maxi(0, value)

func clear_sweep() -> void:
	_hit_nodes.clear()

func scan_overlaps() -> int:
	if area == null or not is_instance_valid(area) or damage <= 0:
		return 0
	var hit_count := 0
	for body in area.get_overlapping_bodies():
		if target_group != "" and not body.is_in_group(target_group):
			continue
		if one_shot_per_sweep and _hit_nodes.has(body):
			continue
		var hurtbox := body.get_node_or_null("HurtboxComponent") as HurtboxComponent
		var applied := false
		if hurtbox:
			applied = hurtbox.receive_hit(damage, source.global_position if source else area.global_position)
		elif body.has_method("take_damage"):
			body.call("take_damage", damage, source.global_position if source else area.global_position)
			applied = true
		if not applied:
			continue
		if apply_knockback and body.has_method("apply_knockback"):
			body.call("apply_knockback", source.global_position if source else area.global_position)
		_hit_nodes.append(body)
		hit_target.emit(body, damage)
		hit_count += 1
	return hit_count
