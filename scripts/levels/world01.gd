extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/monsters/basic_enemy.tscn")
const PICKUP_SCENE := preload("res://scenes/systems/coin.tscn")
const PORTAL_SCENE := preload("res://scenes/systems/portal.tscn")
const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const SCREENS_SCENE := preload("res://scenes/ui/game_screens.tscn")
const DEBUG_SCENE := preload("res://scenes/ui/debug_ui.tscn")

const CAMERA_SCRIPT := preload("res://scripts/systems/camera_follow.gd")
const DEATH_ZONE_SCRIPT := preload("res://scripts/systems/death_zone.gd")
const SPRING_SCRIPT := preload("res://scripts/systems/spring.gd")
const CHECKPOINT_SCRIPT := preload("res://scripts/systems/checkpoint.gd")
const MOVING_PLATFORM_SCRIPT := preload("res://scripts/systems/moving_platform.gd")
const CRUMBLING_PLATFORM_SCRIPT := preload("res://scripts/systems/crumbling_platform.gd")
const SPIKE_SCRIPT := preload("res://scripts/systems/spike_strip.gd")
const WORLD_BACKGROUND_SCRIPT := preload("res://scripts/effects/world_background.gd")

const LEVEL_WIDTH := 6000.0
const FLOOR_TOP := 520.0

var sequence_index := 0

func _ready() -> void:
	AudioManager.play_music("level")
	_build_background()
	_build_camera()
	_build_bounds()
	_build_warmup()
	_build_first_battle()
	_build_high_route()
	_build_hazard_crossing()
	_build_final_encounter()
	_build_bottomless_pit()
	_spawn_player_and_ui()
	GameState.set_checkpoint(Vector2(110, FLOOR_TOP - 26.0))
	call_deferred("_apply_pixel_style")

func _build_background() -> void:
	var background: ParallaxBackground = WORLD_BACKGROUND_SCRIPT.new()
	background.name = "WorldBackground"
	add_child(background)

func _build_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(640, 320)
	camera.limit_left = 0
	camera.limit_right = int(LEVEL_WIDTH) + 100
	camera.limit_top = -520
	camera.limit_bottom = 800
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.set_script(CAMERA_SCRIPT)
	add_child(camera)

func _build_bounds() -> void:
	_static_body("LeftWall", Vector2(-18, 100), Vector2(36, 1600), Color("596274"))
	_static_body("RightWall", Vector2(LEVEL_WIDTH + 18, 100), Vector2(36, 1600), Color("596274"))

func _build_warmup() -> void:
	_ground(1, Vector2(450, FLOOR_TOP + 15), Vector2(900, 30))
	_static_platform(1, Vector2(270, 430), Vector2(150, 16))
	_static_platform(2, Vector2(530, 360), Vector2(130, 14))
	_static_platform(3, Vector2(790, 290), Vector2(140, 14), true)
	_place_pickup(Vector2(790, 245), "coin")
	_place_pickup(Vector2(380, 480), "coin")
	_place_pickup(Vector2(650, 480), "coin")
	_place_enemy("mushroom", Vector2(720, 480))

func _build_first_battle() -> void:
	_ground(2, Vector2(1560, FLOOR_TOP + 15), Vector2(1080, 30))
	_checkpoint(Vector2(1090, FLOOR_TOP - 50))
	_static_platform(4, Vector2(1290, 400), Vector2(130, 14), true)
	_static_platform(5, Vector2(1660, 350), Vector2(150, 14))
	_static_platform(6, Vector2(1980, 410), Vector2(120, 14), true)
	_place_enemy("mushroom", Vector2(1330, 480))
	_place_enemy("snail", Vector2(1680, 480))
	_place_enemy("slime", Vector2(1960, 480))
	for x in [1240.0, 1420.0, 1600.0, 1780.0]:
		_place_pickup(Vector2(x, 480), "coin")
	_place_pickup(Vector2(1660, 305), "heart", 25)

func _build_high_route() -> void:
	_ground(3, Vector2(2730, FLOOR_TOP + 15), Vector2(940, 30))
	_checkpoint(Vector2(2320, FLOOR_TOP - 50))
	_static_platform(7, Vector2(2470, 435), Vector2(120, 14), true)
	_static_platform(8, Vector2(2680, 365), Vector2(120, 14))
	_static_platform(9, Vector2(2900, 295), Vector2(110, 14), true)
	_static_platform(10, Vector2(3120, 235), Vector2(130, 14))
	_place_enemy("snail", Vector2(2600, 480))
	_place_enemy("slime", Vector2(3010, 480))
	for point in [Vector2(2470, 395), Vector2(2680, 325), Vector2(2900, 255)]:
		_place_pickup(point, "coin")
	for x in [2410.0, 2560.0, 2820.0, 3080.0]:
		_place_pickup(Vector2(x, 480), "coin")
	_place_pickup(Vector2(3120, 190), "heart", 20)

func _build_hazard_crossing() -> void:
	_spring(Vector2(3175, FLOOR_TOP - 13))

	var platform_names := ["PlatformMoving1", "PlatformMoving2", "PlatformMoving3"]
	var positions := [Vector2(3345, 430), Vector2(3630, 385), Vector2(3915, 430)]
	var travels := [Vector2(145, 0), Vector2(165, 0), Vector2(150, 0)]
	var periods := [3.1, 3.6, 3.3]
	for index in range(platform_names.size()):
		var platform: AnimatableBody2D = MOVING_PLATFORM_SCRIPT.new()
		platform.name = platform_names[index]
		platform.travel = travels[index]
		platform.period = periods[index]
		platform.phase = PI * 0.5 * float(index)
		platform.setup(Vector2(145, 18))
		platform.position = positions[index]
		add_child(platform)

	var crumble: StaticBody2D = CRUMBLING_PLATFORM_SCRIPT.new()
	crumble.name = "PlatformCrumble1"
	crumble.position = Vector2(4110, 460)
	add_child(crumble)

	_ground(4, Vector2(5080, FLOOR_TOP + 15), Vector2(1840, 30))
	_checkpoint(Vector2(4235, FLOOR_TOP - 50))
	_spike(Vector2(4425, FLOOR_TOP - 5), 170)
	_spike(Vector2(4680, FLOOR_TOP - 5), 210)
	_one_way_platform(11, Vector2(4425, 410), Vector2(130, 12))
	_one_way_platform(12, Vector2(4680, 350), Vector2(130, 12))
	_place_pickup(Vector2(4425, 365), "coin")
	_place_pickup(Vector2(4680, 305), "coin")

func _build_final_encounter() -> void:
	_static_platform(13, Vector2(4980, 410), Vector2(130, 14), true)
	_static_platform(14, Vector2(5310, 350), Vector2(150, 14))
	_static_platform(15, Vector2(5630, 420), Vector2(120, 14), true)
	_place_enemy("mushroom", Vector2(5060, 480))
	_place_enemy("snail", Vector2(5410, 480))
	_place_enemy("slime", Vector2(5740, 480))
	for x in [4930.0, 5120.0, 5420.0, 5720.0]:
		_place_pickup(Vector2(x, 480), "coin")
	_place_pickup(Vector2(5310, 305), "heart", 20)

	var portal := PORTAL_SCENE.instantiate()
	portal.name = "Portal"
	portal.position = Vector2(5880, FLOOR_TOP - 52)
	add_child(portal)

func _spawn_player_and_ui() -> void:
	var player := PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector2(110, FLOOR_TOP - 28)
	add_child(player)

	var hud := HUD_SCENE.instantiate()
	hud.name = "GameHUD"
	add_child(hud)
	var screens := SCREENS_SCENE.instantiate()
	screens.name = "GameScreens"
	add_child(screens)
	var debug_ui := DEBUG_SCENE.instantiate()
	debug_ui.name = "DebugUI"
	add_child(debug_ui)

func _apply_pixel_style() -> void:
	PixelStyleManager.apply_pixel_style()

func _static_body(body_name: String, body_position: Vector2, size_value: Vector2, color: Color) -> void:
	var body := _static_collision_body(body_name, body_position, size_value)
	_attach_visual(body, size_value, color)
	add_child(body)

func _ground(index: int, position_value: Vector2, size_value: Vector2) -> void:
	var body := _static_collision_body("Ground%d" % index, position_value, size_value)
	_attach_visual(body, size_value, Color("4c3a28"))
	add_child(body)

func _static_platform(index: int, position_value: Vector2, size_value: Vector2, one_way := false) -> void:
	var body := _static_collision_body("Platform%d" % index, position_value, size_value, one_way)
	_attach_visual(body, size_value, Color("7a5230"), one_way)
	add_child(body)

func _one_way_platform(index: int, position_value: Vector2, size_value: Vector2) -> void:
	var body := _static_collision_body("PlatformOneWay%d" % index, position_value, size_value, true)
	_attach_visual(body, size_value, Color("8a5a35"), true)
	add_child(body)

func _static_collision_body(body_name: String, position_value: Vector2, size_value: Vector2, one_way := false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = position_value
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size_value
	shape.shape = rectangle
	shape.one_way_collision = one_way
	shape.one_way_collision_margin = 12.0
	body.add_child(shape)
	return body

func _attach_visual(body: Node2D, size_value: Vector2, color: Color, floating := false) -> void:
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.position = -size_value * 0.5
	visual.size = size_value
	visual.color = color
	body.add_child(visual)
	if not floating:
		var fill := ColorRect.new()
		fill.name = "GroundFill"
		fill.position = visual.position
		fill.size = Vector2(size_value.x, 375)
		fill.color = Color("4a3524")
		fill.z_index = -1
		body.add_child(fill)

		var floor_top := ColorRect.new()
		floor_top.name = "GroundTop"
		floor_top.position = visual.position
		floor_top.size = Vector2(size_value.x, 8)
		floor_top.color = Color("59b64f")
		floor_top.z_index = 1
		body.add_child(floor_top)

		var grass := ColorRect.new()
		grass.name = "Grass1"
		grass.position = Vector2(visual.position.x, visual.position.y)
		grass.size = Vector2(size_value.x, 6)
		grass.color = Color("59b64f")
		body.add_child(grass)

func _place_enemy(kind_value: String, position_value: Vector2) -> void:
	sequence_index += 1
	var enemy := ENEMY_SCENE.instantiate()
	enemy.name = "%s%d" % [kind_value.capitalize(), sequence_index]
	enemy.enemy_kind = kind_value
	enemy.position = position_value
	add_child(enemy)

func _place_pickup(position_value: Vector2, pickup_type := "coin", amount := 1) -> void:
	sequence_index += 1
	var pickup := PICKUP_SCENE.instantiate()
	pickup.name = "Pickup%d" % sequence_index
	pickup.pickup_type = pickup_type
	pickup.value = amount if pickup_type == "heart" else 1
	pickup.position = position_value
	add_child(pickup)

func _checkpoint(position_value: Vector2) -> void:
	sequence_index += 1
	var checkpoint: Area2D = CHECKPOINT_SCRIPT.new()
	checkpoint.name = "Checkpoint%d" % sequence_index
	checkpoint.position = position_value
	add_child(checkpoint)

func _spring(position_value: Vector2) -> void:
	sequence_index += 1
	var spring: Area2D = SPRING_SCRIPT.new()
	spring.name = "Spring%d" % sequence_index
	spring.position = position_value
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(42, 26)
	shape.shape = rectangle
	spring.add_child(shape)
	add_child(spring)

func _spike(position_value: Vector2, width_value: float) -> void:
	sequence_index += 1
	var spikes: Area2D = SPIKE_SCRIPT.new()
	spikes.name = "Spikes%d" % sequence_index
	spikes.position = position_value
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width_value, 22)
	shape.shape = rectangle
	spikes.add_child(shape)
	add_child(spikes)

func _build_bottomless_pit() -> void:
	var death_zone := Area2D.new()
	death_zone.name = "WorldDeathZone"
	death_zone.collision_layer = 0
	death_zone.collision_mask = 7
	death_zone.position = Vector2(LEVEL_WIDTH * 0.5, 790)
	death_zone.set_script(DEATH_ZONE_SCRIPT)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(LEVEL_WIDTH + 700, 70)
	shape.shape = rectangle
	death_zone.add_child(shape)
	add_child(death_zone)
