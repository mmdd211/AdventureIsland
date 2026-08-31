class_name BossFormPainter
extends RefCounted

const SIZE := Vector2i(64, 104)
const MEADOW_SIZE := Vector2i(96, 128)

static func build_frames(region_id: String, form_id: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add(frames, region_id, form_id, "idle", 4, 5.0, true)
	_add(frames, region_id, form_id, "move", 4, 8.0, true)
	_add(frames, region_id, form_id, "attack", 6, 12.0, false)
	_add(frames, region_id, form_id, "skill", 7, 10.0, false)
	_add(frames, region_id, form_id, "hurt", 2, 12.0, false)
	_add(frames, region_id, form_id, "evolve", 7, 8.0, false)
	_add(frames, region_id, form_id, "death", 5, 7.0, false)
	return frames

static func _add(frames: SpriteFrames, region_id: String, form_id: String, state: String, count: int, fps: float, looping: bool) -> void:
	if not frames.has_animation(state):
		frames.add_animation(state)
	frames.set_animation_speed(state, fps)
	frames.set_animation_loop(state, looping)
	for index in range(count):
		frames.add_frame(state, _frame(region_id, form_id, state, index, count))

static func _pose(state: String, index: int, count: int) -> Dictionary:
	var phase := TAU * float(index) / float(maxi(1, count))
	var result := {"bob": 0.0, "lean": 0.0, "crouch": 0.0, "arms": 0.5, "weapon": 0.0, "energy": 0.25, "fade": 1.0}
	match state:
		"idle", "move":
			result.bob = sin(phase) * 2.4
			result.arms = sin(phase + PI * 0.5) * 0.5 + 0.5
			result.energy = 0.26 + sin(phase) * 0.10
		"attack":
			var t := float(index) / float(maxi(1, count - 1))
			result.crouch = sin(t * PI) * 5.0
			result.lean = -5.0 + t * 16.0
			result.arms = t
			result.weapon = t
			result.energy = 1.15 - absf(t - 0.66) * 1.8
		"skill":
			var t := float(index) / float(maxi(1, count - 1))
			result.bob = -3.0 + sin(t * PI) * 8.0
			result.arms = 0.35 + t
			result.weapon = 0.35 + t
			result.energy = sin(t * PI) * 1.3
		"hurt":
			result.bob = 2.0 + float(index) * 1.5
			result.lean = 6.0 - float(index) * 2.0
			result.energy = 0.9 - float(index) * 0.3
		"evolve":
			var t := float(index) / float(maxi(1, count - 1))
			result.bob = sin(t * PI) * -8.0
			result.arms = 1.0
			result.energy = 0.7 + sin(t * PI) * 0.7
		"death":
			var t := float(index) / float(maxi(1, count - 1))
			result.bob = t * 14.0
			result.crouch = t * 7.0
			result.fade = 1.0 - t * 0.55
			result.energy = 1.0 - t
	return result

static func _frame(region_id: String, form_id: String, state: String, index: int, count: int) -> ImageTexture:
	var canvas_size := MEADOW_SIZE if region_id == "meadow" else SIZE
	var image := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	var pose := _pose(state, index, count)
	var colors := _palette(region_id, form_id)
	var center := Vector2(48, 70 + float(pose.bob) + float(pose.crouch) * 0.5) if region_id == "meadow" else Vector2(32, 58 + float(pose.bob) + float(pose.crouch) * 0.5)
	if state in ["skill", "hurt", "evolve"]:
		var aura_radius := Vector2(42, 55) if region_id == "meadow" else Vector2(29, 43)
		_ellipse(image, center + Vector2(0, -6), aura_radius, Color(colors.glow, 0.20 * float(pose.energy)))
	match form_id:
		"bee": _meadow_bee_detailed(image, pose, colors, center, state) if region_id == "meadow" else _bee(image, pose, colors, center, state)
		"dancer": _meadow_dancer_detailed(image, pose, colors, center, state) if region_id == "meadow" else _dancer(image, pose, colors, center, state)
		"turtle": _turtle(image, pose, colors, center, state)
		"gatekeeper": _gatekeeper(image, pose, colors, center, state)
		"nest": _nest(image, pose, colors, center, state)
		"bishop": _bishop(image, pose, colors, center, state)
		"eagle": _eagle(image, pose, colors, center, state)
		"hunter": _hunter(image, pose, colors, center, state)
		"statue": _statue(image, pose, colors, center, state)
		"sage": _sage(image, pose, colors, center, state)
		"whale": _whale(image, pose, colors, center, state)
		"judge": _judge(image, pose, colors, center, state)
	return ImageTexture.create_from_image(image)

static func _meadow_bee(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	var flap := float(pose.arms)
	var lean := float(pose.lean)
	var body := center + Vector2(-2.0 + lean * 0.20, 8.0)
	var fade := clampf(float(pose.fade), 0.0, 1.0)
	var energy := clampf(float(pose.energy), 0.0, 1.4)
	var wing_lift := -18.0 - flap * 11.0

	# The first form is deliberately horizontal: a heavy pollen abdomen carried by
	# asymmetrical moth wings, with a small crowned face buried in the thorax.
	_meadow_wing(image, body + Vector2(-10, -24), -1.0, wing_lift, colors, fade, state == "skill")
	_meadow_wing(image, body + Vector2(8, -25), 1.0, wing_lift + 4.0, colors, fade, state == "skill")

	# Rear pollen sac and abdomen, each with an outline, shadow, banding and a
	# separate glow so the silhouette remains readable at the in-game scale.
	_ellipse(image, body + Vector2(-17, 11), Vector2(24, 24), Color(colors.outline, fade))
	_ellipse(image, body + Vector2(-17, 10), Vector2(22, 22), Color(colors.abdomen, fade))
	_ellipse(image, body + Vector2(-23, 2), Vector2(9, 12), Color(colors.honey, fade))
	_ellipse(image, body + Vector2(-29, -4), Vector2(4, 7), Color(colors.glow, fade * (0.35 + energy * 0.24)))
	for band in range(3):
		var band_y := body.y - 3.0 + band * 13.0
		_line(image, Vector2(body.x - 38.0, band_y), Vector2(body.x + 2.0, band_y + 4.0), 5.0, Color(colors.abdomen_dark, fade))
		_line(image, Vector2(body.x - 35.0, band_y - 2.0), Vector2(body.x - 2.0, band_y + 1.0), 2.0, Color(colors.honey, fade * 0.75))

	# Thorax, flower collar and the small humanoid face keep the reference's
	# elegant character while the body remains an aggressive insect silhouette.
	_ellipse(image, body + Vector2(5, -5), Vector2(16, 17), Color(colors.outline, fade))
	_ellipse(image, body + Vector2(5, -6), Vector2(14, 15), Color(colors.armor, fade))
	_ellipse(image, body + Vector2(0, -16), Vector2(12, 10), Color(colors.petal_dark, fade))
	for petal in range(5):
		var angle := -PI * 0.95 + float(petal) * PI * 0.475
		var tip := body + Vector2(1, -18) + Vector2.from_angle(angle) * 13.0
		_meadow_petal(image, body + Vector2(1, -17), tip, 5.0, colors.petal, colors.petal_light, fade)
	_meadow_face(image, body + Vector2(8, -24), colors, fade, true)
	_meadow_crown(image, body + Vector2(8, -37), colors, 0.78, fade)

	# Jointed forelegs and the rear stinger animate separately from the body.
	var reach := 17.0 + flap * 8.0
	_line(image, body + Vector2(10, 1), body + Vector2(25 + reach, -7 - flap * 4.0), 7.0, Color(colors.outline, fade))
	_line(image, body + Vector2(10, 1), body + Vector2(25 + reach, -7 - flap * 4.0), 4.0, Color(colors.leg, fade))
	_line(image, body + Vector2(14, 5), body + Vector2(30 + reach, 14), 6.0, Color(colors.outline, fade))
	_line(image, body + Vector2(14, 5), body + Vector2(30 + reach, 14), 3.0, Color(colors.leg_light, fade))
	_line(image, body + Vector2(-34, 22), body + Vector2(-48, 31), 6.0, Color(colors.outline, fade))
	_line(image, body + Vector2(-45, 29), body + Vector2(-53, 34), 4.0, Color(colors.honey, fade))

	if state == "attack":
		_line(image, body + Vector2(24, -7), body + Vector2(43 + flap * 12.0, -14), 4.0, Color(colors.glow, fade))
		_line(image, body + Vector2(27, -4), body + Vector2(46 + flap * 12.0, -11), 2.0, Color(colors.core, fade))
	if state == "skill":
		for particle in range(7):
			var angle := TAU * float(particle) / 7.0 + energy * 0.28
			var point := body + Vector2(-14, 5) + Vector2.from_angle(angle) * (26.0 + energy * 7.0)
			_ellipse(image, point, Vector2(2.0, 2.0), Color(colors.core, fade * 0.78))

static func _meadow_dancer(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	var motion := float(pose.arms)
	var lean := float(pose.lean)
	var fade := clampf(float(pose.fade), 0.0, 1.0)
	var energy := clampf(float(pose.energy), 0.0, 1.4)
	var body := center + Vector2(lean * 0.18, 0)

	# The second form is a vertical flower queen: petal mantle, narrow waist and
	# a layered skirt. It shares the palette but none of the first form's anatomy.
	_meadow_petal_cape(image, body + Vector2(0, -17), colors, motion, fade)
	_meadow_skirt(image, body + Vector2(0, 28), colors, motion, fade)
	_meadow_legs(image, body + Vector2(0, 42), motion, colors, fade)
	_meadow_torso(image, body + Vector2(0, 3), colors, energy, fade)
	_meadow_arms(image, body + Vector2(0, 2), motion, colors, fade, state)
	_meadow_hair(image, body + Vector2(0, -29), colors, fade)
	_meadow_face(image, body + Vector2(0, -29), colors, fade, false)
	_meadow_crown(image, body + Vector2(0, -45), colors, 1.0 + motion * 0.16, fade)

	if state == "attack":
		var slash_side := 1.0 if motion > 0.5 else -1.0
		_meadow_petal_blade(image, body + Vector2(slash_side * 17.0, 1), slash_side, motion, colors, fade)
	if state == "skill":
		for petal in range(9):
			var angle := TAU * float(petal) / 9.0 + energy * 0.20
			var radius := 31.0 + sin(float(petal)) * 4.0 + energy * 8.0
			var point := body + Vector2(0, 18) + Vector2.from_angle(angle) * radius
			_meadow_petal(image, body + Vector2(0, 18), point, 4.0, colors.petal, colors.petal_light, fade * 0.85)

static func _meadow_wing(image: Image, root: Vector2, side: float, lift: float, colors: Dictionary, alpha: float, charged: bool) -> void:
	var tip := root + Vector2(side * (40.0 + (4.0 if charged else 0.0)), lift)
	var lower := root + Vector2(side * 31.0, 18.0)
	var mid := root + Vector2(side * 22.0, -10.0)
	_line(image, root, tip, 15.0, Color(colors.wing_shadow, alpha * 0.88))
	_line(image, root + Vector2(0, 2), tip, 10.0, Color(colors.wing, alpha * 0.72))
	_line(image, tip, lower, 10.0, Color(colors.wing_shadow, alpha * 0.78))
	_line(image, root + Vector2(0, 2), lower, 7.0, Color(colors.wing, alpha * 0.62))
	_line(image, root, mid, 3.0, Color(colors.wing_vein, alpha))
	_line(image, mid, tip, 3.0, Color(colors.wing_vein, alpha * 0.9))
	_line(image, mid, lower, 3.0, Color(colors.wing_vein, alpha * 0.85))
	_ellipse(image, tip, Vector2(3, 3), Color(colors.core, alpha * (0.50 if charged else 0.26)))

static func _meadow_petal(image: Image, base: Vector2, tip: Vector2, width: float, outer: Color, inner: Color, alpha: float) -> void:
	_line(image, base, tip, width + 3.0, Color(colors_outline(), alpha))
	_line(image, base, tip, width, Color(outer, alpha))
	var normal := Vector2(-(tip - base).y, (tip - base).x).normalized()
	_line(image, base.lerp(tip, 0.40) + normal * width * 0.50, tip, 2.0, Color(inner, alpha))

static func _meadow_face(image: Image, center: Vector2, colors: Dictionary, alpha: float, insect := false) -> void:
	_ellipse(image, center, Vector2(12, 13), Color(colors.outline, alpha))
	_ellipse(image, center + Vector2(0, 1), Vector2(10, 11), Color(colors.skin, alpha))
	_rect(image, center + Vector2(-8, -2), Vector2(16, 3), Color(colors.hair_shadow, alpha))
	_rect(image, center + Vector2(-7, -5), Vector2(14, 3), Color(colors.hair, alpha))
	_ellipse(image, center + Vector2(-4, 2), Vector2(2, 2), Color(colors.eye, alpha))
	_ellipse(image, center + Vector2(4, 2), Vector2(2, 2), Color(colors.eye, alpha))
	_ellipse(image, center + Vector2(-4, 1), Vector2(1, 1), Color(colors.core, alpha))
	_ellipse(image, center + Vector2(4, 1), Vector2(1, 1), Color(colors.core, alpha))
	if insect:
		_line(image, center + Vector2(-7, -9), center + Vector2(-15, -17), 2.0, Color(colors.leg, alpha))
		_line(image, center + Vector2(7, -9), center + Vector2(15, -17), 2.0, Color(colors.leg, alpha))

static func _meadow_crown(image: Image, center: Vector2, colors: Dictionary, scale_factor: float, alpha: float) -> void:
	var points := [Vector2(-15, 4), Vector2(-10, -10), Vector2(-4, 1), Vector2(0, -17), Vector2(6, 1), Vector2(13, -11), Vector2(17, 4)]
	for index in range(points.size() - 1):
		var from_point: Vector2 = center + points[index] * scale_factor
		var to_point: Vector2 = center + points[index + 1] * scale_factor
		_line(image, from_point, to_point, 5.0, Color(colors.outline, alpha))
		_line(image, from_point, to_point, 3.0, Color(colors.crown, alpha))
	for point in [Vector2(-10, -7), Vector2(0, -14), Vector2(13, -8)]:
		_ellipse(image, center + point * scale_factor, Vector2(3, 3), Color(colors.core, alpha))

static func _meadow_hair(image: Image, center: Vector2, colors: Dictionary, alpha: float) -> void:
	_ellipse(image, center + Vector2(0, 2), Vector2(18, 17), Color(colors.outline, alpha))
	_ellipse(image, center + Vector2(0, 1), Vector2(16, 15), Color(colors.hair_shadow, alpha))
	for side in [-1.0, 1.0]:
		_line(image, center + Vector2(side * 10, -6), center + Vector2(side * 18, 19), 7.0, Color(colors.hair, alpha))
		_line(image, center + Vector2(side * 11, 5), center + Vector2(side * 16, 23), 3.0, Color(colors.hair_light, alpha))

static func _meadow_torso(image: Image, center: Vector2, colors: Dictionary, energy: float, alpha: float) -> void:
	_ellipse(image, center, Vector2(14, 19), Color(colors.outline, alpha))
	_ellipse(image, center, Vector2(12, 17), Color(colors.corsage, alpha))
	_line(image, center + Vector2(-7, -9), center + Vector2(-2, 13), 3.0, Color(colors.corsage_light, alpha))
	_line(image, center + Vector2(7, -9), center + Vector2(2, 13), 3.0, Color(colors.corsage_shadow, alpha))
	_ellipse(image, center + Vector2(0, 1), Vector2(5 + energy * 2.0, 5 + energy * 2.0), Color(colors.outline, alpha))
	_ellipse(image, center + Vector2(0, 1), Vector2(3 + energy, 3 + energy), Color(colors.core, alpha))

static func _meadow_arms(image: Image, center: Vector2, motion: float, colors: Dictionary, alpha: float, state: String) -> void:
	var left_hand := center + Vector2(-24.0 - motion * 8.0, -13.0 - motion * 10.0)
	var right_hand := center + Vector2(24.0 + motion * 8.0, -7.0 + motion * 8.0)
	_line(image, center + Vector2(-9, -7), left_hand, 8.0, Color(colors.outline, alpha))
	_line(image, center + Vector2(-9, -7), left_hand, 5.0, Color(colors.skin_shadow, alpha))
	_line(image, center + Vector2(9, -7), right_hand, 8.0, Color(colors.outline, alpha))
	_line(image, center + Vector2(9, -7), right_hand, 5.0, Color(colors.skin_shadow, alpha))
	_ellipse(image, left_hand, Vector2(5, 5), Color(colors.skin, alpha))
	_ellipse(image, right_hand, Vector2(5, 5), Color(colors.skin, alpha))
	if state == "skill":
		_ellipse(image, left_hand, Vector2(8, 8), Color(colors.core, alpha * 0.32))
		_ellipse(image, right_hand, Vector2(8, 8), Color(colors.core, alpha * 0.32))

static func _meadow_legs(image: Image, center: Vector2, motion: float, colors: Dictionary, alpha: float) -> void:
	var left := center + Vector2(-8.0 - motion * 4.0, 23)
	var right := center + Vector2(8.0 + motion * 4.0, 23)
	_line(image, center + Vector2(-6, -2), left, 7.0, Color(colors.outline, alpha))
	_line(image, center + Vector2(-6, -2), left, 4.0, Color(colors.skin_shadow, alpha))
	_line(image, center + Vector2(6, -2), right, 7.0, Color(colors.outline, alpha))
	_line(image, center + Vector2(6, -2), right, 4.0, Color(colors.skin_shadow, alpha))
	_line(image, left, left + Vector2(-7, 4), 5.0, Color(colors.boot, alpha))
	_line(image, right, right + Vector2(7, 4), 5.0, Color(colors.boot, alpha))

static func _meadow_skirt(image: Image, center: Vector2, colors: Dictionary, motion: float, alpha: float) -> void:
	var rows := [
		{"y": 0.0, "radius": 15.0, "count": 5},
		{"y": 11.0, "radius": 25.0, "count": 7},
		{"y": 24.0, "radius": 35.0, "count": 9}
	]
	for row in rows:
		var y: float = row.y
		var radius: float = row.radius + motion * 4.0
		var count: int = row.count
		for index in range(count):
			var x := -radius + float(index) * (radius * 2.0 / float(maxi(1, count - 1)))
			var tip := center + Vector2(x, y + 15.0 + (index % 2) * 2.0)
			_meadow_petal(image, center + Vector2(x * 0.18, y), tip, 6.0, colors.petal if index % 2 == 0 else colors.petal_dark, colors.petal_light, alpha)

static func _meadow_petal_cape(image: Image, center: Vector2, colors: Dictionary, motion: float, alpha: float) -> void:
	for side in [-1.0, 1.0]:
		var root := center + Vector2(side * 10.0, 0)
		for index in range(3):
			var tip := root + Vector2(side * (20.0 + index * 8.0 + motion * 4.0), -13.0 + index * 14.0)
			_meadow_petal(image, root, tip, 7.0 - index * 0.7, colors.petal, colors.petal_light, alpha)

static func _meadow_petal_blade(image: Image, root: Vector2, side: float, motion: float, colors: Dictionary, alpha: float) -> void:
	var tip := root + Vector2(side * (29.0 + motion * 16.0), -17.0 - motion * 8.0)
	_line(image, root, tip, 9.0, Color(colors.outline, alpha))
	_line(image, root, tip, 6.0, Color(colors.petal, alpha))
	_line(image, root + Vector2(0, 2), tip, 2.0, Color(colors.core, alpha))

static func _meadow_bee_detailed(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	var flap := float(pose.arms)
	var lean := float(pose.lean)
	var fade := clampf(float(pose.fade), 0.0, 1.0)
	var energy := clampf(float(pose.energy), 0.0, 1.4)
	var body := center + Vector2(-4.0 + lean * 0.22, 9.0)
	var wing_lift := -15.0 - flap * 13.0

	# Angular pixel panels make the wings read as layered translucent insect wings,
	# rather than two broad lines. Each panel has a dark rim and vein highlights.
	_meadow_wing_panel(image, PackedVector2Array([
		body + Vector2(-10, -20), body + Vector2(-42, -51 + wing_lift),
		body + Vector2(-35, -5 + wing_lift * 0.55), body + Vector2(-7, 5)
	]), colors, -1.0, fade, state == "skill")
	_meadow_wing_panel(image, PackedVector2Array([
		body + Vector2(7, -21), body + Vector2(44, -47 + wing_lift * 0.80),
		body + Vector2(35, -1 + wing_lift * 0.45), body + Vector2(8, 6)
	]), colors, 1.0, fade, state == "skill")

	# Large abdomen: dark shell, honey panels, three irregular bands and pollen
	# flecks. The rear mass is intentionally much larger than the face.
	_pixel_polygon(image, PackedVector2Array([
		body + Vector2(-43, -4), body + Vector2(-34, -25), body + Vector2(-9, -31),
		body + Vector2(10, -17), body + Vector2(9, 20), body + Vector2(-12, 33),
		body + Vector2(-37, 24), body + Vector2(-49, 9)
	]), colors.abdomen, colors.outline, fade)
	_pixel_polygon(image, PackedVector2Array([
		body + Vector2(-40, -1), body + Vector2(-30, -21), body + Vector2(-12, -25),
		body + Vector2(2, -14), body + Vector2(2, 14), body + Vector2(-14, 25),
		body + Vector2(-34, 19), body + Vector2(-43, 7)
	]), colors.abdomen_dark, colors.abdomen_dark, fade)
	_pixel_polygon(image, PackedVector2Array([
		body + Vector2(-33, -20), body + Vector2(-14, -25), body + Vector2(-1, -15),
		body + Vector2(-4, -3), body + Vector2(-27, -8)
	]), colors.honey, colors.outline, fade)
	for band in range(3):
		var band_y := body.y - 5.0 + band * 14.0
		_line(image, Vector2(body.x - 45.0 + band * 2.0, band_y), Vector2(body.x - 7.0, band_y + 5.0), 5.0, Color(colors.outline, fade))
		_line(image, Vector2(body.x - 42.0 + band * 2.0, band_y - 1.0), Vector2(body.x - 11.0, band_y + 3.0), 2.0, Color(colors.honey, fade))
	for fleck in range(8):
		var fleck_point := body + Vector2(-38.0 + (fleck % 4) * 8.0, -14.0 + int(fleck / 4.0) * 21.0)
		_ellipse(image, fleck_point, Vector2(2, 2), Color(colors.core, fade * (0.52 + energy * 0.16)))

	# Thorax and flower collar give the monster a recognizable queen identity.
	_ellipse(image, body + Vector2(5, -7), Vector2(18, 20), Color(colors.outline, fade))
	_ellipse(image, body + Vector2(5, -8), Vector2(15, 17), Color(colors.armor, fade))
	_line(image, body + Vector2(-7, -17), body + Vector2(13, 2), 3.0, Color(colors.honey, fade))
	_line(image, body + Vector2(11, -16), body + Vector2(-4, 7), 3.0, Color(colors.shadow, fade))
	for petal in range(7):
		var angle := -PI * 0.92 + float(petal) * PI * 0.31
		var tip := body + Vector2(2, -19) + Vector2.from_angle(angle) * (13.0 + (petal % 2) * 3.0)
		_meadow_petal(image, body + Vector2(2, -17), tip, 5.0, colors.petal if petal % 2 == 0 else colors.petal_dark, colors.petal_light, fade)

	_meadow_face(image, body + Vector2(9, -29), colors, fade, true)
	_meadow_crown(image, body + Vector2(9, -43), colors, 0.84, fade)

	# Three jointed legs and the needle-tail add the asymmetrical silhouette seen
	# in the reference instead of the usual round bee body.
	for index in range(3):
		var side := -1.0 if index == 0 else 1.0
		var root := body + Vector2(side * (8.0 + index * 3.0), 2.0 + index * 6.0)
		var knee := root + Vector2(side * (17.0 + flap * 5.0), -7.0 + index * 8.0)
		var foot := knee + Vector2(side * (11.0 + index * 3.0), 9.0)
		_line(image, root, knee, 6.0, Color(colors.outline, fade))
		_line(image, root, knee, 3.0, Color(colors.leg, fade))
		_line(image, knee, foot, 5.0, Color(colors.outline, fade))
		_line(image, knee, foot, 2.0, Color(colors.leg_light, fade))
		_ellipse(image, knee, Vector2(3, 3), Color(colors.honey, fade))
	_line(image, body + Vector2(-42, 16), body + Vector2(-55, 27), 7.0, Color(colors.outline, fade))
	_line(image, body + Vector2(-50, 24), body + Vector2(-59, 28), 3.0, Color(colors.honey, fade))

	if state == "attack":
		_meadow_pixel_blade(image, body + Vector2(20, -4), 1.0, 30.0 + flap * 13.0, colors, fade)
	if state == "skill":
		for particle in range(12):
			var angle := TAU * float(particle) / 12.0 + energy * 0.20
			var point := body + Vector2(-18, 4) + Vector2.from_angle(angle) * (30.0 + energy * 8.0)
			_ellipse(image, point, Vector2(2 + particle % 2, 2 + particle % 2), Color(colors.core, fade * 0.80))

static func _meadow_dancer_detailed(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	var motion := float(pose.arms)
	var lean := float(pose.lean)
	var fade := clampf(float(pose.fade), 0.0, 1.0)
	var energy := clampf(float(pose.energy), 0.0, 1.4)
	var body := center + Vector2(lean * 0.18, 0)

	# The evolved form is built from separate petal plates. The silhouette is a
	# tall humanoid queen, not a recolored version of the flying abdomen.
	_meadow_cape_detailed(image, body + Vector2(0, -17), colors, motion, fade)
	_meadow_skirt_detailed(image, body + Vector2(0, 24), colors, motion, fade)
	_meadow_legs_detailed(image, body + Vector2(0, 42), motion, colors, fade)
	_meadow_torso_detailed(image, body + Vector2(0, 1), colors, energy, fade)
	_meadow_arms_detailed(image, body + Vector2(0, 0), motion, colors, fade, state)
	_meadow_hair_detailed(image, body + Vector2(0, -29), colors, fade)
	_meadow_face(image, body + Vector2(0, -29), colors, fade, false)
	_meadow_crown(image, body + Vector2(0, -47), colors, 1.06 + motion * 0.14, fade)

	if state == "attack":
		var slash_side := 1.0 if motion > 0.5 else -1.0
		_meadow_pixel_blade(image, body + Vector2(slash_side * 18.0, 1), slash_side, 34.0 + motion * 14.0, colors, fade)
	if state == "skill":
		for petal in range(12):
			var angle := TAU * float(petal) / 12.0 + energy * 0.16
			var radius := 32.0 + float(petal % 3) * 5.0 + energy * 7.0
			var point := body + Vector2(0, 17) + Vector2.from_angle(angle) * radius
			_meadow_petal(image, body + Vector2(0, 17), point, 4.0, colors.petal if petal % 2 == 0 else colors.petal_dark, colors.petal_light, fade * 0.90)

static func _meadow_wing_panel(image: Image, points: PackedVector2Array, colors: Dictionary, side: float, alpha: float, charged: bool) -> void:
	_pixel_polygon(image, points, colors.wing_shadow, colors.outline, alpha * 0.90)
	var centroid := Vector2.ZERO
	for point in points:
		centroid += point
	centroid /= float(points.size())
	var inner := PackedVector2Array()
	for point in points:
		inner.append(point.lerp(centroid, 0.20))
	_pixel_polygon(image, inner, colors.wing, colors.wing, alpha * 0.86)
	var root := points[0]
	for index in range(1, points.size()):
		_line(image, root, points[index], 2.0, Color(colors.wing_vein, alpha * 0.90))
		var facet_mid: Vector2 = points[index].lerp(centroid, 0.46)
		_line(image, centroid, facet_mid, 2.0, Color(colors.highlight, alpha * 0.72))
	if charged:
		for index in range(1, points.size()):
			_ellipse(image, points[index], Vector2(2, 2), Color(colors.core, alpha * 0.75))

static func _meadow_pixel_blade(image: Image, root: Vector2, side: float, length: float, colors: Dictionary, alpha: float) -> void:
	var tip := root + Vector2(side * length, -12.0)
	var normal := Vector2(-(tip - root).y, (tip - root).x).normalized()
	var points := PackedVector2Array([
		root + normal * 5.0, root - normal * 5.0,
		tip - Vector2(side * 8.0, -3.0) - normal * 4.0, tip, tip - Vector2(side * 8.0, -3.0) + normal * 4.0
	])
	_pixel_polygon(image, points, colors.petal, colors.outline, alpha)
	_line(image, root, tip - Vector2(side * 5.0, 0), 2.0, Color(colors.core, alpha))

static func _meadow_cape_detailed(image: Image, center: Vector2, colors: Dictionary, motion: float, alpha: float) -> void:
	for side in [-1.0, 1.0]:
		var root := center + Vector2(side * 9.0, 0)
		for index in range(4):
			var tip := root + Vector2(side * (22.0 + index * 8.0 + motion * 4.0), -18.0 + index * 14.0)
			_meadow_petal_plate(image, root, tip, 9.0 - index * 0.8, colors.petal if index < 2 else colors.petal_dark, colors.petal_light, colors.outline, alpha)

static func _meadow_skirt_detailed(image: Image, center: Vector2, colors: Dictionary, motion: float, alpha: float) -> void:
	var row_data := [[5, 14.0, 10.0], [7, 24.0, 22.0], [9, 34.0, 35.0]]
	for row in row_data:
		var count: int = row[0]
		var width: float = row[1] + motion * 3.0
		var y: float = row[2]
		for index in range(count):
			var x := -width + float(index) * width * 2.0 / float(maxi(1, count - 1))
			var base := center + Vector2(x * 0.18, y)
			var tip := center + Vector2(x, y + 17.0 + (index % 2) * 2.0)
			_meadow_petal_plate(image, base, tip, 8.0, colors.petal if index % 2 == 0 else colors.petal_dark, colors.petal_light, colors.outline, alpha)

static func _meadow_petal_plate(image: Image, base: Vector2, tip: Vector2, width: float, fill: Color, highlight: Color, outline: Color, alpha: float) -> void:
	var direction := (tip - base).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var shoulder := base + direction * 4.0
	var neck := tip - direction * 7.0
	var points := PackedVector2Array([
		base + normal * width, base - normal * width,
		neck - normal * (width * 0.54), tip,
		neck + normal * (width * 0.54), shoulder + normal * (width * 0.68)
	])
	_pixel_polygon(image, points, fill, outline, alpha)
	_line(image, base, tip - direction * 4.0, 2.0, Color(highlight, alpha * 0.86))
	_line(image, base + normal * (width * 0.42), neck, 1.0, Color(highlight, alpha * 0.48))
	_line(image, base - normal * (width * 0.42), neck, 1.0, Color(outline, alpha * 0.48))

static func _meadow_torso_detailed(image: Image, center: Vector2, colors: Dictionary, energy: float, alpha: float) -> void:
	_pixel_polygon(image, PackedVector2Array([
		center + Vector2(-14, -14), center + Vector2(14, -14), center + Vector2(11, 13),
		center + Vector2(5, 20), center + Vector2(-5, 20), center + Vector2(-11, 13)
	]), colors.corsage, colors.outline, alpha)
	_pixel_polygon(image, PackedVector2Array([
		center + Vector2(-9, -10), center + Vector2(0, -14), center + Vector2(9, -10),
		center + Vector2(5, 10), center + Vector2(0, 14), center + Vector2(-5, 10)
	]), colors.corsage_light, colors.corsage_shadow, alpha)
	_line(image, center + Vector2(-7, -9), center + Vector2(-2, 11), 2.0, Color(colors.highlight, alpha))
	_line(image, center + Vector2(7, -9), center + Vector2(2, 11), 2.0, Color(colors.shadow, alpha))
	_ellipse(image, center + Vector2(0, 1), Vector2(7 + energy * 2.0, 7 + energy * 2.0), Color(colors.outline, alpha))
	_ellipse(image, center + Vector2(0, 1), Vector2(4 + energy, 4 + energy), Color(colors.core, alpha))
	_ellipse(image, center + Vector2(-1, 0), Vector2(2, 2), Color.WHITE)

static func _meadow_hair_detailed(image: Image, center: Vector2, colors: Dictionary, alpha: float) -> void:
	_pixel_polygon(image, PackedVector2Array([
		center + Vector2(-17, -8), center + Vector2(-11, -21), center + Vector2(2, -25),
		center + Vector2(16, -14), center + Vector2(18, 15), center + Vector2(10, 27),
		center + Vector2(5, 8), center + Vector2(-6, 14), center + Vector2(-18, 24)
	]), colors.hair_shadow, colors.outline, alpha)
	_pixel_polygon(image, PackedVector2Array([
		center + Vector2(-12, -12), center + Vector2(-7, -19), center + Vector2(3, -21),
		center + Vector2(12, -12), center + Vector2(13, 12), center + Vector2(7, 20),
		center + Vector2(4, 3), center + Vector2(-4, 8), center + Vector2(-12, 17)
	]), colors.hair, colors.hair_shadow, alpha)
	for side in [-1.0, 1.0]:
		for index in range(3):
			var root := center + Vector2(side * (8.0 + index * 2.0), -10.0 + index * 5.0)
			var tip := center + Vector2(side * (16.0 + index * 3.0), 13.0 + index * 5.0)
			_line(image, root, tip, 3.0, Color(colors.hair_light, alpha * 0.86))

static func _meadow_arms_detailed(image: Image, center: Vector2, motion: float, colors: Dictionary, alpha: float, state: String) -> void:
	var left_hand := center + Vector2(-26.0 - motion * 8.0, -16.0 - motion * 10.0)
	var right_hand := center + Vector2(26.0 + motion * 8.0, -9.0 + motion * 8.0)
	for pair in [[-1.0, left_hand], [1.0, right_hand]]:
		var side: float = pair[0]
		var hand: Vector2 = pair[1]
		var elbow := center + Vector2(side * 11.0, -7.0) + Vector2(side * motion * 4.0, -motion * 2.0)
		_line(image, center + Vector2(side * 8.0, -7), elbow, 8.0, Color(colors.outline, alpha))
		_line(image, center + Vector2(side * 8.0, -7), elbow, 5.0, Color(colors.skin_shadow, alpha))
		_line(image, elbow, hand, 7.0, Color(colors.outline, alpha))
		_line(image, elbow, hand, 4.0, Color(colors.skin, alpha))
		_ellipse(image, elbow, Vector2(3, 3), Color(colors.petal, alpha))
		_ellipse(image, hand, Vector2(5, 5), Color(colors.skin, alpha))
		_line(image, hand, hand + Vector2(side * 8.0, -4.0), 2.0, Color(colors.highlight, alpha))
	if state == "skill":
		_ellipse(image, left_hand, Vector2(9, 9), Color(colors.core, alpha * 0.28))
		_ellipse(image, right_hand, Vector2(9, 9), Color(colors.core, alpha * 0.28))

static func _meadow_legs_detailed(image: Image, center: Vector2, motion: float, colors: Dictionary, alpha: float) -> void:
	var left := center + Vector2(-9.0 - motion * 4.0, 22)
	var right := center + Vector2(9.0 + motion * 4.0, 22)
	for pair in [[-1.0, left], [1.0, right]]:
		var side: float = pair[0]
		var foot: Vector2 = pair[1]
		_line(image, center + Vector2(side * 6.0, -2), foot, 8.0, Color(colors.outline, alpha))
		_line(image, center + Vector2(side * 6.0, -2), foot, 4.0, Color(colors.skin_shadow, alpha))
		_line(image, foot, foot + Vector2(side * 8.0, 5), 6.0, Color(colors.boot, alpha))
		_line(image, foot + Vector2(side * 1.0, 1), foot + Vector2(side * 7.0, 4), 2.0, Color(colors.honey, alpha))

static func _bee(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	var body := center + Vector2(0, 14)
	_wings(image, body + Vector2(-7, -24), float(pose.arms), colors.wing, float(pose.fade))
	_ellipse(image, body + Vector2(-2, 8), Vector2(17, 19), colors.primary)
	_ellipse(image, body + Vector2(-2, -6), Vector2(12, 12), colors.armor)
	for index in range(4):
		_rect(image, body + Vector2(-17, -2 + index * 9), Vector2(30, 4), colors.shadow)
	_face(image, body + Vector2(2, -21), colors, 7)
	_crown(image, body + Vector2(2, -32), colors, 6)
	for index in range(6):
		var side := 1 if index < 3 else -1
		var foot := body + Vector2(side * (16 + (index % 3) * 3), 12 + (index % 3) * 4)
		_line(image, body + Vector2(side * 8, 4), foot, 4, colors.shadow)
	_line(image, body + Vector2(0, 27), body + Vector2(0, 40), 5, colors.shadow)

static func _dancer(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_legs(image, center + Vector2(0, 24), float(pose.arms), colors.armor, colors.shadow)
	_torso(image, center + Vector2(0, 5), colors, 11, 14)
	_skirt(image, center + Vector2(0, 15), colors, 18 + float(pose.weapon) * 4)
	_arms(image, center + Vector2(0, -2), float(pose.arms), colors.skin, colors.shadow)
	_head(image, center + Vector2(float(pose.lean) * 0.16, -18), colors)
	_crown(image, center + Vector2(float(pose.lean) * 0.16, -29), colors, 7)
	_fan(image, center + Vector2(19, -7), float(pose.weapon), colors.accent)

static func _turtle(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	var body := center + Vector2(0, 13)
	_ellipse(image, body, Vector2(28, 20), colors.armor)
	_ellipse(image, body + Vector2(-4, -4), Vector2(20, 13), colors.primary)
	_ellipse(image, body + Vector2(-9, -8), Vector2(7, 5), colors.highlight)
	for index in range(5):
		_ellipse(image, body + Vector2(-16 + index * 8, 2 + (index % 2) * 5), Vector2(4, 3), colors.glow)
	_face(image, body + Vector2(24, -10), colors, 7)
	for index in range(4):
		var side := 1 if index < 2 else -1
		_line(image, body + Vector2(side * 18, 6), body + Vector2(side * 26, 18 + (index % 2) * 5), 6, colors.shadow)
	if float(pose.weapon) > 0.5:
		for offset in [-24.0, -8.0, 8.0, 24.0]:
			_ellipse(image, body + Vector2(offset, -34), Vector2(4, 4), Color(colors.glow, float(pose.energy)))

static func _gatekeeper(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_legs(image, center + Vector2(0, 27), float(pose.arms), colors.armor, colors.shadow, true)
	_torso(image, center + Vector2(0, 2), colors, 15, 17)
	_round(image, center + Vector2(-15, 2), Vector2(8, 9), colors.armor)
	_round(image, center + Vector2(15, 2), Vector2(8, 9), colors.armor)
	_arms(image, center + Vector2(0, 0), float(pose.arms), colors.skin, colors.shadow)
	_head(image, center + Vector2(float(pose.lean) * 0.18, -20), colors)
	_mushroom_hat(image, center + Vector2(float(pose.lean) * 0.18, -29), colors)
	_barrel_shield(image, center + Vector2(-21, 8), colors)
	_hammer(image, center + Vector2(21, 7), float(pose.weapon), colors)

static func _nest(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	for index in range(7):
		var angle := TAU * float(index) / 7.0 + float(pose.energy) * 0.3
		var tip := center + Vector2(cos(angle) * (24 + float(pose.arms) * 4), sin(angle) * (20 + float(pose.arms) * 4) - 4)
		_line(image, center, tip, 4, colors.root)
		_ellipse(image, tip, Vector2(2, 2), colors.glow)
	_ellipse(image, center + Vector2(0, -3), Vector2(20, 24), colors.root)
	_ellipse(image, center + Vector2(-4, -8), Vector2(11, 12), colors.root_dark)
	_crack_face(image, center + Vector2(0, -10), colors)
	_tendrils(image, center + Vector2(0, 18), colors, float(pose.arms))

static func _bishop(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_rob(image, center + Vector2(0, 14), colors, 15, 28)
	_torso(image, center + Vector2(0, -2), colors, 9, 13)
	_arms(image, center + Vector2(0, -5), float(pose.arms), colors.skin, colors.shadow)
	_head(image, center + Vector2(float(pose.lean) * 0.18, -22), colors)
	_wood_mask(image, center + Vector2(float(pose.lean) * 0.18, -23), colors)
	_staff(image, center + Vector2(20, 12), float(pose.weapon), colors)
	for index in range(3):
		_ellipse(image, center + Vector2(-26 + index * 6, -30 - index * 4), Vector2(4, 4), Color(colors.glow, 0.5 + float(pose.energy) * 0.3))

static func _eagle(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_wings(image, center + Vector2(0, -17), float(pose.arms), colors.wing, float(pose.fade), 25)
	_ellipse(image, center + Vector2(0, 6), Vector2(15, 19), colors.primary)
	_ellipse(image, center + Vector2(0, 0), Vector2(11, 11), colors.armor)
	_head(image, center + Vector2(float(pose.lean) * 0.22, -21), colors)
	_line(image, center + Vector2(12, -21), center + Vector2(28, -14), 5, colors.accent)
	_line(image, center + Vector2(-8, 20), center + Vector2(-14, 31), 4, colors.shadow)
	_line(image, center + Vector2(8, 20), center + Vector2(14, 31), 4, colors.shadow)

static func _hunter(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_cape(image, center + Vector2(0, 11), colors.cape, 13, 25)
	_legs(image, center + Vector2(0, 28), float(pose.arms), colors.armor, colors.shadow)
	_torso(image, center + Vector2(0, 2), colors, 10, 14)
	_arms(image, center + Vector2(0, -1), float(pose.arms), colors.skin, colors.shadow)
	_head(image, center + Vector2(float(pose.lean) * 0.18, -20), colors)
	_helmet(image, center + Vector2(float(pose.lean) * 0.18, -23), colors)
	_blade(image, center + Vector2(19, 1), float(pose.weapon), colors)

static func _statue(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_round(image, center + Vector2(0, 14), Vector2(24, 25), colors.armor)
	_round(image, center + Vector2(0, -6), Vector2(15, 17), colors.primary)
	_arms(image, center + Vector2(0, -4), 1.0 - float(pose.arms), colors.armor, colors.shadow)
	_head(image, center + Vector2(float(pose.lean) * 0.16, -26), colors)
	_moss_crown(image, center + Vector2(float(pose.lean) * 0.16, -34), colors)
	for index in range(4):
		_ellipse(image, center + Vector2(-16 + index * 11, 4), Vector2(4, 4), Color(colors.glow, float(pose.energy)))

static func _sage(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_rob(image, center + Vector2(0, 17), colors, 16, 30)
	_torso(image, center + Vector2(0, -2), colors, 11, 15)
	for index in range(4):
		var side := 1 if index % 2 == 0 else -1
		var hand := center + Vector2(side * (18 + float(pose.arms) * 5), -4 + (index / 2) * 10)
		_line(image, center + Vector2(side * 9, -3), hand, 5, colors.armor)
		_ellipse(image, hand, Vector2(3, 3), colors.skin)
	_head(image, center + Vector2(float(pose.lean) * 0.16, -24), colors)
	_stone_helm(image, center + Vector2(float(pose.lean) * 0.16, -27), colors)
	_board(image, center + Vector2(0, 2), float(pose.energy), colors)

static func _whale(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_ellipse(image, center + Vector2(0, 4), Vector2(28, 20), colors.primary)
	_ellipse(image, center + Vector2(-6, -2), Vector2(18, 12), colors.armor)
	_ellipse(image, center + Vector2(19, 5), Vector2(8, 6), colors.armor)
	_tail(image, center + Vector2(-25, 2), float(pose.arms), colors.wing)
	_ellipse(image, center + Vector2(0, 0), Vector2(5, 5), colors.glow)
	_line(image, center + Vector2(8, -14), center + Vector2(23, -20), 5, colors.wing)
	_line(image, center + Vector2(-6, 19), center + Vector2(-13, 30), 4, colors.shadow)

static func _judge(image: Image, pose: Dictionary, colors: Dictionary, center: Vector2, state: String) -> void:
	_wings(image, center + Vector2(0, -18), float(pose.arms), colors.wing, float(pose.fade), 22)
	_round(image, center + Vector2(0, 14), Vector2(15, 26), colors.armor)
	_torso(image, center + Vector2(0, -4), colors, 11, 16)
	_arms(image, center + Vector2(0, -6), float(pose.arms), colors.skin, colors.shadow)
	_head(image, center + Vector2(float(pose.lean) * 0.18, -25), colors)
	_plume(image, center + Vector2(float(pose.lean) * 0.18, -36), colors)
	_great_sword(image, center + Vector2(18, 5), float(pose.weapon), colors)
	_disc(image, center + Vector2(-20, -18), float(pose.energy), colors)

static func _torso(image: Image, center: Vector2, colors: Dictionary, rx: float, ry: float) -> void:
	_round(image, center, Vector2(rx + 2, ry + 2), colors.outline)
	_round(image, center, Vector2(rx, ry), colors.primary)
	_round(image, center + Vector2(-rx * 0.22, -ry * 0.25), Vector2(rx * 0.42, ry * 0.32), colors.highlight)
	_round(image, center + Vector2(rx * 0.18, ry * 0.22), Vector2(rx * 0.46, ry * 0.35), colors.shadow)

static func _head(image: Image, center: Vector2, colors: Dictionary) -> void:
	_ellipse(image, center, Vector2(10, 10), colors.outline)
	_ellipse(image, center, Vector2(8, 8), colors.skin)
	_rect(image, center + Vector2(-6, -2), Vector2(12, 2), colors.outline)
	_ellipse(image, center + Vector2(-4, 1), Vector2(2, 2), colors.outline)
	_ellipse(image, center + Vector2(4, 1), Vector2(2, 2), colors.outline)

static func _face(image: Image, center: Vector2, colors: Dictionary, radius: float) -> void:
	_ellipse(image, center, Vector2(radius + 1, radius + 1), colors.outline)
	_ellipse(image, center, Vector2(radius, radius), colors.skin)
	_ellipse(image, center + Vector2(-3, 0), Vector2(2, 2), colors.outline)
	_ellipse(image, center + Vector2(3, 0), Vector2(2, 2), colors.outline)

static func _crack_face(image: Image, center: Vector2, colors: Dictionary) -> void:
	_ellipse(image, center, Vector2(12, 8), colors.outline)
	_ellipse(image, center, Vector2(10, 6), colors.root_dark)
	_line(image, center + Vector2(-5, -2), center + Vector2(-1, 1), 2, colors.glow)
	_line(image, center + Vector2(2, -3), center + Vector2(6, 0), 2, colors.glow)

static func _legs(image: Image, center: Vector2, swing: float, color: Color, dark: Color, heavy := false) -> void:
	var width := 7 if heavy else 5
	_line(image, center + Vector2(-6, 0), center + Vector2(-9 - swing * 3, 19), width, dark)
	_line(image, center + Vector2(6, 0), center + Vector2(9 + swing * 3, 19), width, dark)
	_line(image, center + Vector2(-6, 0), center + Vector2(-9 - swing * 3, 17), width - 2, color)
	_line(image, center + Vector2(6, 0), center + Vector2(9 + swing * 3, 17), width - 2, color)

static func _arms(image: Image, center: Vector2, raise: float, color: Color, dark: Color) -> void:
	var lift := -4.0 - raise * 14.0
	var spread := 14.0 + raise * 4.0
	_line(image, center + Vector2(-5, 0), center + Vector2(-spread, lift), 5, dark)
	_line(image, center + Vector2(5, 0), center + Vector2(spread, lift), 5, dark)
	_line(image, center + Vector2(-5, 0), center + Vector2(-spread, lift), 3, color)
	_line(image, center + Vector2(5, 0), center + Vector2(spread, lift), 3, color)
	_ellipse(image, center + Vector2(-spread, lift), Vector2(3, 3), color)
	_ellipse(image, center + Vector2(spread, lift), Vector2(3, 3), color)

static func _wings(image: Image, center: Vector2, openness: float, color: Color, alpha: float, reach := 20.0) -> void:
	for side in [-1.0, 1.0]:
		var tip := center + Vector2(side * (reach + openness * 7), -13 - openness * 9)
		var lower := center + Vector2(side * (reach * 0.75), 4)
		_line(image, center, tip, 5, Color(color, alpha * 0.70))
		_line(image, tip, lower, 4, Color(color.darkened(0.16), alpha * 0.62))

static func _tail(image: Image, root: Vector2, swing: float, color: Color) -> void:
	_line(image, root, root + Vector2(-13, -7 - swing * 5), 8, color)
	_line(image, root + Vector2(-13, -7 - swing * 5), root + Vector2(-23, 0 - swing * 6), 6, color)

static func _skirt(image: Image, center: Vector2, colors: Dictionary, width: float) -> void:
	for index in range(7):
		var x := center.x - width + index * (width * 2.0 / 6.0)
		_line(image, center + Vector2(x * 0.35, -4), Vector2(x, center.y + 14), 5, colors.accent if index % 2 == 0 else colors.primary)

static func _rob(image: Image, center: Vector2, colors: Dictionary, rx: float, ry: float) -> void:
	_ellipse(image, center, Vector2(rx + 2, ry + 2), colors.outline)
	_ellipse(image, center, Vector2(rx, ry), colors.primary)
	_ellipse(image, center + Vector2(-rx * 0.22, -ry * 0.24), Vector2(rx * 0.35, ry * 0.25), colors.highlight)

static func _cape(image: Image, center: Vector2, color: Color, rx: float, ry: float) -> void:
	_ellipse(image, center, Vector2(rx + 2, ry + 2), colors_outline())
	_ellipse(image, center, Vector2(rx, ry), color)

static func _helmet(image: Image, center: Vector2, colors: Dictionary) -> void:
	_ellipse(image, center, Vector2(11, 7), colors.armor)
	_line(image, center + Vector2(-10, -1), center + Vector2(10, -1), 2, colors.glow)

static func _mushroom_hat(image: Image, center: Vector2, colors: Dictionary) -> void:
	_ellipse(image, center, Vector2(19, 8), colors.outline)
	_ellipse(image, center, Vector2(17, 6), colors.primary)
	_ellipse(image, center + Vector2(-5, -2), Vector2(5, 3), colors.highlight)

static func _wood_mask(image: Image, center: Vector2, colors: Dictionary) -> void:
	_round(image, center, Vector2(10, 10), colors.root_dark)
	_line(image, center + Vector2(-5, -1), center + Vector2(5, -1), 2, colors.glow)
	_line(image, center + Vector2(0, -5), center + Vector2(0, 4), 2, colors.glow)

static func _stone_helm(image: Image, center: Vector2, colors: Dictionary) -> void:
	_round(image, center, Vector2(12, 10), colors.armor)
	_line(image, center + Vector2(-8, 0), center + Vector2(8, 0), 2, colors.glow)

static func _moss_crown(image: Image, center: Vector2, colors: Dictionary) -> void:
	for index in range(5):
		_rect(image, center + Vector2(-12 + index * 6, -7 - (index % 2) * 4), Vector2(4, 8 + (index % 2) * 4), colors.glow)

static func _plume(image: Image, center: Vector2, colors: Dictionary) -> void:
	for index in range(4):
		_line(image, center + Vector2(index * 3 - 4, 3), center + Vector2(index * 5 - 6, -6 - index * 2), 3, colors.glow)

static func _crown(image: Image, center: Vector2, colors: Dictionary, width: float) -> void:
	for index in range(4):
		var x := center.x - width + index * (width * 2.0 / 3.0)
		var height := 8 if index == 1 else 5
		_line(image, Vector2(x, center.y + 3), Vector2(x, center.y - height), 3, colors.accent)

static func _fan(image: Image, center: Vector2, openness: float, color: Color) -> void:
	for index in range(4):
		var angle := -0.6 + index * 0.4 + openness * 0.5
		_line(image, center, center + Vector2(cos(angle) * 14, sin(angle) * 11), 3, color)

static func _barrel_shield(image: Image, center: Vector2, colors: Dictionary) -> void:
	_ellipse(image, center, Vector2(8, 12), colors.wood_dark)
	_ellipse(image, center, Vector2(6, 10), colors.wood)
	_line(image, center + Vector2(-5, -3), center + Vector2(5, -3), 2, colors.shadow)

static func _hammer(image: Image, center: Vector2, raise: float, colors: Dictionary) -> void:
	var top := center + Vector2(-raise * 6, -18 - raise * 5)
	_line(image, center, top, 4, colors.wood)
	_round(image, top, Vector2(8, 7), colors.armor)
	_rect(image, top + Vector2(-4, -5), Vector2(8, 3), colors.glow)

static func _staff(image: Image, center: Vector2, raise: float, colors: Dictionary) -> void:
	var top := center + Vector2(-raise * 4, -31)
	_line(image, center, top, 4, colors.wood)
	_ellipse(image, top, Vector2(6 + raise * 2, 6 + raise * 2), Color(colors.glow, 0.65))

static func _blade(image: Image, center: Vector2, raise: float, colors: Dictionary) -> void:
	var tip := center + Vector2(5 + raise * 7, -13 - raise * 7)
	_line(image, center, tip, 5, colors.shadow)
	_line(image, center, tip, 3, colors.accent)

static func _board(image: Image, center: Vector2, energy: float, colors: Dictionary) -> void:
	for index in range(8):
		var x := center.x - 18 + (index % 4) * 12
		var y := center.y - 12 + int(index / 4.0) * 16
		_rect(image, Vector2(x, y), Vector2(9, 9), Color(colors.glow, 0.16 + energy * 0.25))

static func _great_sword(image: Image, center: Vector2, raise: float, colors: Dictionary) -> void:
	var tip := center + Vector2(4 + raise * 9, -31 - raise * 5)
	_line(image, center, tip, 7, colors.shadow)
	_line(image, center, tip, 4, colors.accent)

static func _disc(image: Image, center: Vector2, energy: float, colors: Dictionary) -> void:
	_ellipse(image, center, Vector2(9 + energy * 2, 9 + energy * 2), Color(colors.glow, 0.28 + energy * 0.2))
	_ellipse(image, center, Vector2(4, 4), colors.accent)

static func _tendrils(image: Image, center: Vector2, colors: Dictionary, swing: float) -> void:
	for index in range(4):
		var x := center.x - 13 + index * 9
		_line(image, Vector2(x, center.y), Vector2(x + swing * 3, center.y + 15), 3, colors.root)

static func _palette(region_id: String, form_id: String) -> Dictionary:
	match region_id + ":" + form_id:
		"meadow:bee":
			return {
				"outline": Color("241815"), "primary": Color("c47a20"), "highlight": Color("ffd08a"),
				"armor": Color("6d3218"), "shadow": Color("4a2418"), "skin": Color("f4d6a0"),
				"wing": Color("e4c99c"), "wing_shadow": Color("876b55"), "wing_vein": Color("5f483c"),
				"abdomen": Color("9a4a1f"), "abdomen_dark": Color("4c2118"), "honey": Color("d39a2e"),
				"leg": Color("5a2b1c"), "leg_light": Color("a65c26"), "hair": Color("e7bd77"),
				"hair_light": Color("f4d6a0"), "hair_shadow": Color("8c4d2e"), "skin_shadow": Color("a65c58"),
				"petal": Color("d84f6a"), "petal_dark": Color("8e2940"),
				"petal_light": Color("f27a62"), "crown": Color("c47a20"), "corsage": Color("6d3218"),
				"corsage_light": Color("c47a20"), "corsage_shadow": Color("4a2418"), "boot": Color("3a1d19"),
				"eye": Color("3b1116"), "glow": Color("ffe06a"), "core": Color("fff0b0"), "accent": Color("d84f6a")
			}
		"meadow:dancer":
			return {
				"outline": Color("241815"), "primary": Color("d84f6a"), "highlight": Color("ffd08a"),
				"armor": Color("c47a20"), "shadow": Color("8e2940"), "skin": Color("f4d6a0"),
				"wing": Color("d84f6a"), "wing_shadow": Color("8e2940"), "wing_vein": Color("ffd08a"),
				"abdomen": Color("9a4a1f"), "abdomen_dark": Color("4c2118"), "honey": Color("d39a2e"),
				"leg": Color("5a2b1c"), "leg_light": Color("a65c26"), "hair": Color("e7bd77"),
				"hair_light": Color("f4d6a0"), "hair_shadow": Color("8c4d2e"), "skin_shadow": Color("a65c58"),
				"petal": Color("d84f6a"), "petal_dark": Color("8e2940"),
				"petal_light": Color("f27a62"), "crown": Color("d39a2e"), "corsage": Color("4a2418"),
				"corsage_light": Color("c47a20"), "corsage_shadow": Color("241815"), "boot": Color("3a1d19"),
				"eye": Color("3b1116"), "glow": Color("ffe06a"), "core": Color("fff0b0"), "accent": Color("f27a62")
			}
		"forest:turtle":
			return {"outline": colors_outline(), "primary": Color("d94837"), "highlight": Color("f2d7a6"), "armor": Color("6c472c"), "shadow": Color("352113"), "skin": Color("f2d7a6"), "glow": Color("8ed45a"), "accent": Color("d94837")}
		"forest:gatekeeper":
			return {"outline": colors_outline(), "primary": Color("a9713f"), "highlight": Color("f2d7a6"), "armor": Color("6c472c"), "shadow": Color("352113"), "skin": Color("f2d7a6"), "wood": Color("a9713f"), "wood_dark": Color("5b4029"), "glow": Color("8ed45a"), "accent": Color("d94837")}
		"grove:nest":
			return {"outline": colors_outline(), "primary": Color("3f8d77"), "highlight": Color("9fffe0"), "root": Color("4bb489"), "root_dark": Color("22564e"), "skin": Color("9fffe0"), "glow": Color("7ff4c9"), "accent": Color("7ff4c9")}
		"grove:bishop":
			return {"outline": colors_outline(), "primary": Color("22564e"), "highlight": Color("9fffe0"), "armor": Color("3f8d77"), "shadow": Color("122d2e"), "skin": Color("9fffe0"), "root": Color("4bb489"), "root_dark": Color("22564e"), "wood": Color("a9713f"), "wood_dark": Color("5b4029"), "glow": Color("7ff4c9"), "accent": Color("7ff4c9")}
		"canyon:eagle":
			return {"outline": colors_outline(), "primary": Color("c7764c"), "highlight": Color("ffe4a8"), "armor": Color("b6bfc7"), "shadow": Color("74432f"), "skin": Color("ffe4a8"), "wing": Color("f6b15f"), "wood": Color("a9713f"), "wood_dark": Color("5b4029"), "glow": Color("ffe066"), "accent": Color("e8574b")}
		"canyon:hunter":
			return {"outline": colors_outline(), "primary": Color("74432f"), "highlight": Color("ffe4a8"), "armor": Color("b6bfc7"), "shadow": Color("47231b"), "skin": Color("ffe4a8"), "cape": Color("e8574b"), "glow": Color("ffe066"), "accent": Color("ffe066")}
		"ruins:statue":
			return {"outline": colors_outline(), "primary": Color("8a8db0"), "highlight": Color("c1b6e9"), "armor": Color("b6bfc7"), "shadow": Color("34375e"), "skin": Color("c1b6e9"), "glow": Color("a9d36d"), "accent": Color("a9d36d")}
		"ruins:sage":
			return {"outline": colors_outline(), "primary": Color("5d6091"), "highlight": Color("c1b6e9"), "armor": Color("b6bfc7"), "shadow": Color("34375e"), "skin": Color("c1b6e9"), "glow": Color("a9d36d"), "accent": Color("a9d36d")}
		"gate:whale":
			return {"outline": colors_outline(), "primary": Color("2e55b8"), "highlight": Color("8cdfff"), "armor": Color("17337a"), "shadow": Color("111b55"), "skin": Color("8cdfff"), "wing": Color("61d6ff"), "glow": Color("fff0a6"), "accent": Color("61d6ff")}
	return {"outline": colors_outline(), "primary": Color("2e55b8"), "highlight": Color("8cdfff"), "armor": Color("b6bfc7"), "shadow": Color("17337a"), "skin": Color("fffbe8"), "cape": Color("61d6ff"), "wing": Color("61d6ff"), "wood": Color("a9713f"), "wood_dark": Color("5b4029"), "root": Color("4bb489"), "root_dark": Color("22564e"), "glow": Color("fff0a6"), "accent": Color("61d6ff")}

static func colors_outline() -> Color:
	return Color("241713")

static func _rect(image: Image, origin: Vector2, size: Vector2, color: Color) -> void:
	for y in range(maxi(0, int(origin.y)), mini(image.get_height(), int(origin.y + size.y))):
		for x in range(maxi(0, int(origin.x)), mini(image.get_width(), int(origin.x + size.x))):
			image.set_pixel(x, y, color)

static func _pixel_polygon(image: Image, points: PackedVector2Array, fill: Color, outline: Color, alpha := 1.0) -> void:
	if points.size() < 3:
		return
	_fill_polygon(image, points, Color(fill, fill.a * alpha))
	for index in range(points.size()):
		var from_point: Vector2 = points[index]
		var to_point: Vector2 = points[(index + 1) % points.size()]
		_line(image, from_point, to_point, 2.0, Color(outline, outline.a * alpha))

static func _fill_polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	if color.a <= 0.0 or points.size() < 3:
		return
	var min_y := image.get_height() - 1
	var max_y := 0
	for point in points:
		min_y = mini(min_y, int(floor(point.y)))
		max_y = maxi(max_y, int(ceil(point.y)))
	min_y = maxi(0, min_y)
	max_y = mini(image.get_height() - 1, max_y)
	for y in range(min_y, max_y + 1):
		var intersections: Array[float] = []
		var scan_y := float(y) + 0.5
		for index in range(points.size()):
			var a: Vector2 = points[index]
			var b: Vector2 = points[(index + 1) % points.size()]
			if (a.y <= scan_y and b.y > scan_y) or (b.y <= scan_y and a.y > scan_y):
				var ratio := (scan_y - a.y) / (b.y - a.y)
				intersections.append(a.x + (b.x - a.x) * ratio)
		intersections.sort()
		var pair_index := 0
		while pair_index + 1 < intersections.size():
			var start_x := maxi(0, int(ceil(intersections[pair_index])))
			var end_x := mini(image.get_width() - 1, int(floor(intersections[pair_index + 1])))
			for x in range(start_x, end_x + 1):
				image.set_pixel(x, y, color)
			pair_index += 2

static func _round(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	_ellipse(image, center, radius, color)
	_ellipse(image, center + Vector2(0, radius.y * 0.2), Vector2(radius.x, radius.y * 0.85), color)

static func _ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	if color.a <= 0.0:
		return
	for y in range(maxi(0, int(center.y - radius.y)), mini(image.get_height(), int(center.y + radius.y) + 1)):
		for x in range(maxi(0, int(center.x - radius.x)), mini(image.get_width(), int(center.x + radius.x) + 1)):
			var offset := (Vector2(x, y) - center) / radius
			if offset.length_squared() <= 1.0:
				image.set_pixel(x, y, color)

static func _line(image: Image, from_point: Vector2, to_point: Vector2, thickness: float, color: Color) -> void:
	var steps := maxi(1, int(from_point.distance_to(to_point) * 1.7))
	for index in range(steps + 1):
		_ellipse(image, from_point.lerp(to_point, float(index) / float(steps)), Vector2(thickness * 0.5, thickness * 0.5), color)
