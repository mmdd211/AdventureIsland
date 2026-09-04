extends CanvasLayer

const WorldMapDisplayScript := preload("res://scripts/ui/world_map_display.gd")

var map_display: Control

func _ready() -> void:
	visible = false
	%Title.text = LocalizationSystem.tr_key("world_map_title")
	%CloseButton.text = LocalizationSystem.tr_key("close_map")
	%CloseButton.pressed.connect(close_map)
	map_display = WorldMapDisplayScript.new()
	map_display.name = "ZoneMapDisplay"
	map_display.compact = false
	map_display.custom_minimum_size = Vector2(940, 460)
	map_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%MapDisplay.add_child(map_display)
	# %MapDisplay 是普通 Control 而非容器，子节点必须用锚点跟随其尺寸，
	# 否则保持 0x0，_draw 画不出任何内容。
	map_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func open_map() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	%CloseButton.grab_focus()

func close_map() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
