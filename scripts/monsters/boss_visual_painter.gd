class_name BossVisualPainter
extends RefCounted

const CANVAS := Vector2i(64, 88)

static func build_frames(region_id: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_state(frames, region_id, "idle", 4, 5.0, true)
	_add_state(frames, region_id, "move", 4, 8.0, true)
	_add_state(frames, region_id, "attack", 5, 12.0, false)
	_add_state(frames, region_id, "skill", 6, 10.0, false)
	_add_state(frames, region_id, "hurt", 2, 12.0, false)
	_add_state(frames, region_id, "death", 4, 6.0, false)
	return frames

static func _add_state(frames: SpriteFrames, region_id: String, state: String, count: int, fps: float, looping: bool) -> void:
	if not frames.has_animation(state):
		frames.add_animation(state)
	frames.set_animation_speed(state, fps)
	frames.set_animation_loop(state, looping)
	for index in range(count):
		frames.add_frame(state, _create_frame(region_id, state, index, count))

static func _create_frame(region_id: String, state: String, index: int, count: int) -> ImageTexture:
	var pose := {
		"body_y": 0.0,
		"crouch": 0.0,
		"lean": 0.0,
		"wing": 0.0,
		"arm": 0.0,
		"weapon": 0.0,
		"energy": 0.0,
		"outline": 0.0,
		"fade": 1.0,
	}
	var phase := TAU * float(index) / float(maxi(1, count))
	match state:
		"idle", "move":
			pose.body_y = sin(phase) * 2.5
			pose.wing = sin(phase) * 0.5 + 0.5
			pose.arm = sin(phase + PI * 0.5) * 0.5 + 0.5
			pose.energy = 0.25 + sin(phase) * 0.10
		"attack":
			var ratio := float(index) / float(maxi(1, count - 1))
			pose.crouch = sin(ratio * PI) * 7.0
			pose.lean = -4.0 + ratio * 14.0
			pose.arm = clampf(ratio * 1.4, 0.0, 1.0)
			pose.weapon = clampf(ratio * 1.25, 0.0, 1.0)
			pose.energy = clampf(1.1 - absf(ratio - 0.62) * 1.8, 0.0, 1.0)
		"skill":
			var ratio := float(index) / float(maxi(1, count - 1))
			pose.body_y = -3.0 + sin(ratio * PI) * 8.0
			pose.wing = clampf(ratio * 1.3, 0.0, 1.0)
			pose.arm = clampf(0.35 + ratio, 0.0, 1.0)
			pose.weapon = clampf(0.3 + ratio * 1.1, 0.0, 1.0)
			pose.energy = clampf(sin(ratio * PI) * 1.25, 0.0, 1.0)
		"hurt":
			var ratio := float(index) / float(maxi(1, count - 1))
			pose.body_y = 2.0 + ratio * 3.0
			pose.lean = 5.0 - ratio * 3.0
			pose.energy = 0.8 - ratio * 0.4
		"death":
			var ratio := float(index) / float(maxi(1, count - 1))
			pose.body_y = ratio * 12.0
			pose.crouch = ratio * 8.0
			pose.energy = 1.0 - ratio
			pose.fade = 1.0 - ratio * 0.55
	var image := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	_paint_boss(image, region_id, state, pose)
	return ImageTexture.create_from_image(image)

static func _paint_boss(image: Image, region_id: String, state: String, pose: Dictionary) -> void:
	var colors := _colors(region_id)
	var alpha: float = clampf(float(pose.fade), 0.0, 1.0)
	var body_y: float = float(pose.body_y)
	var crouch: float = float(pose.crouch)
	var lean: float = float(pose.lean)
	var center := Vector2(32.0, 47.0 + body_y + crouch * 0.5)
	var energy: float = float(pose.energy)
	var wing: float = float(pose.wing)
	var arm: float = float(pose.arm)

	if state == "skill" or state == "hurt":
		_fill_ellipse(image, center + Vector2(0, -4), Vector2(29 + energy * 4, 37 + energy * 4), Color(colors.glow, 0.18 * energy))

	match region_id:
		"meadow":
			_draw_wing(image, center + Vector2(-18, -29), Vector2(-17, 6), wing, colors.light, alpha)
			_draw_wing(image, center + Vector2(18, -29), Vector2(17, 6), wing, colors.light, alpha)
			_draw_body(image, center, colors, alpha, crouch, 19.0, 24.0)
			_draw_stripes(image, center, colors)
			_draw_crown(image, center + Vector2(lean * 0.22, -33), colors)
			_draw_face(image, center + Vector2(lean * 0.22, -25), colors)
			_draw_stinger(image, center + Vector2(0, 24), colors, alpha)
		"forest":
			_draw_arm(image, center + Vector2(-22, 2), Vector2(-14, 16), arm, colors.wood, colors.wood_dark, alpha)
			_draw_arm(image, center + Vector2(22, 2), Vector2(14, 16), arm, colors.wood, colors.wood_dark, alpha)
			_draw_body(image, center, colors, alpha, crouch, 18.0, 17.0)
			_draw_cap(image, center + Vector2(lean * 0.18, -24), colors, 22.0)
			_draw_face(image, center + Vector2(lean * 0.18, -9), colors)
			_draw_spore_cracks(image, center, colors, energy, alpha)
		"grove":
			_draw_root_crown(image, center + Vector2(lean * 0.16, -32), colors, wing, alpha)
			_draw_body(image, center, colors, alpha, crouch, 17.0, 23.0)
			_draw_face(image, center + Vector2(lean * 0.16, -22), colors)
			_draw_arms(image, center, colors, arm, colors.root, colors.root_dark, alpha)
			_draw_roots(image, center + Vector2(0, 21), colors, alpha, wing)
		"canyon":
			_draw_wing(image, center + Vector2(-22, -24), Vector2(-24, -2), wing, colors.wing, alpha)
			_draw_wing(image, center + Vector2(22, -24), Vector2(24, -2), wing, colors.wing, alpha)
			_draw_body(image, center, colors, alpha, crouch, 17.0, 22.0)
			_draw_beak(image, center + Vector2(lean * 0.32, -28), colors)
			_draw_face(image, center + Vector2(lean * 0.22, -32), colors)
			_draw_arms(image, center, colors, arm, colors.stone, colors.stone_dark, alpha)
		"ruins":
			_draw_arms(image, center, colors, 1.0 - arm, colors.stone, colors.stone_dark, alpha)
			_draw_body(image, center, colors, alpha, crouch, 19.0, 24.0)
			_draw_face(image, center + Vector2(lean * 0.16, -31), colors)
			_draw_crown(image, center + Vector2(lean * 0.16, -38), colors)
			_draw_runes(image, center, colors, energy, alpha)
		"gate":
			_draw_wing(image, center + Vector2(-22, -22), Vector2(-20, -10), wing, colors.wing, alpha)
			_draw_wing(image, center + Vector2(22, -22), Vector2(20, -10), wing, colors.wing, alpha)
			_draw_body(image, center, colors, alpha, crouch, 18.0, 24.0)
			_draw_face(image, center + Vector2(lean * 0.20, -31), colors)
			_draw_crown(image, center + Vector2(lean * 0.20, -37), colors)
			_draw_staff(image, center + Vector2(23, -6), pose, colors, alpha)

	if state == "attack" or state == "skill":
		var burst := Color(colors.glow, energy * 0.32)
		_fill_ellipse(image, center + Vector2(signf(lean) * 17.0, -8.0), Vector2(10.0 + energy * 7.0, 7.0 + energy * 4.0), burst)

static func _draw_body(image: Image, center: Vector2, colors: Dictionary, alpha: float, crouch: float, rx: float, ry: float) -> void:
	var squash := clampf(1.0 - crouch / 42.0, 0.84, 1.0)
	_fill_ellipse(image, center, Vector2(rx + 2.0, ry + 2.0), Color(colors.outline, alpha))
	_fill_ellipse(image, center, Vector2(rx * squash, ry * squash), Color(colors.primary, alpha))
	_fill_ellipse(image, center + Vector2(-rx * 0.24, -ry * 0.34), Vector2(rx * 0.36, ry * 0.28), Color(colors.highlight, alpha * 0.72))
	_fill_ellipse(image, center + Vector2(rx * 0.20, ry * 0.32), Vector2(rx * 0.44, ry * 0.32), Color(colors.shadow, alpha * 0.62))

static func _draw_face(image: Image, center: Vector2, colors: Dictionary) -> void:
	_fill_rect(image, center + Vector2(-8, -4), Vector2(16, 3), Color(colors.outline, 1.0))
	_fill_ellipse(image, center + Vector2(-5, 0), Vector2(2.6, 2.6), colors.eye)
	_fill_ellipse(image, center + Vector2(5, 0), Vector2(2.6, 2.6), colors.eye)
	_fill_rect(image, center + Vector2(-3, 6), Vector2(6, 2), Color(colors.outline, 0.72))

static func _draw_crown(image: Image, center: Vector2, colors: Dictionary) -> void:
	for index in range(5):
		var x := center.x - 14.0 + index * 7.0
		var height := 5.0 if index % 2 == 0 else 9.0
		_fill_rect(image, Vector2(x - 2.0, center.y - height), Vector2(5.0, height + 4.0), colors.accent)
		_fill_rect(image, Vector2(x - 1.0, center.y - height + 2.0), Vector2(2.0, height), colors.glow)
	_fill_rect(image, center + Vector2(-16, 0), Vector2(32, 5), colors.accent)
	_fill_rect(image, center + Vector2(-16, 4), Vector2(32, 2), colors.shadow)

static func _draw_cap(image: Image, center: Vector2, colors: Dictionary, radius: float) -> void:
	_fill_ellipse(image, center, Vector2(radius + 2.0, radius * 0.60 + 2.0), Color(colors.outline, 1.0))
	_fill_ellipse(image, center, Vector2(radius, radius * 0.60), colors.primary)
	_fill_ellipse(image, center + Vector2(-radius * 0.22, -radius * 0.18), Vector2(radius * 0.36, radius * 0.18), colors.highlight)
	for index in range(5):
		_fill_ellipse(image, center + Vector2(-16.0 + index * 8.0, 2.0 + (index % 2) * 2.0), Vector2(2.4, 1.8), colors.accent)

static func _draw_wing(image: Image, root: Vector2, offset: Vector2, openness: float, color: Color, alpha: float) -> void:
	var spread := signf(offset.x) * (10.0 + openness * 12.0)
	var lift := -5.0 - openness * 12.0
	var tip := root + Vector2(spread, lift)
	_draw_thick_line(image, root, tip, 6.0, Color(color, alpha * 0.86))
	_draw_thick_line(image, root + Vector2(0, 3), tip + Vector2(-signf(offset.x) * 2.0, 9.0), 4.0, Color(color.darkened(0.22), alpha * 0.78))
	_fill_ellipse(image, tip, Vector2(3.0, 3.0), Color(colors_outline(), alpha))

static func _draw_arm(image: Image, shoulder: Vector2, hand: Vector2, raise: float, color: Color, dark: Color, alpha: float) -> void:
	var lifted := hand + Vector2(0, -raise * 15.0)
	_draw_thick_line(image, shoulder, lifted, 7.0, Color(dark, alpha))
	_draw_thick_line(image, shoulder, lifted, 4.0, Color(color, alpha))
	_fill_ellipse(image, lifted, Vector2(5.0, 5.0), Color(colors_outline(), alpha))
	_fill_ellipse(image, lifted, Vector2(3.4, 3.4), Color(color.lightened(0.15), alpha))

static func _draw_arms(image: Image, center: Vector2, colors: Dictionary, raise: float, color: Color, dark: Color, alpha: float) -> void:
	_draw_arm(image, center + Vector2(-20, -2), Vector2(-32, 13), raise, color, dark, alpha)
	_draw_arm(image, center + Vector2(20, -2), Vector2(32, 13), raise, color, dark, alpha)

static func _draw_staff(image: Image, root: Vector2, pose: Dictionary, colors: Dictionary, alpha: float) -> void:
	var raise: float = float(pose.weapon)
	var top := root + Vector2(-raise * 5.0, -50.0 - raise * 8.0)
	_draw_thick_line(image, root, top, 5.0, Color(colors.wood_dark, alpha))
	_draw_thick_line(image, root + Vector2(-1, 0), top + Vector2(-1, 0), 2.0, Color(colors.wood, alpha))
	_fill_ellipse(image, top, Vector2(8.0 + raise * 3.0, 8.0 + raise * 3.0), Color(colors.glow, alpha * (0.28 + raise * 0.42)))
	_fill_ellipse(image, top, Vector2(5.0, 5.0), Color(colors.accent, alpha))
	_fill_ellipse(image, top, Vector2(2.4, 2.4), Color(Color.WHITE, alpha))

static func _draw_stripes(image: Image, center: Vector2, colors: Dictionary) -> void:
	for index in range(3):
		var y := center.y - 9.0 + index * 9.0
		_fill_rect(image, Vector2(center.x - 15.0, y), Vector2(30.0, 4.0), Color(colors.shadow, 0.78))

static func _draw_stinger(image: Image, root: Vector2, colors: Dictionary, alpha: float) -> void:
	_draw_thick_line(image, root, root + Vector2(0, 14), 5.0, Color(colors.shadow, alpha))
	_fill_ellipse(image, root + Vector2(0, 14), Vector2(2.4, 3.0), Color(colors.outline, alpha))

static func _draw_spore_cracks(image: Image, center: Vector2, colors: Dictionary, energy: float, alpha: float) -> void:
	for index in range(4):
		var point := center + Vector2(-11.0 + index * 7.0, -3.0 + (index % 2) * 7.0)
		_fill_ellipse(image, point, Vector2(2.0 + energy * 1.5, 2.0 + energy * 1.5), Color(colors.glow, alpha * (0.35 + energy * 0.45)))

static func _draw_root_crown(image: Image, center: Vector2, colors: Dictionary, openness: float, alpha: float) -> void:
	for index in range(6):
		var angle := PI + PI * float(index) / 5.0
		var tip := center + Vector2(cos(angle) * (13.0 + openness * 6.0), sin(angle) * (16.0 + openness * 4.0))
		_draw_thick_line(image, center + Vector2(0, -20), tip, 4.0, Color(colors.root_dark, alpha))
		_fill_ellipse(image, tip, Vector2(2.2, 2.2), Color(colors.glow, alpha * 0.68))

static func _draw_roots(image: Image, root: Vector2, colors: Dictionary, alpha: float, openness: float) -> void:
	for offset in [-12.0, 0.0, 12.0]:
		var tip := root + Vector2(offset + openness * signf(offset) * 3.0, 16.0)
		_draw_thick_line(image, root + Vector2(offset, 0), tip, 4.0, Color(colors.root, alpha))
		_draw_thick_line(image, root + Vector2(offset, 0), tip, 2.0, Color(colors.root_dark, alpha))

static func _draw_beak(image: Image, center: Vector2, colors: Dictionary) -> void:
	var tip := center + Vector2(16, 7)
	_draw_thick_line(image, center, tip, 8.0, colors.accent)
	_draw_thick_line(image, center, tip, 4.0, colors.glow)

static func _draw_runes(image: Image, center: Vector2, colors: Dictionary, energy: float, alpha: float) -> void:
	for index in range(6):
		var angle := TAU * float(index) / 6.0 + energy * 0.8
		var point := center + Vector2(cos(angle) * 22.0, sin(angle) * 24.0 - 4.0)
		_fill_ellipse(image, point, Vector2(2.4 + energy, 2.4 + energy), Color(colors.glow, alpha * (0.34 + energy * 0.48)))

static func _colors(region_id: String) -> Dictionary:
	match region_id:
		"meadow":
			return {
				"outline": Color("241713"), "primary": Color("ffcf4d"), "highlight": Color("fff3b0"),
				"shadow": Color("a9713f"), "glow": Color("ffe066"), "eye": Color("100b09"),
				"light": Color("fffbe8"), "accent": Color("ffcf4d")
			}
		"forest":
			return {
				"outline": Color("241713"), "primary": Color("d94837"), "highlight": Color("ff9a70"),
				"shadow": Color("8f2d2a"), "glow": Color("8ed45a"), "eye": Color("fffbe8"),
				"wood": Color("a9713f"), "wood_dark": Color("5b4029"), "accent": Color("ffe066")
			}
		"grove":
			return {
				"outline": Color("0d1d1a"), "primary": Color("3f8d77"), "highlight": Color("7ff4c9"),
				"shadow": Color("22564e"), "glow": Color("7ff4c9"), "eye": Color("fffbe8"),
				"root": Color("4bb489"), "root_dark": Color("22564e"), "accent": Color("7ff4c9")
			}
		"canyon":
			return {
				"outline": Color("33150f"), "primary": Color("c7764c"), "highlight": Color("ffe4a8"),
				"shadow": Color("74432f"), "glow": Color("ffe066"), "eye": Color("fffbe8"),
				"stone": Color("b6bfc7"), "stone_dark": Color("5f6870"), "wing": Color("f6b15f"),
				"accent": Color("e8574b")
			}
		"ruins":
			return {
				"outline": Color("222236"), "primary": Color("8a8db0"), "highlight": Color("c1b6e9"),
				"shadow": Color("34375e"), "glow": Color("a9d36d"), "eye": Color("a9d36d"),
				"stone": Color("b6bfc7"), "stone_dark": Color("5f6870"), "accent": Color("a9d36d")
			}
	return {
		"outline": Color("101b4d"), "primary": Color("2e55b8"), "highlight": Color("8cdfff"),
		"shadow": Color("17337a"), "glow": Color("61d6ff"), "eye": Color("fffbe8"),
		"wing": Color("61d6ff"), "wood": Color("a9713f"), "wood_dark": Color("5b4029"),
		"accent": Color("fff0a6")
	}

static func colors_outline() -> Color:
	return Color("241713")

static func _fill_rect(image: Image, origin: Vector2, size: Vector2, color: Color) -> void:
	for y in range(maxi(0, int(origin.y)), mini(image.get_height(), int(origin.y + size.y))):
		for x in range(maxi(0, int(origin.x)), mini(image.get_width(), int(origin.x + size.x))):
			image.set_pixel(x, y, color)

static func _fill_ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	if color.a <= 0.0:
		return
	for y in range(maxi(0, int(center.y - radius.y)), mini(image.get_height(), int(center.y + radius.y) + 1)):
		for x in range(maxi(0, int(center.x - radius.x)), mini(image.get_width(), int(center.x + radius.x) + 1)):
			var offset := (Vector2(x, y) - center) / radius
			if offset.length_squared() <= 1.0:
				image.set_pixel(x, y, color)

static func _draw_thick_line(image: Image, from_point: Vector2, to_point: Vector2, thickness: float, color: Color) -> void:
	if color.a <= 0.0:
		return
	var distance := from_point.distance_to(to_point)
	var steps := maxi(1, int(distance * 1.6))
	for index in range(steps + 1):
		var point := from_point.lerp(to_point, float(index) / float(steps))
		_fill_ellipse(image, point, Vector2(thickness * 0.5, thickness * 0.5), color)
