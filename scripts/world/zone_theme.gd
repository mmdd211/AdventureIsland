extends RefCounted

static func build(zone: Node2D) -> void:
	var theme: Dictionary = zone.zone_theme
	_add_backdrop(zone, theme)
	_add_landmarks(zone, theme)

static func _add_backdrop(zone: Node2D, theme: Dictionary) -> void:
	var backdrop := TextureRect.new()
	backdrop.name = "ThemeBackdrop"
	backdrop.texture = _create_background_texture(theme)
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.position = Vector2(-260.0, -420.0)
	backdrop.size = Vector2(zone.zone_width + 520.0, 1280.0)
	backdrop.z_index = -100
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(backdrop)

static func _add_landmarks(zone: Node2D, theme: Dictionary) -> void:
	var root := Node2D.new()
	root.name = "ThemeLandmarks"
	root.z_index = -5
	zone.add_child(root)

	var texture := _create_landmark_texture(zone.zone_id, theme)
	var spacing := maxf(650.0, zone.zone_width / 5.0)
	for index in range(6):
		var sprite := Sprite2D.new()
		sprite.name = "ThemeLandmark%d" % index
		sprite.texture = texture
		sprite.scale = Vector2(1.45, 1.45)
		sprite.position = Vector2(spacing * float(index) + spacing * 0.32, 445.0 - float(index % 2) * 18.0)
		root.add_child(sprite)


static func _create_background_texture(theme: Dictionary) -> ImageTexture:
	var width := 512
	var height := 288
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var sky_top := Color(str(theme.sky_top))
	var sky_bottom := Color(str(theme.sky_bottom))

	for y in range(height):
		var color := sky_top.lerp(sky_bottom, float(y) / float(height - 1))
		for x in range(width):
			if (x * 7 + y * 3) % 31 == 0:
				color = color.lightened(0.025)
			image.set_pixel(x, y, color)

	_draw_sun_or_moon(image, theme)
	_draw_far_silhouette(image, theme)
	_draw_near_silhouette(image, theme)
	return ImageTexture.create_from_image(image)

static func _draw_sun_or_moon(image: Image, theme: Dictionary) -> void:
	var motif := _motif(theme)
	var center := Vector2(390.0, 58.0)
	var radius := Vector2(30.0, 30.0)
	var color := Color(str(theme.accent))
	if motif == "mushroom_canopy":
		center = Vector2(405.0, 66.0)
		radius = Vector2(25.0, 22.0)
	elif motif == "glowing_roots":
		center = Vector2(96.0, 110.0)
		radius = Vector2(18.0, 18.0)
	elif motif == "sky_stars":
		for index in range(46):
			var x := (index * 37 + 17) % image.get_width()
			var y := 12 + ((index * 19 + 7) % 130)
			var star := Color(str(theme.accent), 0.72)
			image.set_pixel(x, y, star)
			if index % 5 == 0:
				_fill_rect(image, x - 1, y, 3, 1, star)
				_fill_rect(image, x, y - 1, 1, 3, star)
	_centered_ellipse(image, center, radius, color)
	_centered_ellipse(image, center + Vector2(-4, -4), radius * 0.42, color.lightened(0.3))

static func _draw_far_silhouette(image: Image, theme: Dictionary) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var far := Color(str(theme.far), 0.92)
	var accent := Color(str(theme.accent), 0.68)
	var motif := _motif(theme)
	for x in range(width):
		var horizon := 190.0
		match motif:
			"bright_pastoral":
				horizon = 171.0 + sin(float(x) * 0.018) * 14.0 + sin(float(x) * 0.043) * 7.0
			"mushroom_canopy":
				horizon = 154.0 + sin(float(x) * 0.021) * 18.0 + cos(float(x) * 0.064) * 8.0
			"glowing_roots":
				horizon = 132.0 + sin(float(x) * 0.011) * 10.0
			"wind_mesas":
				horizon = 142.0 + sin(float(x) * 0.013) * 22.0 + (8.0 if x % 83 < 30 else 0.0)
			"mossy_arches":
				horizon = 158.0 + (34.0 if x % 96 < 16 else 0.0) + sin(float(x) * 0.03) * 5.0
			_:
				horizon = 168.0 + sin(float(x) * 0.018) * 17.0
		for y in range(maxi(0, int(horizon)), height):
			if motif == "wind_mesas" and y < 204 and (x + y * 2) % 43 < 2:
				image.set_pixel(x, y, accent)
			else:
				image.set_pixel(x, y, far)

	if motif == "mossy_arches":
		for index in range(5):
			var column_x := 38 + index * 98
			_fill_rect(image, column_x, 136, 14, 82, far.darkened(0.16))
			_fill_rect(image, column_x - 5, 128, 24, 10, far.lightened(0.06))
			_fill_rect(image, column_x + 2, 147, 10, 16, Color(str(theme.accent), 0.32))
	elif motif == "glowing_roots":
		for index in range(8):
			var root_x := 18 + index * 62
			var root_length := 72 + (index % 3) * 26
			for y in range(root_length):
				var sway := int(sin(float(y) * 0.16 + float(index)) * 5.0)
				_fill_rect(image, root_x + sway, 0 + y, 2 + int(y / 42), 1, Color(str(theme.near), 0.72))

static func _draw_near_silhouette(image: Image, theme: Dictionary) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var near := Color(str(theme.near), 0.98)
	var motif := _motif(theme)
	for x in range(width):
		var horizon := 221.0 + sin(float(x) * 0.027) * 10.0
		if motif == "mushroom_canopy":
			horizon = 211.0 + cos(float(x) * 0.041) * 8.0
		elif motif == "mossy_arches":
			horizon = 215.0 + (14.0 if x % 74 < 12 else 0.0)
		for y in range(maxi(0, int(horizon)), height):
			image.set_pixel(x, y, near)

static func _create_landmark_texture(zone_id: String, theme: Dictionary) -> ImageTexture:
	match zone_id:
		"meadow":
			return _texture_from_rows([
				"....PPPP....PPPP....",
				"...PPYYP....PYYPP...",
				"...PPPPP....PPPPP...",
				".....PP......PP.....",
				".....GG......GG.....",
				"...G.GG......GG.G...",
				"..GG.GG......GG.GG..",
				"....GGG......GGG....",
				".....GG......GG.....",
				".....GG......GG.....",
				"....GGG......GGG....",
			], {"P": Color(str(theme.landmark_a)), "Y": Color(str(theme.landmark_b)), "G": Color(str(theme.ground_grass))})
		"forest":
			return _texture_from_rows([
				".......RRRRRRR.......",
				"....RRRRRRRRRRRRR....",
				"..RRRRRRRRRRRRRRRRR..",
				".RRRRRRRRRRRRRRRRRRR.",
				".RRRRRRRRRRRRRRRRRRR.",
				"......T..T..T........",
				"......T..T..T........",
				"......T..T..T........",
				"......TTTTTTT........",
				"......T..T..T........",
			], {"R": Color(str(theme.landmark_b)), "T": Color(str(theme.landmark_a))})
		"grove":
			return _texture_from_rows([
				"........C........",
				".......CCC.......",
				"......CCPCC......",
				".....CCPPCC......",
				"....CCPCCPCC.....",
				"....CCCPPCCC.....",
				"......CCP........",
				"......CC.........",
				"......N..........",
				"......NNN........",
				"........NNN......",
			], {"C": Color(str(theme.accent)), "P": Color("eaffff"), "N": Color(str(theme.near))})
		"canyon":
			return _texture_from_rows([
				"....OOOOOOOOOOO....",
				"..OOOOOOOOOOOOOOO..",
				".OOOOOO..OOOOOOOOO.",
				".OOOOOO..OOOOOOOOO.",
				"..OOOOOOOOOOOOOO...",
				"....OOOOOOOOO......",
				".....OOOOOO........",
				".....O..O..........",
				".....O..OOO........",
				".....O........AAAA.",
			], {"O": Color(str(theme.near)), "A": Color(str(theme.landmark_a))})
		"ruins":
			return _texture_from_rows([
				"....SSSSSS....SSSSSS....",
				"..SSSSSSSS....SSSSSSSS..",
				"..SSSSSSSS....SSSSSSSS..",
				"....SSSSSS....SSSSSS....",
				"....SSSSSS....SSSSSS....",
				"..SSSSSSSS....SSSSSSSS..",
				"..SSSSSSSS....SSSSSSSS..",
				"....SSSSSS....SSSSSS....",
				"..MSSSSSSMM..MMSSSSSSM..",
				"..MMMMMMMMMMMMMMMMMMMM..",
			], {"S": Color(str(theme.landmark_a)), "M": Color(str(theme.landmark_b))})
		_:
			return _texture_from_rows([
				"........A........",
				".......AAA.......",
				".....AAAAAAA.....",
				"....AAAAAAAAA....",
				"..AAAAAAAAAAAAA..",
				"....AAAAAAAAA....",
				".....AA...AA.....",
				"...AAA.....AAA...",
				"..AA.........AA..",
				"...................",
				"...AAAA...AAAA...",
			], {"A": Color(str(theme.accent))})

static func _texture_from_rows(rows: Array, palette: Dictionary) -> ImageTexture:
	var width := 0
	for row in rows:
		width = maxi(width, String(row).length())
	var image := Image.create(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in range(rows.size()):
		var row := String(rows[y])
		for x in range(row.length()):
			var key := row[x]
			if palette.has(key):
				image.set_pixel(x, y, Color(palette[key]))
	return ImageTexture.create_from_image(image)

static func _centered_ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(maxi(0, int(center.y - radius.y)), mini(image.get_height(), int(center.y + radius.y) + 1)):
		for x in range(maxi(0, int(center.x - radius.x)), mini(image.get_width(), int(center.x + radius.x) + 1)):
			var offset := (Vector2(x, y) - center) / radius
			if offset.length_squared() <= 1.0:
				image.set_pixel(x, y, color)

static func _fill_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			if px >= 0 and py >= 0 and px < image.get_width() and py < image.get_height():
				image.set_pixel(px, py, color)

static func _motif(theme: Dictionary) -> String:
	var metadata: Dictionary = theme.get("metadata", {})
	return str(metadata.get("motif", ""))
