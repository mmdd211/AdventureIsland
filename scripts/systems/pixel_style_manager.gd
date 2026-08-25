# 像素艺术风格管理器：冒险岛风格 Q 版角色
extends Node

func _ready() -> void:
	call_deferred("apply_pixel_style")

func apply_pixel_style() -> void:
	await get_tree().create_timer(0.2).timeout

	_apply_to_player()
	_apply_to_enemies()
	_apply_to_coins()
	_apply_ground_style()
	_apply_portal_style()

func refresh_enemy_styles() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var existing := enemy.get_node_or_null("PixelSprite")
		if existing:
			enemy.remove_child(existing)
			existing.queue_free()
		_apply_sprite_to_enemy(enemy)

func _apply_to_player() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		var visual = player.get_node_or_null("Visual")
		if visual:
			visual.visible = false
		var old_sprite = player.get_node_or_null("PixelSprite")
		if old_sprite:
			player.remove_child(old_sprite)
			old_sprite.queue_free()
		var old_animator = player.get_node_or_null("PixelAnimator")
		if old_animator:
			player.remove_child(old_animator)
			old_animator.queue_free()

		var animator := AnimatedSprite2D.new()
		animator.name = "PixelAnimator"
		animator.sprite_frames = _create_player_frames()
		animator.scale = Vector2(2, 2)
		animator.z_index = 10
		animator.play("idle")
		player.add_child(animator)
		player.set("base_animator_scale", animator.scale)

func _apply_to_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		_apply_sprite_to_enemy(enemy)

func _apply_sprite_to_enemy(enemy: Node) -> void:
	var existing_sprite = enemy.get_node_or_null("PixelSprite")
	if existing_sprite:
		enemy.remove_child(existing_sprite)
		existing_sprite.queue_free()
	var visual = enemy.get_node_or_null("Visual")
	if visual:
		visual.visible = false
	var kind = enemy.get("enemy_kind")
	if kind == null:
		kind = "mushroom"
	var sprite := Sprite2D.new()
	sprite.name = "PixelSprite"
	sprite.texture = _create_enemy_texture(str(kind))
	var mini = enemy.get("is_mini") if enemy.get("is_mini") != null else false
	sprite.scale = Vector2(1.55, 1.55) if mini else Vector2(2, 2)
	sprite.z_index = 10
	enemy.add_child(sprite)

func _apply_to_coins() -> void:
	var root = get_tree().current_scene
	if not root:
		return
	for child in root.get_children():
		var is_coin: bool = child.name.begins_with("Coin") and not child.is_in_group("pickups")
		if is_coin:
			var visual = child.get_node_or_null("Visual")
			if visual:
				visual.visible = false
			var old_sprite = child.get_node_or_null("PixelSprite")
			if old_sprite:
				child.remove_child(old_sprite)
				old_sprite.queue_free()
			var sprite := Sprite2D.new()
			sprite.name = "PixelSprite"
			sprite.texture = _create_coin_texture()
			sprite.scale = Vector2.ONE
			sprite.z_index = 10
			child.add_child(sprite)

func _apply_ground_style() -> void:
	var root = get_tree().current_scene
	if not root:
		return
	for child in root.get_children():
		if child.name.begins_with("Ground"):
			_set_terrain_sprite(child, "PixelGround", false)
			var grass = child.get_node_or_null("Grass1")
			if grass:
				grass.visible = false
		elif child.name.begins_with("Platform"):
			_set_terrain_sprite(child, "PixelPlatform", true)
		elif child.name.begins_with("EdgeWall") or child.name in ["LeftWall", "RightWall"]:
			var visual = child.get_node_or_null("Visual")
			if visual:
				visual.visible = false

func _apply_portal_style() -> void:
	var root = get_tree().current_scene
	if not root:
		return
	for child in root.get_children():
		if child.name == "Portal":
			var visual = child.get_node_or_null("Visual")
			if visual:
				visual.visible = false
			var frame = child.get_node_or_null("Visual/Frame")

			for old_child_name in ["PixelPortal", "PortalSparkles"]:
				var old_child = child.get_node_or_null(old_child_name)
				if old_child:
					child.remove_child(old_child)
					old_child.queue_free()

			var portal := AnimatedSprite2D.new()
			portal.name = "PixelPortal"
			portal.sprite_frames = _create_portal_frames()
			portal.scale = Vector2(2, 2)
			portal.z_index = 10
			portal.play("portal")
			child.add_child(portal)

			var sparkles := CPUParticles2D.new()
			sparkles.name = "PortalSparkles"
			sparkles.amount = 14
			sparkles.lifetime = 1.2
			sparkles.preprocess = 1.0
			sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			sparkles.emission_rect_extents = Vector2(17, 26)
			sparkles.direction = Vector2(0, -1)
			sparkles.spread = 14
			sparkles.gravity = Vector2(0, -28)
			sparkles.initial_velocity_min = 5.0
			sparkles.initial_velocity_max = 14.0
			sparkles.scale_amount_min = 0.5
			sparkles.scale_amount_max = 1.1
			sparkles.color = Color(0.74, 0.95, 1.00, 0.85)
			sparkles.z_index = 9
			child.add_child(sparkles)

func _create_portal_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("portal")
	frames.set_animation_speed("portal", 8.0)
	frames.set_animation_loop("portal", true)
	for frame_index in range(6):
		frames.add_frame("portal", _create_portal_frame(frame_index))
	return frames

func _create_portal_frame(frame_index: int) -> ImageTexture:
	var img = Image.create(32, 40, false, Image.FORMAT_RGBA8)
	var wood := Color(0.66, 0.42, 0.20)
	var wood_light := Color(0.82, 0.58, 0.31)
	var wood_dark := Color(0.42, 0.24, 0.11)
	var outline := Color(0.13, 0.09, 0.08)
	var stone := Color(0.62, 0.63, 0.68)
	var stone_light := Color(0.79, 0.81, 0.85)
	var stone_dark := Color(0.37, 0.39, 0.46)
	var portal_deep := Color(0.07, 0.13, 0.36)
	var portal_mid := Color(0.13, 0.36, 0.82)
	var portal_cyan := Color(0.38, 0.84, 1.00)
	var portal_white := Color(0.86, 0.98, 1.00)

	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var dx := (x - 15.5) / 12.0
			var dy := (y - 20.0) / 17.0
			var arch_distance := pow(pow(absf(dx), 3.5) + pow(absf(dy), 3.5), 1.0 / 3.5)

			if arch_distance <= 1.0:
				var color := wood
				if x < 10 or y < 12:
					color = wood_light
				elif x > 21 or y > 29:
					color = wood_dark
				img.set_pixel(x, y, color)

				if arch_distance >= 0.48:
					if arch_distance >= 0.90:
						color = outline
					elif x < 9 or y < 10:
						color = wood_light
					elif x > 22 or y > 30:
						color = wood_dark
					else:
						color = wood
					img.set_pixel(x, y, color)
				else:
					var angle := atan2(y - 20.0, x - 15.5)
					var phase := float(frame_index) / 6.0
					var wave := sin(angle * 2.0 + arch_distance * 9.0 - phase * TAU)
					color = portal_deep
					if wave > 0.65:
						color = portal_white
					elif wave > 0.0:
						color = portal_cyan
					elif wave > -0.45:
						color = portal_mid
					img.set_pixel(x, y, color)

	# 底座用几个硬边石块收住传送门，让它落在地形上。
	_fill_rect(img, 3, 34, 26, 1, outline)
	_fill_rect(img, 3, 35, 26, 4, stone)
	_fill_rect(img, 3, 35, 26, 1, stone_light)
	_fill_rect(img, 3, 38, 26, 1, stone_dark)
	_fill_rect(img, 10, 36, 1, 2, stone_dark)
	_fill_rect(img, 21, 36, 1, 2, stone_dark)

	# 少量十字形亮点，保持像素颗粒感。
	var sparkle_positions := [
		Vector2i(10 + (frame_index * 2) % 11, 13),
		Vector2i(20 - (frame_index * 3) % 10, 23),
		Vector2i(14 + (frame_index % 3) * 2, 30),
	]
	for position in sparkle_positions:
		_fill_rect(img, position.x, position.y, 1, 3, portal_white)
		_fill_rect(img, position.x - 1, position.y + 1, 3, 1, portal_white)

	return ImageTexture.create_from_image(img)

func _create_player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var definitions := {
		"idle": {"fps": 6.0, "loop": true, "poses": ["idle"]},
		"walk": {"fps": 10.0, "loop": true, "poses": ["walk_step_a", "walk_pass_a", "walk_step_b", "walk_pass_b"]},
		"jump": {"fps": 8.0, "loop": false, "poses": ["jump"]},
		"fall": {"fps": 8.0, "loop": false, "poses": ["fall"]},
		"attack": {"fps": 15.0, "loop": false, "poses": ["attack_wind", "attack_hit", "attack_recover"]},
	}
	for animation_name in definitions:
		var config = definitions[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, config.fps)
		frames.set_animation_loop(animation_name, config.loop)
		for pose in config.poses:
			frames.add_frame(animation_name, _create_player_pose_texture(pose))
	return frames

func _create_player_texture() -> ImageTexture:
	return _create_player_pose_texture("idle")

func _create_player_pose_texture(pose: String) -> ImageTexture:
	var img = Image.create(32, 24, false, Image.FORMAT_RGBA8)
	var outline := Color(0.12, 0.09, 0.12)
	var hair := Color(0.34, 0.20, 0.13)
	var skin := Color(1.00, 0.87, 0.71)
	var skin_shadow := Color(0.90, 0.70, 0.56)
	var blush := Color(0.98, 0.65, 0.58)
	var eye := Color(0.13, 0.10, 0.13)
	var shirt := Color(0.22, 0.48, 0.92)
	var shirt_dark := Color(0.15, 0.34, 0.72)
	var belt := Color(1.00, 0.78, 0.20)
	var pants := Color(0.20, 0.26, 0.48)
	var boots := Color(0.48, 0.30, 0.17)
	var blade := Color(0.82, 0.88, 0.95)
	var blade_dark := Color(0.48, 0.56, 0.68)
	var slash := Color(1.00, 0.92, 0.48)

	# 帽子和头部
	_fill_rect(img, 12, 2, 8, 1, outline)
	_fill_rect(img, 11, 3, 10, 2, Color(0.88, 0.19, 0.22))
	_fill_rect(img, 10, 5, 12, 1, Color(0.68, 0.11, 0.16))
	_fill_rect(img, 11, 6, 10, 1, hair)
	_fill_rect(img, 12, 7, 8, 5, skin)
	_fill_rect(img, 14, 9, 2, 2, eye)
	_fill_rect(img, 18, 9, 2, 2, eye)
	_fill_rect(img, 12, 11, 8, 1, skin_shadow)
	_fill_rect(img, 14, 12, 5, 1, blush)

	# 上半身
	var body_y := 13
	var body_x := 11
	if pose == "attack_hit":
		body_x = 12
	elif pose == "attack_wind":
		body_x = 10
	_fill_rect(img, body_x, body_y + 3, 10, 1, outline)
	_fill_rect(img, body_x + 1, body_y, 8, 3, shirt)
	_fill_rect(img, body_x + 1, body_y + 2, 8, 1, shirt_dark)
	_fill_rect(img, body_x + 1, body_y + 3, 8, 1, belt)

	# 手臂姿态
	if pose == "jump" or pose == "fall":
		_fill_rect(img, 9, 8, 2, 5, shirt)
		_fill_rect(img, 21, 8, 2, 5, shirt)
		_fill_rect(img, 9, 13, 2, 2, skin)
		_fill_rect(img, 21, 13, 2, 2, skin)
	elif pose == "attack_wind":
		_fill_rect(img, 7, 12, 4, 2, shirt)
		_fill_rect(img, 20, 14, 2, 2, skin)
		_fill_rect(img, 4, 7, 2, 6, blade_dark)
		_fill_rect(img, 6, 11, 3, 2, blade)
	elif pose.begins_with("walk_"):
		if pose == "walk_step_a":
			_fill_rect(img, 6, 14, 2, 4, shirt)
			_fill_rect(img, 22, 13, 2, 4, shirt)
			_fill_rect(img, 6, 18, 2, 2, skin)
			_fill_rect(img, 22, 17, 2, 2, skin)
		elif pose == "walk_step_b":
			_fill_rect(img, 7, 13, 2, 4, shirt)
			_fill_rect(img, 21, 14, 2, 4, shirt)
			_fill_rect(img, 7, 17, 2, 2, skin)
			_fill_rect(img, 21, 18, 2, 2, skin)
		else:
			_fill_rect(img, 9, 13, 2, 5, shirt)
			_fill_rect(img, 21, 13, 2, 5, shirt)
			_fill_rect(img, 9, 18, 2, 2, skin)
			_fill_rect(img, 21, 18, 2, 2, skin)
	elif pose == "attack_hit":
		_fill_rect(img, 20, 12, 4, 2, skin)
		_fill_rect(img, 23, 10, 7, 2, blade)
		_fill_rect(img, 23, 12, 6, 1, blade_dark)
		_fill_rect(img, 22, 7, 8, 1, slash)
		_fill_rect(img, 25, 8, 6, 1, slash)
		_fill_rect(img, 22, 14, 8, 1, slash)
	else:
		_fill_rect(img, 9, 13, 2, 5, shirt)
		_fill_rect(img, 21, 13, 2, 5, shirt)
		_fill_rect(img, 9, 18, 2, 2, skin)
		_fill_rect(img, 21, 18, 2, 2, skin)
		if pose == "attack_recover":
			_fill_rect(img, 23, 15, 5, 2, blade)
			_fill_rect(img, 23, 17, 4, 1, blade_dark)

	# 腿部和鞋子
	if pose == "jump":
		_fill_rect(img, 12, 17, 3, 3, pants)
		_fill_rect(img, 17, 17, 3, 3, pants)
		_fill_rect(img, 10, 19, 5, 2, boots)
		_fill_rect(img, 17, 19, 5, 2, boots)
		_fill_rect(img, 10, 21, 12, 1, outline)
	elif pose == "fall":
		_fill_rect(img, 11, 17, 3, 5, pants)
		_fill_rect(img, 18, 17, 3, 5, pants)
		_fill_rect(img, 8, 21, 5, 2, boots)
		_fill_rect(img, 19, 21, 5, 2, boots)
		_fill_rect(img, 8, 23, 16, 1, outline)
	elif pose == "idle" or pose == "attack_recover" or pose == "attack_wind":
		_fill_rect(img, 12, 17, 3, 4, pants)
		_fill_rect(img, 17, 17, 3, 4, pants)
		_fill_rect(img, 10, 21, 5, 2, boots)
		_fill_rect(img, 17, 21, 5, 2, boots)
		_fill_rect(img, 10, 23, 12, 1, outline)

	if pose == "walk_step_a":
		_fill_rect(img, 9, 17, 3, 3, pants)
		_fill_rect(img, 18, 17, 3, 3, pants)
		_fill_rect(img, 7, 20, 4, 2, boots)
		_fill_rect(img, 18, 21, 5, 2, boots)
		_fill_rect(img, 7, 23, 16, 1, outline)
	elif pose == "walk_pass_a":
		_fill_rect(img, 11, 17, 3, 4, pants)
		_fill_rect(img, 16, 17, 3, 3, pants)
		_fill_rect(img, 10, 21, 5, 2, boots)
		_fill_rect(img, 15, 20, 5, 2, boots)
		_fill_rect(img, 10, 23, 10, 1, outline)
	elif pose == "walk_step_b":
		_fill_rect(img, 18, 17, 3, 3, pants)
		_fill_rect(img, 11, 17, 3, 3, pants)
		_fill_rect(img, 20, 20, 4, 2, boots)
		_fill_rect(img, 8, 21, 5, 2, boots)
		_fill_rect(img, 8, 23, 16, 1, outline)
	elif pose == "walk_pass_b":
		_fill_rect(img, 16, 17, 3, 4, pants)
		_fill_rect(img, 11, 17, 3, 3, pants)
		_fill_rect(img, 15, 21, 5, 2, boots)
		_fill_rect(img, 10, 20, 5, 2, boots)
		_fill_rect(img, 10, 23, 10, 1, outline)

	return ImageTexture.create_from_image(img)

func _fill_rect(img: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)

func _create_player_rows_texture() -> ImageTexture:
	var rows := PackedStringArray([
		"................",
		"................",
		"....OOOOOOOO....",
		"...ORRRRRRRRO...",
		"...ORrrrrrrRO...",
		"..OrrrrrrrrrrO..",
		"...OHHHHHHHHO...",
		"...OHSSSSSSHO...",
		"...OSKWSSWKSO...",
		"...OSKWSSWKSO...",
		"...OSSSSSSSSO...",
		"....OsPPPPsO....",
		".....OOOOOO.....",
		"..OSBBBBBBBBSO..",
		"..OSBBBBBBBBSO..",
		"..OSBBBBBBBBSO..",
		"...ObBBBBBBbO...",
		"...OYYYYYYYYO...",
		"...ONNO..ONNO...",
		"...ONNO..ONNO...",
		"...ONNO..ONNO...",
		"..OTTTTOOTTTTO..",
		"..OTTTTOOTTTTO..",
		"..OOOOOOOOOOOO..",
	])
	var palette := {
		"O": Color(0.12, 0.09, 0.12),
		"R": Color(0.88, 0.19, 0.22),
		"r": Color(0.68, 0.11, 0.16),
		"H": Color(0.34, 0.20, 0.13),
		"S": Color(1.00, 0.87, 0.71),
		"s": Color(0.90, 0.70, 0.56),
		"P": Color(0.98, 0.65, 0.58),
		"K": Color(0.13, 0.10, 0.13),
		"B": Color(0.22, 0.48, 0.92),
		"b": Color(0.15, 0.34, 0.72),
		"Y": Color(1.00, 0.78, 0.20),
		"N": Color(0.20, 0.26, 0.48),
		"T": Color(0.48, 0.30, 0.17),
	}
	return _texture_from_rows(rows, palette)

func _create_enemy_texture(kind: String) -> ImageTexture:
	if kind == "snail":
		return _create_snail_texture()
	if kind == "slime":
		return _create_slime_texture()
	return _create_mushroom_texture()

func _create_mushroom_texture() -> ImageTexture:
	var rows := PackedStringArray([
		"......OOO......",
		"....OORRROO....",
		"..ORRRRRRRRRO..",
		".ORRWRRRRRWRRRO",
		".OrrRRRRRRRrrO.",
		".ORRRRRRRRRRRO.",
		"..OOOOOOOOOOO..",
		"...OWWWWWWO...",
		"...OWKWWKWO...",
		"...OWWKKWWO...",
		"...OsWWWWsO...",
		"...OsWWWWsO...",
		"....OWWWWO....",
		"....OWWWWO....",
		".....OOOO.....",
	])
	var palette := {
		"O": Color(0.16, 0.10, 0.08),
		"R": Color(0.95, 0.48, 0.14),
		"r": Color(1.00, 0.72, 0.25),
		"W": Color(1.00, 0.95, 0.82),
		"s": Color(0.91, 0.81, 0.66),
		"K": Color(0.16, 0.10, 0.08),
	}
	return _texture_from_rows(rows, palette)

func _create_snail_texture() -> ImageTexture:
	var rows := PackedStringArray([
		"...K.....K....",
		"...O.....O....",
		"...Y..BB.O....",
		"..OBBBBBBBO...",
		".OBbbBBBBBbBO.",
		"OBWBBBBBBWBBBO",
		"OBWBBBBBBWBBBO",
		"OBBBBBBBBBBBBO",
		"OBbBBBBBBBBbBO",
		".OBBBBBBBBBBO.",
		"..OBBBBBBBBO..",
		".OYYYYYYYYYYO.",
		"OYYKYYYYYYKYYO",
		".OOOOOOOOOOOO.",
		"..............",
	])
	var palette := {
		"O": Color(0.12, 0.13, 0.22),
		"B": Color(0.28, 0.55, 0.95),
		"b": Color(0.18, 0.36, 0.72),
		"W": Color(0.85, 0.94, 1.00),
		"Y": Color(1.00, 0.85, 0.48),
		"K": Color(0.12, 0.13, 0.22),
	}
	return _texture_from_rows(rows, palette)

func _create_slime_texture() -> ImageTexture:
	var rows := PackedStringArray([
		"..............",
		".....OOOO.....",
		"...OOGGGGOO...",
		"..OGGggggGGO..",
		".OGGggggggGGO.",
		".OGWGGGGGWGGO.",
		"OGWKGGGGGKWGGO",
		"OGGGGGGGGGGGO.",
		"OGGGGKKGGGGGGO",
		"OGgGGGGGGGGgGO",
		".OGggggggggGO.",
		"..OOGggggOOO..",
		"....OOOOOO....",
		"..............",
		"..............",
	])
	var palette := {
		"O": Color(0.10, 0.20, 0.12),
		"G": Color(0.28, 0.80, 0.36),
		"g": Color(0.55, 0.95, 0.55),
		"W": Color(0.88, 1.00, 0.90),
		"K": Color(0.10, 0.20, 0.12),
	}
	return _texture_from_rows(rows, palette)

func _create_coin_texture() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	for y in range(2, 22):
		for x in range(2, 22):
			var dist = Vector2(x - 12, y - 12).length()
			if dist < 10:
				img.set_pixel(x, y, Color(0.85, 0.68, 0))
	for y in range(4, 20):
		for x in range(4, 20):
			var dist = Vector2(x - 12, y - 12).length()
			if dist < 8:
				img.set_pixel(x, y, Color(1, 0.85, 0.15))
	for y in range(5, 10):
		for x in range(6, 12):
			var dist = Vector2(x - 9, y - 7).length()
			if dist < 4:
				img.set_pixel(x, y, Color(1, 0.95, 0.5))
	return ImageTexture.create_from_image(img)

func _set_terrain_sprite(body: Node2D, sprite_name: String, floating: bool) -> void:
	var size := Vector2(160, 24)
	var collider = body.get_node_or_null("CollisionShape2D")
	if collider and collider.shape is RectangleShape2D:
		size = collider.shape.size

	var visual = body.get_node_or_null("Visual")
	if visual:
		visual.visible = false

	var old_sprite = body.get_node_or_null(sprite_name)
	if old_sprite:
		body.remove_child(old_sprite)
		old_sprite.queue_free()

	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = _create_terrain_texture(int(size.x), int(size.y), floating)
	sprite.z_index = 0
	body.add_child(sprite)
	if floating:
		sprite.position.y = 5.0

func _create_terrain_texture(width: int, height: int, floating: bool) -> ImageTexture:
	width = maxi(24, width)
	height = maxi(12, height)
	var terrain_height := height if not floating else height + 10
	var draw_height := height if not floating else height + 4
	var img = Image.create(width, terrain_height, false, Image.FORMAT_RGBA8)
	var grass_outline := Color(0.08, 0.26, 0.11)
	var grass_light := Color(0.62, 0.85, 0.32)
	var grass := Color(0.31, 0.68, 0.25)
	var grass_dark := Color(0.18, 0.47, 0.19)
	var dirt := Color(0.55, 0.34, 0.18)
	var dirt_light := Color(0.70, 0.45, 0.24)
	var dirt_dark := Color(0.39, 0.23, 0.12)
	var outline := Color(0.16, 0.09, 0.05)
	var root_color := Color(0.43, 0.27, 0.15)

	for y in range(draw_height):
		for x in range(width):
			var edge := x == 0 or x == width - 1 or y == 0 or y == draw_height - 1
			var grass_depth := clampi(int(6.0 + sin(x * 0.17) * 1.7 + cos(x * 0.41) * 0.9), 3, 8)
			if y <= grass_depth:
				var color := grass
				if y == 0 or edge:
					color = grass_outline
				elif y == 1:
					color = grass_light
				elif y == grass_depth:
					color = grass_dark
				elif (x + y) % 9 == 0:
					color = grass_light
				img.set_pixel(x, y, color)
				continue

			if edge:
				img.set_pixel(x, y, outline)
				continue

			var grain = fmod(abs(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			var color := dirt
			if grain > 0.88:
				color = dirt_light
			elif grain < 0.14:
				color = dirt_dark
			elif (x + y * 2) % 23 == 0:
				color = dirt_dark
			img.set_pixel(x, y, color)

	if floating:
		var roots := [int(width * 0.22), int(width * 0.50), int(width * 0.76)]
		for base_x in roots:
			for tail_y in range(height + 4, terrain_height):
				var sway := int(sin((tail_y - height) * 0.8 + base_x) * 1.2)
				var root_x := clampi(base_x + sway, 1, width - 2)
				img.set_pixel(root_x, tail_y, root_color)
				img.set_pixel(root_x - 1, tail_y, outline)

	return ImageTexture.create_from_image(img)

func _texture_from_rows(rows: PackedStringArray, palette: Dictionary) -> ImageTexture:
	var width := 0
	for row in rows:
		width = maxi(width, row.length())
	var height := rows.size()
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y in range(height):
		var row := rows[y]
		for x in range(row.length()):
			var key = row[x]
			if palette.has(key):
				img.set_pixel(x, y, palette[key])

	return ImageTexture.create_from_image(img)
