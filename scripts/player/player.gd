extends CharacterBody2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

signal attack_hit(enemy: Node)

@export_group("移动")
@export var move_speed := 350.0
@export var acceleration := 2600.0
@export var deceleration := 2800.0
@export var air_acceleration := 1900.0

@export_group("跳跃")
@export var jump_force := -580.0
@export var jump_cut_multiplier := 0.42
@export var coyote_time := 0.11
@export var jump_buffer_time := 0.11
@export var max_air_jumps := 1

@export_group("重力")
@export var gravity := 1750.0
@export var fall_multiplier := 1.45
@export var max_fall_speed := 940.0

@export_group("攻击")
@export var attack_cooldown := 0.16
@export var attack_duration := 0.26
@export var attack_active_from := 0.05
@export var attack_active_until := 0.19

@export_group("冲刺")
@export var dash_speed := 760.0
@export var dash_duration := 0.17
@export var dash_cooldown := 0.48
@export var dash_invulnerability := 0.23

@export_group("受击")
@export var hurt_invulnerability := 0.85

var air_jumps_left := 0
var facing_direction := 1
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var was_on_floor := false

var attack_timer := 0.0
var attack_stage := 0
var queued_attack := false
var attack_hit_nodes: Array[Node] = []
var attack_input_held := false

var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var invulnerable_timer := 0.0

var step_timer := 0.0
var is_dead := false
var control_enabled := true
var base_animator_scale := Vector2.ONE
var visual_base_scale := Vector2.ONE
var death_tween: Tween

func _ready() -> void:
	add_to_group("player")
	GameState.player_died.connect(_on_player_died)
	GameState.respawn_requested.connect(_on_respawn_requested)
	var visual := get_node_or_null("Visual")
	if visual:
		visual_base_scale = visual.scale
	call_deferred("_capture_animator")
	GameState.equipment_changed.connect(_refresh_equipment)
	call_deferred("_refresh_equipment")

func _capture_animator() -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator:
		base_animator_scale = animator.scale

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not control_enabled:
		velocity = Vector2.ZERO
		return

	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	_handle_dash(delta)
	_handle_attack()
	_update_visual()
	move_and_slide()
	_process_attack_hits()

func _update_timers(delta: float) -> void:
	coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

func _apply_gravity(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		air_jumps_left = max_air_jumps
		coyote_timer = coyote_time
		if not was_on_floor:
			AudioManager.play_sfx("land")
			_create_land_dust()
	else:
		var current_gravity := gravity * (fall_multiplier if velocity.y > 0.0 else 1.0)
		if dash_timer <= 0.0:
			velocity.y = minf(velocity.y + current_gravity * delta, max_fall_speed)
	was_on_floor = on_floor

func _handle_jump() -> void:
	var can_ground_jump := is_on_floor() or coyote_timer > 0.0
	if jump_buffer_timer > 0.0 and can_ground_jump:
		_perform_jump(false)
	elif Input.is_action_just_pressed("jump") and air_jumps_left > 0 and dash_timer <= 0.0:
		_perform_jump(true)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

func _perform_jump(is_air_jump: bool) -> void:
	velocity.y = jump_force * (0.88 if is_air_jump else 1.0)
	if is_air_jump:
		air_jumps_left -= 1
		AudioManager.play_sfx("double_jump")
		_create_ring_effect(Palette.CYAN)
	else:
		AudioManager.play_sfx("jump")
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_apply_squash(Vector2(0.72, 1.24))

func _handle_horizontal_movement(delta: float) -> void:
	if dash_timer > 0.0:
		velocity.x = facing_direction * dash_speed
		return

	var axis := Input.get_axis("move_left", "move_right")
	var accel := acceleration if is_on_floor() else air_acceleration
	if absf(axis) > 0.1:
		velocity.x = move_toward(velocity.x, axis * move_speed, accel * delta)
		facing_direction = 1 if axis > 0.0 else -1
		step_timer -= delta
		if is_on_floor() and step_timer <= 0.0:
			AudioManager.play_sfx("step")
			step_timer = 0.24
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		step_timer = 0.0

func _handle_dash(delta: float) -> void:
	dash_timer = maxf(0.0, dash_timer - delta)
	if not Input.is_action_just_pressed("dash") or dash_cooldown_timer > 0.0:
		return
	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.1:
		facing_direction = 1 if axis > 0.0 else -1
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	invulnerable_timer = maxf(invulnerable_timer, dash_invulnerability)
	velocity.y = 0.0
	AudioManager.play_sfx("dash")
	_create_dash_trail()

func _handle_attack() -> void:
	var pressed := Input.is_action_just_pressed("attack") or (Input.is_action_pressed("attack") and not attack_input_held)
	attack_input_held = Input.is_action_pressed("attack")
	if pressed and attack_timer <= 0.0:
		_start_attack(_next_attack_stage())
	elif pressed and attack_timer > 0.0:
		queued_attack = true

	if attack_timer <= 0.0 and queued_attack:
		queued_attack = false
		_start_attack(_next_attack_stage())

func _weapon() -> EquipmentData:
	return GameState.get_current_weapon()

func _next_attack_stage() -> int:
	var weapon := _weapon()
	var combo_count := maxi(1, weapon.combo_damage.size())
	return attack_stage % combo_count + 1

func _start_attack(stage: int) -> void:
	attack_stage = stage
	var weapon := _weapon()
	attack_timer = attack_duration / maxf(0.4, weapon.attack_speed)
	attack_hit_nodes.clear()
	AudioManager.play_sfx("attack")
	_play_action("attack")
	var area := _attack_area()
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var rectangle := RectangleShape2D.new()
	if shape_node and shape_node.shape is RectangleShape2D:
		rectangle = shape_node.shape as RectangleShape2D
	var reach := weapon.reach_bonus
	rectangle.size = Vector2(
		(82.0 if stage == 1 else 116.0) + reach,
		(52.0 if stage == 1 else 66.0) + reach * 0.25
	)
	area.position.x = ((56.0 if stage == 1 else 68.0) + reach * 0.5) * facing_direction
	_create_slash_arc(stage)
	_apply_squash(Vector2(1.14, 0.90))

func _process_attack_hits() -> void:
	if attack_timer <= 0.0:
		return
	var elapsed := attack_duration - attack_timer
	if elapsed < attack_active_from or elapsed > attack_active_until:
		return
	var weapon := _weapon()
	for body in _attack_area().get_overlapping_bodies():
		if body.is_in_group("enemies") and not attack_hit_nodes.has(body):
			attack_hit_nodes.append(body)
			var damage: int = int(weapon.combo_damage[mini(attack_stage, weapon.combo_damage.size()) - 1])
			if body.has_method("take_damage"):
				body.call("take_damage", damage, global_position)
			if body.has_method("apply_knockback"):
				body.call("apply_knockback", global_position)
			attack_hit.emit(body)
			_spawn_damage_number(damage, body.global_position)
			if weapon.special == "star_impact" and attack_stage == 2:
				_create_star_impact(body.global_position)
			_hitstop()
			_shake_camera(4.5 if attack_stage == 1 else 7.0)

func take_damage(amount: int, source_position := Vector2.ZERO) -> void:
	if is_dead or invulnerable_timer > 0.0:
		return
	invulnerable_timer = hurt_invulnerability
	GameState.damage_player(amount)
	_shake_camera(8.0)
	_spawn_floating_text(str(-amount), global_position + Vector2(0, -42), Palette.RED)
	if GameState.current_hp > 0:
		var away := signf(global_position.x - source_position.x)
		if away == 0.0:
			away = -facing_direction
		velocity = Vector2(away * 230.0, -280.0)
		_flash(Color(1.0, 0.45, 0.45), 0.16)
		AudioManager.play_sfx("hurt")

func _hitstop() -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.08
	get_tree().create_timer(0.055, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func _shake_camera(strength: float) -> void:
	get_tree().call_group("game_camera", "shake", strength)

func _spawn_damage_number(value: int, target_position: Vector2) -> void:
	_spawn_floating_text(str(value), target_position + Vector2(randf_range(-8.0, 8.0), -38.0), Palette.YELLOW)

func _spawn_floating_text(text_value: String, world_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.z_index = 200
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	get_tree().current_scene.add_child(label)
	label.global_position = world_position + Vector2(-14.0, -12.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 54.0, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func _flash(color: Color, duration: float) -> void:
	var target := get_node_or_null("PixelAnimator")
	if target == null:
		target = get_node_or_null("Visual")
	if target == null:
		return
	target.modulate = color
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(target):
			target.modulate = Color.WHITE
	)

func _play_action(action_name: String) -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator and animator.sprite_frames and animator.sprite_frames.has_animation(action_name):
		animator.play(action_name)

func _update_visual() -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator:
		animator.flip_h = facing_direction < 0
	if attack_timer <= 0.0:
		if is_on_floor():
			_play_action("walk" if absf(velocity.x) > 20.0 else "idle")
		else:
			_play_action("jump" if velocity.y < 0.0 else "fall")
	var alpha := 0.45 if invulnerable_timer > 0.0 and Engine.get_frames_drawn() % 8 < 4 else 1.0
	modulate.a = alpha
	_decay_squash()

func _apply_squash(scale_value: Vector2) -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator:
		animator.scale = base_animator_scale * scale_value
	var visual := get_node_or_null("Visual")
	if visual:
		visual.scale = visual_base_scale * scale_value

func _decay_squash() -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator:
		animator.scale = animator.scale.lerp(base_animator_scale, 0.16)
	var visual := get_node_or_null("Visual")
	if visual:
		visual.scale = visual.scale.lerp(visual_base_scale, 0.16)

func _attack_area() -> Area2D:
	return get_node("AttackArea") as Area2D

func _on_player_died() -> void:
	is_dead = true
	if death_tween:
		death_tween.kill()
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	modulate = Color(1.0, 0.55, 0.55, 0.75)
	_play_action("fall")
	death_tween = create_tween()
	death_tween.tween_property(self, "position:y", position.y - 35.0, 0.22)
	death_tween.tween_property(self, "position:y", position.y + 120.0, 0.45)

func _on_respawn_requested(_zone_id: String, spawn_position: Vector2) -> void:
	is_dead = false
	if death_tween:
		death_tween.kill()
	global_position = spawn_position
	velocity = Vector2.ZERO
	collision_layer = 1
	collision_mask = 2
	modulate = Color.WHITE
	invulnerable_timer = 1.0
	air_jumps_left = max_air_jumps
	_play_action("idle")

func _create_land_dust() -> void:
	var particles := CPUParticles2D.new()
	particles.position = Vector2(0, 24)
	particles.amount = 12
	particles.lifetime = 0.34
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 70.0
	particles.initial_velocity_min = 35.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, 320)
	particles.color = Color("d9c79c")
	particles.z_index = 90
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.8).timeout.connect(particles.queue_free)

func _create_slash_arc(stage: int) -> void:
	var arc := Line2D.new()
	var weapon := _weapon()
	arc.width = (12.0 if stage == 1 else 17.0) + weapon.reach_bonus * 0.08
	arc.default_color = Color(weapon.icon_color.lightened(0.2), 0.88)
	arc.z_index = 80
	var points := PackedVector2Array()
	var radius := (44.0 if stage == 1 else 62.0) + weapon.reach_bonus
	for index in range(9):
		var angle := lerpf(-1.15, 1.15, float(index) / 8.0)
		points.append(Vector2(cos(angle), sin(angle)) * radius * facing_direction)
	arc.points = points
	add_child(arc)
	var tween := create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.16)
	tween.tween_callback(arc.queue_free)

func _create_star_impact(target_position: Vector2) -> void:
	var ring := Line2D.new()
	ring.closed = true
	ring.width = 5.0
	ring.default_color = Color("68d8ff")
	ring.z_index = 90
	var points := PackedVector2Array()
	for index in range(12):
		points.append(Vector2.from_angle(TAU * float(index) / 12.0) * 36.0)
	ring.points = points
	get_tree().current_scene.add_child(ring)
	ring.global_position = target_position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.4, 1.8), 0.25)
	tween.tween_property(ring, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(ring.queue_free)

func _refresh_equipment() -> void:
	var weapon := _weapon()
	if weapon == null:
		return
	var animator := get_node_or_null("PixelAnimator") as AnimatedSprite2D
	if animator:
		animator.self_modulate = Color.WHITE.lerp(weapon.icon_color, 0.12)
		if has_node("ArmorOutline"):
			get_node("ArmorOutline").queue_free()
		if has_node("WeaponSprite"):
			get_node("WeaponSprite").queue_free()
		if has_node("ArmorSprite"):
			get_node("ArmorSprite").queue_free()
		var weapon_sprite := Sprite2D.new()
		weapon_sprite.name = "WeaponSprite"
		weapon_sprite.texture = PixelStyleManager.make_equipment_texture(weapon.id)
		weapon_sprite.position = Vector2(14, 2)
		weapon_sprite.scale = Vector2(1.4, 1.4)
		weapon_sprite.z_index = 12
		add_child(weapon_sprite)
		var armor := GameState.get_current_armor()
		if armor != null and armor.id != "none_armor":
			var outline := ColorRect.new()
			outline.name = "ArmorOutline"
			outline.color = Color(armor.icon_color, 0.20)
			outline.position = Vector2(-17, -26)
			outline.size = Vector2(34, 52)
			outline.z_index = -1
			add_child(outline)
			var armor_sprite := Sprite2D.new()
			armor_sprite.name = "ArmorSprite"
			armor_sprite.texture = PixelStyleManager.make_equipment_texture(armor.id)
			armor_sprite.position = Vector2(0, 4)
			armor_sprite.scale = Vector2(1.4, 1.4)
			armor_sprite.modulate = Color(1, 1, 1, 0.82)
			armor_sprite.z_index = 11
			add_child(armor_sprite)

func _create_ring_effect(color: Color) -> void:
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = color
	ring.closed = true
	ring.z_index = 80
	var points := PackedVector2Array()
	for index in range(16):
		points.append(Vector2.from_angle(TAU * float(index) / 16.0) * 18.0)
	ring.points = points
	add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.4, 1.4), 0.24)
	tween.tween_property(ring, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(ring.queue_free)

func _create_dash_trail() -> void:
	var particles := CPUParticles2D.new()
	particles.amount = 16
	particles.lifetime = 0.22
	particles.direction = Vector2(-facing_direction, 0)
	particles.spread = 18.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 180.0
	particles.gravity = Vector2.ZERO
	particles.color = Palette.CYAN
	particles.z_index = 70
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.45).timeout.connect(particles.queue_free)
