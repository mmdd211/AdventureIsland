extends Node2D

func _ready() -> void:
	call_deferred("_apply_pixel_style")

func _apply_pixel_style() -> void:
	PixelStyleManager.apply_pixel_style()
