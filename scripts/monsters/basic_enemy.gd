extends CharacterBody2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const ENEMY_DATA_SCRIPT := preload("res://scripts/monsters/enemy_data.gd")
const COIN_SCENE := preload("res://scenes/systems/coin.tscn")

@export var data: Resource
@export_enum("mushroom", "snail", "slime") var enemy_kind := "mushroom"
@export var is_mini := false

const MINI_SLIME_SPEED := 110.0
const MINI_CHASE_SPEED := Vector2(250.0, 320.0)
const MINI_HOP_COOLDOWN := Vector2(0.42, 0.62)

enum State { PATROL, WINDUP, CHARGE, RECOVER }

var health := 30
var direction := 1
var state: State = State.PATROL
var state_timer := 0.0
var hop_timer := 0.0
var flash_timer := 0.0
var turn_cooldown := 0.0
var spawn_grace_timer := 0.0
var inherited_contact_damage := 0
var is_dead := false
var gravity := 1750.0
var edge_ray: RayCast2D
var health_fill: ColorRect

func _ready() -> void:
	add_to_group("enemies")
	if data == null:
		data = _create_default_data(enemy_kind)
	if is_mini:
		data = _create_default_data("slime")
		data.max_health = 12
		data.display_name = "小史莱姆"
		data.contact_damage = inherited_contact_damage if inherited_contact_damage > 0 else data.contact_damage
		data.move_speed = MINI_SLIME_SPEED
		data.exp_reward = 6
		data.coin_reward = 1
		data.can_split = false
	health = data.max_health
	direction = -1 if randf() < 0.5 else 1
	_setup_edge_ray()
	_setup_health_bar()
	_refresh_visual_scale()

func _create_default_data(kind_value: String) -> Resource:
	var result: Resource = ENEMY_DATA_SCRIPT.new()
	result.kind = kind_value
	match kind_value:
		"snail":
			result.display_name = "蜗牛"
			result.max_health = 42
			result.move_speed = 32.0
			result.contact_damage = 10
			result.exp_reward = 30
			result.coin_reward = 4
			result.front_guard = true
			result.detection_range = 230.0
			result.charge_speed = 275.0
			result.windup_time = 0.48
		"slime":
			result.display_name = "史莱姆"
			result.max_health = 26
			result.move_speed = 28.0
			result.contact_damage = 8
			result.exp_reward = 22
			result.coin_reward = 2
			result.can_split = true
			result.detection_range = 280.0
		_:
			result.display_name = "蘑菇"
			result.kind = "mushroom"
			result.max_health = 58
			result.move_speed = 46.0
			result.contact_damage = 15
			result.exp_reward = 26
			result.coin_reward = 3
	return result

func _setup_edge_ray() -> void:
	edge_ray = RayCast2D.new()
	edge_ray.position = Vector2.ZERO
	edge_ray.target_position = Vector2(28 * direction, 48)
	edge_ray.collision_mask = 2
	edge_ray.enabled = true
	add_child(edge_ray)

func _setup_health_bar() -> void:
	var background := ColorRect.new()
	background.name = "HealthBackground"
	background.position = Vector2(-19, -38)
	background.size = Vector2(38, 5)
	background.color = Color(0, 0, 0, 0.62)
	background.z_index = 30
	add_child(background)
	health_fill = ColorRect.new()
	health_fill.name = "HealthFill"
	health_fill.position = Vector2(-18, -37)
	health_fill.size = Vector2(36, 3)
	health_fill.color = Palette.RED
	health_fill.z_index = 31
	add_child(health_fill)

func _refresh_visual_scale() -> void:
	var target_scale := Vector2(1.55, 1.55) if is_mini else Vector2(2.0, 2.0)
	for node_name in ["PixelSprite", "Visual"]:
		var node := get_node_or_null(node_name)
		if node:
			node.scale = target_scale

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if spawn_grace_timer > 0.0:
		spawn_grace_timer = maxf(0.0, spawn_grace_timer - delta)
		modulate = Color(1.0, 1.0, 1.0, 0.55 + 0.45 * absf(sin(spawn_grace_timer * 22.0)))
		if spawn_grace_timer <= 0.0:
			modulate = Color.WHITE
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			modulate = Color.WHITE
	turn_cooldown = maxf(0.0, turn_cooldown - delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 900.0)
	else:
		velocity.y = 0.0

	match state:
		State.PATROL:
			_process_patrol(delta)
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			state_timer -= delta
			modulate = Color(1.0, 0.68, 0.30) if fmod(state_timer, 0.16) < 0.08 else Color.WHITE
			if state_timer <= 0.0:
				state = State.CHARGE
				state_timer = 0.72
				modulate = Color(1.0, 0.82, 0.58)
		State.CHARGE:
			velocity.x = direction * data.charge_speed
			state_timer -= delta
			if state_timer <= 0.0 or is_on_wall():
				state = State.RECOVER
				state_timer = 0.38
				modulate = Color.WHITE
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.PATROL

	move_and_slide()
	_update_facing()
	_apply_contact_damage()
	_update_health_bar()

func _process_patrol(delta: float) -> void:
	var player := _find_player()
	if data.front_guard:
		_process_snail(player, delta)
	elif enemy_kind == "slime":
		_process_slime(player, delta)
	else:
		velocity.x = direction * data.move_speed
		_turn_at_terrain()

func _process_snail(player: Node2D, _delta: float) -> void:
	if state != State.PATROL:
		return
	_turn_at_terrain()
	velocity.x = direction * data.move_speed
	if player and global_position.distance_to(player.global_position) < data.detection_range and absf(global_position.y - player.global_position.y) < 70.0:
		direction = 1 if player.global_position.x > global_position.x else -1
		state = State.WINDUP
		state_timer = data.windup_time
		AudioManager.play_sfx("block")

func _process_slime(player: Node2D, delta: float) -> void:
	hop_timer -= delta
	if player and global_position.distance_to(player.global_position) < data.detection_range:
		var chase := signf(player.global_position.x - global_position.x)
		if absf(chase) > 0.1 and is_on_floor() and hop_timer <= 0.0:
			if is_mini:
				velocity = Vector2(
					chase * randf_range(MINI_CHASE_SPEED.x, MINI_CHASE_SPEED.y),
					-400.0
				)
				hop_timer = randf_range(MINI_HOP_COOLDOWN.x, MINI_HOP_COOLDOWN.y)
			else:
				velocity = Vector2(chase * randf_range(130.0, 190.0), -430.0)
				hop_timer = randf_range(0.85, 1.15)
			AudioManager.play_sfx("jump")
	elif is_on_floor():
		velocity.x = direction * data.move_speed
		_turn_at_terrain(true)

func _turn_at_terrain(ignore_edges := false) -> void:
	if turn_cooldown > 0.0:
		return
	if is_on_wall():
		direction *= -1
		turn_cooldown = 0.22
	if not ignore_edges and is_on_floor():
		edge_ray.position = Vector2.ZERO
		edge_ray.target_position = Vector2(28 * direction, 48)
		if not edge_ray.is_colliding():
			direction *= -1
			turn_cooldown = 0.22

func _update_facing() -> void:
	var sprite := get_node_or_null("PixelSprite")
	if sprite:
		sprite.flip_h = direction < 0
	else:
		var visual := get_node_or_null("Visual")
		if visual:
			visual.scale.x = absf(visual.scale.x) * direction

func _apply_contact_damage() -> void:
	if spawn_grace_timer > 0.0:
		return
	var damage_area := get_node_or_null("DamageArea") as Area2D
	if damage_area == null:
		return
	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.call("take_damage", data.contact_damage, global_position)

func take_damage(amount: int, source_position := Vector2.ZERO) -> void:
	if is_dead or spawn_grace_timer > 0.0:
		return
	var shown_amount := amount
	if data.front_guard and state != State.RECOVER:
		var attacker_side := signf(global_position.x - source_position.x)
		if attacker_side == float(direction):
			shown_amount = maxi(1, int(round(amount * 0.2)))
			AudioManager.play_sfx("block")
			_spawn_text("格挡", Palette.CYAN)
		else:
			shown_amount = amount * 2
			_spawn_text("背击!", Palette.YELLOW)

	health -= shown_amount
	flash_timer = 0.09
	modulate = Color(3.0, 3.0, 3.0)
	AudioManager.play_sfx("hit")
	_update_health_bar()
	if shown_amount > 0:
		_spawn_text(str(shown_amount), Color.WHITE)
	if health <= 0:
		die()

func apply_knockback(source_position: Vector2) -> void:
	if is_dead or data.front_guard:
		return
	var away := signf(global_position.x - source_position.x)
	if away == 0.0:
		away = -direction
	velocity += Vector2(away * 170.0, -150.0)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	GameState.register_kill()
	GameState.add_experience(data.exp_reward)
	_spawn_coin_rewards()
	_spawn_text("+%d EXP" % [data.exp_reward], Palette.YELLOW)
	AudioManager.play_sfx("enemy_death")
	_create_death_effect()
	modulate = Color(1.0, 0.7, 0.7, 0.75)
	if data.can_split and not is_mini:
		_split_slime()
		for node_name in ["PixelSprite", "Visual"]:
			var node := get_node_or_null(node_name) as Node2D
			if node:
				node.visible = false
	await get_tree().create_timer(0.32).timeout
	queue_free()

func _split_slime() -> void:
	var scene := load("res://scenes/monsters/basic_enemy.tscn") as PackedScene
	for offset in [-16.0, 16.0]:
		var child := scene.instantiate()
		child.set("enemy_kind", "slime")
		child.set("is_mini", true)
		child.set("spawn_grace_timer", 0.42)
		child.set("inherited_contact_damage", data.contact_damage)
		child.set("position", global_position + Vector2(offset, -6.0))
		get_parent().call_deferred("add_child", child)
	call_deferred("_refresh_split_styles")

func _refresh_split_styles() -> void:
	if PixelStyleManager.has_method("refresh_enemy_styles"):
		PixelStyleManager.call("refresh_enemy_styles")

func _spawn_coin_rewards() -> void:
	for index in range(data.coin_reward):
		var coin := COIN_SCENE.instantiate() as Node2D
		coin.set("pickup_type", "coin")
		coin.set("value", 1)
		var angle := TAU * float(index) / maxf(1.0, float(data.coin_reward))
		coin.set("position", global_position + Vector2(cos(angle) * 14.0, -8.0))
		get_parent().call_deferred("add_child", coin)

func _update_health_bar() -> void:
	if health_fill:
		health_fill.size.x = maxf(0.0, 36.0 * float(maxi(health, 0)) / float(data.max_health))

func _spawn_text(text_value: String, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.z_index = 180
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector2(-20.0, -52.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 38.0, 0.48)
	tween.tween_property(label, "modulate:a", 0.0, 0.48)
	tween.chain().tween_callback(label.queue_free)

func _create_death_effect() -> void:
	var particles := CPUParticles2D.new()
	particles.amount = 22
	particles.lifetime = 0.55
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 230.0
	particles.gravity = Vector2(0, 520)
	particles.color = Color("e07a3c")
	particles.z_index = 120
	get_parent().call_deferred("add_child", particles)
	particles.position = global_position
	particles.emitting = true
	get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null
