extends Node2D

var kind := "circle"
var size := Vector2(100, 40)
var duration := 0.45
var color := Color("ff6a70")
var life := 0.0

func setup(telegraph_kind: String, telegraph_size: Vector2, telegraph_duration: float, telegraph_color: Color) -> void:
	kind = telegraph_kind
	size = telegraph_size
	duration = telegraph_duration
	color = telegraph_color
	z_index = 80

func _process(delta: float) -> void:
	life += delta
	queue_redraw()
	if life >= duration:
		queue_free()

func _draw() -> void:
	var progress: float = clampf(life / maxf(0.01, duration), 0.0, 1.0)
	var pulse: float = 0.30 + progress * 0.38 + sin(life * 20.0) * 0.05
	match kind:
		"circle":
			draw_circle(Vector2.ZERO, size.x * 0.5, Color(color, pulse))
			draw_arc(Vector2.ZERO, size.x * 0.5, 0.0, TAU, 40, Color(color, 0.9), 3.0)
		"line":
			draw_rect(Rect2(-size * 0.5, size), Color(color, pulse))
			draw_rect(Rect2(-size * 0.5, size), Color(color, 0.9), false, 3.0)
		_:
			draw_rect(Rect2(-size * 0.5, size), Color(color, pulse))
			draw_rect(Rect2(-size * 0.5, size), Color(color, 0.9), false, 3.0)
