class_name EnemyBehaviors
extends RefCounted

## 敌人 AI 行为集合：从 basic_enemy.gd 拆分而来。
## 所有方法接受 enemy 实例参数,直接读写其状态。

const FLYING_KINDS := ["pollen_bee", "glow_bat", "wind_falcon", "star_wisp"]

static func is_flying(enemy: CharacterBody2D) -> bool:
	return enemy.enemy_kind in FLYING_KINDS

static func process_patrol(enemy: CharacterBody2D, delta: float) -> void:
	var player := _find_player(enemy)
	if enemy.enemy_kind == "root_ambusher":
		process_ambusher(enemy, player)
	elif is_flying(enemy):
		process_flyer(enemy, player, delta)
	elif enemy.data.front_guard:
		process_snail(enemy, player, delta)
	elif enemy.enemy_kind == "slime":
		process_slime(enemy, player, delta)
	elif enemy.enemy_kind in ["thorn_roller", "sky_knight", "wind_falcon"]:
		process_charger(enemy, player)
	elif enemy.enemy_kind in ["spore_lobber", "rock_thrower", "rune_weaver"]:
		process_caster(enemy, player, delta)
	else:
		enemy.velocity.x = enemy.direction * enemy.data.move_speed
		enemy._turn_at_terrain()

static func process_flyer(enemy: CharacterBody2D, player: Node2D, delta: float) -> void:
	var patrol_bounds := _patrol_bounds(enemy)
	var local_x: float = enemy.global_position.x - patrol_bounds.x
	if enemy.is_on_wall() and enemy.turn_cooldown <= 0.0:
		enemy.direction = -1 if enemy.velocity.x > 0.0 else 1
		enemy.turn_cooldown = 0.22
	if local_x <= 120.0:
		enemy.direction = 1
	elif local_x >= patrol_bounds.y - 120.0:
		enemy.direction = -1
	if player == null:
		enemy.velocity.x = enemy.direction * enemy.data.move_speed
		return
	var offset := player.global_position - enemy.global_position
	if offset.length() < enemy.data.detection_range:
		enemy.direction = 1 if offset.x > 0.0 else -1
		enemy.velocity.x = move_toward(enemy.velocity.x, signf(offset.x) * enemy.data.move_speed, 850.0 * delta)
		enemy.velocity.y = sin(enemy.phase) * 70.0 + clampf(offset.y, -80.0, 80.0) * 0.8
		if enemy.enemy_kind == "wind_falcon" and absf(offset.x) < 260.0:
			enemy.velocity.x = signf(offset.x) * enemy.data.charge_speed
	else:
		enemy.velocity.x = enemy.direction * enemy.data.move_speed
		enemy.velocity.y = sin(enemy.phase) * 55.0

static func process_ambusher(enemy: CharacterBody2D, player: Node2D) -> void:
	if player == null:
		enemy.velocity.x = 0.0
		return
	var distance := enemy.global_position.distance_to(player.global_position)
	if enemy.is_hidden:
		if distance < enemy.data.detection_range:
			enemy.is_hidden = false
			enemy.velocity.y = -360.0
			enemy._spawn_text("!", PixelPalette.YELLOW_LIGHT)
		else:
			enemy.velocity.x = 0.0
		return
	if distance < 170.0:
		enemy.velocity.x = enemy.direction * enemy.data.charge_speed
		enemy.direction = 1 if player.global_position.x > enemy.global_position.x else -1
	else:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 900.0)

static func process_charger(enemy: CharacterBody2D, player: Node2D) -> void:
	if enemy.state != 0:  # State.PATROL
		return
	enemy._turn_at_terrain(true)
	enemy.velocity.x = enemy.direction * enemy.data.move_speed
	if player != null and enemy.global_position.distance_to(player.global_position) < enemy.data.detection_range:
		enemy.direction = 1 if player.global_position.x > enemy.global_position.x else -1
		enemy.state = 1  # State.WINDUP
		enemy.state_timer = 0.38

static func process_caster(enemy: CharacterBody2D, player: Node2D, delta: float) -> void:
	enemy.attack_cooldown = maxf(0.0, enemy.attack_cooldown - delta)
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 800.0)
	if player != null and enemy.attack_cooldown <= 0.0 and enemy.global_position.distance_to(player.global_position) < enemy.data.detection_range:
		enemy.direction = 1 if player.global_position.x > enemy.global_position.x else -1
		_fire_enemy_projectile(enemy, player)
		enemy.attack_cooldown = 1.8
		if enemy.enemy_kind == "rune_weaver":
			var teleport_offset := Vector2(enemy.direction * -180.0, 0.0)
			if not enemy.test_move(enemy.global_transform, teleport_offset):
				enemy.global_position += teleport_offset

static func process_snail(enemy: CharacterBody2D, player: Node2D, _delta: float) -> void:
	if enemy.state != 0:  # State.PATROL
		return
	enemy._turn_at_terrain()
	enemy.velocity.x = enemy.direction * enemy.data.move_speed
	if player and enemy.global_position.distance_to(player.global_position) < enemy.data.detection_range and absf(enemy.global_position.y - player.global_position.y) < 70.0:
		enemy.direction = 1 if player.global_position.x > enemy.global_position.x else -1
		enemy.state = 1  # State.WINDUP
		enemy.state_timer = enemy.data.windup_time
		AudioManager.play_sfx("block")

static func process_slime(enemy: CharacterBody2D, player: Node2D, delta: float) -> void:
	enemy.hop_timer -= delta
	if player and enemy.global_position.distance_to(player.global_position) < enemy.data.detection_range:
		var chase := signf(player.global_position.x - enemy.global_position.x)
		if absf(chase) > 0.1 and enemy.is_on_floor() and enemy.hop_timer <= 0.0:
			if enemy.is_mini:
				enemy.velocity = Vector2(
					chase * randf_range(250.0, 320.0),
					-400.0
				)
				enemy.hop_timer = randf_range(0.42, 0.62)
			else:
				enemy.velocity = Vector2(chase * randf_range(130.0, 190.0), -430.0)
				enemy.hop_timer = randf_range(0.85, 1.15)
			AudioManager.play_sfx("jump")
	elif enemy.is_on_floor():
		enemy.velocity.x = enemy.direction * enemy.data.move_speed
		enemy._turn_at_terrain(true)

static func _patrol_bounds(enemy: CharacterBody2D) -> Vector2:
	var current := enemy.get_parent()
	while current != null:
		if current.is_in_group("world_zone"):
			var origin := 0.0
			var width := 2400.0
			var origin_value = current.get("zone_offset_x")
			var width_value = current.get("zone_width")
			if origin_value != null:
				origin = float(origin_value)
			if width_value != null:
				width = float(width_value)
			return Vector2(origin, origin + width)
		current = current.get_parent()
	return Vector2(enemy.global_position.x - 1200.0, enemy.global_position.x + 1200.0)

static func _fire_enemy_projectile(enemy: CharacterBody2D, player: Node2D) -> void:
	var angle := enemy.global_position.angle_to_point(player.global_position)
	var projectile := Area2D.new()
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
	projectile.set("direction", Vector2.from_angle(angle))
	projectile.set("speed", 300.0 + float(enemy.data.contact_damage) * 2.0)
	projectile.set("damage", maxi(5, enemy.data.contact_damage - 3))
	projectile.set("lifetime", 2.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16, 16)
	shape.shape = rectangle
	projectile.add_child(shape)
	var visual := ColorRect.new()
	visual.position = Vector2(-7, -7)
	visual.size = Vector2(14, 14)
	visual.color = Color("ffd166")
	projectile.add_child(visual)
	projectile.global_position = enemy.global_position + Vector2(enemy.direction * 24.0, -12.0)
	enemy.get_parent().add_child(projectile)

static func _find_player(enemy: CharacterBody2D) -> Node2D:
	var players := enemy.get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null
