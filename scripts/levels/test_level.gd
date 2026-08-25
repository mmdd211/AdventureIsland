extends Node2D

func _ready() -> void:
	add_to_group("pixel_style_root")
	call_deferred("_apply_pixel_style")

func _apply_pixel_style() -> void:
	PixelStyleManager.apply_pixel_style()
