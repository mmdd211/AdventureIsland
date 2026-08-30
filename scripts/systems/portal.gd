extends Area2D

const ENEMY_BOUNDARY_LAYER := 16
const ENEMY_BOUNDARY_SIZE := Vector2(8.0, 120.0)
const ENEMY_BOUNDARY_OFFSET_X := 36.0

var time := 0.0
var triggered := false
var locked := false
var portal_sprite: AnimatedSprite2D

@export var target_zone_id := ""
@export var target_portal_id := ""
@export var portal_id := ""
@export var is_goal := true
@export var lock_region_id := ""
signal travel_requested(portal: Area2D)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("portals")
	_build_enemy_boundaries()
	call_deferred("_capture_portal")
	_refresh_locked()

func _build_enemy_boundaries() -> void:
	# 传送门两侧的隐形挡墙只存在于敌人碰撞层：
	# 敌人无法巡逻/冲锋/跳进传送门，玩家的碰撞掩码不含该层，照常进出。
	for side in [-1.0, 1.0]:
		var boundary := StaticBody2D.new()
		boundary.name = "EnemyBoundaryLeft" if side < 0.0 else "EnemyBoundaryRight"
		boundary.collision_layer = ENEMY_BOUNDARY_LAYER
		boundary.collision_mask = 0
		boundary.position = Vector2(side * ENEMY_BOUNDARY_OFFSET_X, -20.0)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = ENEMY_BOUNDARY_SIZE
		shape.shape = rectangle
		boundary.add_child(shape)
		add_child(boundary)

func _capture_portal() -> void:
	portal_sprite = get_node_or_null("PixelPortal") as AnimatedSprite2D

func _process(delta: float) -> void:
	time += delta
	if portal_sprite:
		if locked:
			portal_sprite.modulate = Color(0.55, 0.55, 0.58, 0.72)
		else:
			portal_sprite.modulate = Color(1, 1, 1, 0.86 + sin(time * 5.0) * 0.12)

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	if locked:
		AudioManager.play_sfx("block")
		_show_locked_text()
		return
	triggered = true
	body.velocity = Vector2.ZERO
	AudioManager.play_sfx("portal")
	if is_goal:
		GameState.complete_level()
	else:
		travel_requested.emit(self)

func reset_portal() -> void:
	triggered = false

func _refresh_locked() -> void:
	locked = not lock_region_id.is_empty() and not GameState.is_boss_defeated(lock_region_id)

func _show_locked_text() -> void:
	var label := Label.new()
	label.text = "先击败本区域精英守卫"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.z_index = 200
	add_child(label)
	label.position = Vector2(-90, -92)
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)
