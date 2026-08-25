extends Node

var level: Node
var enemy: CharacterBody2D
var samples: Array[int] = []

func _ready() -> void:
	level = (load("res://scenes/levels/test_level.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().create_timer(0.35).timeout
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate.get("enemy_kind") == "mushroom":
			enemy = candidate
			break
	if enemy == null:
		push_error("FAIL: mushroom missing")
		get_tree().quit(1)
		return
	enemy.global_position = Vector2(584, 470)
	enemy.direction = 1
	enemy.turn_cooldown = 0.0

func _physics_process(_delta: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	samples.append(enemy.direction)
	if samples.size() < 75:
		return
	var reversals := 0
	for index in range(1, samples.size()):
		if samples[index] != samples[index - 1]:
			reversals += 1
	if reversals != 1 or samples[-1] != -1:
		push_error("FAIL: enemy boundary movement jittered (reversals=%d, final=%d)" % [reversals, samples[-1]])
		get_tree().quit(1)
		return
	print("PASS: enemy made one stable turn at the ground edge")
	print("ENEMY_EDGE_CHECK COMPLETE")
	get_tree().quit(0)
