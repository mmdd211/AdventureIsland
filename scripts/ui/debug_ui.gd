extends CanvasLayer

var player: Node2D

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible

func _process(_delta: float) -> void:
	if not visible:
		return
	if player == null or not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		player = players[0] if players.size() > 0 else null
	%FPSLabel.text = "FPS %d" % Engine.get_frames_per_second()
	if player:
		%PosLabel.text = "(%d, %d)" % [player.position.x, player.position.y]
		%StateLabel.text = "地面" if player.is_on_floor() else ("上升" if player.velocity.y < 0.0 else "下落")
