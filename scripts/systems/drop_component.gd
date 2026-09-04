class_name DropComponent
extends Node

@export var coin_scene: PackedScene
@export var coin_count := 0
@export var experience := 0
@export var spread := 14.0
@export var height := -8.0

var source: Node2D

func setup(target: Node2D, coins := 0, exp_value := 0) -> void:
	source = target
	coin_count = coins
	experience = exp_value
	if coin_scene == null:
		coin_scene = load("res://scenes/systems/coin.tscn") as PackedScene

func drop() -> void:
	if experience > 0:
		GameState.add_experience(experience)
	if coin_scene == null or coin_count <= 0 or source == null or not is_instance_valid(source):
		return
	var parent := source.get_parent()
	for index in range(coin_count):
		var pickup := coin_scene.instantiate() as Node2D
		pickup.set("pickup_type", "coin")
		pickup.set("value", 1)
		var angle := TAU * float(index) / float(coin_count)
		var spawn_global := source.global_position + Vector2(cos(angle) * spread, height)
		pickup.set("position", parent.to_local(spawn_global))
		parent.call_deferred("add_child", pickup)
