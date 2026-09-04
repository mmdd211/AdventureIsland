extends CanvasLayer

const WORLD_MAP_OVERLAY := preload("res://scenes/ui/world_map_overlay.tscn")

var world_map_overlay: CanvasLayer
var reward_region_id := ""
var reward_weapon_chosen := false
var reward_armor_chosen := false

func _ready() -> void:
	world_map_overlay = WORLD_MAP_OVERLAY.instantiate()
	world_map_overlay.name = "WorldMapOverlay"
	add_child(world_map_overlay)
	_apply_localized_text()
	_connect_buttons()
	_populate_equipment()
	GameState.player_died.connect(_on_player_died)
	GameState.level_completed.connect(_on_level_completed)
	GameState.equipment_gained.connect(_on_equipment_gained)

func _apply_localized_text() -> void:
	%PauseTitle.text = LocalizationSystem.tr_key("pause")
	%ResumeButton.text = LocalizationSystem.tr_key("resume")
	%EquipmentButton.text = LocalizationSystem.tr_key("equipment")
	%PauseRestartButton.text = LocalizationSystem.tr_key("restart")
	%PauseBackTitleButton.text = LocalizationSystem.tr_key("back_title")
	%DeathTitle.text = LocalizationSystem.tr_key("death_title")
	%RespawnButton.text = LocalizationSystem.tr_key("respawn")
	%DeathRestartButton.text = LocalizationSystem.tr_key("restart_level")
	%DeathBackTitleButton.text = LocalizationSystem.tr_key("back_title")
	%CompleteTitle.text = LocalizationSystem.tr_key("complete_title")
	%PlayAgainButton.text = LocalizationSystem.tr_key("play_again")
	%CompleteBackTitleButton.text = LocalizationSystem.tr_key("back_title")
	%EquipmentTitle.text = LocalizationSystem.tr_key("equipment")
	%WeaponHeader.text = LocalizationSystem.tr_key("weapon")
	%ArmorHeader.text = LocalizationSystem.tr_key("armor")
	%EquipmentBackButton.text = LocalizationSystem.tr_key("back")
	%RewardTitle.text = LocalizationSystem.tr_key("reward_title")
	%WeaponCurrent.text = LocalizationSystem.tr_key("weapon")
	%ArmorCurrent.text = LocalizationSystem.tr_key("armor")
	%WeaponButton.text = LocalizationSystem.tr_key("equip_weapon")
	%WeaponKeepButton.text = LocalizationSystem.tr_key("keep")
	%ArmorButton.text = LocalizationSystem.tr_key("equip_armor")
	%ArmorKeepButton.text = LocalizationSystem.tr_key("keep")
	%ContinueButton.text = LocalizationSystem.tr_key("reward_continue")

func _connect_buttons() -> void:
	%ResumeButton.pressed.connect(_toggle_pause)
	%EquipmentButton.pressed.connect(_open_equipment_panel)
	%PauseRestartButton.pressed.connect(_restart_level)
	%PauseBackTitleButton.pressed.connect(_go_title)
	%RespawnButton.pressed.connect(_respawn)
	%DeathRestartButton.pressed.connect(_restart_level)
	%DeathBackTitleButton.pressed.connect(_go_title)
	%PlayAgainButton.pressed.connect(_restart_level)
	%CompleteBackTitleButton.pressed.connect(_go_title)
	%EquipmentBackButton.pressed.connect(_close_equipment_panel)
	%WeaponButton.pressed.connect(func(): _choose_reward("weapon", true))
	%WeaponKeepButton.pressed.connect(func(): _choose_reward("weapon", false))
	%ArmorButton.pressed.connect(func(): _choose_reward("armor", true))
	%ArmorKeepButton.pressed.connect(func(): _choose_reward("armor", false))
	%ContinueButton.pressed.connect(_close_reward_panel)

func _populate_equipment() -> void:
	for item_id in ["grass_blade", "petal_blade", "spore_edge", "glow_hook", "gale_rock", "rune_blade", "star_edge"]:
		%WeaponColumn.add_child(_make_equipment_button(item_id))
	for item_id in ["none_armor", "moss_light", "mushroom_shell", "root_weave", "gale_plate", "rune_armor", "sky_armor"]:
		%ArmorColumn.add_child(_make_equipment_button(item_id))

func _make_equipment_button(item_id: String) -> Button:
	var button := PixelUI.icon_button(GameState.get_equipment(item_id).display_name, PixelStyleManager.make_equipment_texture(item_id), func():
		GameState.equip(item_id)
		_refresh_equipment_panel()
	)
	button.set_meta("item_id", item_id)
	return button

func _on_player_died() -> void:
	# 与旧版一致：死亡后延迟给死亡动画留时间，再暂停并弹面板。
	await get_tree().create_timer(0.65).timeout
	if not is_inside_tree():
		return
	_show_only(%DeathDim)
	%RespawnButton.grab_focus()

func _on_level_completed() -> void:
	var coin_ratio := 0.0
	if GameState.total_coin_pickups > 0:
		coin_ratio = float(GameState.collected_coin_pickups) / GameState.total_coin_pickups
	%Stats.text = LocalizationSystem.tr_key("complete_stats") % [
		GameState.get_formatted_time(), GameState.collected_coin_pickups, GameState.total_coin_pickups,
		int(coin_ratio * 100.0), GameState.kills, GameState.deaths, GameState.get_rating()
	]
	_show_only(%CompleteDim)

func _toggle_pause() -> void:
	var tree := get_tree()
	tree.paused = not tree.paused
	%PauseDim.visible = tree.paused
	if tree.paused:
		%ResumeButton.grab_focus()

func _show_only(panel: Control) -> void:
	get_tree().paused = true
	for dim in [%PauseDim, %DeathDim, %CompleteDim, %RewardDim, %EquipmentDim]:
		dim.visible = dim == panel

func _hide_all() -> void:
	get_tree().paused = false
	for dim in [%PauseDim, %DeathDim, %CompleteDim, %RewardDim, %EquipmentDim]:
		dim.visible = false

func _restart_level() -> void:
	_hide_all()
	# 重开也走加载界面：重新搭建世界 + 重画像素美术需要数秒。
	GameState.reset_run()
	GameState.pending_loading_screen = true
	get_tree().reload_current_scene.call_deferred()

func _go_title() -> void:
	_hide_all()
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")

func _respawn() -> void:
	_hide_all()
	GameState.respawn_from_checkpoint()

func _open_equipment_panel() -> void:
	_refresh_equipment_panel()
	%PauseDim.visible = false
	%EquipmentDim.visible = true
	%EquipmentBackButton.grab_focus()

func _close_equipment_panel() -> void:
	%EquipmentDim.visible = false
	%PauseDim.visible = true

func _refresh_equipment_panel() -> void:
	for column in [%WeaponColumn, %ArmorColumn]:
		for button in column.get_children():
			if button is Button and button.has_meta("item_id"):
				var item := GameState.get_equipment(str(button.get_meta("item_id")))
				var owned := GameState.owns_equipment(str(button.get_meta("item_id")))
				var equipped := str(button.get_meta("item_id")) in [GameState.equipped_weapon_id, GameState.equipped_armor_id]
				var state := LocalizationSystem.tr_key("state_equipped") if equipped else (LocalizationSystem.tr_key("state_owned") if owned else LocalizationSystem.tr_key("state_locked"))
				button.text = "%s · %s" % [state, item.display_name]
				button.disabled = not owned

func _on_equipment_gained(weapon_id: String, armor_id: String, region_id: String) -> void:
	reward_region_id = region_id
	reward_weapon_chosen = false
	reward_armor_chosen = false
	var weapon := GameState.get_equipment(weapon_id)
	var armor := GameState.get_equipment(armor_id)
	%WeaponIcon.texture = PixelStyleManager.make_equipment_texture(weapon_id)
	%ArmorIcon.texture = PixelStyleManager.make_equipment_texture(armor_id)
	%WeaponCurrent.text = LocalizationSystem.tr_key("current") % GameState.get_current_weapon().display_name
	%WeaponNew.text = LocalizationSystem.tr_key("new_item") % [LocalizationSystem.tr_key("weapon"), weapon.description]
	%ArmorCurrent.text = LocalizationSystem.tr_key("current") % GameState.get_current_armor().display_name
	%ArmorNew.text = LocalizationSystem.tr_key("new_item") % [LocalizationSystem.tr_key("armor"), armor.description]
	%WeaponButton.text = LocalizationSystem.tr_key("equip_weapon")
	%WeaponButton.disabled = false
	%WeaponKeepButton.text = LocalizationSystem.tr_key("keep")
	%WeaponKeepButton.disabled = false
	%ArmorButton.text = LocalizationSystem.tr_key("equip_armor")
	%ArmorButton.disabled = false
	%ArmorKeepButton.text = LocalizationSystem.tr_key("keep")
	%ArmorKeepButton.disabled = false
	%ContinueButton.disabled = true
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		return
	_show_only(%RewardDim)
	%WeaponButton.grab_focus()

func _choose_reward(slot: String, equip_item: bool) -> void:
	var region := DataCatalog.region_metadata(reward_region_id)
	if slot == "weapon":
		reward_weapon_chosen = true
		if equip_item:
			GameState.equip(str(region.get("weapon", "")))
			%WeaponButton.text = LocalizationSystem.tr_key("equipped")
		else:
			%WeaponButton.text = LocalizationSystem.tr_key("equip")
			%WeaponKeepButton.text = LocalizationSystem.tr_key("kept")
		%WeaponButton.disabled = true
		%WeaponKeepButton.disabled = true
	else:
		reward_armor_chosen = true
		if equip_item:
			GameState.equip(str(region.get("armor", "")))
			%ArmorButton.text = LocalizationSystem.tr_key("equipped")
		else:
			%ArmorButton.text = LocalizationSystem.tr_key("equip")
			%ArmorKeepButton.text = LocalizationSystem.tr_key("kept")
		%ArmorButton.disabled = true
		%ArmorKeepButton.disabled = true
	%ContinueButton.disabled = not (reward_weapon_chosen and reward_armor_chosen)

func _close_reward_panel() -> void:
	_hide_all()

func _input(event: InputEvent) -> void:
	# 加载界面显示期间不响应地图/暂停输入，避免加载未完成就打开覆盖层。
	if get_tree().get_first_node_in_group("loading_screen") != null:
		return
	if event.is_action_pressed("toggle_map"):
		if world_map_overlay.visible:
			world_map_overlay.close_map()
		elif not %DeathDim.visible and not %CompleteDim.visible and not %PauseDim.visible and not %EquipmentDim.visible:
			world_map_overlay.open_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and world_map_overlay.visible:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and %EquipmentDim.visible:
		_close_equipment_panel()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and not %DeathDim.visible and not %CompleteDim.visible and not %RewardDim.visible:
		_toggle_pause()
		get_viewport().set_input_as_handled()
