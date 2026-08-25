extends Node

func _ready() -> void:
	var level := (load("res://scenes/levels/test_level.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().create_timer(0.35).timeout
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var portal := level.get_node("Portal") as Area2D
	var screens := level.get_node("GameScreens")
	if player == null or portal == null or screens == null:
		push_error("FAIL: gameplay loop nodes missing")
		get_tree().quit(1)
		return
	player.global_position = portal.global_position
	await get_tree().create_timer(0.25).timeout
	if not GameState.level_finished or not get_tree().paused or not screens.complete_panel.visible:
		push_error("FAIL: portal did not trigger completion screen")
		get_tree().quit(1)
		return
	print("PASS: portal triggered completion screen")
	print("GAMEPLAY_LOOP_CHECK COMPLETE")
	get_tree().quit(0)
