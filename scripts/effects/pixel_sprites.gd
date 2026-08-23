# 像素艺术精灵生成器
extends Node

## 创建玩家像素精灵
static func create_player_sprite() -> ImageTexture:
	var img = Image.create(32, 48, false, Image.FORMAT_RGBA8)

	# 帽子 (红色)
	for y in range(0, 12):
		for x in range(6, 26):
			img.set_pixel(x, y, Color(0.9, 0.2, 0.2))

	# 脸部 (肤色)
	for y in range(12, 22):
		for x in range(8, 24):
			img.set_pixel(x, y, Color(1, 0.85, 0.7))

	# 眼睛
	img.set_pixel(12, 16, Color(0, 0, 0))
	img.set_pixel(13, 16, Color(0, 0, 0))
	img.set_pixel(19, 16, Color(0, 0, 0))
	img.set_pixel(20, 16, Color(0, 0, 0))

	# 嘴巴
	for x in range(14, 18):
		img.set_pixel(x, 20, Color(0.9, 0.3, 0.3))

	# 身体 (蓝色衣服)
	for y in range(22, 36):
		for x in range(8, 24):
			img.set_pixel(x, y, Color(0.2, 0.4, 0.9))

	# 腿部 (裤子)
	for y in range(36, 44):
		for x in range(10, 16):
			img.set_pixel(x, y, Color(0.2, 0.2, 0.7))
		for x in range(16, 22):
			img.set_pixel(x, y, Color(0.2, 0.2, 0.7))

	# 鞋子 (棕色)
	for x in range(8, 16):
		img.set_pixel(x, 44, Color(0.5, 0.3, 0.1))
		img.set_pixel(x, 45, Color(0.5, 0.3, 0.1))
	for x in range(16, 24):
		img.set_pixel(x, 44, Color(0.5, 0.3, 0.1))
		img.set_pixel(x, 45, Color(0.5, 0.3, 0.1))

	# 手臂
	for y in range(22, 32):
		for x in range(4, 8):
			img.set_pixel(x, y, Color(0.2, 0.4, 0.9))
		for x in range(24, 28):
			img.set_pixel(x, y, Color(0.2, 0.4, 0.9))

	return ImageTexture.create_from_image(img)

## 创建敌人像素精灵
static func create_enemy_sprite() -> ImageTexture:
	var img = Image.create(32, 48, false, Image.FORMAT_RGBA8)

	# 身体 (绿色)
	for y in range(10, 38):
		for x in range(8, 24):
			img.set_pixel(x, y, Color(0.3, 0.8, 0.3))

	# 头部 (绿色)
	for y in range(0, 16):
		for x in range(6, 26):
			img.set_pixel(x, y, Color(0.4, 0.85, 0.4))

	# 眼睛 (红色)
	for y in range(6, 10):
		for x in range(10, 14):
			img.set_pixel(x, y, Color(1, 0, 0))
		for x in range(18, 22):
			img.set_pixel(x, y, Color(1, 0, 0))

	# 瞳孔
	img.set_pixel(11, 8, Color(0, 0, 0))
	img.set_pixel(19, 8, Color(0, 0, 0))

	# 嘴巴
	for x in range(12, 20):
		img.set_pixel(x, 13, Color(0.2, 0.5, 0.2))

	# 腿部
	for y in range(38, 46):
		for x in range(10, 16):
			img.set_pixel(x, y, Color(0.25, 0.65, 0.25))
		for x in range(16, 22):
			img.set_pixel(x, y, Color(0.25, 0.65, 0.25))

	# 鞋子
	for x in range(8, 16):
		img.set_pixel(x, 46, Color(0.3, 0.2, 0.1))
		img.set_pixel(x, 47, Color(0.3, 0.2, 0.1))
	for x in range(16, 24):
		img.set_pixel(x, 46, Color(0.3, 0.2, 0.1))
		img.set_pixel(x, 47, Color(0.3, 0.2, 0.1))

	return ImageTexture.create_from_image(img)

## 创建金币像素精灵
static func create_coin_sprite() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)

	# 金色圆形
	for y in range(2, 14):
		for x in range(2, 14):
			var dist = Vector2(x - 8, y - 8).length()
			if dist < 6:
				img.set_pixel(x, y, Color(1, 0.84, 0))

	# 高光
	img.set_pixel(5, 5, Color(1, 1, 0.6))
	img.set_pixel(6, 5, Color(1, 1, 0.6))
	img.set_pixel(5, 6, Color(1, 1, 0.6))

	return ImageTexture.create_from_image(img)

## 创建地面像素精灵
static func create_ground_sprite() -> ImageTexture:
	var img = Image.create(64, 32, false, Image.FORMAT_RGBA8)

	# 泥土
	for y in range(0, 32):
		for x in range(0, 64):
			var dirt_color = Color(0.5, 0.35, 0.2).lerp(Color(0.6, 0.45, 0.25), randf())
			img.set_pixel(x, y, dirt_color)

	# 草地顶部
	for y in range(0, 8):
		for x in range(0, 64):
			var grass_color = Color(0.3, 0.7, 0.2).lerp(Color(0.4, 0.8, 0.3), randf())
			img.set_pixel(x, y, grass_color)

	return ImageTexture.create_from_image(img)

## 创建平台像素精灵
static func create_platform_sprite() -> ImageTexture:
	var img = Image.create(64, 16, false, Image.FORMAT_RGBA8)

	# 木头平台
	for y in range(0, 16):
		for x in range(0, 64):
			var wood_color = Color(0.6, 0.4, 0.2).lerp(Color(0.7, 0.5, 0.3), randf())
			img.set_pixel(x, y, wood_color)

	# 木纹
	for x in range(0, 64, 8):
		for y in range(0, 16):
			img.set_pixel(x, y, Color(0.5, 0.3, 0.15))

	return ImageTexture.create_from_image(img)
