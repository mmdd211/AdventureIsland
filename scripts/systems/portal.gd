# 关卡出口传送门
extends Area2D

@export var teleport_position: Vector2 = Vector2(100, 470)
@export var reload_level: bool = false

var time: float = 0.0
var visual_node = null
var is_triggered: bool = false

func _ready() -> void:
	visual_node = get_node_or_null("Visual")
	body_entered.connect(_on_body_entered)
	print("传送门已就绪: ", name)

func _process(delta: float) -> void:
	time += delta
	if visual_node:
		visual_node.modulate = Color(
			0.5 + sin(time * 3) * 0.3,
			0.8 + sin(time * 2) * 0.2,
			1,
			0.8 + sin(time * 4) * 0.2
		)

func _on_body_entered(body: Node2D) -> void:
	if is_triggered:
		return

	print("传送门碰撞: ", body.name, " 组: ", body.get_groups())
	if body.is_in_group("player"):
		is_triggered = true
		print("玩家到达出口！关卡完成！")

		# 播放传送门音效
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_portal()

		# 闪烁效果
		if visual_node:
			for i in range(3):
				visual_node.modulate = Color(1, 1, 1, 1)
				await get_tree().create_timer(0.1).timeout
				visual_node.modulate = Color(0.3, 0.6, 1, 1)
				await get_tree().create_timer(0.1).timeout

		# 传送玩家到起始位置（模拟重新开始）
		if reload_level:
			get_tree().reload_current_scene()
		else:
			body.position = teleport_position
			body.velocity = Vector2.ZERO
			is_triggered = false
