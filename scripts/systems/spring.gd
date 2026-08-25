extends Area2D

@export var launch_force := -940.0

var cooldown := 0.0
var spring_sprite: Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

func _on_body_entered(body: Node2D) -> void:
	if cooldown > 0.0 or not body.is_in_group("player"):
		return
	cooldown = 0.18
	if "velocity" in body:
		body.velocity.y = launch_force
	AudioManager.play_sfx("jump")
	_compress()

func _build_visual() -> void:
	var old_visual := get_node_or_null("Visual")
	if old_visual:
		old_visual.queue_free()
	spring_sprite = Sprite2D.new()
	spring_sprite.name = "SpringSprite"
	spring_sprite.texture = _create_spring_texture()
	spring_sprite.scale = Vector2(3, 3)
	spring_sprite.position = Vector2(0, -5)
	spring_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spring_sprite)

func _compress() -> void:
	if spring_sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(spring_sprite, "scale:y", 1.7, 0.05)
	tween.tween_property(spring_sprite, "scale:y", 3.0, 0.14).set_ease(Tween.EASE_OUT)

func _create_spring_texture() -> ImageTexture:
	var image := Image.create(16, 12, false, Image.FORMAT_RGBA8)
	for x in range(2, 14):
		for y in range(2, 5):
			image.set_pixel(x, y, Color("ffe066"))
	for x in range(3, 13):
		image.set_pixel(x, 5, Color("fff3b0"))
	for y in range(6, 10):
		var coil_width := 3 if y % 2 == 0 else 5
		for x in range(8 - coil_width, 8 + coil_width):
			image.set_pixel(x, y, Color("ff8a5c"))
	for x in range(1, 15):
		image.set_pixel(x, 10, Color("7a5230"))
		image.set_pixel(x, 11, Color("5b4029"))
	return ImageTexture.create_from_image(image)
