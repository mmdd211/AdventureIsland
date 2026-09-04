class_name PlayerAssetLibrary
extends RefCounted

const Palette := preload("res://scripts/systems/pixel_palette.gd")

static func frames() -> SpriteFrames:
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
			frames.add_frame(animation_name, pose_texture(pose))
	return frames

static func texture() -> ImageTexture:
	return pose_texture("idle")

static func pose_texture(pose: String) -> ImageTexture:
	var img = Image.create(32, 24, false, Image.FORMAT_RGBA8)
	var outline := Palette.OUTLINE
	var hair := Color(0.34, 0.20, 0.13)
	var skin := Color(1.00, 0.87, 0.71)
	var skin_shadow := Color(0.90, 0.70, 0.56)
	var blush := Color(0.98, 0.65, 0.58)
	var eye := Color(0.13, 0.10, 0.13)
	var shirt := Color("3a6fd8")
	var shirt_dark := Color("2650a8")
	var belt := Palette.YELLOW
	var pants := Color(0.20, 0.26, 0.48)
	var boots := Color(0.48, 0.30, 0.17)
	var blade := Color(0.82, 0.88, 0.95)
	var blade_dark := Color(0.48, 0.56, 0.68)
	var slash := Palette.YELLOW_LIGHT

	# 帽子和头部
	fill_rect(img, 12, 2, 8, 1, outline)
	fill_rect(img, 11, 3, 10, 2, Color("e0574f"))
	fill_rect(img, 10, 5, 12, 1, Color("b23c40"))
	fill_rect(img, 11, 6, 10, 1, hair)
	fill_rect(img, 12, 7, 8, 5, skin)
	fill_rect(img, 14, 9, 2, 2, eye)
	fill_rect(img, 18, 9, 2, 2, eye)
	fill_rect(img, 12, 11, 8, 1, skin_shadow)
	fill_rect(img, 14, 12, 5, 1, blush)

	# 上半身
	var body_y := 13
	var body_x := 11
	if pose == "attack_hit":
		body_x = 12
	elif pose == "attack_wind":
		body_x = 10
	fill_rect(img, body_x, body_y + 3, 10, 1, outline)
	fill_rect(img, body_x + 1, body_y, 8, 3, shirt)
	fill_rect(img, body_x + 1, body_y + 2, 8, 1, shirt_dark)
	fill_rect(img, body_x + 1, body_y + 3, 8, 1, belt)

	# 手臂姿态
	if pose == "jump" or pose == "fall":
		fill_rect(img, 9, 8, 2, 5, shirt)
		fill_rect(img, 21, 8, 2, 5, shirt)
		fill_rect(img, 9, 13, 2, 2, skin)
		fill_rect(img, 21, 13, 2, 2, skin)
	elif pose == "attack_wind":
		fill_rect(img, 7, 12, 4, 2, shirt)
		fill_rect(img, 20, 14, 2, 2, skin)
		fill_rect(img, 4, 7, 2, 6, blade_dark)
		fill_rect(img, 6, 11, 3, 2, blade)
	elif pose.begins_with("walk_"):
		if pose == "walk_step_a":
			fill_rect(img, 6, 14, 2, 4, shirt)
			fill_rect(img, 22, 13, 2, 4, shirt)
			fill_rect(img, 6, 18, 2, 2, skin)
			fill_rect(img, 22, 17, 2, 2, skin)
		elif pose == "walk_step_b":
			fill_rect(img, 7, 13, 2, 4, shirt)
			fill_rect(img, 21, 14, 2, 4, shirt)
			fill_rect(img, 7, 17, 2, 2, skin)
			fill_rect(img, 21, 18, 2, 2, skin)
		else:
			fill_rect(img, 9, 13, 2, 5, shirt)
			fill_rect(img, 21, 13, 2, 5, shirt)
			fill_rect(img, 9, 18, 2, 2, skin)
			fill_rect(img, 21, 18, 2, 2, skin)
	elif pose == "attack_hit":
		fill_rect(img, 20, 12, 4, 2, skin)
		fill_rect(img, 23, 10, 7, 2, blade)
		fill_rect(img, 23, 12, 6, 1, blade_dark)
		fill_rect(img, 22, 7, 8, 1, slash)
		fill_rect(img, 25, 8, 6, 1, slash)
		fill_rect(img, 22, 14, 8, 1, slash)
	else:
		fill_rect(img, 9, 13, 2, 5, shirt)
		fill_rect(img, 21, 13, 2, 5, shirt)
		fill_rect(img, 9, 18, 2, 2, skin)
		fill_rect(img, 21, 18, 2, 2, skin)
		if pose == "attack_recover":
			fill_rect(img, 23, 15, 5, 2, blade)
			fill_rect(img, 23, 17, 4, 1, blade_dark)

	# 腿部和鞋子
	if pose == "jump":
		fill_rect(img, 12, 17, 3, 3, pants)
		fill_rect(img, 17, 17, 3, 3, pants)
		fill_rect(img, 10, 19, 5, 2, boots)
		fill_rect(img, 17, 19, 5, 2, boots)
		fill_rect(img, 10, 21, 12, 1, outline)
	elif pose == "fall":
		fill_rect(img, 11, 17, 3, 5, pants)
		fill_rect(img, 18, 17, 3, 5, pants)
		fill_rect(img, 8, 21, 5, 2, boots)
		fill_rect(img, 19, 21, 5, 2, boots)
		fill_rect(img, 8, 23, 16, 1, outline)
	elif pose == "idle" or pose == "attack_recover" or pose == "attack_wind":
		fill_rect(img, 12, 17, 3, 4, pants)
		fill_rect(img, 17, 17, 3, 4, pants)
		fill_rect(img, 10, 21, 5, 2, boots)
		fill_rect(img, 17, 21, 5, 2, boots)
		fill_rect(img, 10, 23, 12, 1, outline)

	if pose == "walk_step_a":
		fill_rect(img, 9, 17, 3, 3, pants)
		fill_rect(img, 18, 17, 3, 3, pants)
		fill_rect(img, 7, 20, 4, 2, boots)
		fill_rect(img, 18, 21, 5, 2, boots)
		fill_rect(img, 7, 23, 16, 1, outline)
	elif pose == "walk_pass_a":
		fill_rect(img, 11, 17, 3, 4, pants)
		fill_rect(img, 16, 17, 3, 3, pants)
		fill_rect(img, 10, 21, 5, 2, boots)
		fill_rect(img, 15, 20, 5, 2, boots)
		fill_rect(img, 10, 23, 10, 1, outline)
	elif pose == "walk_step_b":
		fill_rect(img, 18, 17, 3, 3, pants)
		fill_rect(img, 11, 17, 3, 3, pants)
		fill_rect(img, 20, 20, 4, 2, boots)
		fill_rect(img, 8, 21, 5, 2, boots)
		fill_rect(img, 8, 23, 16, 1, outline)
	elif pose == "walk_pass_b":
		fill_rect(img, 16, 17, 3, 4, pants)
		fill_rect(img, 11, 17, 3, 3, pants)
		fill_rect(img, 15, 21, 5, 2, boots)
		fill_rect(img, 10, 20, 5, 2, boots)
		fill_rect(img, 10, 23, 10, 1, outline)

	return ImageTexture.create_from_image(img)


static func fill_rect(img: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)
