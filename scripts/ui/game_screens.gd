extends CanvasLayer

const WORLD_MAP_OVERLAY := preload("res://scripts/ui/world_map_overlay.gd")
const Palette := preload("res://scripts/systems/pixel_palette.gd")
const PixelUI := preload("res://scripts/ui/pixel_ui.gd")

var pause_panel: PanelContainer
var death_panel: PanelContainer
var complete_panel: PanelContainer
var complete_stats: Label
var world_map_overlay: CanvasLayer
var reward_panel: PanelContainer
var reward_weapon_current: Label
var reward_weapon_new: Label
var reward_weapon_icon: TextureRect
var reward_armor_current: Label
var reward_armor_new: Label
var reward_armor_icon: TextureRect
var reward_weapon_button: Button
var reward_armor_button: Button
var reward_weapon_keep_button: Button
var reward_armor_keep_button: Button
var reward_continue_button: Button
var reward_region_id := ""
var reward_weapon_chosen := false
var reward_armor_chosen := false
var equipment_panel: PanelContainer

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	GameState.player_died.connect(_on_player_died)
	GameState.level_completed.connect(_on_level_completed)
	GameState.equipment_gained.connect(_on_equipment_gained)

func _build_ui() -> void:
	world_map_overlay = WORLD_MAP_OVERLAY.new()
	world_map_overlay.name = "WorldMapOverlay"
	add_child(world_map_overlay)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	pause_panel = _make_panel(root, "暂停", Color("1d6d80"))
	var pause_box := pause_panel.get_meta("box") as VBoxContainer
	_add_button(pause_box, "继续冒险", _toggle_pause, true)
	_add_button(pause_box, "装备", _open_equipment_panel)
	_add_button(pause_box, "重新开始", _restart_level)
	_add_button(pause_box, "返回标题", _go_title)

	death_panel = _make_panel(root, "冒险失败", Color("b8404d"))
	var death_box := death_panel.get_meta("box") as VBoxContainer
	_add_button(death_box, "从检查点继续", _respawn, true)
	_add_button(death_box, "重新开始关卡", _restart_level)
	_add_button(death_box, "返回标题", _go_title)

	complete_panel = _make_panel(root, "世界通关！", Color("2f7a34"))
	var complete_box := complete_panel.get_meta("box") as VBoxContainer
	complete_stats = Label.new()
	complete_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_stats.add_theme_font_size_override("font_size", 20)
	complete_stats.add_theme_color_override("font_color", Palette.OUTLINE_SOFT)
	complete_box.add_child(complete_stats)
	_add_button(complete_box, "再玩一次", _restart_level, true)
	_add_button(complete_box, "返回标题", _go_title)

	_build_reward_panel(root)
	_build_equipment_panel(root)

	_set_panel_visible(pause_panel, false)
	_set_panel_visible(death_panel, false)
	_set_panel_visible(complete_panel, false)
	_set_panel_visible(reward_panel, false)
	_set_panel_visible(equipment_panel, false)

func _build_reward_panel(parent: Control) -> void:
	reward_panel = _make_panel(parent, "战利品选择", Color("c79a2f"))
	var box := reward_panel.get_meta("box") as VBoxContainer
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 26)
	box.add_child(columns)
	var weapon_column := VBoxContainer.new()
	var armor_column := VBoxContainer.new()
	columns.add_child(weapon_column)
	columns.add_child(armor_column)
	weapon_column.add_child(_make_status_label("武器"))
	reward_weapon_current = _make_status_label("")
	reward_weapon_new = _make_status_label("")
	weapon_column.add_child(reward_weapon_current)
	weapon_column.add_child(reward_weapon_new)
	reward_weapon_icon = TextureRect.new()
	reward_weapon_icon.custom_minimum_size = Vector2(64, 64)
	reward_weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_column.add_child(reward_weapon_icon)
	reward_weapon_button = Button.new()
	reward_weapon_button.custom_minimum_size = Vector2(118, 40)
	PixelUI.style_button(reward_weapon_button, true)
	reward_weapon_button.pressed.connect(func(): _choose_reward("weapon", true))
	weapon_column.add_child(reward_weapon_button)
	reward_weapon_keep_button = Button.new()
	reward_weapon_keep_button.custom_minimum_size = Vector2(104, 40)
	PixelUI.style_button(reward_weapon_keep_button, false)
	reward_weapon_keep_button.pressed.connect(func(): _choose_reward("weapon", false))
	weapon_column.add_child(reward_weapon_keep_button)
	armor_column.add_child(_make_status_label("防具"))
	reward_armor_current = _make_status_label("")
	reward_armor_new = _make_status_label("")
	armor_column.add_child(reward_armor_current)
	armor_column.add_child(reward_armor_new)
	reward_armor_icon = TextureRect.new()
	reward_armor_icon.custom_minimum_size = Vector2(64, 64)
	reward_armor_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_armor_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_armor_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	armor_column.add_child(reward_armor_icon)
	reward_armor_button = Button.new()
	reward_armor_button.custom_minimum_size = Vector2(118, 40)
	PixelUI.style_button(reward_armor_button, true)
	reward_armor_button.pressed.connect(func(): _choose_reward("armor", true))
	armor_column.add_child(reward_armor_button)
	reward_armor_keep_button = Button.new()
	reward_armor_keep_button.custom_minimum_size = Vector2(104, 40)
	PixelUI.style_button(reward_armor_keep_button, false)
	reward_armor_keep_button.pressed.connect(func(): _choose_reward("armor", false))
	armor_column.add_child(reward_armor_keep_button)
	reward_continue_button = _add_reward_button(box, "继续冒险", _close_reward_panel)

func _build_equipment_panel(parent: Control) -> void:
	equipment_panel = _make_panel(parent, "装备", Color("1d6d80"))
	var box := equipment_panel.get_meta("box") as VBoxContainer
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	box.add_child(columns)
	var weapon_column := VBoxContainer.new()
	var armor_column := VBoxContainer.new()
	weapon_column.add_theme_constant_override("separation", 7)
	armor_column.add_theme_constant_override("separation", 7)
	columns.add_child(weapon_column)
	columns.add_child(armor_column)
	weapon_column.add_child(_make_status_label("武器"))
	armor_column.add_child(_make_status_label("防具"))
	equipment_panel.set_meta("weapon_column", weapon_column)
	equipment_panel.set_meta("armor_column", armor_column)
	for item_id in ["grass_blade", "petal_blade", "spore_edge", "glow_hook", "gale_rock", "rune_blade", "star_edge"]:
		var button := PixelUI.icon_button(GameState.get_equipment(item_id).display_name, PixelStyleManager.make_equipment_texture(item_id), func():
			GameState.equip(item_id)
			_refresh_equipment_panel()
		)
		weapon_column.add_child(button)
		button.set_meta("item_id", item_id)
	for item_id in ["none_armor", "moss_light", "mushroom_shell", "root_weave", "gale_plate", "rune_armor", "sky_armor"]:
		var button := PixelUI.icon_button(GameState.get_equipment(item_id).display_name, PixelStyleManager.make_equipment_texture(item_id), func():
			GameState.equip(item_id)
			_refresh_equipment_panel()
		)
		armor_column.add_child(button)
		button.set_meta("item_id", item_id)
	_add_button(box, "返回", _close_equipment_panel)

func _make_status_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Palette.OUTLINE_SOFT)
	label.add_theme_constant_override("outline_size", 0)
	return label

func _make_panel(parent: Control, title_text: String, panel_color: Color) -> PanelContainer:
	var dim := ColorRect.new()
	dim.color = Color(Palette.OUTLINE, 0.54)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	var style := PixelUI.panel_style(Color(Palette.WHITE, 0.96), Palette.OUTLINE, 8)
	style.border_width_top = 4
	style.border_width_bottom = 8
	style.shadow_size = 7
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 30.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	panel.add_child(box)
	panel.set_meta("box", box)
	panel.set_meta("dim", dim)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", panel_color.darkened(0.12))
	title.add_theme_color_override("font_outline_color", Palette.WHITE)
	title.add_theme_constant_override("outline_size", 9)
	box.add_child(title)
	return panel

func _add_button(parent: VBoxContainer, text: String, action: Callable, primary := false) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 44)
	PixelUI.style_button(button, primary)
	button.pressed.connect(action)
	parent.add_child(button)

func _add_reward_button(parent: VBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 44)
	PixelUI.style_button(button, true)
	button.pressed.connect(action)
	button.disabled = true
	parent.add_child(button)
	return button

func _set_panel_visible(panel: PanelContainer, shown: bool) -> void:
	var dim := panel.get_meta("dim") as Control
	panel.visible = shown
	if dim:
		dim.visible = shown

func _show_only_panel(panel: PanelContainer) -> void:
	_set_panel_visible(pause_panel, panel == pause_panel)
	_set_panel_visible(death_panel, panel == death_panel)
	_set_panel_visible(complete_panel, panel == complete_panel)
	_set_panel_visible(reward_panel, false)
	_set_panel_visible(equipment_panel, false)

func _input(event: InputEvent) -> void:
	# 加载界面显示期间不响应地图/暂停输入，避免加载未完成就打开覆盖层。
	if get_tree().get_first_node_in_group("loading_screen") != null:
		return
	if event.is_action_pressed("toggle_map"):
		if world_map_overlay.visible:
			_close_world_map()
		elif not death_panel.visible and not complete_panel.visible and not pause_panel.visible and not equipment_panel.visible:
			_open_world_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and world_map_overlay.visible:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and equipment_panel.visible:
		_close_equipment_panel()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and not death_panel.visible and not complete_panel.visible and not reward_panel.visible:
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _open_equipment_panel() -> void:
	_refresh_equipment_panel()
	_set_panel_visible(pause_panel, false)
	_set_panel_visible(equipment_panel, true)

func _close_equipment_panel() -> void:
	_set_panel_visible(equipment_panel, false)
	_set_panel_visible(pause_panel, true)
	pause_panel.get_meta("box").get_child(1).grab_focus()

func _refresh_equipment_panel() -> void:
	if equipment_panel == null:
		return
	for column in [equipment_panel.get_meta("weapon_column"), equipment_panel.get_meta("armor_column")]:
		for button in column.get_children():
			if button is Button and button.has_meta("item_id"):
				var item := GameState.get_equipment(str(button.get_meta("item_id")))
				var owned := GameState.owns_equipment(str(button.get_meta("item_id")))
				var equipped := str(button.get_meta("item_id")) in [GameState.equipped_weapon_id, GameState.equipped_armor_id]
				var state := "已装备" if equipped else ("可装备" if owned else "未获得")
				button.text = "%s · %s" % [state, item.display_name]
				button.disabled = not owned

func _on_equipment_gained(weapon_id: String, armor_id: String, region_id: String) -> void:
	reward_region_id = region_id
	reward_weapon_chosen = false
	reward_armor_chosen = false
	var weapon := GameState.get_equipment(weapon_id)
	var armor := GameState.get_equipment(armor_id)
	reward_weapon_icon.texture = PixelStyleManager.make_equipment_texture(weapon_id)
	reward_armor_icon.texture = PixelStyleManager.make_equipment_texture(armor_id)
	reward_weapon_current.text = "当前：%s" % GameState.get_current_weapon().display_name
	reward_weapon_new.text = "新装备：%s\n%s" % [weapon.display_name, weapon.description]
	reward_armor_current.text = "当前：%s" % GameState.get_current_armor().display_name
	reward_armor_new.text = "新装备：%s\n%s" % [armor.display_name, armor.description]
	reward_weapon_button.text = "装备武器"
	reward_weapon_button.disabled = false
	reward_weapon_keep_button.text = "保留"
	reward_weapon_keep_button.disabled = false
	reward_armor_button.text = "装备防具"
	reward_armor_button.disabled = false
	reward_armor_keep_button.text = "保留"
	reward_armor_keep_button.disabled = false
	reward_continue_button.disabled = true
	await get_tree().create_timer(0.55).timeout
	get_tree().paused = true
	_show_only_panel(null)
	_set_panel_visible(reward_panel, true)
	reward_weapon_button.grab_focus()

func _choose_reward(slot: String, equip_item: bool) -> void:
	var maps := load("res://scripts/world/world_maps.gd")
	var region: Dictionary = maps.REGIONS.get(reward_region_id, {})
	if slot == "weapon":
		reward_weapon_chosen = true
		if equip_item:
			GameState.equip(str(region.get("weapon", "")))
			reward_weapon_button.text = "已装备"
		else:
			reward_weapon_button.text = "装备"
			reward_weapon_keep_button.text = "已保留"
		reward_weapon_button.disabled = true
		reward_weapon_keep_button.disabled = true
	else:
		reward_armor_chosen = true
		if equip_item:
			GameState.equip(str(region.get("armor", "")))
			reward_armor_button.text = "已装备"
		else:
			reward_armor_button.text = "装备"
			reward_armor_keep_button.text = "已保留"
		reward_armor_button.disabled = true
		reward_armor_keep_button.disabled = true
	reward_continue_button.disabled = not (reward_weapon_chosen and reward_armor_chosen)

func _close_reward_panel() -> void:
	if not (reward_weapon_chosen and reward_armor_chosen):
		return
	_set_panel_visible(reward_panel, false)
	get_tree().paused = false
	if reward_region_id == "gate":
		GameState.complete_level()

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
