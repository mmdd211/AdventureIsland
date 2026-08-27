extends Node2D

const ENEMY_SCENE := preload("res://scenes/monsters/basic_enemy.tscn")
const PICKUP_SCENE := preload("res://scenes/systems/coin.tscn")
const PORTAL_SCENE := preload("res://scenes/systems/portal.tscn")
const DEATH_ZONE_SCRIPT := preload("res://scripts/systems/death_zone.gd")
const SPRING_SCRIPT := preload("res://scripts/systems/spring.gd")
const CHECKPOINT_SCRIPT := preload("res://scripts/systems/checkpoint.gd")
const MOVING_PLATFORM_SCRIPT := preload("res://scripts/systems/moving_platform.gd")
const CRUMBLING_PLATFORM_SCRIPT := preload("res://scripts/systems/crumbling_platform.gd")
const SPIKE_SCRIPT := preload("res://scripts/systems/spike_strip.gd")
const ZONE_THEME_SCRIPT := preload("res://scripts/world/zone_theme.gd")
const Palette := preload("res://scripts/systems/pixel_palette.gd")

var zone_id := ""
var display_name := ""
var zone_width := 3200.0
var zone_offset_x := 0.0
var floor_top := 520.0
var zone_theme: Dictionary = {}
var sequence_index := 0

func setup(metadata: Dictionary) -> void:
	zone_id = metadata.get("id", "")
	display_name = metadata.get("display_name", "")
	zone_width = float(metadata.get("width", 3200.0))
	zone_offset_x = float(metadata.get("offset_x", 0.0))
	floor_top = float(metadata.get("floor_top", 520.0))
	zone_theme = metadata.get("theme", {})
	name = "Zone_%s" % zone_id.capitalize()
	position = Vector2(zone_offset_x, 0.0)

func build_common() -> void:
	add_to_group("world_zone")
	ZONE_THEME_SCRIPT.build(self)
	_static_body("LeftWall", Vector2(-18, 100), Vector2(36, 1600), Palette.STONE_DARK)
	_static_body("RightWall", Vector2(zone_width + 18, 100), Vector2(36, 1600), Palette.STONE_DARK)
	var death_zone := Area2D.new()
	death_zone.name = "DeathZone"
	death_zone.collision_layer = 0
	death_zone.collision_mask = 7
	death_zone.position = Vector2(zone_width * 0.5, 790)
	death_zone.set_script(DEATH_ZONE_SCRIPT)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(zone_width + 80.0, 70.0)
	shape.shape = rectangle
	death_zone.add_child(shape)
	add_child(death_zone)

func _ground(index: int, position_value: Vector2, size_value: Vector2) -> void:
	var body := _static_collision_body("Ground%d" % index, position_value, size_value)
	_theme_collision_body(body)
	_attach_visual(body, size_value, _theme_color("ground_body", Palette.DIRT_DARK))
	add_child(body)

func _static_platform(index: int, position_value: Vector2, size_value: Vector2, one_way := false) -> void:
	var body := _static_collision_body("Platform%d" % index, position_value, size_value, one_way)
	_theme_collision_body(body)
	_attach_visual(body, size_value, _theme_color("accent", Palette.WOOD), true)
	add_child(body)

func _one_way_platform(index: int, position_value: Vector2, size_value: Vector2) -> void:
	var body := _static_collision_body("PlatformOneWay%d" % index, position_value, size_value, true)
	_theme_collision_body(body)
	_attach_visual(body, size_value, _theme_color("ground_body", Palette.DIRT), true)
	add_child(body)

func _moving_platform(name_suffix: String, position_value: Vector2, travel: Vector2, period: float, phase := 0.0) -> void:
	var platform: AnimatableBody2D = MOVING_PLATFORM_SCRIPT.new()
	platform.name = "PlatformMoving%s" % name_suffix
	platform.travel = travel
	platform.period = period
	platform.phase = phase
	platform.setup(Vector2(145, 18))
	platform.set_meta("zone_theme", zone_theme)
	platform.set_meta("zone_id", zone_id)
	platform.position = position_value
	add_child(platform)

func _crumbling_platform(position_value: Vector2) -> void:
	sequence_index += 1
	var platform: StaticBody2D = CRUMBLING_PLATFORM_SCRIPT.new()
	platform.name = "PlatformCrumble%d" % sequence_index
	platform.set_meta("zone_theme", zone_theme)
	platform.set_meta("zone_id", zone_id)
	platform.position = position_value
	add_child(platform)

func _enemy(kind_value: String, position_value: Vector2) -> void:
	sequence_index += 1
	var enemy := ENEMY_SCENE.instantiate()
	enemy.name = "%s%d" % [kind_value.capitalize(), sequence_index]
	enemy.enemy_kind = kind_value
	enemy.position = position_value
	add_child(enemy)

func _pickup(position_value: Vector2, pickup_type := "coin", amount := 1) -> void:
	sequence_index += 1
	var pickup := PICKUP_SCENE.instantiate()
	pickup.name = "Pickup%d" % sequence_index
	pickup.pickup_type = pickup_type
	pickup.value = amount
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

func _portal(id: String, position_value: Vector2, destination_zone := "", destination_portal := "", goal := false) -> void:
	var portal := PORTAL_SCENE.instantiate()
	portal.name = "PortalGoal" if goal else "Portal%s" % id.capitalize()
	portal.portal_id = id
	portal.target_zone_id = destination_zone
	portal.target_portal_id = destination_portal
	portal.is_goal = goal
	portal.set_meta("zone_theme", zone_theme)
	portal.set_meta("zone_id", zone_id)
	portal.position = position_value
	add_child(portal)

func _static_body(body_name: String, body_position: Vector2, size_value: Vector2, color: Color) -> void:
	var body := _static_collision_body(body_name, body_position, size_value)
	_theme_collision_body(body)
	_attach_visual(body, size_value, color)
	add_child(body)

func _static_collision_body(body_name: String, position_value: Vector2, size_value: Vector2, one_way := false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = position_value
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
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
	if floating:
		return
	var fill := ColorRect.new()
	fill.name = "GroundFill"
	fill.position = visual.position
	fill.size = Vector2(size_value.x, 260.0)
	fill.color = Color(_theme_color("ground_dark", Palette.DIRT_DARK), 0.96)
	fill.z_index = -1
	body.add_child(fill)

func _theme_collision_body(body: Node) -> void:
	body.set_meta("zone_theme", zone_theme)
	body.set_meta("zone_id", zone_id)

func _theme_color(key: String, fallback: Color) -> Color:
	if zone_theme.has(key):
		return Color(str(zone_theme[key]))
	return fallback
