extends CharacterBody2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const ENEMY_DATA_SCRIPT := preload("res://scripts/monsters/enemy_data.gd")
const ENEMY_LIBRARY := preload("res://scripts/monsters/enemy_library.gd")
@export var data: Resource
@export var enemy_data: EnemyData
@export var enemy_kind := "mushroom"
@export var is_mini := false
@export var is_boss_minion := false

const MINI_SLIME_SPEED := 110.0
const MINI_CHASE_SPEED := Vector2(250.0, 320.0)
const MINI_HOP_COOLDOWN := Vector2(0.42, 0.62)
const MINI_SPAWN_SPREAD := 84.0
const MINI_SPAWN_VERTICAL := 6.0
const EXTRA_DETECTION_RANGE := 70.0

enum State { PATROL, WINDUP, CHARGE, RECOVER }

var direction := 1
var state: State = State.PATROL
var state_timer := 0.0
var hop_timer := 0.0
var turn_cooldown := 0.0
var spawn_grace_timer := 0.0
var inherited_contact_damage := 0
var is_dead := false
var gravity := 1750.0
var edge_ray: RayCast2D
var health_fill: ColorRect
var spawn_facing := 0
var spawn_hop_delay := 0.0
var attack_cooldown := 1.5
var base_y := 0.0
var phase := 0.0
var is_hidden := false
var health_component: HealthComponent
var knockback_component: KnockbackComponent
var hurtbox_component: HurtboxComponent
var contact_hitbox: HitboxComponent
var status_component: StatusEffectComponent
var drop_component: DropComponent

func _ready() -> void:
	add_to_group("enemies")
	if data == null:
		data = _create_default_data(enemy_kind)
	enemy_data = data as EnemyData
	if is_mini:
		data = _create_default_data("slime")
		data.max_health = 12
		data.display_name = "小史莱姆"
		data.contact_damage = inherited_contact_damage if inherited_contact_damage > 0 else data.contact_damage
		data.move_speed = MINI_SLIME_SPEED
		data.exp_reward = 6
		data.coin_reward = 1
		data.can_split = false
	if spawn_facing != 0:
		direction = spawn_facing
	else:
		direction = -1 if randf() < 0.5 else 1
	hop_timer = spawn_hop_delay
	base_y = position.y
	phase = randf_range(0.0, TAU)
	_setup_edge_ray()
	_setup_health_bar()
	_apply_region_scaling()
	_apply_minion_profile()
	_apply_enemy_range_profile()
	enemy_data = data as EnemyData
	_setup_combat_components()
	_refresh_visual_scale()

func _create_default_data(kind_value: String) -> Resource:
	var resource_enemy := DataCatalog.enemy(kind_value)
	if resource_enemy:
		# 共享资源必须复制后再改写，否则难度缩放会跨出生点累积。
		return resource_enemy.duplicate()
	return ENEMY_LIBRARY.create(kind_value)

func _apply_region_scaling() -> void:
	var difficulty := int(get_meta("difficulty", 1))
	var health_scale: float = [1.0, 1.22, 1.48, 1.80, 2.20, 2.70][mini(6, maxi(1, difficulty)) - 1]
	var speed_scale: float = [1.0, 1.06, 1.12, 1.18, 1.25, 1.32][mini(6, maxi(1, difficulty)) - 1]
	var damage_bonus: int = [0, 2, 4, 6, 9, 12][mini(6, maxi(1, difficulty)) - 1]
	if not is_mini:
		data.max_health = int(round(float(data.max_health) * health_scale))
		data.move_speed *= speed_scale
		data.charge_speed *= speed_scale
	data.contact_damage += damage_bonus
	data.detection_range += 20.0 * float(difficulty - 1)
	data.exp_reward += 5 * (difficulty - 1)
	data.coin_reward += difficulty - 1

func _apply_minion_profile() -> void:
	if not is_boss_minion:
		return
	var minion_scale := 0.62
	_scale_collision_shape(get_node_or_null("CollisionShape2D") as CollisionShape2D, minion_scale)
	_scale_collision_shape(get_node_or_null("DamageArea/CollisionShape2D") as CollisionShape2D, minion_scale)
	data.max_health = maxi(8, int(round(float(data.max_health) * 0.62)))
	data.contact_damage = maxi(6, int(round(float(data.contact_damage) * 0.60)))
	data.move_speed *= 0.88
	data.charge_speed *= 0.88
	data.detection_range = maxf(250.0, data.detection_range * 0.85)
func _scale_collision_shape(shape_node: CollisionShape2D, scale_value: float) -> void:
	if shape_node == null or shape_node.shape == null:
		return
	var shape := shape_node.shape.duplicate()
	if shape is RectangleShape2D:
		shape.size *= Vector2(scale_value, scale_value)
	elif shape is CircleShape2D:
		shape.radius *= scale_value
	shape_node.shape = shape

func _setup_combat_components() -> void:
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"
	add_child(health_component)
	health_component.setup(data.max_health, data.max_health)
	health_component.health_changed.connect(func(_current, _maximum): _update_health_bar())
	health_component.died.connect(die)

	knockback_component = KnockbackComponent.new()
	knockback_component.name = "KnockbackComponent"
	knockback_component.enabled = not data.front_guard
	add_child(knockback_component)
	knockback_component.setup(self, 170.0, -150.0, true)
	hurtbox_component = HurtboxComponent.new()
	hurtbox_component.name = "HurtboxComponent"
	add_child(hurtbox_component)
	hurtbox_component.setup(self)
	contact_hitbox = HitboxComponent.new()
	contact_hitbox.name = "ContactHitbox"
	add_child(contact_hitbox)
	contact_hitbox.setup(get_node_or_null("DamageArea") as Area2D, self, "player", data.contact_damage, false)
	contact_hitbox.apply_knockback = false
	contact_hitbox.hit_target.connect(_on_contact_hit)

	status_component = StatusEffectComponent.new()
	status_component.name = "StatusEffectComponent"
	add_child(status_component)
	status_component.setup(self)

	drop_component = DropComponent.new()
	drop_component.name = "DropComponent"
	add_child(drop_component)
	drop_component.setup(self, data.coin_reward, data.exp_reward)

func _apply_enemy_range_profile() -> void:
	if is_mini:
		data.detection_range *= 0.82
	else:
		data.detection_range += EXTRA_DETECTION_RANGE

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
	if is_boss_minion:
		target_scale = Vector2(1.12, 1.12)
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
	turn_cooldown = maxf(0.0, turn_cooldown - delta)

	if _is_flying():
		phase += delta * 3.2
		velocity.y = sin(phase) * 55.0
	elif enemy_kind == "root_ambusher":
		velocity.y = 0.0
	else:
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
	if enemy_kind == "root_ambusher":
		_process_ambusher(player)
	elif _is_flying():
		_process_flyer(player, delta)
	elif data.front_guard:
		_process_snail(player, delta)
	elif enemy_kind == "slime":
		_process_slime(player, delta)
	elif enemy_kind == "thorn_roller" or enemy_kind == "sky_knight" or enemy_kind == "wind_falcon":
		_process_charger(player, delta)
	elif enemy_kind == "spore_lobber" or enemy_kind == "rock_thrower" or enemy_kind == "rune_weaver":
		_process_caster(player, delta)
	else:
		velocity.x = direction * data.move_speed
		_turn_at_terrain()

func _is_flying() -> bool:
	return enemy_kind in ["pollen_bee", "glow_bat", "wind_falcon", "star_wisp"]

func _process_flyer(player: Node2D, delta: float) -> void:
	var patrol_bounds := _patrol_bounds()
	var local_x: float = global_position.x - patrol_bounds.x
	if is_on_wall() and turn_cooldown <= 0.0:
		direction = -1 if velocity.x > 0.0 else 1
		turn_cooldown = 0.22
	if local_x <= 120.0:
		direction = 1
	elif local_x >= patrol_bounds.y - 120.0:
		direction = -1
	if player == null:
		velocity.x = direction * data.move_speed
		return
	var offset := player.global_position - global_position
	if offset.length() < data.detection_range:
		var desired_direction := 1 if offset.x > 0.0 else -1
		direction = desired_direction
		velocity.x = move_toward(velocity.x, signf(offset.x) * data.move_speed, 850.0 * delta)
		velocity.y = sin(phase) * 70.0 + clampf(offset.y, -80.0, 80.0) * 0.8
		if enemy_kind == "wind_falcon" and absf(offset.x) < 260.0:
			velocity.x = signf(offset.x) * data.charge_speed
	else:
		velocity.x = direction * data.move_speed
		velocity.y = sin(phase) * 55.0
		move_and_slide()

func _patrol_bounds() -> Vector2:
	var current := get_parent()
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
	return Vector2(global_position.x - 1200.0, global_position.x + 1200.0)

func _process_ambusher(player: Node2D) -> void:
	if player == null:
		velocity.x = 0.0
		return
	var distance := global_position.distance_to(player.global_position)
	if is_hidden:
		if distance < data.detection_range:
			is_hidden = false
			velocity.y = -360.0
			_spawn_text("!", Palette.YELLOW_LIGHT)
		else:
			velocity.x = 0.0
		return
	if distance < 170.0:
		velocity.x = direction * data.charge_speed
		direction = 1 if player.global_position.x > global_position.x else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0)

func _process_charger(player: Node2D, _delta: float) -> void:
	if state != State.PATROL:
		return
	_turn_at_terrain(true)
	velocity.x = direction * data.move_speed
	if player != null and global_position.distance_to(player.global_position) < data.detection_range:
		direction = 1 if player.global_position.x > global_position.x else -1
		state = State.WINDUP
		state_timer = 0.38

func _process_caster(player: Node2D, _delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - _delta)
	velocity.x = move_toward(velocity.x, 0.0, 800.0)
	if player != null and attack_cooldown <= 0.0 and global_position.distance_to(player.global_position) < data.detection_range:
		direction = 1 if player.global_position.x > global_position.x else -1
		_fire_enemy_projectile(player)
		attack_cooldown = 1.8
		if enemy_kind == "rune_weaver":
			var teleport_offset := Vector2(direction * -180.0, 0.0)
			if not test_move(global_transform, teleport_offset):
				global_position += teleport_offset

func _fire_enemy_projectile(player: Node2D) -> void:
	var angle := global_position.angle_to_point(player.global_position)
	var projectile := Area2D.new()
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
	projectile.set("direction", Vector2.from_angle(angle))
	projectile.set("speed", 300.0 + float(data.contact_damage) * 2.0)
	projectile.set("damage", maxi(5, data.contact_damage - 3))
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
	projectile.global_position = global_position + Vector2(direction * 24.0, -12.0)
	get_parent().add_child(projectile)

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

func _flash_visual() -> void:
	var visual := get_node_or_null("PixelSprite") as CanvasItem
	if visual == null:
		visual = get_node_or_null("Visual") as CanvasItem
	if visual:
		SpriteEffect.flash(visual, 0.09)

func _apply_contact_damage() -> void:
	if spawn_grace_timer > 0.0:
		return
	if contact_hitbox:
		contact_hitbox.set_damage(data.contact_damage)
		contact_hitbox.scan_overlaps()

func _on_contact_hit(target: Node, _amount: int) -> void:
	if target == null or not is_instance_valid(target) or data.status_on_contact.is_empty():
		return
	var target_status := target.get("status_component") as StatusEffectComponent
	if target_status:
		target_status.apply(data.status_on_contact, data.status_duration)

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

	_flash_visual()
	AudioManager.play_sfx("hit")
	var applied := health_component.damage(shown_amount, source_position)
	if applied and shown_amount > 0:
		_spawn_text(str(shown_amount), Color.WHITE)

func apply_knockback(source_position: Vector2) -> void:
	if is_dead or data.front_guard:
		return
	knockback_component.apply(source_position, -direction)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	status_component.clear_all()
	GameState.register_kill()
	drop_component.coin_count = data.coin_reward
	drop_component.experience = data.exp_reward
	drop_component.drop()
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
	var parent := get_parent()
	for side in [-1.0, 1.0]:
		var child := scene.instantiate()
		child.set("enemy_kind", "slime")
		child.set("is_mini", true)
		child.set("spawn_facing", int(side))
		child.set("spawn_hop_delay", 0.18 if side < 0.0 else 0.0)
		child.set("spawn_grace_timer", 0.42)
		child.set("inherited_contact_damage", data.contact_damage)
		var spawn_global := global_position + Vector2(side * MINI_SPAWN_SPREAD, -MINI_SPAWN_VERTICAL)
		child.set("position", parent.to_local(spawn_global))
		parent.call_deferred("add_child", child)
	call_deferred("_refresh_split_styles")

func _refresh_split_styles() -> void:
	if PixelStyleManager.has_method("refresh_enemy_styles"):
		PixelStyleManager.call("refresh_enemy_styles")

func _update_health_bar() -> void:
	if health_fill:
		health_fill.size.x = maxf(0.0, 36.0 * float(health_component.current_health) / float(health_component.max_health))

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
	var parent := get_parent()
	particles.position = parent.to_local(global_position)
	parent.call_deferred("add_child", particles)
	particles.emitting = true
	get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null
