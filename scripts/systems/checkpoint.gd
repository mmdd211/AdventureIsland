extends Area2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")

var activated := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	_build_visual()

func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player"):
		return
	activated = true
	GameState.set_checkpoint(global_position + Vector2(0, 16))
	AudioManager.play_sfx("checkpoint")
	var flag := get_node_or_null("Flag") as Polygon2D
	if flag:
		flag.color = Palette.BLUE

func _build_visual() -> void:
	collision_layer = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(72, 100)
	shape.shape = rectangle
	add_child(shape)

	var post := ColorRect.new()
	post.name = "Post"
	post.color = Palette.WOOD
	post.position = Vector2(-3, -46)
	post.size = Vector2(6, 92)
	post.z_index = 15
	add_child(post)

	var post_light := ColorRect.new()
	post_light.name = "PostLight"
	post_light.color = Palette.WOOD_LIGHT
	post_light.position = Vector2(-3, -46)
	post_light.size = Vector2(2, 92)
	post_light.z_index = 15
	add_child(post_light)

	var flag := Polygon2D.new()
	flag.name = "Flag"
	flag.color = Palette.STONE_LIGHT
	flag.polygon = PackedVector2Array([
		Vector2(3, -46), Vector2(33, -38), Vector2(3, -29)
	])
	flag.z_index = 15
	add_child(flag)

	var flag_light := Polygon2D.new()
	flag_light.name = "FlagLight"
	flag_light.color = Palette.WHITE
	flag_light.polygon = PackedVector2Array([
		Vector2(5, -44), Vector2(24, -38), Vector2(5, -33)
	])
	flag_light.z_index = 16
	add_child(flag_light)
