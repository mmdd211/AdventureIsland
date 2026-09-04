extends Node

func _ready() -> void:
	var failures := 0
	var source := GameState.create_snapshot()
	source.current_hp = 67
	source.coins = 12
	source.score = 430
	source.current_level = 3
	source.current_map_id = "forest_2"
	source.current_zone_id = "forest_2"
	source.checkpoint_zone_id = "forest_1"
	source.checkpoint_position = Vector2(500.0, 486.0)
	source.defeated_bosses = ["meadow"]
	source.owned_equipment = ["grass_blade", "none_armor", "spore_edge"]
	var restored := GameState.restore_snapshot(source)
	if not restored or GameState.current_hp != 67 or GameState.coins != 12:
		printerr("Save snapshot restore failed.")
		failures += 1
	if GameState.current_map_id != "forest_2" or GameState.checkpoint_zone_id != "forest_1":
		printerr("Save map/checkpoint restore failed.")
		failures += 1
	if not GameState.is_boss_defeated("meadow") or not GameState.owns_equipment("spore_edge"):
		printerr("Save progression restore failed.")
		failures += 1
	if GameState.pending_restore_save != false:
		printerr("Pending restore flag should remain false until title request.")
		failures += 1
	GameState.pending_restore_save = true
	if GameState.pending_restore_save != true:
		printerr("Pending restore flag failed to set.")
		failures += 1
	GameState.pending_restore_save = false
	var drop := DropComponent.new()
	var drop_source := Node2D.new()
	drop.setup(drop_source, 0, 0)
	if drop.coin_scene == null:
		printerr("DropComponent default coin scene missing.")
		failures += 1
	if failures == 0:
		print("Save snapshot smoke check passed.")
	else:
		printerr("Save snapshot smoke check failed.")
	get_tree().quit(failures)
