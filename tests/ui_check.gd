extends Node

func _ready() -> void:
	var title := (load("res://scenes/ui/title_screen.tscn") as PackedScene).instantiate() as Control
	add_child(title)
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_rect := Rect2(Vector2.ZERO, title.get_viewport_rect().size)
	for node_path in ["Content", "Content/TitleLabel", "Content/SubtitleLabel", "Content/Menu/StartButton", "BottomMargin/ControlsLabel"]:
		var control := title.get_node_or_null(node_path) as Control
		if control == null:
			push_error("FAIL: missing title control " + node_path)
			get_tree().quit(1)
			return
		var control_rect := control.get_global_rect()
		if not viewport_rect.encloses(control_rect):
			push_error("FAIL: title control escaped viewport %s: %s" % [node_path, control_rect])
			get_tree().quit(1)
			return
	print("PASS: all title controls remain on screen")
	title.queue_free()
	await get_tree().process_frame

	var screens := (load("res://scenes/ui/game_screens.tscn") as PackedScene).instantiate()
	add_child(screens)
	await get_tree().create_timer(0.15).timeout
	_assert_overlay_state(screens, null, "initial")

	var hud := (load("res://scenes/ui/game_hud.tscn") as PackedScene).instantiate()
	add_child(hud)
	await get_tree().process_frame
	var hp_bar: ProgressBar = hud.get("hp_bar")
	GameState.damage_player(23)
	await get_tree().process_frame
	await get_tree().process_frame
	if GameState.current_hp != 77 or hp_bar.max_value != 100 or not is_equal_approx(hp_bar.value, 77.0):
		push_error("FAIL: health bar did not synchronize (%d hp, bar=%s/%s)" % [GameState.current_hp, hp_bar.value, hp_bar.max_value])
		get_tree().quit(1)
		return
	print("PASS: health bar synchronized to HP")
	hud.queue_free()
	await get_tree().process_frame

	var pause_event := InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	Input.parse_input_event(pause_event)
	await get_tree().process_frame
	await get_tree().process_frame
	if not get_tree().paused or not screens.pause_panel.visible:
		push_error("FAIL: pause input did not open pause menu")
		get_tree().quit(1)
		return
	print("PASS: pause input opened pause menu")
	_assert_overlay_state(screens, screens.pause_panel, "paused")
	screens._toggle_pause()
	await get_tree().process_frame
	_assert_overlay_state(screens, null, "resumed")

	GameState.damage_player(999)
	await get_tree().create_timer(0.85).timeout
	var death_panel := screens.death_panel as PanelContainer
	if not death_panel.visible or not get_tree().paused:
		push_error("FAIL: death screen did not pause game")
		get_tree().quit(1)
		return
	print("PASS: death screen shown and game paused")
	_assert_overlay_state(screens, screens.death_panel, "death")
	screens._respawn()
	await get_tree().process_frame
	if GameState.current_hp != GameState.max_hp or get_tree().paused:
		push_error("FAIL: checkpoint respawn failed")
		get_tree().quit(1)
		return
	print("PASS: checkpoint respawn restored HP")
	GameState.total_coin_pickups = 4
	GameState.collected_coin_pickups = 3
	GameState.complete_level()
	await get_tree().process_frame
	if not screens.complete_panel.visible or not get_tree().paused:
		push_error("FAIL: completion screen did not appear")
		get_tree().quit(1)
		return
	print("PASS: completion screen shown; rating=", GameState.get_rating())
	_assert_overlay_state(screens, screens.complete_panel, "complete")
	print("UI_CHECK COMPLETE")
	get_tree().quit(0)

func _assert_overlay_state(screens: Node, shown_panel: PanelContainer, state_name: String) -> void:
	for panel in [screens.pause_panel, screens.death_panel, screens.complete_panel]:
		var dim: Control = panel.get_meta("dim")
		var should_show: bool = panel == shown_panel
		if panel.visible != should_show or dim.visible != should_show:
			push_error("FAIL: overlay desynchronized during %s" % state_name)
			get_tree().quit(1)
			return
	print("PASS: overlay layers synchronized during ", state_name)
