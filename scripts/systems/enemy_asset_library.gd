class_name EnemyAssetLibrary
extends RefCounted

const Palette := preload("res://scripts/systems/pixel_palette.gd")
const ArtLibrary := preload("res://scripts/systems/pixel_art_library.gd")

static func texture(kind: String) -> ImageTexture:
	if kind in ["pollen_bee", "thorn_roller", "spore_lobber", "spore_puppet", "root_ambusher", "glow_bat", "wind_falcon", "rock_thrower", "moss_guard", "rune_weaver", "star_wisp", "sky_knight"]:
		return ArtLibrary.enemy_texture(kind)
	if kind == "snail":
		return snail_texture()
	if kind == "slime":
		return slime_texture()
	return mushroom_texture()

static func creature_texture(color: Color, flying := false, armored := false, pod := false, root := false, robed := false) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var outline := Palette.OUTLINE
	var center := Vector2(7.5, 8.5 if not flying else 7.5)
	var radius := Vector2(5.5, 5.5)
	fill_ellipse(image, center, radius, outline)
	fill_ellipse(image, center, radius - Vector2(1, 1), color)
	if flying:
		fill_rect(image, 0, 4, 3, 2, Color.WHITE)
		fill_rect(image, 13, 4, 3, 2, Color.WHITE)
		fill_rect(image, 2, 3, 2, 1, color.lightened(0.3))
		fill_rect(image, 12, 3, 2, 1, color.lightened(0.3))
	if armored:
		fill_rect(image, 3, 5, 10, 2, outline)
		fill_rect(image, 4, 6, 8, 1, color.lightened(0.25))
	if pod:
		fill_rect(image, 6, 3, 4, 2, color.lightened(0.4))
	if root:
		fill_rect(image, 6, 11, 1, 4, color.darkened(0.15))
		fill_rect(image, 9, 11, 1, 4, color.darkened(0.15))
	if robed:
		fill_rect(image, 4, 10, 8, 5, color.darkened(0.2))
		fill_rect(image, 6, 11, 4, 1, Palette.YELLOW)
	fill_rect(image, 5, 6, 2, 2, Color.WHITE)
	fill_rect(image, 9, 6, 2, 2, Color.WHITE)
	fill_rect(image, 6, 7, 1, 1, outline)
	fill_rect(image, 10, 7, 1, 1, outline)
	return ImageTexture.create_from_image(image)

static func mushroom_texture() -> ImageTexture:
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
		"O": Palette.OUTLINE,
		"R": Color("e07a3c"),
		"r": Palette.YELLOW,
		"W": Color(1.00, 0.95, 0.82),
		"s": Color(0.91, 0.81, 0.66),
		"K": Palette.OUTLINE,
	}
	return texture_from_rows(rows, palette)

static func snail_texture() -> ImageTexture:
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
		"O": Palette.OUTLINE,
		"B": Color("4f83d8"),
		"b": Color("31599f"),
		"W": Color(0.85, 0.94, 1.00),
		"Y": Palette.YELLOW,
		"K": Palette.OUTLINE,
	}
	return texture_from_rows(rows, palette)

static func slime_texture() -> ImageTexture:
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
		"O": Palette.GRASS_OUTLINE,
		"G": Palette.GRASS,
		"g": Palette.GRASS_LIGHT,
		"W": Color(0.88, 1.00, 0.90),
		"K": Palette.GRASS_OUTLINE,
	}
	return texture_from_rows(rows, palette)

static func coin_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(2, 14):
		for x in range(2, 14):
			var dist = Vector2(x - 7.5, y - 7.5).length()
			if dist <= 6.2:
				img.set_pixel(x, y, Palette.YELLOW)
			if dist <= 4.8:
				img.set_pixel(x, y, Color("f7c948"))
			if dist <= 2.4 and x < 8 and y < 8:
				img.set_pixel(x, y, Palette.YELLOW_LIGHT)
	for x in range(3, 13):
		set_pixel_if_empty(img, x, 2, Palette.OUTLINE)
		set_pixel_if_empty(img, x, 13, Palette.OUTLINE)
	for y in range(3, 13):
		set_pixel_if_empty(img, 2, y, Palette.OUTLINE)
		set_pixel_if_empty(img, 13, y, Palette.OUTLINE)
	return ImageTexture.create_from_image(img)

static func set_pixel_if_empty(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height() and img.get_pixel(x, y).a == 0.0:
		img.set_pixel(x, y, color)


static func texture_from_rows(rows: PackedStringArray, palette: Dictionary) -> ImageTexture:
	var width := 1
	for row in rows:
		width = maxi(width, row.length())
	var image := Image.create(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var key := row[x]
			if palette.has(key):
				image.set_pixel(x, y, palette[key])
	return ImageTexture.create_from_image(image)
static func fill_ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(maxi(0, int(center.y - radius.y)), mini(image.get_height(), int(center.y + radius.y) + 1)):
		for x in range(maxi(0, int(center.x - radius.x)), mini(image.get_width(), int(center.x + radius.x) + 1)):
			var offset := (Vector2(x, y) - center) / radius
			if offset.length_squared() <= 1.0:
				image.set_pixel(x, y, color)
static func fill_rect(img: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)
