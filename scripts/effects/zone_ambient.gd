extends Node2D

var elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	elapsed += delta
	for index in range(get_child_count()):
		var mote := get_child(index) as Sprite2D
		if mote == null:
			continue
		var base: Vector2 = mote.get_meta("base_position", mote.position)
		var phase: float = float(mote.get_meta("phase", 0.0))
		var drift: float = float(mote.get_meta("drift", 8.0))
		mote.position = base + Vector2(sin(elapsed * 0.55 + phase) * drift, cos(elapsed * 0.8 + phase) * 5.0)
		mote.modulate.a = 0.40 + (sin(elapsed * 1.35 + phase) + 1.0) * 0.22
