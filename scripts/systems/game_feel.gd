extends Node

@export var shake_enabled := true
@export var hit_stop_enabled := true
@export var max_shake := 14.0

var _hit_stop_active := false

func shake(strength: float) -> void:
	if not shake_enabled:
		return
	get_tree().call_group("game_camera", "shake", clampf(strength, 0.0, max_shake))

func hit_stop(duration := 0.055, time_scale := 0.08) -> void:
	if not hit_stop_enabled or _hit_stop_active:
		return
	_hit_stop_active = true
	var previous_scale := Engine.time_scale
	Engine.time_scale = clampf(time_scale, 0.02, 1.0)
	await get_tree().create_timer(duration, true, false, true).timeout
	if _hit_stop_active:
		Engine.time_scale = previous_scale
		_hit_stop_active = false
