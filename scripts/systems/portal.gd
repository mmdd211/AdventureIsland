extends Area2D

var time := 0.0
var triggered := false
var portal_sprite: AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	call_deferred("_capture_portal")

func _capture_portal() -> void:
	portal_sprite = get_node_or_null("PixelPortal") as AnimatedSprite2D

func _process(delta: float) -> void:
	time += delta
	if portal_sprite:
		portal_sprite.modulate.a = 0.86 + sin(time * 5.0) * 0.12

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	body.velocity = Vector2.ZERO
	AudioManager.play_sfx("portal")
	GameState.complete_level()
