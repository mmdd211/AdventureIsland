# 像素艺术背景生成器
extends Sprite2D

@export var width: int = 2560
@export var height: int = 720
@export var pixel_size: int = 4

var image: Image

func _ready() -> void:
	_generate_background()

func _generate_background() -> void:
	if width <= 0 or height <= 0 or pixel_size <= 0:
		return

	image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	# 绘制天空渐变
	var logical_width := int(ceil(float(width) / float(pixel_size)))
	var logical_height := int(ceil(float(height) / float(pixel_size)))
	for y in range(logical_height):
		var block_y := y * pixel_size
		var sample_y := float(block_y + pixel_size / 2)
		for x in range(logical_width):
			var block_x := x * pixel_size
			var sample_x := float(block_x + pixel_size / 2)
			var t := sample_y / float(height)
			var color: Color

			if t < 0.4:  # 上部天空
				color = Color(0.4, 0.7, 1.0).lerp(Color(0.6, 0.85, 1.0), t / 0.4)
			elif t < 0.6:  # 中部天空
				color = Color(0.6, 0.85, 1.0).lerp(Color(0.8, 0.9, 0.7), (t - 0.4) / 0.2)
			else:  # 下部草地
				color = Color(0.8, 0.9, 0.7).lerp(Color(0.4, 0.7, 0.3), (t - 0.6) / 0.4)

			# 添加云朵
			if _should_draw_cloud(sample_x, sample_y, width * 0.25, height * 0.24, 170, 55):
				color = Color(1, 1, 1, 0.8)
			elif _should_draw_cloud(sample_x, sample_y, width * 0.52, height * 0.18, 210, 65):
				color = Color(1, 1, 1, 0.9)
			elif _should_draw_cloud(sample_x, sample_y, width * 0.78, height * 0.3, 185, 58):
				color = Color(1, 1, 1, 0.85)

			# 添加远处的山
			if t > 0.42 and t < 0.68:
				var mountain_height := absf(sin(sample_x / 300.0)) * 50.0 + 30.0
				if sample_y > height * 0.45 + mountain_height:
					color = Color(0.5, 0.6, 0.4).lerp(color, 0.3)

			# 每个逻辑像素填充为一个 pixel_size 方块
			for py in range(pixel_size):
				var draw_y := block_y + py
				if draw_y >= height:
					break

				for px in range(pixel_size):
					var draw_x := block_x + px
					if draw_x < width:
						image.set_pixel(draw_x, draw_y, color)

	# 添加草地纹理
	_add_grass_texture()

	# 添加树木
	_add_trees()

	self.texture = ImageTexture.create_from_image(image)

func _should_draw_cloud(x: float, y: float, center_x: float, center_y: float, radius_x: float, radius_y: float) -> bool:
	var dx := (x - center_x) / radius_x
	var dy := (y - center_y) / radius_y
	return dx * dx + dy * dy <= 1.0

func _add_grass_texture() -> void:
	var grass_top := int(height * 0.6)
	for y in range(grass_top, height):
		for x in range(0, width, 2):
			if randf() > 0.7:
				var grass_color = Color(0.3, 0.6, 0.2).lerp(Color(0.5, 0.8, 0.3), randf())
				image.set_pixel(x, y, grass_color)

func _add_trees() -> void:
	var tree_positions = [200, 500, 800, 1200, 1600, 2000, 2300]
	for tree_x in tree_positions:
		_draw_tree(tree_x, int(height * 0.55))

func _draw_tree(x: int, base_y: int) -> void:
	# 树干
	for y in range(base_y - 40, base_y):
		for px in range(-3, 4):
			image.set_pixel(x + px, y, Color(0.4, 0.3, 0.2))

	# 树叶
	for y in range(base_y - 70, base_y - 30):
		var leaf_width = 20 - abs(y - (base_y - 50)) * 0.5
		for px in range(int(-leaf_width), int(leaf_width) + 1):
			var draw_x := x + px
			if draw_x >= 0 and draw_x < width and randf() > 0.3:
				image.set_pixel(draw_x, y, Color(0.2, 0.6, 0.2).lerp(Color(0.3, 0.8, 0.3), randf()))
