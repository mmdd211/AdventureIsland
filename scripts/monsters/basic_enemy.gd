# 基础敌人脚本（带经验奖励）
extends CharacterBody2D

@export var max_health: int = 30
@export var move_speed: float = 100.0
@export var gravity: float = 1600.0
@export var exp_reward: int = 20  # 击杀获得经验（比金币多）
@export_enum("mushroom", "snail", "slime") var enemy_kind: String = "mushroom"
@export var contact_damage: int = 10

var health: int = 30
var is_dead: bool = false
var direction: int = 1
var turn_cooldown: float = 0.0

var visual_node = null

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	visual_node = get_node_or_null("Visual")
	print("敌人已就绪: ", name, " 血量: ", health, " 经验奖励: ", exp_reward)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 转向冷却
	if turn_cooldown > 0:
		turn_cooldown -= delta

	# 重力
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, 800)
	else:
		velocity.y = 0

	# 巡逻移动
	velocity.x = direction * move_speed

	# 移动
	move_and_slide()

	# 检测墙壁转向
	if is_on_wall() and turn_cooldown <= 0:
		direction *= -1
		turn_cooldown = 0.3

	# 更新朝向
	if visual_node:
		visual_node.scale.x = direction
	var sprite = get_node_or_null("PixelSprite")
	if sprite:
		sprite.flip_h = direction < 0

	_apply_contact_damage()

func _apply_contact_damage() -> void:
	var damage_area = get_node_or_null("DamageArea")
	if not damage_area:
		return

	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage, global_position)

## 受到伤害
func take_damage(amount: int) -> void:
	print("take_damage 被调用! 敌人: ", name, " 伤害: ", amount)

	if is_dead:
		print("敌人已死亡，忽略伤害")
		return

	health -= amount
	print("敌人受到伤害: ", amount, " 剩余血量: ", health)

	# 播放命中音效
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_hit()

	# 受击闪烁
	var flash_target := get_node_or_null("PixelSprite")
	if not flash_target:
		flash_target = visual_node
	if flash_target:
		flash_target.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		if flash_target and not is_dead:
			flash_target.modulate = Color.WHITE

	# 死亡
	if health <= 0:
		die()

## 死亡
func die() -> void:
	is_dead = true
	print("敌人死亡！")

	# 给玩家增加经验
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud:
		hud.add_experience(exp_reward)
		print("击杀敌人获得经验: ", exp_reward)

	# 播放死亡音效
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_enemy_death()

	# 创建死亡粒子效果
	_create_death_effect()

	# 死亡动画
	var death_target := get_node_or_null("PixelSprite")
	if not death_target:
		death_target = visual_node
	if death_target:
		death_target.modulate = Color(0.5, 0.5, 0.5)

	# 延迟删除
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _create_death_effect() -> void:
	var particles = CPUParticles2D.new()
	particles.name = "DeathEffect"
	particles.amount = 20
	particles.lifetime = 0.8
	particles.speed_scale = 2.5
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 200)
	particles.initial_size_min = 0.8
	particles.initial_size_max = 1.5
	particles.color = Color(1, 0.2, 0.2, 1)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.z_index = 100  # 显示在最上层
	add_child(particles)
	particles.emitting = true

	await particles.finished
	particles.queue_free()
