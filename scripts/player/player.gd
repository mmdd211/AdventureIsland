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
@export var cape_unfold_fall_distance := 60.0

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
var hurt_timer := 0.0
var landing_timer := 0.0

var step_timer := 0.0
var is_dead := false
var control_enabled := true
var knockback_component: KnockbackComponent
var base_animator_scale := Vector2.ONE
var base_animator_offset := Vector2.ZERO
var visual_base_scale := Vector2.ONE
var death_tween: Tween
var hurtbox_component: HurtboxComponent
var attack_hitbox: HitboxComponent
var status_component: StatusEffectComponent
var _apex_y := 0.0

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
	knockback_component = KnockbackComponent.new()
	knockback_component.name = "KnockbackComponent"
	add_child(knockback_component)
	# 受击击退应覆盖当前速度，与旧实现手感一致，避免移动/下落速度叠加。
	knockback_component.setup(self, 230.0, -280.0, true)
	status_component = StatusEffectComponent.new()
	status_component.name = "StatusEffectComponent"
	add_child(status_component)
	status_component.setup(self)
	hurtbox_component = HurtboxComponent.new()
	hurtbox_component.name = "HurtboxComponent"
	add_child(hurtbox_component)
	hurtbox_component.setup(self)
	attack_hitbox = HitboxComponent.new()
	attack_hitbox.name = "AttackHitbox"
	add_child(attack_hitbox)
	attack_hitbox.setup(_attack_area(), self, "enemies", 0, true)
	attack_hitbox.hit_target.connect(_on_attack_hit)

func _capture_animator() -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator:
		base_animator_scale = animator.scale
		base_animator_offset = animator.offset

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
	hurt_timer = maxf(0.0, hurt_timer - delta)
	landing_timer = maxf(0.0, landing_timer - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

func _apply_gravity(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		air_jumps_left = max_air_jumps
		coyote_timer = coyote_time
		if not was_on_floor and velocity.y > 0.0:
			AudioManager.play_sfx("land")
			_create_land_dust()
			landing_timer = 0.24
			_play_action("landing")
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
	velocity.y = jump_force * (BalanceConfig.AIR_JUMP_MULTIPLIER if is_air_jump else 1.0)
	if is_air_jump:
		air_jumps_left -= 1
		AudioManager.play_sfx("double_jump")
		_create_ring_effect(Palette.CYAN)
	else:
		AudioManager.play_sfx("jump")
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_play_action("jump")

func _handle_horizontal_movement(delta: float) -> void:
	if dash_timer > 0.0:
		velocity.x = facing_direction * dash_speed
		return

	var axis := Input.get_axis("move_left", "move_right")
	var slow_factor := BalanceConfig.SLOW_FACTOR if status_component.has_effect("slow") else 1.0
	var accel := (acceleration if is_on_floor() else air_acceleration) * slow_factor
	if absf(axis) > 0.1:
		velocity.x = move_toward(velocity.x, axis * move_speed * slow_factor, accel * delta)
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
	_play_action("run")

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
	attack_hitbox.clear_sweep()
	AudioManager.play_sfx("attack")
	_play_action("attack1" if stage == 1 else "attack2")
	var area := _attack_area()
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var rectangle := RectangleShape2D.new()
	if shape_node and shape_node.shape is RectangleShape2D:
		rectangle = shape_node.shape as RectangleShape2D
	var reach := weapon.reach_bonus
	var stage_idx := 0 if stage == 1 else 1
	rectangle.size = Vector2(
		BalanceConfig.ATTACK_BOX_WIDTH[stage_idx] + reach,
		BalanceConfig.ATTACK_BOX_HEIGHT[stage_idx] + reach * 0.25
	)
	area.position.x = (BalanceConfig.ATTACK_BOX_OFFSET_X[stage_idx] + reach * 0.5) * facing_direction
	_create_slash_arc(stage)
	attack_hitbox.set_damage(weapon.combo_damage[mini(stage, weapon.combo_damage.size()) - 1])

func _process_attack_hits() -> void:
	if attack_timer <= 0.0:
		return
	var elapsed := attack_duration - attack_timer
	if elapsed < attack_active_from or elapsed > attack_active_until:
		return
	attack_hitbox.scan_overlaps()

func _on_attack_hit(target: Node, amount: int) -> void:
	var weapon := _weapon()
	attack_hit.emit(target)
	_spawn_damage_number(amount, (target as Node2D).global_position)
	if weapon.special == "star_impact" and attack_stage == 2:
		_create_star_impact((target as Node2D).global_position)
	_hitstop()
	_shake_camera(4.5 if attack_stage == 1 else 7.0)

func take_damage(amount: int, source_position := Vector2.ZERO) -> void:
	if is_dead or invulnerable_timer > 0.0:
		return
	invulnerable_timer = hurt_invulnerability
	hurt_timer = 0.33
	GameState.damage_player(amount)
	_shake_camera(8.0)
	_spawn_floating_text(str(-amount), global_position + Vector2(0, -42), Palette.RED)
	if GameState.current_hp > 0:
		knockback_component.apply(source_position, -facing_direction)
		_flash(Color(1.0, 0.45, 0.45), 0.16)
		AudioManager.play_sfx("hurt")

func _hitstop() -> void:
	GameFeel.hit_stop(0.055, 0.08)

func _shake_camera(strength: float) -> void:
	get_tree().call_group("game_camera", "shake", strength)

func _spawn_damage_number(value: int, target_position: Vector2) -> void:
	_spawn_floating_text(str(value), target_position + Vector2(randf_range(-8.0, 8.0), -38.0), Palette.YELLOW)

func _spawn_floating_text(text_value: String, world_position: Vector2, color: Color) -> void:
	FxUtil.spawn_floating_text(get_tree().current_scene, text_value, world_position, color)

func _flash(color: Color, duration: float) -> void:
	var target := get_node_or_null("PixelAnimator")
	if target == null:
		target = get_node_or_null("Visual")
	if target == null:
		return
	SpriteEffect.flash(target, duration, Color(color.r * 2.4, color.g * 2.4, color.b * 2.4, 1.0))

func _play_action(action_name: String) -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator == null or animator.sprite_frames == null or not animator.sprite_frames.has_animation(action_name):
		return
	if animator.animation != action_name:
		animator.play(action_name)
	var config = PlayerAssetLibrary.animation_config(action_name)
	if config != null:
		base_animator_scale = config["display_scale"]
		base_animator_offset = config["display_offset"]
		animator.scale = base_animator_scale if base_animator_scale is Vector2 else Vector2(base_animator_scale, base_animator_scale)
		animator.offset = base_animator_offset

func _update_visual() -> void:
	var animator := get_node_or_null("PixelAnimator")
	if animator:
		animator.flip_h = facing_direction < 0
	var weapon_sprite := get_node_or_null("WeaponSprite") as Sprite2D
	if weapon_sprite:
		weapon_sprite.flip_h = facing_direction < 0
		weapon_sprite.position.x = 14.0 * facing_direction
	if hurt_timer > 0.0:
		_play_action("hurt")
	elif attack_timer > 0.0:
		_play_action("attack1" if attack_stage == 1 else "attack2")
	elif landing_timer > 0.0:
		_play_action("landing")
	elif dash_timer > 0.0:
		_play_action("run")
	elif is_on_floor():
		_play_action("run" if absf(velocity.x) > 0.1 else "idle")
	else:
		if velocity.y < 0.0:
			_apex_y = global_position.y
			_play_action("jump")
		else:
			var fall_dist := global_position.y - _apex_y
			_play_action("fall" if fall_dist > cape_unfold_fall_distance else "fall_short")
	var alpha := 0.45 if invulnerable_timer > 0.0 and Engine.get_frames_drawn() % 8 < 4 else 1.0
	modulate.a = alpha

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
	_play_action("death")
	death_tween = create_tween()
	death_tween.tween_property(self, "position:y", position.y - 35.0, 0.22)
	death_tween.tween_property(self, "position:y", position.y + 120.0, 0.45)

func _on_respawn_requested(_zone_id: String, spawn_position: Vector2) -> void:
	is_dead = false
	if death_tween:
		death_tween.kill()
	status_component.clear_all()
	global_position = spawn_position
	velocity = Vector2.ZERO
	collision_layer = 1
	collision_mask = 2
	modulate = Color.WHITE
	invulnerable_timer = 1.0
	air_jumps_left = max_air_jumps
	landing_timer = 0.0
	_play_action("idle")

func _create_land_dust() -> void:
	FxUtil.spawn_particles(self, Vector2(0, 24), {
		"amount": 12, "lifetime": 0.34, "spread": 70.0,
		"velocity_min": 35.0, "velocity_max": 80.0,
		"gravity": Vector2(0, 320), "color": Color("d9c79c"),
	})

func _create_slash_arc(stage: int) -> void:
	var weapon := _weapon()
	FxUtil.spawn_slash_arc(self, facing_direction, stage, weapon.icon_color, weapon.reach_bonus)

func _create_star_impact(target_position: Vector2) -> void:
	FxUtil.spawn_star_impact(get_tree().current_scene, target_position)

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
		# The generated hero frames already carry the starter sword.
		if weapon.id != "grass_blade":
			var weapon_sprite := Sprite2D.new()
			weapon_sprite.name = "WeaponSprite"
			weapon_sprite.texture = PixelStyleManager.make_equipment_texture(weapon.id)
			weapon_sprite.position = Vector2(14, 2)
			weapon_sprite.scale = Vector2(1.4, 1.4)
			weapon_sprite.z_index = 12
			add_child(weapon_sprite)
		var armor := GameState.get_current_armor()
		if armor != null and armor.id != "none_armor":
			var armor_sprite := Sprite2D.new()
			armor_sprite.name = "ArmorSprite"
			armor_sprite.texture = PixelStyleManager.make_equipment_texture(armor.id)
			armor_sprite.position = Vector2(0, 4)
			armor_sprite.scale = Vector2(1.4, 1.4)
			armor_sprite.modulate = Color(1, 1, 1, 0.82)
			armor_sprite.z_index = 11
			add_child(armor_sprite)

func _create_ring_effect(color: Color) -> void:
	FxUtil.spawn_ring(self, Vector2.ZERO, color)

func _create_dash_trail() -> void:
	FxUtil.spawn_particles(self, Vector2.ZERO, {
		"amount": 16, "lifetime": 0.22, "spread": 18.0,
		"direction": Vector2(-facing_direction, 0),
		"velocity_min": 80.0, "velocity_max": 180.0,
		"gravity": Vector2.ZERO, "color": Palette.CYAN,
		"z_index": 70, "cleanup_time": 0.45,
	})
