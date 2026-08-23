# 玩家角色控制器（阶段三：攻击版）
extends CharacterBody2D

# ==================== 导出参数 ====================

@export_group("移动")
@export var move_speed: float = 350.0
@export var acceleration: float = 2000.0
@export var deceleration: float = 2500.0
@export var air_acceleration: float = 1500.0

@export_group("跳跃")
@export var jump_force: float = -550.0
@export var jump_cut_multiplier: float = 0.4
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1
@export var max_air_jumps: int = 1

@export_group("重力")
@export var gravity: float = 1600.0
@export var fall_multiplier: float = 1.5
@export var max_fall_speed: float = 800.0

@export_group("攻击")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.4
@export var attack_duration: float = 0.2

@export_group("受击")
@export var contact_damage_cooldown: float = 0.8

@export_group("视觉")
@export var squash_stretch: bool = true
@export var land_squash: float = 0.7
@export var jump_stretch: float = 1.3

# ==================== 信号 ====================

signal attack_hit(enemy)

# ==================== 内部状态 ====================

var air_jumps_left: int = 0
var facing_direction: int = 1

# 高级状态
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var visual_scale: Vector2 = Vector2.ONE

# 攻击状态
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var hit_enemies: Array = []
var contact_damage_timer: float = 0.0

# 节点引用
var visual_node = null

# ==================== 生命周期 ====================

func _ready() -> void:
	print("玩家角色已就绪（攻击版）")
	add_to_group("player")
	visual_node = get_node_or_null("Visual")

	# 获取攻击判定区域
	var attack_area = get_node_or_null("AttackArea")
	# 连接攻击区域信号
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	if visual_node:
		visual_scale = visual_node.scale

func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()
	if contact_damage_timer > 0:
		contact_damage_timer -= delta

	# 攻击计时器
	_update_attack_timers(delta)

	# 重力
	_apply_gravity(delta, on_floor)

	# 计时器
	_update_timers(delta, on_floor)

	# 跳跃
	_handle_jump(on_floor)

	# 移动
	_handle_movement(delta, on_floor)

	# 攻击输入
	_handle_attack()

	# 视觉效果
	_update_visual(on_floor)

	move_and_slide()

# ==================== 攻击系统 ====================

func _update_attack_timers(delta: float) -> void:
	# 攻击持续时间
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			_end_attack()

	# 攻击冷却
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

func _handle_attack() -> void:
	# 按攻击键且冷却已结束
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0:
		_start_attack()

func _start_attack() -> void:
	is_attacking = true
	attack_timer = attack_duration
	attack_cooldown_timer = attack_cooldown
	hit_enemies.clear()
	_play_action("attack")

	# 攻击视觉反馈
	var attack_flash = get_node_or_null("PixelAnimator")
	if not attack_flash:
		attack_flash = visual_node
	if attack_flash:
		attack_flash.modulate = Color(1, 0.5, 0.5)  # 变红

	# 创建攻击粒子效果
	_create_attack_effect()

	# 播放攻击音效
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_attack()

	print("攻击！伤害: ", attack_damage)

	# 立即检测攻击范围内的敌人
	var attack_area = get_node_or_null("AttackArea")
	if attack_area:
		var bodies = attack_area.get_overlapping_bodies()
		print("攻击范围内物体数量: ", bodies.size())
		for body in bodies:
			print("检测到物体: ", body.name, " 组: ", body.get_groups())
			_on_attack_area_body_entered(body)

func _create_attack_effect() -> void:
	var particles = CPUParticles2D.new()
	particles.name = "AttackEffect"
	particles.position = Vector2(50 * facing_direction, 0)
	particles.amount = 18
	particles.lifetime = 0.5
	particles.speed_scale = 3.0
	particles.direction = Vector2(facing_direction, -0.5)
	particles.spread = 40.0
	particles.gravity = Vector2(0, 150)
	particles.initial_size_min = 0.6
	particles.initial_size_max = 1.2
	particles.color = Color(1, 1, 0.5, 0.9)
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 1.5
	particles.z_index = 100  # 显示在最上层
	add_child(particles)
	particles.emitting = true

	# 自动删除
	await particles.finished
	particles.queue_free()

func _end_attack() -> void:
	is_attacking = false
	_play_action("idle")

	# 恢复颜色
	var attack_flash = get_node_or_null("PixelAnimator")
	if not attack_flash:
		attack_flash = visual_node
	if attack_flash:
		attack_flash.modulate = Color.WHITE

func take_damage(amount: int, source_position := Vector2.ZERO) -> void:
	if contact_damage_timer > 0:
		return

	contact_damage_timer = contact_damage_cooldown
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud:
		hud.take_damage(amount)

	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_hurt()

	var knockback_direction = signf(global_position.x - source_position.x)
	if knockback_direction == 0:
		knockback_direction = -facing_direction
	velocity = Vector2(knockback_direction * 180, -260)

	var animator = get_node_or_null("PixelAnimator")
	if animator:
		animator.modulate = Color(1, 0.45, 0.45)
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(animator):
			animator.modulate = Color.WHITE

	print("玩家受到接触伤害: ", amount)

func _on_attack_area_body_entered(body: Node2D) -> void:
	print("body_entered 触发: ", body.name, " 是否攻击中: ", is_attacking)

	if not is_attacking:
		print("不在攻击状态，忽略")
		return

	# 检查是否是敌人
	print("检查敌人组: ", body.is_in_group("enemies"))
	if body.is_in_group("enemies") and body not in hit_enemies:
		hit_enemies.append(body)
		print("准备调用 take_damage")

		# 对敌人造成伤害
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
			attack_hit.emit(body)
			print("命中敌人: ", body.name)
		else:
			print("敌人没有 take_damage 方法")

# ==================== 核心逻辑 ====================

func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor:
		air_jumps_left = max_air_jumps
		coyote_timer = coyote_time
	else:
		var grav = gravity
		if velocity.y > 0:
			grav *= fall_multiplier
		velocity.y += grav * delta
		velocity.y = min(velocity.y, max_fall_speed)

func _update_timers(_delta: float, on_floor: bool) -> void:
	if not on_floor and was_on_floor and velocity.y >= 0:
		pass

	if coyote_timer > 0:
		coyote_timer -= _delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	if jump_buffer_timer > 0:
		jump_buffer_timer -= _delta

	was_on_floor = on_floor

func _handle_jump(on_floor: bool) -> void:
	var can_coyote = coyote_timer > 0
	var has_jump_buffer = jump_buffer_timer > 0
	var can_air_jump = air_jumps_left > 0

	if (on_floor or can_coyote) and has_jump_buffer:
		_perform_jump(false)
	elif not on_floor and can_air_jump and Input.is_action_just_pressed("jump"):
		_perform_jump(true)

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

func _perform_jump(is_air_jump: bool) -> void:
	velocity.y = jump_force
	_play_action("jump")

	if is_air_jump:
		velocity.y *= 0.85
		air_jumps_left -= 1

	coyote_timer = 0
	jump_buffer_timer = 0

	if squash_stretch and visual_node:
		visual_node.scale = visual_scale * Vector2(0.7, jump_stretch)

func _handle_movement(delta: float, _on_floor: bool) -> void:
	var input_direction = Input.get_axis("move_left", "move_right")

	var accel = acceleration if _on_floor else air_acceleration

	if input_direction != 0:
		velocity.x = move_toward(velocity.x, input_direction * move_speed, accel * delta)
		facing_direction = 1 if input_direction > 0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

	# 更新朝向和攻击区域
	if visual_node:
		visual_node.scale.x = facing_direction * abs(visual_scale.x)
	var animator = get_node_or_null("PixelAnimator")
	if animator:
		animator.flip_h = facing_direction < 0

	# 翻转攻击区域位置
	var attack_area = get_node_or_null("AttackArea")
	if attack_area:
		attack_area.position.x = 50 * facing_direction

func _play_action(action_name: String) -> void:
	var animator = get_node_or_null("PixelAnimator")
	if animator and animator.sprite_frames and animator.sprite_frames.has_animation(action_name):
		animator.play(action_name)

func _update_visual(on_floor: bool) -> void:
	if is_attacking:
		return

	if on_floor and not was_on_floor:
		_create_land_dust()

	if not on_floor:
		_play_action("jump" if velocity.y < 0 else "fall")
	elif attack_cooldown_timer <= 0:
		_play_action("idle")

func _create_land_dust() -> void:
	var particles = CPUParticles2D.new()
	particles.name = "LandDust"
	particles.position = Vector2(0, 24)
	particles.amount = 10
	particles.lifetime = 0.6
	particles.speed_scale = 2.0
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.gravity = Vector2(0, 30)
	particles.initial_size_min = 0.5
	particles.initial_size_max = 1.0
	particles.color = Color(0.8, 0.7, 0.5, 0.7)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	particles.z_index = 100  # 显示在最上层
	add_child(particles)
	particles.emitting = true

	await particles.finished
	particles.queue_free()
