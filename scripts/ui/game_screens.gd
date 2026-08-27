extends CanvasLayer

const WORLD_MAP_OVERLAY := preload("res://scripts/ui/world_map_overlay.gd")

var pause_panel: PanelContainer
var death_panel: PanelContainer
var complete_panel: PanelContainer
var complete_stats: Label
var world_map_overlay: CanvasLayer

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	GameState.player_died.connect(_on_player_died)
	GameState.level_completed.connect(_on_level_completed)

func _build_ui() -> void:
	world_map_overlay = WORLD_MAP_OVERLAY.new()
	world_map_overlay.name = "WorldMapOverlay"
	add_child(world_map_overlay)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	pause_panel = _make_panel(root, "暂停", Color("0f2027"))
	var pause_box := pause_panel.get_meta("box") as VBoxContainer
	_add_button(pause_box, "继续冒险", _toggle_pause)
	_add_button(pause_box, "重新开始", _restart_level)
	_add_button(pause_box, "返回标题", _go_title)

	death_panel = _make_panel(root, "冒险失败", Color("30101d"))
	var death_box := death_panel.get_meta("box") as VBoxContainer
	_add_button(death_box, "从检查点继续", _respawn)
	_add_button(death_box, "重新开始关卡", _restart_level)
	_add_button(death_box, "返回标题", _go_title)

	complete_panel = _make_panel(root, "世界通关！", Color("12281d"))
	var complete_box := complete_panel.get_meta("box") as VBoxContainer
	complete_stats = Label.new()
	complete_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_stats.add_theme_font_size_override("font_size", 20)
	complete_box.add_child(complete_stats)
	_add_button(complete_box, "再玩一次", _restart_level)
	_add_button(complete_box, "返回标题", _go_title)

	_set_panel_visible(pause_panel, false)
	_set_panel_visible(death_panel, false)
	_set_panel_visible(complete_panel, false)

func _make_panel(parent: Control, title_text: String, panel_color: Color) -> PanelContainer:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.border_color = Color("ffd700")
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 28.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	panel.set_meta("box", box)
	panel.set_meta("dim", dim)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("ffd700"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 9)
	box.add_child(title)
	return panel

func _add_button(parent: VBoxContainer, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 44)
	button.pressed.connect(action)
	parent.add_child(button)

func _set_panel_visible(panel: PanelContainer, shown: bool) -> void:
	var dim := panel.get_meta("dim") as Control
	panel.visible = shown
	if dim:
		dim.visible = shown

func _show_only_panel(panel: PanelContainer) -> void:
	_set_panel_visible(pause_panel, panel == pause_panel)
	_set_panel_visible(death_panel, panel == death_panel)
	_set_panel_visible(complete_panel, panel == complete_panel)

func _input(event: InputEvent) -> void:
	# 加载界面显示期间不响应地图/暂停输入，避免加载未完成就打开覆盖层。
	if get_tree().get_first_node_in_group("loading_screen") != null:
		return
	if event.is_action_pressed("toggle_map"):
		if world_map_overlay.visible:
			_close_world_map()
		elif not death_panel.visible and not complete_panel.visible and not pause_panel.visible:
			_open_world_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and world_map_overlay.visible:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and not death_panel.visible and not complete_panel.visible:
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _open_world_map() -> void:
	world_map_overlay.open_map()

func _close_world_map() -> void:
	world_map_overlay.close_map()

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_set_panel_visible(pause_panel, paused)
	if paused:
		pause_panel.get_meta("box").get_child(1).grab_focus()

func _on_player_died() -> void:
	await get_tree().create_timer(0.65).timeout
	get_tree().paused = true
	_show_only_panel(death_panel)
	death_panel.get_meta("box").get_child(1).grab_focus()

func _respawn() -> void:
	_set_panel_visible(death_panel, false)
	get_tree().paused = false
	GameState.respawn_from_checkpoint()

func _on_level_completed() -> void:
	get_tree().paused = true
	_show_only_panel(complete_panel)
	var coin_ratio := 0.0
	if GameState.total_coin_pickups > 0:
		coin_ratio = float(GameState.collected_coin_pickups) / GameState.total_coin_pickups
	complete_stats.text = "用时 %s\n金币 %d/%d（%d%%）\n击杀 %d\n死亡 %d\n评分 %s" % [
		GameState.get_formatted_time(), GameState.collected_coin_pickups, GameState.total_coin_pickups,
		int(coin_ratio * 100.0), GameState.kills, GameState.deaths, GameState.get_rating()
	]
	_set_panel_visible(complete_panel, true)
	complete_panel.get_meta("box").get_child(2).grab_focus()

func _restart_level() -> void:
	get_tree().paused = false
	world_map_overlay.visible = false
	GameState.reset_run()
	# 重开也走加载界面：重新搭建世界 + 重画像素美术需要数秒。
	GameState.pending_loading_screen = true
	get_tree().reload_current_scene()

func _go_title() -> void:
	get_tree().paused = false
	world_map_overlay.visible = false
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
