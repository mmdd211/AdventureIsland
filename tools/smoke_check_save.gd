extends SceneTree

func _init() -> void:
	call_deferred("_run_check")

func _run_check() -> void:
	var failures := 0
	# --script 入口在编译期拿不到 autoload 标识符，运行时从 root 取。
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("GameState autoload missing.")
		quit(1)
		return
	var source: Dictionary = game_state.create_snapshot()
	source["current_hp"] = 67
	source["coins"] = 12
	source["score"] = 430
	source["current_level"] = 3
	source["current_map_id"] = "forest_2"
	source["current_zone_id"] = "forest_2"
	source["checkpoint_zone_id"] = "forest_1"
	source["checkpoint_position"] = Vector2(500.0, 486.0)
	source["defeated_bosses"] = ["meadow"]
	source["owned_equipment"] = ["grass_blade", "none_armor", "spore_edge"]
	source["hero_id"] = "light_swordsman"
	var restored: bool = game_state.restore_snapshot(source)
	if not restored or game_state.current_hp != 67 or game_state.coins != 12:
		printerr("Save snapshot restore failed.")
		failures += 1
	if game_state.current_map_id != "forest_2" or game_state.checkpoint_zone_id != "forest_1":
		printerr("Save map/checkpoint restore failed.")
		failures += 1
	if not game_state.is_boss_defeated("meadow") or not game_state.owns_equipment("spore_edge"):
		printerr("Save progression restore failed.")
		failures += 1
	if game_state.selected_hero_id != "light_swordsman":
		printerr("Save hero_id restore failed.")
		failures += 1
	if str(game_state.create_snapshot().get("hero_id", "")) != "light_swordsman":
		printerr("Save snapshot should include hero_id.")
		failures += 1
	var bad: Dictionary = game_state.create_snapshot()
	bad["hero_id"] = "ghost"
	if not game_state.restore_snapshot(bad) or game_state.selected_hero_id != PlayerAssetLibrary.DEFAULT_HERO_ID:
		printerr("Save hero_id invalid should fallback.")
		failures += 1
	var legacy: Dictionary = game_state.create_snapshot()
	legacy.erase("hero_id")
	if not game_state.restore_snapshot(legacy) or game_state.selected_hero_id != PlayerAssetLibrary.DEFAULT_HERO_ID:
		printerr("Legacy save without hero_id should fallback.")
		failures += 1
	if game_state.pending_restore_save != false:
		printerr("Pending restore flag should remain false until title request.")
		failures += 1
	game_state.pending_restore_save = true
	if game_state.pending_restore_save != true:
		printerr("Pending restore flag failed to set.")
		failures += 1
	game_state.pending_restore_save = false
	var drop_script: Script = load("res://scripts/systems/drop_component.gd")
	if drop_script != null:
		var drop: Node = drop_script.new()
		var drop_source := Node2D.new()
		if drop.has_method("setup"):
			drop.setup(drop_source, 0, 0)
		if drop.get("coin_scene") == null:
			printerr("DropComponent default coin scene missing.")
			failures += 1
		drop.free()
		drop_source.free()
	else:
		printerr("DropComponent script not found for save smoke.")
		failures += 1
	if failures == 0:
		print("Save snapshot smoke check passed.")
	else:
		printerr("Save snapshot smoke check failed.")
	quit(failures)
