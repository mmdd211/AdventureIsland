extends CanvasLayer

var player: Node2D
var pos_label: Label
var state_label: Label
var fps_label: Label

func _ready() -> void:
	visible = false
	layer = 25
	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 12.0
	panel.offset_top = -104.0
	panel.offset_right = 240.0
	panel.offset_bottom = -12.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	fps_label = Label.new()
	pos_label = Label.new()
	state_label = Label.new()
	for label in [fps_label, pos_label, state_label]:
		label.add_theme_font_size_override("font_size", 12)
		box.add_child(label)

func _process(_delta: float) -> void:
	if not visible:
		return
	if player == null or not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		player = players[0] if players.size() > 0 else null
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	if player:
		pos_label.text = "(%d, %d)" % [player.position.x, player.position.y]
		state_label.text = "地面" if player.is_on_floor() else ("上升" if player.velocity.y < 0.0 else "下落")
