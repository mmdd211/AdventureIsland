# 调试 UI（阶段四增强版）
extends CanvasLayer

var player = null
var player_found: bool = false

var pos_label: Label = null
var vel_label: Label = null
var state_label: Label = null
var jump_label: Label = null
var score_label: Label = null
var fps_label: Label = null

func _ready() -> void:
	call_deferred("_init_ui")

func _init_ui() -> void:
	var vbox = get_node_or_null("VBoxContainer")
	if vbox:
		pos_label = vbox.get_node_or_null("PosLabel")
		vel_label = vbox.get_node_or_null("VelLabel")
		state_label = vbox.get_node_or_null("StateLabel")
		jump_label = vbox.get_node_or_null("JumpLabel")
		score_label = vbox.get_node_or_null("ScoreLabel")
		fps_label = vbox.get_node_or_null("FpsLabel")

	# 如果没有 JumpLabel，创建一个
	if vbox and not jump_label:
		jump_label = Label.new()
		jump_label.name = "JumpLabel"
		vbox.add_child(jump_label)

	# 如果没有 ScoreLabel，创建一个
	if vbox and not score_label:
		score_label = Label.new()
		score_label.name = "ScoreLabel"
		vbox.add_child(score_label)

	print("调试 UI 已就绪")

func _process(_delta: float) -> void:
	if not player_found and is_inside_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			player_found = true

	if player and is_instance_valid(player):
		if pos_label:
			pos_label.text = "位置: (%.0f, %.0f)" % [player.position.x, player.position.y]
		if vel_label:
			vel_label.text = "速度: (%.0f, %.0f)" % [player.velocity.x, player.velocity.y]
		if state_label:
			var state_text = "地面" if player.is_on_floor() else ("上升" if player.velocity.y < 0 else "下落")
			state_label.text = "状态: " + state_text
		if jump_label and player.has_method("get") and "air_jumps_left" in player:
			var jump_text = "空中跳跃: %d" % player.air_jumps_left
			if player.coyote_timer > 0:
				jump_text += " | 郊狼时间: %.2f" % player.coyote_timer
			if player.jump_buffer_timer > 0:
				jump_text += " | 跳跃缓冲"
			jump_label.text = jump_text

	# 显示分数
	if score_label:
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			score_label.text = "分数: %d" % gm.score
		else:
			score_label.text = "分数: 0"

	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
