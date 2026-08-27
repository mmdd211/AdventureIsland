extends Node

const CHECKPOINT_SCRIPT := preload("res://scripts/systems/checkpoint.gd")
const WORLD_ZONES := preload("res://scripts/world/world_zones.gd")

var level: Node2D

func _ready() -> void:
	var packed := load("res://scenes/levels/world_map.tscn") as PackedScene
	level = packed.instantiate()
	add_child(level)
	await get_tree().create_timer(0.45).timeout
	# lazy 模式下主动触发所有 zone 的像素美术生成，
	# 否则 _check_zone_themes 检查远端 zone 的 PixelGround 时还没画完。
	for zone_id in WORLD_ZONES.ORDER:
		await PixelStyleManager.apply_pixel_style_for_zone(level.zones[zone_id])
	await get_tree().create_timer(1.6).timeout
	_check_structure()
	await _check_main_travel()
	await _check_branch_route()
	await _check_map_ui()
	await _check_cross_zone_respawn()
	await _check_goal_portal()
	print("WORLD_MAP_CHECK COMPLETE")
	get_tree().quit(0)

func _check_structure() -> void:
	_assert(level.name == "WorldMap", "WorldMap loaded")
	_assert(level.zones.size() == 6, "WorldMap contains six zones")
	for zone_id in ["meadow", "forest", "grove", "canyon", "ruins", "gate"]:
		_assert(level.zones.has(zone_id), "Zone exists: " + zone_id)
		if level.zones.has(zone_id):
			var checkpoints := _find_checkpoints(level.zones[zone_id])
			_assert(checkpoints.size() >= 1, "Zone has a checkpoint: " + zone_id)

	var portals := _find_portals(level.zone_root)
	_assert(portals.size() == 13, "All thirteen zone and goal portals exist")
	var goal_count := 0
	for portal in portals:
		if portal.get("is_goal"):
			goal_count += 1
	_assert(goal_count == 1, "Exactly one final goal portal exists")
	_assert(_find_portals(level.zones.forest).size() == 3, "Forest has main and branch exits")
	_assert(_find_portals(level.zones.canyon).size() == 3, "Canyon has main and side entries")
	_assert(GameState.total_coin_pickups >= 50, "Expanded world registers collectible coins")
	_assert(level.get_tree().get_nodes_in_group("player").size() == 1, "World keeps one player instance")
	_assert(level.camera.limit_right == 3200, "Initial camera bounds are limited to Meadow")
	var hud := level.get_node("GameHUD")
	_assert(hud.get("zone_banner") != null and hud.zone_banner_label.text == "初始草原",
		"Zone banner announces Meadow")
	_assert(AudioManager.get("LEVEL_BGM_BPM") == 132, "Level BGM uses an upbeat tempo")
	var level_music = AudioManager.get("_streams").get("level")
	_assert(level_music != null and level_music.get_meta("style") == "upbeat_chiptune",
		"Level BGM is the light chiptune track")
	_check_zone_themes()
	_check_portal_graph()

func _check_main_travel() -> void:
	var coins := GameState.coins
	var experience := GameState.current_exp
	var health := GameState.current_hp
	var source := _find_portal(level.zones.meadow, "right")
	_assert(source != null, "Meadow right portal exists")
	player().global_position = source.global_position
	player().velocity = Vector2.ZERO
	await get_tree().create_timer(0.80).timeout
	_assert(GameState.current_zone_id == "forest", "Main portal enters Forest")
	_assert(level.camera.limit_left == 3200 and level.camera.limit_right == 7600, "Forest camera bounds applied")
	_assert(player().control_enabled, "Player control returns after teleport")
	_assert(player().global_position.distance_to(_find_portal(level.zones.forest, "left").global_position) < 110.0,
		"Player arrives beside the destination portal")
	_assert(GameState.coins == coins and GameState.current_exp == experience and GameState.current_hp == health,
		"Teleport preserves run state")
	var hud := level.get_node("GameHUD")
	_assert(hud.get("zone_banner_label") != null and hud.zone_banner_label.text == "蘑菇森林",
		"Zone banner updates after teleport")
	_assert(level.zones.meadow.process_mode == Node.PROCESS_MODE_DISABLED, "Departed zone is dormant")
	_assert(level.zones.forest.process_mode == Node.PROCESS_MODE_INHERIT, "Arrival zone is active")
	_assert(_find_portal(level.zones.meadow, "right").monitoring == false, "Departed portal stops monitoring")
	_assert(_find_portal(level.zones.forest, "left").monitoring, "Arrival portal monitors the player")

func _check_zone_themes() -> void:
	var sky_colors := {}
	var ground_signatures := {}
	for zone_id in ["meadow", "forest", "grove", "canyon", "ruins", "gate"]:
		var zone: Node2D = level.zones[zone_id]
		var backdrop := zone.get_node_or_null("ThemeBackdrop") as TextureRect
		var landmarks := zone.get_node_or_null("ThemeLandmarks")
		var sky := str(zone.zone_theme.sky_top)
		_assert(backdrop != null and backdrop.texture != null and backdrop.texture.get_image() != null,
			"Zone has a themed backdrop: " + zone_id)
		_assert(landmarks != null and landmarks.get_child_count() >= 6,
			"Zone has name-specific landmarks: " + zone_id)
		_assert(zone.get_node_or_null("ThemeParticles") == null,
			"Zone has no scattered non-pickup particles: " + zone_id)
		_assert(not sky_colors.has(sky), "Zone sky colors are unique: " + zone_id)
		sky_colors[sky] = true

		var ground := zone.get_node_or_null("Ground1")
		_assert(ground != null and ground.has_meta("zone_theme"), "Ground carries zone theme: " + zone_id)
		var ground_sprite := ground.get_node_or_null("PixelGround") as Sprite2D
		_assert(ground_sprite != null and ground_sprite.texture != null, "Ground receives themed pixel art: " + zone_id)
		_assert(ground.get_node_or_null("PixelDecor/GlowSpores") == null,
			"Ground has no coin-like glow spores: " + zone_id)
		if ground_sprite:
			var image := ground_sprite.texture.get_image()
			var center := image.get_pixel(image.get_width() / 2, mini(12, image.get_height() - 1))
			var signature := center.to_html(false)
			_assert(not ground_signatures.has(signature), "Ground palettes are unique: " + zone_id)
			ground_signatures[signature] = true

func _check_portal_graph() -> void:
	var connections: Array = WORLD_ZONES.CONNECTIONS
	for connection in connections:
		var source := _find_portal(level.zones[connection.from_zone], connection.from_portal)
		var destination := _find_portal(level.zones[connection.to_zone], connection.to_portal)
		_assert(source != null, "Connection source exists: %s/%s" % [connection.from_zone, connection.from_portal])
		_assert(destination != null, "Connection destination exists: %s/%s" % [connection.to_zone, connection.to_portal])
		if source:
			_assert(str(source.target_zone_id) == connection.to_zone and str(source.target_portal_id) == connection.to_portal,
				"Portal points at its declared destination: %s/%s" % [connection.from_zone, connection.from_portal])

	var linked_sources := 0
	for portal in _find_portals(level.zone_root):
		if not portal.is_goal:
			linked_sources += 1
		else:
			_assert(str(portal.target_zone_id).is_empty(), "Goal portal has no zone target")
	_assert(linked_sources == connections.size(), "Every travel portal is wired into the graph")


func _check_hud_layout() -> void:
	var viewport_rect := Rect2(Vector2.ZERO, level.get_viewport().get_visible_rect().size)
	var status_panel := level.get_node("GameHUD/Root/StatusPanel") as Control
	var minimap_panel := level.get_node("GameHUD/Root/MiniMapPanel") as Control
	var status_size := status_panel.get_global_rect().size
	_assert(status_size.x <= 430.0 and status_size.y <= 110.0,
		"Status HUD is compact (%sx%s)" % [status_size.x, status_size.y])
	_assert(viewport_rect.encloses(minimap_panel.get_global_rect()), "Minimap remains on screen")
	var hp_bar: ProgressBar = level.get_node("GameHUD").hp_bar
	_assert(not minimap_panel.get_global_rect().intersects(hp_bar.get_global_rect()), "Minimap does not cover status bars")
	var minimap := level.get_node("GameHUD/Root/MiniMapPanel/ZoneMiniMap")
	_assert(minimap.get("compact") == true, "Mini map uses compact mode")
	_assert(minimap.last_shown_zones == [GameState.current_zone_id], "Mini map only shows the current zone layout")
	_assert(minimap.last_player_marker_visible, "Mini map includes the player position marker")
	_assert(minimap.last_terrain_rect_count >= 10, "Mini map renders real terrain and platform silhouettes")

func _check_branch_route() -> void:
	await _travel(level.zones.forest, "branch_right")
	_assert(GameState.current_zone_id == "grove", "Branch route enters Grove")
	_assert(not GameState.level_finished, "Branch portal does not finish the run")
	await _travel(level.zones.grove, "right")
	_assert(GameState.current_zone_id == "canyon", "Grove connects to Canyon side entry")
	_assert(level.get_tree().get_nodes_in_group("player").size() == 1, "Branch travel does not duplicate player")
	_assert(_count_named(level, "GameHUD") == 1, "Branch travel does not duplicate HUD")

func _check_map_ui() -> void:
	var screens := level.get_node("GameScreens")
	screens._close_world_map()
	await get_tree().process_frame
	_check_hud_layout()
	screens._open_world_map()
	await get_tree().process_frame
	var overlay: CanvasLayer = screens.world_map_overlay
	_assert(overlay.visible and overlay.map_display.visible, "Large world map opens")
	_assert(overlay.map_display.last_shown_zones.size() == 6, "Large map shows all six zone tiles")
	_assert(get_tree().paused, "Large world map pauses gameplay")
	screens._close_world_map()
	await get_tree().process_frame
	_assert(not overlay.visible and not get_tree().paused, "Large world map closes and resumes")

	var map_event := InputEventAction.new()
	map_event.action = "toggle_map"
	map_event.pressed = true
	Input.parse_input_event(map_event)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(overlay.visible and get_tree().paused, "Tab input opens large world map")
	screens._close_world_map()
	await get_tree().process_frame

func _check_cross_zone_respawn() -> void:
	player().invulnerable_timer = 0.0
	GameState.heal_player(GameState.max_hp)
	var canyon_checkpoint: Area2D = _find_checkpoints(level.zones.canyon)[1]
	player().velocity = Vector2.ZERO
	player().global_position = canyon_checkpoint.global_position
	await get_tree().create_timer(0.20).timeout
	_assert(canyon_checkpoint.activated, "Canyon checkpoint activates")
	_assert(GameState.checkpoint_zone_id == "canyon", "Canyon checkpoint stores its zone")

	GameState.activate_zone("forest", Vector2(3295, 492))
	level._activate_zone("forest")
	GameState.damage_player(999)
	await get_tree().create_timer(0.85).timeout
	var screens := level.get_node("GameScreens")
	_assert(screens.death_panel.visible, "Death screen appears after cross-zone damage")
	screens._respawn()
	await get_tree().process_frame
	_assert(GameState.checkpoint_zone_id == "forest", "Old Canyon checkpoint is not reused in Forest")
	_assert(player().global_position.distance_to(GameState.checkpoint_position) < 60.0, "Respawn uses the active zone checkpoint")

func _check_goal_portal() -> void:
	GameState.heal_player(GameState.max_hp)
	level._activate_zone("gate")
	var goal := _find_portal(level.zones.gate, "goal")
	player().velocity = Vector2.ZERO
	player().global_position = goal.global_position
	await get_tree().create_timer(0.30).timeout
	var screens := level.get_node("GameScreens")
	_assert(GameState.level_finished, "Final portal finishes the expanded world")
	_assert(screens.complete_panel.visible, "Completion screen appears")

func _travel(zone: Node2D, portal_id: String) -> void:
	var portal := _find_portal(zone, portal_id)
	_assert(portal != null, "Portal exists for travel: " + portal_id)
	if portal == null:
		return
	portal.set("triggered", true)
	level._on_portal_travel_requested(portal)
	await get_tree().create_timer(0.62).timeout

func player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player") as CharacterBody2D

func _find_portal(root_node: Node, portal_id: String) -> Area2D:
	for portal in _find_portals(root_node):
		if str(portal.get("portal_id")) == portal_id:
			return portal
	return null

func _find_portals(root_node: Node) -> Array:
	var result: Array = []
	for node in root_node.find_children("*", "Area2D", true, false):
		if node.has_method("reset_portal"):
			result.append(node)
	return result

func _find_checkpoints(root_node: Node) -> Array:
	var result: Array = []
	for node in root_node.find_children("*", "Area2D", true, false):
		if node.get_script() == CHECKPOINT_SCRIPT:
			result.append(node)
	return result

func _count_named(root_node: Node, node_name: String) -> int:
	var count := 0
	for node in root_node.find_children("*", "", true, false):
		if node.name == node_name:
			count += 1
	return count

func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		get_tree().quit(1)
