# 云朵视差效果
extends ColorRect

@export var scroll_speed: float = 20.0
@export var parallax_factor: float = 0.3

var start_position: Vector2
var camera: Camera2D = null

func _ready() -> void:
	start_position = position
	# 延迟获取摄像机
	call_deferred("_find_camera")

func _find_camera() -> void:
	camera = get_viewport().get_camera_2d()

func _process(delta: float) -> void:
	if camera:
		# 视差滚动效果
		var camera_offset = camera.position - Vector2(640, 300)
		position.x = start_position.x - camera_offset.x * parallax_factor

		# 缓慢移动
		start_position.x += scroll_speed * delta

		# 循环滚动
		if start_position.x > 2500:
			start_position.x = -500
		elif start_position.x < -500:
			start_position.x = 2500
