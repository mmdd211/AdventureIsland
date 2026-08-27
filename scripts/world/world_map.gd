extends Node2D

const ZONE_BUILDER := preload("res://scripts/world/zone_builder.gd")
const WORLD_ZONES := preload("res://scripts/world/world_zones.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const SCREENS_SCENE := preload("res://scenes/ui/game_screens.tscn")
const DEBUG_SCENE := preload("res://scenes/ui/debug_ui.tscn")
const CAMERA_SCRIPT := preload("res://scripts/systems/camera_follow.gd")
const LOADING_OVERLAY := preload("res://scripts/ui/loading_overlay.gd")

signal loading_finished

var zones := {}
var zone_root: Node2D
var player: CharacterBody2D
var camera: Camera2D
var fade_rect: ColorRect
var transitioning := false
var loading_overlay: CanvasLayer

func _ready() -> void:
	add_to_group("pixel_style_root")
	if GameState.pending_loading_screen:
		# 从标题屏/重开进入：在加载界面下分阶段搭建世界，避免长时间卡死。
		GameState.pending_loading_screen = false
		GameState.reset_run()
		_start_loading_flow()
		return
	AudioManager.play_music("level")
	GameState.reset_run()
	_build_zones()
	_build_camera()
	_build_player()
	_build_ui()
	_build_transition_layer()
	_connect_portals()
	# 初始 zone 不触发单 zone 像素化：紧随其后的 _apply_pixel_style 会统一处理活跃 zone，
	# 两条路径同时跑会把 meadow 的地形位图连续生成两遍，抵消懒加载带来的启动优化。
	_activate_zone(GameState.INITIAL_ZONE_ID, false)
	GameState.activate_zone(GameState.INITIAL_ZONE_ID, player.position)
	camera.global_position = player.global_position
	call_deferred("_apply_pixel_style")

func _build_zones() -> void:
	zone_root = Node2D.new()
	zone_root.name = "ZoneRoot"
	add_child(zone_root)
	for zone_id in WORLD_ZONES.ORDER:
		_build_one_zone(zone_id)

func _build_one_zone(zone_id: String) -> void:
	var metadata: Dictionary = WORLD_ZONES.METADATA[zone_id]
	var zone: Node2D = ZONE_BUILDER.new()
	zone.setup(metadata)
	zone_root.add_child(zone)
	zone.build_common()
	WORLD_ZONES.build(zone)
	zones[zone_id] = zone

func _start_loading_flow() -> void:
	# 先搭好摄像机/玩家/UI/过渡层，再暂停游戏并显示加载界面，
	# 随后在 _run_loading_steps 里分阶段完成音乐、地形、唤醒、美术。
	zone_root = Node2D.new()
	zone_root.name = "ZoneRoot"
	add_child(zone_root)
	_build_camera()
	_build_player()
	_build_ui()
	_build_transition_layer()
	player.control_enabled = false
	get_tree().paused = true
	loading_overlay = LOADING_OVERLAY.new()
	loading_overlay.name = "LoadingOverlay"
	add_child(loading_overlay)
	call_deferred("_run_loading_steps")

func _run_loading_steps() -> void:
	# ① 分块预载关卡 BGM：同步合成 17 万帧波形会阻塞数秒。
	var music_progress := func(music_name: String, progress: float):
		if music_name == "level":
			loading_overlay.set_progress(0.18 * progress)
	AudioManager.music_preload_progress.connect(music_progress)
	loading_overlay.set_stage("正在谱写冒险曲…")
	await AudioManager.preload_music_async("level")
	AudioManager.music_preload_progress.disconnect(music_progress)

	# ② 逐个搭建六大区域，每完成一个汇报一次进度。
	var total_zones := WORLD_ZONES.ORDER.size()
	for i in total_zones:
		var zone_id: String = WORLD_ZONES.ORDER[i]
		var metadata: Dictionary = WORLD_ZONES.METADATA[zone_id]
		loading_overlay.set_stage("正在搭建「%s」…" % str(metadata["display_name"]))
		_build_one_zone(zone_id)
		zones[zone_id].process_mode = Node.PROCESS_MODE_DISABLED
		loading_overlay.set_progress(0.18 + 0.50 * float(i + 1) / float(total_zones))
		await get_tree().process_frame

	# ③ 唤醒世界：连接传送门、激活初始区域、放置玩家。
	loading_overlay.set_stage("正在唤醒世界…")
	_connect_portals()
	_activate_zone(GameState.INITIAL_ZONE_ID, false)
	player.position = Vector2(110, 492)
	player.velocity = Vector2.ZERO
	GameState.activate_zone(GameState.INITIAL_ZONE_ID, player.position)
	camera.global_position = player.global_position
	camera.reset_smoothing()
	loading_overlay.set_progress(0.68)
	await get_tree().process_frame

	# ④ 只给活跃区域画像素美术，其余区域留到进区时懒加载。
	var style_progress := func(done: int, total: int):
		if total > 0:
			loading_overlay.set_progress(0.68 + 0.30 * float(done) / float(total))
	PixelStyleManager.style_progress.connect(style_progress)
	loading_overlay.set_stage("正在描绘像素画…")
	await PixelStyleManager.apply_pixel_style_for_active()
	PixelStyleManager.style_progress.disconnect(style_progress)

	# ⑤ 完成：起音乐、解除暂停、淡出加载界面。
	loading_overlay.set_stage("出发！")
	loading_overlay.set_progress(1.0)
	AudioManager.play_music("level")
	get_tree().paused = false
	player.invulnerable_timer = 1.0
	player.control_enabled = true
	await loading_overlay.finish()
	loading_overlay = null
	loading_finished.emit()

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.limit_top = -520
	camera.limit_bottom = 800
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.set_script(CAMERA_SCRIPT)
	add_child(camera)

func _build_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector2(110, 492)
	add_child(player)

func _build_ui() -> void:
	var hud := HUD_SCENE.instantiate()
	hud.name = "GameHUD"
	add_child(hud)
	var screens := SCREENS_SCENE.instantiate()
	screens.name = "GameScreens"
	add_child(screens)
	var debug_ui := DEBUG_SCENE.instantiate()
	debug_ui.name = "DebugUI"
	add_child(debug_ui)

func _build_transition_layer() -> void:
	var transition_layer := CanvasLayer.new()
	transition_layer.name = "TransitionLayer"
	transition_layer.layer = 45
	add_child(transition_layer)
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_layer.add_child(fade_rect)

func _connect_portals() -> void:
	for zone in zones.values():
		for node in zone.find_children("*", "Area2D", true, false):
			if node.has_signal("travel_requested"):
				node.travel_requested.connect(_on_portal_travel_requested)

func _on_portal_travel_requested(source: Area2D) -> void:
	if transitioning or source.get("triggered") != true:
		return
	var target_zone_id := str(source.get("target_zone_id"))
	var target_portal_id := str(source.get("target_portal_id"))
	if target_zone_id.is_empty() or not zones.has(target_zone_id):
		push_error("Unknown portal destination: %s" % target_zone_id)
		return

	transitioning = true
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	await _fade(1.0, 0.18)

	var destination_portal := _find_portal(zones[target_zone_id], target_portal_id)
	if destination_portal == null:
		push_error("Missing destination portal %s in %s" % [target_portal_id, target_zone_id])
		# 目标传送点缺失时也要把黑幕淡回去并复位触发，否则画面永久停在黑屏。
		source.set("triggered", false)
		await _fade(0.0, 0.22)
		transitioning = false
		player.control_enabled = true
		return

	_activate_zone(target_zone_id)
	source.set("triggered", false)
	destination_portal.set("triggered", false)
	player.global_position = destination_portal.global_position + _arrival_offset(str(destination_portal.get("portal_id")))
	player.velocity = Vector2.ZERO
	GameState.activate_zone(target_zone_id, player.global_position)
	_apply_camera_bounds(zones[target_zone_id])
	camera.global_position = player.global_position
	camera.reset_smoothing()
	await _fade(0.0, 0.22)

	player.control_enabled = true
	transitioning = false

func _activate_zone(zone_id: String, trigger_style := true) -> void:
	for candidate_id in zones:
		var zone: Node = zones[candidate_id]
		var active: bool = candidate_id == zone_id
		zone.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		for node in zone.find_children("*", "Area2D", true, false):
			node.set_deferred("monitoring", active)
			node.set_deferred("monitorable", active)
	if zones.has(zone_id):
		# 玩家跨区进入新 zone 时，再补一次像素美术生成（首次进入世界时由 _apply_pixel_style 走活跃 zone 完成）。
		var target_zone: Node = zones[zone_id]
		if trigger_style and target_zone.process_mode == Node.PROCESS_MODE_INHERIT:
			PixelStyleManager.call_deferred("apply_pixel_style_for_zone", target_zone)
		_apply_camera_bounds(zones[zone_id])

func _apply_camera_bounds(zone: Node2D) -> void:
	camera.limit_left = int(zone.zone_offset_x)
	camera.limit_right = int(zone.zone_offset_x + zone.zone_width)

func _find_portal(root_node: Node, portal_id: String) -> Area2D:
	for node in root_node.find_children("*", "Area2D", true, false):
		if node.has_method("reset_portal") and str(node.get("portal_id")) == portal_id:
			return node
	return null

func _arrival_offset(portal_id: String) -> Vector2:
	if portal_id.contains("right"):
		return Vector2(-78, 0)
	return Vector2(78, 0)

func _fade(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "color:a", target_alpha, duration)
	await tween.finished

func _apply_pixel_style() -> void:
	# 首次进入世界：只对当前活跃 zone（meadow）画像素美术，
	# 避免点开始游戏时把 6 个 zone 的 ~200 个 body 一次性画完导致卡顿。
	PixelStyleManager.apply_pixel_style_for_active()
