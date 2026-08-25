extends Area2D

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
	var flag := get_node_or_null("Flag") as ColorRect
	if flag:
		flag.color = Color("61d6ff")

func _build_visual() -> void:
	collision_layer = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(72, 100)
	shape.shape = rectangle
	add_child(shape)

	var post := ColorRect.new()
	post.name = "Post"
	post.color = Color("7a5230")
	post.position = Vector2(-3, -46)
	post.size = Vector2(6, 92)
	post.z_index = 15
	add_child(post)

	var flag := ColorRect.new()
	flag.name = "Flag"
	flag.color = Color("b9c4cc")
	flag.position = Vector2(3, -46)
	flag.size = Vector2(26, 17)
	flag.z_index = 15
	add_child(flag)
