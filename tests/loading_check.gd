# 加载界面流程检查：标题屏标记 pending_loading_screen 后，
# world_map 应在加载层下分阶段搭建世界，完成后世界可正常游玩。
extends Node

const CHECKPOINT_SCRIPT := preload("res://scripts/systems/checkpoint.gd")

var level: Node2D
var _finished := false
var _start_ms := 0
var _elapsed_ms := 0

func _ready() -> void:
	GameState.pending_loading_screen = true
	var packed := load("res://scenes/levels/world_map.tscn") as PackedScene
	level = packed.instantiate()
	level.loading_finished.connect(_on_loading_finished)
	_start_ms = Time.get_ticks_msec()
	add_child(level)

	# 加载界面应立即出现，且世界尚未搭建、游戏处于暂停。
	await get_tree().process_frame
	_assert(get_tree().get_first_node_in_group("loading_screen") != null,
		"Loading overlay appears immediately")
	_assert(level.loading_overlay != null, "WorldMap tracks the loading overlay")
	_assert(level.zones.size() == 0, "Zones are not built before staged loading")
	_assert(get_tree().paused, "Game is paused while loading")
	_assert(not level.player.control_enabled, "Player control is disabled while loading")

	# 轮询等待加载完成（create_timer 默认 process_always，暂停期间也走）。
	var waited := 0.0
	while not _finished and waited < 30.0:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	_elapsed_ms = Time.get_ticks_msec() - _start_ms
	_assert(_finished, "Loading flow finishes within 30 seconds")
	if not _finished:
		return
	print("Loading took %d ms" % _elapsed_ms)

	_check_world_ready()
	await _check_travel_smoke()
	print("LOADING_CHECK COMPLETE")
	get_tree().quit(0)

func _on_loading_finished() -> void:
	_finished = true

func _check_world_ready() -> void:
	_assert(level.loading_overlay == null, "Loading overlay is removed after finish")
	_assert(get_tree().get_first_node_in_group("loading_screen") == null,
		"No loading screen node remains in the tree")
	_assert(level.zones.size() == 6, "All six zones are built")
	_assert(not get_tree().paused, "Game unpauses after loading")
	_assert(level.player.control_enabled, "Player control returns after loading")
	_assert(absf(level.player.position.x - 110.0) < 60.0 and absf(level.player.position.y - 492.0) < 60.0,
		"Player stands at the meadow spawn point")
	_assert(GameState.current_zone_id == "meadow", "Initial zone is Meadow")
	_assert(level.camera.limit_left == 0 and level.camera.limit_right == 3200,
		"Camera bounds are limited to Meadow")
	var streams: Dictionary = AudioManager.get("_streams")
	var level_music = streams.get("level")
	_assert(level_music != null and level_music.get_meta("style") == "upbeat_chiptune",
		"Level BGM was preloaded asynchronously")
	_assert(AudioManager.get("_current_music") == "level", "Level BGM is playing")
	var ground = level.zones.meadow.get_node_or_null("Ground1")
	_assert(ground != null and ground.get_node_or_null("PixelGround") != null,
		"Meadow ground received pixel art during loading")
	_assert(level.zones.forest.get_node_or_null("Ground1/PixelGround") == null,
		"Inactive zones keep their pixel art for lazy loading")
	_assert(_elapsed_ms < 5000, "Staged loading completes in under five seconds")

func _check_travel_smoke() -> void:
	# 加载完成后世界必须可玩：走一次 meadow → forest 的传送。
	var portal := _find_portal(level.zones.meadow, "right")
	_assert(portal != null, "Meadow right portal exists after loading")
	if portal == null:
		return
	portal.set("triggered", true)
	level._on_portal_travel_requested(portal)
	await get_tree().create_timer(0.9).timeout
	_assert(GameState.current_zone_id == "forest", "Portal travel works after loading screen")
	_assert(level.player.control_enabled, "Player control returns after portal travel")

func _find_portal(root_node: Node, portal_id: String) -> Area2D:
	for node in root_node.find_children("*", "Area2D", true, false):
		if node.has_method("reset_portal") and str(node.get("portal_id")) == portal_id:
			return node
	return null

func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		get_tree().quit(1)
