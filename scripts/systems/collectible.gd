# 收集物脚本（金币、宝石等）
extends Area2D

@export var score_value: int = 10
@export var exp_value: int = 5
@export var bob_height: float = 5.0
@export var bob_speed: float = 2.0

var start_position: Vector2
var time: float = 0.0

func _ready() -> void:
	start_position = position
	body_entered.connect(_on_body_entered)
	print("金币已就绪: ", name)

func _process(delta: float) -> void:
	time += delta
	position.y = start_position.y + sin(time * bob_speed) * bob_height

func _on_body_entered(body: Node2D) -> void:
	print("金币碰撞: ", body.name, " 组: ", body.get_groups())
	if body.is_in_group("player"):
		# 增加分数
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.add_score(score_value)
			print("金币收集! 分数: ", gm.score)

		# 增加经验
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud:
			hud.add_experience(exp_value)

		# 播放收集音效
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_coin()

		# 创建收集闪光效果
		_create_collect_effect()

		queue_free()

func _create_collect_effect() -> void:
	var particles = CPUParticles2D.new()
	particles.name = "CollectEffect"
	particles.amount = 15
	particles.lifetime = 0.7
	particles.speed_scale = 2.5
	particles.direction = Vector2(0, -1)
	particles.spread = 80.0
	particles.gravity = Vector2(0, 80)
	particles.initial_size_min = 0.6
	particles.initial_size_max = 1.2
	particles.color = Color(1, 0.84, 0, 1)  # 金色
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 1.5
	particles.z_index = 100  # 显示在最上层

	# 添加到父节点，这样效果会留在原位
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true

	await particles.finished
	particles.queue_free()
