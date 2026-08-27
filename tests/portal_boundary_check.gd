# 传送门敌人边界检查：巡逻敌人走向传送门时应被隐形挡墙拦下并转身，
# 且全程不与传送门碰撞区重叠；玩家碰撞掩码不含敌人边界层，可照常进出。
extends Node

const PORTAL_SCENE := preload("res://scenes/systems/portal.tscn")
const ENEMY_SCENE := preload("res://scenes/monsters/basic_enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var portal: Area2D
var enemy: CharacterBody2D

func _ready() -> void:
	_build_ground()
	_build_portal()
	_build_enemy()
	_build_player()

	await get_tree().create_timer(2.5).timeout
	var left: StaticBody2D = portal.get_node_or_null("EnemyBoundaryLeft")
	var right: StaticBody2D = portal.get_node_or_null("EnemyBoundaryRight")
	_assert(left != null and right != null, "Portal spawns enemy boundary walls")
	if left == null or right == null:
		return
	_assert(left.collision_layer == 16 and left.collision_mask == 0,
		"Boundary walls only exist on the enemy layer")
	var overlap_limit := 45.0
	_assert(absf(enemy.global_position.x - portal.global_position.x) >= overlap_limit,
		"Enemy never overlaps the portal area")
	_assert(enemy.direction == -1, "Enemy turns away from the portal boundary")
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	_assert(player != null and (player.collision_mask & 16) == 0,
		"Player collision mask ignores enemy boundaries")
	print("PORTAL_BOUNDARY_CHECK COMPLETE")
	get_tree().quit(0)

func _build_ground() -> void:
	var ground := StaticBody2D.new()
	ground.name = "Ground"
	ground.collision_layer = 2
	ground.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1200, 60)
	shape.shape = rectangle
	ground.add_child(shape)
	ground.position = Vector2(0, 30)
	add_child(ground)

func _build_portal() -> void:
	portal = PORTAL_SCENE.instantiate() as Area2D
	portal.name = "PortalRight"
	portal.portal_id = "right"
	portal.position = Vector2(0, -40)
	add_child(portal)

func _build_enemy() -> void:
	enemy = ENEMY_SCENE.instantiate() as CharacterBody2D
	enemy.name = "PatrolEnemy"
	enemy.enemy_kind = "mushroom"
	enemy.spawn_facing = 1
	enemy.position = Vector2(-110, -15)
	add_child(enemy)

func _build_player() -> void:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	player.name = "CheckPlayer"
	player.position = Vector2(240, -30)
	add_child(player)

func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		get_tree().quit(1)
