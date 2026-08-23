# 粒子效果管理器
extends Node

## 创建收集闪光效果
static func create_collect_effect(parent: Node, pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.name = "CollectEffect"
	particles.position = pos
	particles.amount = 8
	particles.lifetime = 0.5
	particles.speed_scale = 2.0
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.gravity = Vector2(0, 100)
	particles.initial_size_min = 0.3
	particles.initial_size_max = 0.5
	particles.color = Color(1, 0.84, 0, 1)  # 金色
	parent.add_child(particles)
	particles.emitting = true

	# 自动删除
	await particles.finished
	particles.queue_free()

## 创建攻击特效
static func create_attack_effect(parent: Node, pos: Vector2, direction: int) -> void:
	var particles = CPUParticles2D.new()
	particles.name = "AttackEffect"
	particles.position = pos
	particles.amount = 12
	particles.lifetime = 0.3
	particles.speed_scale = 3.0
	particles.direction = Vector2(direction, -0.5)
	particles.spread = 30.0
	particles.gravity = Vector2(0, 200)
	particles.initial_size_min = 0.2
	particles.initial_size_max = 0.4
	particles.color = Color(1, 1, 1, 0.8)  # 白色
	parent.add_child(particles)
	particles.emitting = true

	await particles.finished
	particles.queue_free()

## 创建敌人死亡效果
static func create_death_effect(parent: Node, pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.name = "DeathEffect"
	particles.position = pos
	particles.amount = 15
	particles.lifetime = 0.6
	particles.speed_scale = 2.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 300)
	particles.initial_size_min = 0.3
	particles.initial_size_max = 0.6
	particles.color = Color(1, 0.2, 0.2, 1)  # 红色
	parent.add_child(particles)
	particles.emitting = true

	await particles.finished
	particles.queue_free()

## 创建落地灰尘效果
static func create_land_dust(parent: Node, pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.name = "LandDust"
	particles.position = pos
	particles.amount = 6
	particles.lifetime = 0.4
	particles.speed_scale = 1.5
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 50)
	particles.initial_size_min = 0.2
	particles.initial_size_max = 0.4
	particles.color = Color(0.8, 0.7, 0.5, 0.6)  # 灰色
	parent.add_child(particles)
	particles.emitting = true

	await particles.finished
	particles.queue_free()
