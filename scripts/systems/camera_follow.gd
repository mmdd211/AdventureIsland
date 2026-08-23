# 摄像机跟随控制器
extends Camera2D

@export var smooth_speed: float = 0.1
@export var offset_value: Vector2 = Vector2.ZERO
@export var follow_enabled: bool = true

var target: Node2D = null
var _initialized: bool = false

func _ready() -> void:
	# 延迟初始化
	call_deferred("_init_camera")

func _init_camera() -> void:
	_initialized = true
	_find_player()

func _physics_process(_delta: float) -> void:
	if not follow_enabled or not _initialized:
		return

	if target == null:
		_find_player()
		return

	var target_position = target.position + offset_value
	position = position.lerp(target_position, smooth_speed)

func _find_player() -> void:
	if not is_inside_tree():
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
