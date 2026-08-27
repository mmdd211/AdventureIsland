extends Area2D

const ENEMY_BOUNDARY_LAYER := 16
const ENEMY_BOUNDARY_SIZE := Vector2(8.0, 120.0)
const ENEMY_BOUNDARY_OFFSET_X := 36.0

var time := 0.0
var triggered := false
var portal_sprite: AnimatedSprite2D

@export var target_zone_id := ""
@export var target_portal_id := ""
@export var portal_id := ""
@export var is_goal := true
signal travel_requested(portal: Area2D)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_enemy_boundaries()
	call_deferred("_capture_portal")

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
		portal_sprite.modulate.a = 0.86 + sin(time * 5.0) * 0.12

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
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
