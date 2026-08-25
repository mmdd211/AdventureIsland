extends Area2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

@export_enum("coin", "heart") var pickup_type := "coin"
@export var value := 1
@export var bob_height := 4.0
@export var bob_speed := 2.4

var start_position: Vector2
var time := 0.0
var collected := false

func _ready() -> void:
	add_to_group("pickups")
	if pickup_type == "coin":
		GameState.register_coin_pickups(value)
	start_position = position
	body_entered.connect(_on_body_entered)
	_build_visual()

func _process(delta: float) -> void:
	time += delta
	position.y = start_position.y + sin(time * bob_speed) * bob_height
	var sprite := get_node_or_null("PickupSprite") as Sprite2D
	if sprite:
		var base_scale := 1.5 if pickup_type == "heart" else 1.25
		sprite.scale.x = base_scale * absf(sin(time * 4.0))

func _build_visual() -> void:
	var old_visual := get_node_or_null("Visual")
	if old_visual:
		old_visual.visible = false
	var sprite := Sprite2D.new()
	sprite.name = "PickupSprite"
	sprite.texture = PixelStyleManager._create_coin_texture() if pickup_type == "coin" else _create_heart_texture()
	sprite.scale = Vector2(1.25, 1.25) if pickup_type == "coin" else Vector2(1.5, 1.5)
	sprite.z_index = 20
	add_child(sprite)

func _create_heart_texture() -> ImageTexture:
	var rows := PackedStringArray([
		"..RR...RR..",
		".RRRR.RRRR.",
		"RRrRRRRRrRR",
		"RRRRRRRRRRR",
		"rRRRRRRRRRr",
		".rRRRRRRRr.",
		"..rRRRRRr..",
		"...rRRRr...",
		"....rRr....",
		".....r.....",
	])
	var palette := {
		"R": Palette.RED,
		"r": Color("ffc2c6"),
	}
	var image := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			if palette.has(rows[y][x]):
				image.set_pixel(x, y, palette[rows[y][x]])
	return ImageTexture.create_from_image(image)

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	if pickup_type == "coin":
		GameState.add_coin(value)
		AudioManager.play_sfx("coin")
	else:
		GameState.heal_player(value)
		AudioManager.play_sfx("heart")
	_create_effect(Palette.YELLOW if pickup_type == "coin" else Color("ff8093"))
	queue_free()

func _create_effect(color: Color) -> void:
	var particles := CPUParticles2D.new()
	particles.amount = 14
	particles.lifetime = 0.42
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 240)
	particles.color = color
	particles.z_index = 120
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	get_tree().create_timer(0.8).timeout.connect(particles.queue_free)
