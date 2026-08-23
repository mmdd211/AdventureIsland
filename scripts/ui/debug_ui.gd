# 调试 UI（精简版）
extends CanvasLayer

var player = null
var player_found: bool = false

var pos_label: Label = null
var state_label: Label = null
var fps_label: Label = null

func _ready() -> void:
	call_deferred("_init_ui")

func _init_ui() -> void:
	var panel = get_node_or_null("Panel")
	if panel:
		var vbox = panel.get_node_or_null("VBox")
		if vbox:
			fps_label = vbox.get_node_or_null("FPSLabel")
			pos_label = vbox.get_node_or_null("PosLabel")
			state_label = vbox.get_node_or_null("StateLabel")
	print("调试 UI 已就绪")

func _process(_delta: float) -> void:
	if not player_found and is_inside_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			player_found = true

	if player and is_instance_valid(player):
		if pos_label:
			pos_label.text = "(%.0f, %.0f)" % [player.position.x, player.position.y]
		if state_label:
			var state_text = "地面" if player.is_on_floor() else ("上升" if player.velocity.y < 0 else "下落")
			state_label.text = state_text

	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
