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
	var pixel_portal = get_node_or_null("PixelPortal")
	if pixel_portal:
		pixel_portal.modulate = Color(
			0.94 + sin(time * 4.0) * 0.06,
			0.96 + sin(time * 3.0) * 0.04,
			1.0,
			0.94 + sin(time * 5.0) * 0.06
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
		var flash_target = get_node_or_null("PixelPortal")
		if not flash_target:
			flash_target = visual_node
		if flash_target:
			for i in range(3):
				flash_target.modulate = Color(1, 1, 1, 1)
				await get_tree().create_timer(0.1).timeout
				flash_target.modulate = Color(0.55, 0.85, 1, 1)
				await get_tree().create_timer(0.1).timeout

		# 传送玩家到起始位置（模拟重新开始）
		if reload_level:
			get_tree().reload_current_scene()
		else:
			body.position = teleport_position
			body.velocity = Vector2.ZERO
			is_triggered = false
