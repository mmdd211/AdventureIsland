extends ParallaxBackground

const LAYER_WIDTH := 512

func _ready() -> void:
	layer = -100
	_build_sky()
	_build_clouds()
	_build_mountains()
	_build_forest()
	_build_near_grass()

func _build_sky() -> void:
	var image := Image.create(256, 480, false, Image.FORMAT_RGBA8)
	for y in range(480):
		var color := Color("69b8e8").lerp(Color("d8f3ff"), float(y) / 480.0)
		for x in range(256):
			image.set_pixel(x, y, color)
	_add_layer(_sprite_from_image(image, Vector2(8.0, 3.0)), Vector2.ZERO, Vector2(-400, -520), Vector2.ZERO)

func _build_clouds() -> void:
	var image := Image.create(LAYER_WIDTH, 180, false, Image.FORMAT_RGBA8)
	var random := RandomNumberGenerator.new()
	random.seed = 20260825
	for index in range(7):
		var center := Vector2(random.randf_range(45.0, 465.0), random.randf_range(45.0, 125.0))
		var radius := Vector2(random.randf_range(42.0, 78.0), random.randf_range(20.0, 32.0))
		_fill_ellipse(image, center, radius, Color(1, 1, 1, 0.92))
		_fill_ellipse(image, center + Vector2(0, radius.y * 0.45), radius * Vector2(0.85, 0.55), Color("e9f7ff"))
	_add_layer(_sprite_from_image(image, Vector2(2.5, 1.6), 0.55), Vector2(0.10, 0.0), Vector2(-100, -205), Vector2(1280, 0))

func _build_mountains() -> void:
	var image := Image.create(LAYER_WIDTH, 260, false, Image.FORMAT_RGBA8)
	var peaks := [
		{"center": 90.0, "width": 230.0, "height": 190.0, "color": Color("7d9d8f")},
		{"center": 270.0, "width": 260.0, "height": 230.0, "color": Color("678877")},
		{"center": 430.0, "width": 220.0, "height": 175.0, "color": Color("7d9d8f")},
	]
	for peak_data in peaks:
		var center: float = peak_data.center
		var width_value: float = peak_data.width
		var height_value: float = peak_data.height
		var color: Color = peak_data.color
		for y in range(260):
			var progress := float(y) / height_value
			if progress < 0.0 or progress > 1.0:
				continue
			var half_width := width_value * 0.5 * progress
			for x in range(maxi(0, int(center - half_width)), mini(LAYER_WIDTH, int(center + half_width))):
				image.set_pixel(x, y, color)
		for y in range(int(height_value * 0.22)):
			var progress := float(y) / height_value
			var snow_half := width_value * 0.5 * progress * 0.72
			for x in range(maxi(0, int(center - snow_half)), mini(LAYER_WIDTH, int(center + snow_half))):
				image.set_pixel(x, y, Color("eef8f4"))
	_add_layer(_sprite_from_image(image, Vector2(2.5, 1.6), 0.38), Vector2(0.20, 0.0), Vector2(-100, 120), Vector2(1280, 0))

func _build_forest() -> void:
	var image := Image.create(LAYER_WIDTH, 230, false, Image.FORMAT_RGBA8)
	var random := RandomNumberGenerator.new()
	random.seed = 8620
	for index in range(7):
		var x := int(45.0 + index * 70.0 + random.randf_range(-18.0, 18.0))
		var base_y := int(random.randf_range(195.0, 220.0))
		var height := int(random.randf_range(75.0, 115.0))
		for y in range(base_y - height, base_y):
			for trunk_x in range(x - 4, x + 5):
				if trunk_x >= 0 and trunk_x < LAYER_WIDTH and y >= 0:
					image.set_pixel(trunk_x, y, Color("5b4029"))
		var canopy_center := Vector2(x, base_y - height - 12)
		var canopy_size := Vector2(21 + random.randf_range(0.0, 8.0), 19 + random.randf_range(0.0, 7.0))
		_fill_ellipse(image, canopy_center, canopy_size, Color("316d34"))
		_fill_ellipse(image, canopy_center + Vector2(-7, -7), canopy_size * 0.65, Color("438a3f"))
	_add_layer(_sprite_from_image(image, Vector2(2.5, 1.6), 0.26), Vector2(0.38, 0.0), Vector2(-100, 220), Vector2(1280, 0))

func _build_near_grass() -> void:
	var image := Image.create(LAYER_WIDTH, 130, false, Image.FORMAT_RGBA8)
	var random := RandomNumberGenerator.new()
	random.seed = 5410
	for index in range(24):
		var x := int(random.randf_range(4.0, 505.0))
		var base_y := int(random.randf_range(78.0, 118.0))
		var height := int(random.randf_range(12.0, 30.0))
		var color := Color("3d7c37") if index % 2 == 0 else Color("4f9440")
		for y in range(base_y - height, base_y):
			var spread := int(2.0 * (1.0 - float(base_y - y) / height))
			for blade_x in range(x - spread, x + spread + 1):
				if blade_x >= 0 and blade_x < LAYER_WIDTH and y >= 0:
					image.set_pixel(blade_x, y, color)
	for index in range(5):
		var center := Vector2(random.randf_range(20.0, 480.0), random.randf_range(95.0, 112.0))
		_fill_ellipse(image, center, Vector2(random.randf_range(5.0, 9.0), random.randf_range(3.0, 5.0)), Color("77808a"))
	_add_layer(_sprite_from_image(image, Vector2(2.5, 1.5), 0.15), Vector2(0.62, 0.0), Vector2(-100, 365), Vector2(1280, 0))

func _add_layer(sprite: Sprite2D, motion_scale: Vector2, position_value: Vector2, mirroring: Vector2, alpha := 1.0) -> void:
	var parallax_layer := ParallaxLayer.new()
	parallax_layer.motion_scale = motion_scale
	parallax_layer.motion_mirroring = mirroring
	sprite.position = position_value
	sprite.modulate.a = alpha
	parallax_layer.add_child(sprite)
	add_child(parallax_layer)

func _sprite_from_image(image: Image, scale_value: Vector2, alpha := 1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	sprite.scale = scale_value
	sprite.modulate.a = alpha
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite

func _fill_ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(maxi(0, int(center.y - radius.y)), mini(image.get_height(), int(center.y + radius.y) + 1)):
		for x in range(maxi(0, int(center.x - radius.x)), mini(image.get_width(), int(center.x + radius.x) + 1)):
			var offset := (Vector2(x, y) - center) / radius
			if offset.length_squared() <= 1.0:
				image.set_pixel(x, y, color)
