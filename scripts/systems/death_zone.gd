# 死亡区域（掉进去扣血并重置位置）
extends Area2D

@export var damage_amount: int = 20  # 掉落伤害

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("死亡区域已就绪，掉落伤害: ", damage_amount)

func _on_body_entered(body: Node2D) -> void:
	print("物体掉入死亡区域: ", body.name)

	# 如果是玩家，扣血并重置位置
	if body.is_in_group("player"):
		print("玩家掉入深渊！")

		# 播放受伤音效
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_hurt()

		# 扣血
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud:
			hud.take_damage(damage_amount)
			print("掉落伤害: ", damage_amount, " 剩余HP: ", hud.current_hp)

		# 重置位置
		body.position = Vector2(100, 470)
		body.velocity = Vector2.ZERO

	# 如果是敌人，直接删除
	elif body.is_in_group("enemies"):
		print("敌人掉入深渊: ", body.name)
		body.queue_free()
