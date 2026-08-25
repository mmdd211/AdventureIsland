extends Camera2D

@export var follow_speed := 7.5
@export var look_ahead := Vector2(55.0, -35.0)
@export var follow_enabled := true

var target: Node2D
var shake_strength := 0.0

func _ready() -> void:
	add_to_group("game_camera")
	make_current()
	call_deferred("_find_player")

func _physics_process(delta: float) -> void:
	if not follow_enabled:
		return
	if target == null or not is_instance_valid(target):
		_find_player()
		return
	var facing = target.get("facing_direction")
	if facing == null:
		facing = 1
	var target_velocity: Vector2 = target.get("velocity")
	var desired := target.global_position + look_ahead * float(facing)
	desired.y += clampf(target_velocity.y * 0.055, -45.0, 75.0)
	position = position.lerp(desired, 1.0 - exp(-follow_speed * delta))
	if shake_strength > 0.01:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
		shake_strength = lerpf(shake_strength, 0.0, minf(1.0, 10.0 * delta))
	else:
		offset = Vector2.ZERO

func shake(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)

func _find_player() -> void:
	if not is_inside_tree():
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0] as Node2D
		global_position = target.global_position
		reset_smoothing()
