# 像素艺术风格管理器：冒险岛风格 Q 版角色
extends Node

const Palette := preload("res://scripts/systems/pixel_palette.gd")
const TILE_SIZE := 32

# 加载界面进度回调：done/total 工作项数量。
signal style_progress(done: int, total: int)
var _style_work_done := 0
var _style_work_total := 0

# 已经做过像素美术的 zone（按 node path 记录），避免重复计算。
var _styled_zone_paths := {}

func _ready() -> void:
	# 启动时不主动跑；由 world_map 在合适时机调用，避免点开始游戏瞬间主线程卡顿。
	pass

func make_enemy_texture(kind: String) -> ImageTexture:
	# 暴露给加载界面：用于展示弹跳的史莱姆。
	return _create_enemy_texture(kind)

func make_coin_texture() -> ImageTexture:
	# 暴露给标题屏：装饰用的旋转金币。
	return _create_coin_texture()

func _tick_style_work() -> void:
	# 仅在异步路径设置了 _style_work_total 时才 emit 进度；旧式调用不 emit。
	if _style_work_total <= 0:
		return
	_style_work_done += 1
	style_progress.emit(_style_work_done, _style_work_total)

func apply_pixel_style() -> void:
	# 兼容旧用法：处理所有 zone，但跨帧让步，每个 zone 之间 await 一帧。
	await get_tree().create_timer(0.2).timeout

	await _apply_to_player()
	await _apply_to_enemies()
	# 单层关卡（如 world01.tscn）的 ground/platform/portal/pickup 直接挂在 root 下。
	await _style_one_zone(null)
	for zone in _collect_zones(false):
		await _style_one_zone(zone)
		await get_tree().process_frame

func apply_pixel_style_for_active() -> void:
	# 首次进入世界：只处理当前 process_mode != DISABLED 的 zone（通常只有 meadow），
	# 避免一次性画完全部 6 个区近 200 个 body 的像素位图导致长时间黑屏。
	# 每次重新加载世界都清空缓存：节点路径在重载后会复用，
	# 旧缓存会让已访问过的 zone 被误判为"已处理"而跳过美术生成。
	_styled_zone_paths.clear()
	_style_work_done = 0
	_style_work_total = _count_work_items(true)
	style_progress.emit(0, _style_work_total)
	await _apply_to_player()
	await _apply_to_enemies()
	# 单层关卡（无 world_zone）也走这条路径：只画 root 直挂的非 zone 节点，
	# 非活跃 zone 留给玩家进区时懒加载。
	await _style_nodes(_root_level_nodes(_style_root()))
	for zone in _collect_zones(true):
		await _style_one_zone(zone)
		# 记录已处理的 zone，玩家之后回到该 zone 时不必重新生成位图。
		_styled_zone_paths[str(zone.get_path())] = true
		await get_tree().process_frame
	_style_work_total = 0

func apply_pixel_style_for_zone(target_zone: Node) -> void:
	# 单 zone 应用，已处理过的跳过。玩家跨区时由 world_map 调度。
	if target_zone == null:
		return
	var key := str(target_zone.get_path())
	if _styled_zone_paths.has(key):
		return
	_styled_zone_paths[key] = true
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if _find_owning_zone(enemy) == target_zone:
			_apply_sprite_to_enemy(enemy)
	await _style_one_zone(target_zone)

func _collect_zones(only_active: bool) -> Array:
	var result: Array = []
	var root := _style_root()
	if root == null:
		return result
	for zone in _world_zones(root):
		if only_active and zone.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		result.append(zone)
	return result

func _style_one_zone(zone: Node) -> void:
	var root := _style_root()
	if root == null:
		return
	# zone == null 表示处理 root 下所有非 zone 子节点（单层关卡如 world01，
	# 以及兼容旧用法）；否则只处理指定 zone 的子节点。
	await _style_nodes(_styleable_nodes(root, zone))

func _find_owning_zone(node: Node) -> Node:
	var current := node.get_parent()
	while current != null:
		if current.is_in_group("world_zone"):
			return current
		current = current.get_parent()
	return null

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
		_tick_style_work()

func _apply_to_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var owning_zone := _find_owning_zone(enemy)
		if owning_zone != null and owning_zone.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		_apply_sprite_to_enemy(enemy)
		_tick_style_work()

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

func _style_nodes(nodes: Array) -> void:
	# 对给定节点批次按 地面 → 传送门 → 金币 三段处理，段间让出一帧。
	if nodes.is_empty():
		return
	await _apply_ground_style_for_nodes(nodes)
	await get_tree().process_frame
	await _apply_portal_style_for_nodes(nodes)
	await get_tree().process_frame
	await _apply_coin_style_for_nodes(nodes)

func _apply_ground_style_for_nodes(nodes: Array) -> void:
	var processed := 0
	for child in nodes:
		if child.name.begins_with("Ground"):
			_set_terrain_sprite(child, "PixelGround", false)
			_apply_ground_fill_style(child)
			var grass = child.get_node_or_null("Grass1")
			if grass:
				grass.visible = false
			var ground_top = child.get_node_or_null("GroundTop")
			if ground_top:
				ground_top.visible = false
			_apply_terrain_decorations(child, true)
		elif child.name.begins_with("Platform"):
			_set_terrain_sprite(child, "PixelPlatform", true)
			_apply_terrain_decorations(child, false)
		elif child.name.begins_with("EdgeWall") or child.name in ["LeftWall", "RightWall"]:
			var visual = child.get_node_or_null("Visual")
			if visual:
				visual.visible = false
		else:
			continue
		processed += 1
		_tick_style_work()
		# 位图生成较重，每 2 个 body 让出一帧，避免主线程长时间卡顿。
		if processed % 2 == 0:
			await get_tree().process_frame

func _apply_portal_style_for_nodes(nodes: Array) -> void:
	for child in nodes:
		if not String(child.name).begins_with("Portal"):
			continue
		var visual = child.get_node_or_null("Visual")
		if visual:
			visual.visible = false

		for old_child_name in ["PixelPortal", "PortalSparkles"]:
			var old_child = child.get_node_or_null(old_child_name)
			if old_child:
				child.remove_child(old_child)
				old_child.queue_free()

		var portal := AnimatedSprite2D.new()
		portal.name = "PixelPortal"
		portal.sprite_frames = _create_portal_frames(_body_theme(child))
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
		_tick_style_work()

func _apply_coin_style_for_nodes(nodes: Array) -> void:
	for child in nodes:
		if not child.is_in_group("pickups"):
			continue
		if child.get("pickup_type") != "coin":
			continue
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
		sprite.scale = Vector2(1.25, 1.25)
		sprite.z_index = 10
		child.add_child(sprite)
		_tick_style_work()

func _root_level_nodes(root: Node) -> Array:
	# root 直挂的非 zone 子节点（单层关卡的 ground/portal 等）。
	var result: Array = []
	if root == null:
		return result
	for child in root.get_children():
		if not child.is_in_group("world_zone"):
			result.append(child)
	return result

func _is_styleable_child(child: Node) -> bool:
	# 真正需要像素美术处理的节点，用于统计工作量（进度条分母）。
	var n := String(child.name)
	if n.begins_with("Ground") or n.begins_with("Platform") or n.begins_with("EdgeWall"):
		return true
	if n in ["LeftWall", "RightWall"]:
		return true
	if n.begins_with("Portal"):
		return true
	if child.is_in_group("pickups") and child.get("pickup_type") == "coin":
		return true
	return false

func _count_work_items(only_active: bool) -> int:
	# 估算本次运行的总工作量：玩家 + 敌人 + 可样式化节点。
	var count := 0
	count += get_tree().get_nodes_in_group("player").size()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if only_active:
			var owning_zone := _find_owning_zone(enemy)
			if owning_zone != null and owning_zone.process_mode == Node.PROCESS_MODE_DISABLED:
				continue
		count += 1
	var root := _style_root()
	if root != null:
		for child in _root_level_nodes(root):
			if _is_styleable_child(child):
				count += 1
		for zone in _collect_zones(only_active):
			for child in zone.get_children():
				if _is_styleable_child(child):
					count += 1
	return count

func _apply_ground_fill_style(body: Node2D) -> void:
	var old_fill = body.get_node_or_null("PixelGroundFill")
	if old_fill:
		body.remove_child(old_fill)
		old_fill.queue_free()
	var fill: ColorRect = body.get_node_or_null("GroundFill") as ColorRect
	if fill == null:
		return
	var size_value := fill.size
	var sprite := Sprite2D.new()
	sprite.name = "PixelGroundFill"
	sprite.texture = _create_ground_fill_texture(int(size_value.x), int(size_value.y), _body_theme(body))
	sprite.position = fill.position + size_value * 0.5
	sprite.z_index = -1
	body.add_child(sprite)
	fill.visible = false

func _style_root() -> Node:
	var roots := get_tree().get_nodes_in_group("pixel_style_root")
	if roots.size() > 0:
		return roots[0]
	return get_tree().current_scene

func _styleable_nodes(root: Node, zone_filter: Node = null) -> Array:
	var result: Array = []
	# 单层关卡（如 world01.tscn）的 ground/platform 直接挂在 root 下。
	if zone_filter == null:
		for child in root.get_children():
			if not child.is_in_group("world_zone"):
				result.append(child)
	# 多区域世界地图的 world_zone 可能挂在 ZoneRoot 之类的容器下，递归收集。
	for zone in _world_zones(root):
		if zone_filter == null or zone == zone_filter:
			result.append_array(zone.get_children())
	return result

func _world_zones(root: Node) -> Array:
	var result: Array = []
	var stack: Array = [root]
	while stack.size() > 0:
		var current = stack.pop_back()
		for child in current.get_children():
			if child.is_in_group("world_zone"):
				result.append(child)
			stack.push_back(child)
	return result

func _body_theme(body: Node) -> Dictionary:
	return body.get_meta("zone_theme", {})

func _theme_color(theme: Dictionary, key: String, fallback: Color) -> Color:
	if theme.has(key):
		return Color(str(theme[key]))
	return fallback

func _create_portal_frames(theme := {}) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("portal")
	frames.set_animation_speed("portal", 8.0)
	frames.set_animation_loop("portal", true)
	for frame_index in range(6):
		frames.add_frame("portal", _create_portal_frame(frame_index, theme))
	return frames

func _create_portal_frame(frame_index: int, theme := {}) -> ImageTexture:
	var img = Image.create(32, 40, false, Image.FORMAT_RGBA8)
	var wood := Palette.WOOD_LIGHT
	var wood_light := Color("c98f52")
	var wood_dark := Palette.WOOD_DARK
	var outline := Palette.OUTLINE
	var stone := Palette.STONE
	var stone_light := Palette.STONE_LIGHT
	var stone_dark := Palette.STONE_DARK
	var portal_deep := _theme_color(theme, "near", Palette.PORTAL_DEEP)
	var portal_mid := _theme_color(theme, "far", Palette.PORTAL_MID)
	var portal_cyan := _theme_color(theme, "accent", Palette.PORTAL_CYAN)
	var portal_white := Palette.PORTAL_WHITE

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
	_fill_rect(img, 12, 2, 8, 1, outline)
	_fill_rect(img, 11, 3, 10, 2, Color("e0574f"))
	_fill_rect(img, 10, 5, 12, 1, Color("b23c40"))
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

func _fill_ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(maxi(0, int(center.y - radius.y)), mini(image.get_height(), int(center.y + radius.y) + 1)):
		for x in range(maxi(0, int(center.x - radius.x)), mini(image.get_width(), int(center.x + radius.x) + 1)):
			var offset := (Vector2(x, y) - center) / radius
			if offset.length_squared() <= 1.0:
				image.set_pixel(x, y, color)

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
		"O": Palette.OUTLINE,
		"R": Color("e0574f"),
		"r": Color("b23c40"),
		"H": Color(0.34, 0.20, 0.13),
		"S": Color(1.00, 0.87, 0.71),
		"s": Color(0.90, 0.70, 0.56),
		"P": Color(0.98, 0.65, 0.58),
		"K": Palette.OUTLINE,
		"B": Color("3a6fd8"),
		"b": Color("2650a8"),
		"Y": Palette.YELLOW,
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
		"O": Palette.OUTLINE,
		"R": Color("e07a3c"),
		"r": Palette.YELLOW,
		"W": Color(1.00, 0.95, 0.82),
		"s": Color(0.91, 0.81, 0.66),
		"K": Palette.OUTLINE,
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
		"O": Palette.OUTLINE,
		"B": Color("4f83d8"),
		"b": Color("31599f"),
		"W": Color(0.85, 0.94, 1.00),
		"Y": Palette.YELLOW,
		"K": Palette.OUTLINE,
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
		"O": Palette.GRASS_OUTLINE,
		"G": Palette.GRASS,
		"g": Palette.GRASS_LIGHT,
		"W": Color(0.88, 1.00, 0.90),
		"K": Palette.GRASS_OUTLINE,
	}
	return _texture_from_rows(rows, palette)

func _create_coin_texture() -> ImageTexture:
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
		_set_pixel_if_empty(img, x, 2, Palette.OUTLINE)
		_set_pixel_if_empty(img, x, 13, Palette.OUTLINE)
	for y in range(3, 13):
		_set_pixel_if_empty(img, 2, y, Palette.OUTLINE)
		_set_pixel_if_empty(img, 13, y, Palette.OUTLINE)
	return ImageTexture.create_from_image(img)

func _set_pixel_if_empty(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height() and img.get_pixel(x, y).a == 0.0:
		img.set_pixel(x, y, color)

func _apply_terrain_decorations(body: Node2D, allow_sign: bool) -> void:
	var theme := _body_theme(body)
	var zone_id := str(body.get_meta("zone_id", ""))
	var old_decor = body.get_node_or_null("PixelDecor")
	if old_decor:
		body.remove_child(old_decor)
		old_decor.queue_free()
	var old_underdecor = body.get_node_or_null("PixelUnderdecor")
	if old_underdecor:
		body.remove_child(old_underdecor)
		old_underdecor.queue_free()

	var collider = body.get_node_or_null("CollisionShape2D")
	if collider == null:
		for child in body.get_children():
			if child is CollisionShape2D:
				collider = child
				break
	if collider == null or not (collider.shape is RectangleShape2D):
		return
	var size: Vector2 = collider.shape.size
	var decor := Node2D.new()
	decor.name = "PixelDecor"
	body.add_child(decor)

	var random := RandomNumberGenerator.new()
	random.seed = hash(String(body.name))
	var count := clampi(int(size.x / 230.0), 2, 7)
	var is_platform := String(body.name).begins_with("Platform")
	for index in range(count):
		var kind := _theme_decor_kind(zone_id, index, is_platform, allow_sign)
		var texture := _create_terrain_decor_texture(kind, theme)
		var sprite := Sprite2D.new()
		sprite.name = "%s%d" % [kind.capitalize(), index]
		sprite.texture = texture
		sprite.z_index = 3
		var margin := 26.0 if not is_platform else 18.0
		var x := clampf(size.x * (float(index) + 0.5) / count + random.randf_range(-28.0, 28.0), margin, size.x - margin)
		var overlap := 4.0 if kind == "sign" else 2.0
		sprite.position = Vector2(x - size.x * 0.5, -size.y * 0.5 + overlap - texture.get_height() * 0.5)
		decor.add_child(sprite)

	if String(body.name).begins_with("Platform"):
		var underdecor := Node2D.new()
		underdecor.name = "PixelUnderdecor"
		body.add_child(underdecor)
		var vine_count := clampi(int(size.x / 72.0), 2, 5)
		for index in range(vine_count):
			var vine := Sprite2D.new()
			vine.name = "Vine%d" % index
			vine.texture = _create_vine_texture()
			vine.z_index = -1
			vine.position = Vector2(
				-size.x * 0.5 + size.x * (float(index) + 0.5) / vine_count + random.randf_range(-10.0, 10.0),
				size.y * 0.5 + _create_vine_texture().get_height() * 0.5 - 4.0
			)
			underdecor.add_child(vine)

func _theme_decor_kind(zone_id: String, index: int, is_platform: bool, allow_sign: bool) -> String:
	match zone_id:
		"meadow":
			var kinds := ["flower", "grass", "flower", "stone"]
			return "sign" if allow_sign and index == 2 and not is_platform else kinds[index % kinds.size()]
		"forest":
			return "mushroom" if index % 3 != 1 else "grass"
		"grove":
			return "crystal" if index % 3 == 0 else ("mushroom" if index % 3 == 1 else "grass")
		"canyon":
			return "stone" if index % 3 == 0 else "grass"
		"ruins":
			return "stone" if index % 3 != 1 else "stump"
		"gate":
			return "crystal" if index % 2 == 0 else "flower"
		_:
			var kind := "mushroom" if index % 3 == 0 else ("grass" if index % 3 == 1 else "flower")
			if index % 4 == 3:
				kind = "stone"
			if not is_platform and index == 1:
				kind = "stump"
			if allow_sign and index == 2:
				kind = "sign"
			if is_platform and kind == "sign":
				kind = "mushroom"
			return kind

func _create_terrain_decor_texture(kind: String, theme := {}) -> ImageTexture:
	if kind == "crystal":
		return _create_crystal_texture(theme)
	if kind == "stone":
		return _create_stone_texture(theme)
	if kind == "sign":
		return _create_sign_texture()
	if kind == "mushroom":
		return _create_mushroom_decor_texture()
	if kind == "grass":
		return _create_grass_tuft_texture(theme)
	if kind == "stump":
		return _create_stump_texture()
	return _create_flower_texture(theme)

func _create_crystal_texture(theme: Dictionary) -> ImageTexture:
	var img = Image.create(18, 26, false, Image.FORMAT_RGBA8)
	var crystal := _theme_color(theme, "accent", Palette.CYAN)
	_fill_rect(img, 7, 2, 4, 20, crystal)
	_fill_rect(img, 5, 6, 3, 14, crystal.darkened(0.12))
	_fill_rect(img, 10, 5, 3, 15, crystal.lightened(0.22))
	_fill_rect(img, 6, 21, 7, 3, crystal.darkened(0.28))
	_fill_rect(img, 8, 1, 2, 1, Palette.WHITE)
	_fill_rect(img, 6, 2, 1, 19, crystal.darkened(0.3))
	_fill_rect(img, 11, 3, 1, 18, crystal.darkened(0.3))
	return ImageTexture.create_from_image(img)

func _create_stump_texture() -> ImageTexture:
	var img = Image.create(24, 21, false, Image.FORMAT_RGBA8)
	_fill_rect(img, 4, 6, 16, 14, Palette.WOOD)
	_fill_rect(img, 4, 6, 3, 14, Palette.WOOD_LIGHT)
	_fill_rect(img, 16, 6, 4, 14, Palette.WOOD_DARK)
	_fill_ellipse(img, Vector2(12, 6), Vector2(9, 5), Palette.OUTLINE)
	_fill_ellipse(img, Vector2(12, 6), Vector2(8, 4), Palette.WOOD_LIGHT)
	_fill_ellipse(img, Vector2(12, 6), Vector2(5, 3), Palette.WOOD_DARK)
	_fill_rect(img, 8, 11, 1, 8, Palette.OUTLINE)
	_fill_rect(img, 14, 13, 1, 6, Palette.OUTLINE)
	return ImageTexture.create_from_image(img)

func _create_mushroom_decor_texture() -> ImageTexture:
	var img = Image.create(16, 18, false, Image.FORMAT_RGBA8)
	_fill_rect(img, 6, 9, 4, 8, Color("f2e3c2"))
	_fill_rect(img, 6, 9, 1, 8, Color("d8c4a0"))
	_fill_rect(img, 9, 9, 1, 8, Color("c9b28d"))
	_fill_rect(img, 2, 4, 12, 5, Color("e0574f"))
	_fill_rect(img, 4, 2, 8, 2, Color("e0574f"))
	_fill_rect(img, 4, 4, 3, 2, Palette.WHITE)
	_fill_rect(img, 10, 5, 3, 2, Palette.WHITE)
	_fill_rect(img, 2, 8, 12, 1, Palette.OUTLINE)
	_fill_rect(img, 3, 2, 10, 1, Palette.OUTLINE)
	_fill_rect(img, 2, 3, 1, 5, Palette.OUTLINE)
	_fill_rect(img, 13, 3, 1, 5, Palette.OUTLINE)
	_fill_rect(img, 5, 16, 6, 1, Palette.OUTLINE)
	return ImageTexture.create_from_image(img)

func _create_grass_tuft_texture(theme := {}) -> ImageTexture:
	var img = Image.create(18, 13, false, Image.FORMAT_RGBA8)
	var grass := _theme_color(theme, "ground_grass", Palette.GRASS)
	var blades := [Vector2i(2, 7), Vector2i(5, 3), Vector2i(8, 1), Vector2i(11, 4), Vector2i(15, 8)]
	for index in range(blades.size()):
		var blade: Vector2i = blades[index]
		var color := grass if index % 2 == 0 else grass.lightened(0.18)
		for y in range(blade.y, 12):
			var sway := (11 - y) / 5
			img.set_pixel(blade.x + sway, y, color)
			if y > blade.y + 2:
				img.set_pixel(blade.x + sway + 1, y, grass.darkened(0.22))
	return ImageTexture.create_from_image(img)

func _create_vine_texture() -> ImageTexture:
	var img = Image.create(10, 26, false, Image.FORMAT_RGBA8)
	for y in range(1, 25):
		var sway := int(sin(float(y) * 0.35) * 2.0)
		img.set_pixel(5 + sway, y, Palette.GRASS_DARK)
		if y % 5 == 0:
			img.set_pixel(3 + sway, y, Palette.GRASS)
			img.set_pixel(7 + sway, y + 1, Palette.GRASS)
	return ImageTexture.create_from_image(img)

func _create_flower_texture(theme := {}) -> ImageTexture:
	var img = Image.create(12, 16, false, Image.FORMAT_RGBA8)
	var grass := _theme_color(theme, "ground_grass", Palette.GRASS)
	var blossom := _theme_color(theme, "landmark_a", Palette.RED)
	_fill_rect(img, 5, 8, 2, 8, grass.darkened(0.22))
	_fill_rect(img, 3, 11, 2, 1, grass)
	_fill_rect(img, 7, 13, 2, 1, grass)
	_fill_rect(img, 4, 3, 4, 4, blossom)
	_fill_rect(img, 3, 4, 6, 2, blossom)
	_fill_rect(img, 5, 4, 2, 2, Palette.YELLOW_LIGHT)
	_fill_rect(img, 4, 2, 4, 1, Palette.OUTLINE)
	_fill_rect(img, 3, 3, 1, 4, Palette.OUTLINE)
	_fill_rect(img, 8, 3, 1, 4, Palette.OUTLINE)
	_fill_rect(img, 4, 7, 4, 1, Palette.OUTLINE)
	return ImageTexture.create_from_image(img)

func _create_stone_texture(theme := {}) -> ImageTexture:
	var img = Image.create(16, 10, false, Image.FORMAT_RGBA8)
	var stone := _theme_color(theme, "landmark_a", Palette.STONE)
	_fill_rect(img, 3, 2, 10, 6, stone)
	_fill_rect(img, 5, 1, 6, 1, stone)
	_fill_rect(img, 4, 2, 5, 2, stone.lightened(0.18))
	_fill_rect(img, 8, 6, 5, 2, stone.darkened(0.18))
	_fill_rect(img, 3, 8, 10, 1, Palette.OUTLINE)
	_fill_rect(img, 2, 3, 1, 5, Palette.OUTLINE)
	_fill_rect(img, 13, 3, 1, 5, Palette.OUTLINE)
	_fill_rect(img, 5, 0, 6, 1, Palette.OUTLINE)
	return ImageTexture.create_from_image(img)

func _create_sign_texture() -> ImageTexture:
	var img = Image.create(24, 30, false, Image.FORMAT_RGBA8)
	_fill_rect(img, 10, 14, 4, 16, Palette.WOOD)
	_fill_rect(img, 10, 14, 1, 16, Palette.WOOD_LIGHT)
	_fill_rect(img, 13, 14, 1, 16, Palette.WOOD_DARK)
	_fill_rect(img, 2, 2, 20, 13, Palette.WOOD)
	_fill_rect(img, 3, 3, 18, 2, Palette.WOOD_LIGHT)
	_fill_rect(img, 4, 6, 16, 1, Palette.WOOD_DARK)
	_fill_rect(img, 4, 9, 12, 1, Palette.WOOD_DARK)
	_fill_rect(img, 2, 2, 20, 1, Palette.OUTLINE)
	_fill_rect(img, 2, 14, 20, 1, Palette.OUTLINE)
	_fill_rect(img, 2, 2, 1, 13, Palette.OUTLINE)
	_fill_rect(img, 21, 2, 1, 13, Palette.OUTLINE)
	return ImageTexture.create_from_image(img)

func _set_terrain_sprite(body: Node2D, sprite_name: String, floating: bool) -> void:
	var size := Vector2(160, 24)
	var collider = body.get_node_or_null("CollisionShape2D")
	if collider == null:
		for child in body.get_children():
			if child is CollisionShape2D:
				collider = child
				break
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
	sprite.texture = _create_terrain_texture(int(size.x), int(size.y), floating, _body_theme(body))
	sprite.z_index = 0
	body.add_child(sprite)
	sprite.position.y = _terrain_sprite_offset(int(size.y), floating)

func _create_terrain_texture(width: int, height: int, floating: bool, theme := {}) -> ImageTexture:
	width = maxi(TILE_SIZE, width)
	height = maxi(16, height)
	var top_pad := 7 if floating else 6
	var bottom_tail := 24 if floating else 0
	var terrain_height := top_pad + height + bottom_tail
	var img = Image.create(width, terrain_height, false, Image.FORMAT_RGBA8)
	var body_top := top_pad
	var body_bottom := top_pad + height
	var radius := clampi(mini(width, height) / 5, 4, 9) if floating else 6
	var random := RandomNumberGenerator.new()
	random.seed = hash("%d-%d-%s" % [width, height, floating])
	var grass := _theme_color(theme, "ground_grass", Palette.GRASS)
	var grass_light := grass.lightened(0.22)
	var grass_dark := grass.darkened(0.24)
	var grass_outline := grass.darkened(0.48)
	var dirt := _theme_color(theme, "ground_body", Palette.DIRT)
	var dirt_light := dirt.lightened(0.16)
	var dirt_dark := _theme_color(theme, "ground_dark", Palette.DIRT_DARK)
	var root := _theme_color(theme, "landmark_b", Palette.WOOD)
	var root_dark := root.darkened(0.28)

	for y in range(top_pad, body_bottom):
		for x in range(width):
			if not _terrain_point_inside(x, y, body_top, height, width, floating, radius):
				continue
			var body_y := y - body_top
			var edge := x < 2 or x >= width - 2 or body_y < 2 or body_y >= height - 2
			var grass_depth := top_pad + clampi(
				18 + int(sin(float(x) * 0.043) * 4.0 + cos(float(x) * 0.017) * 3.0),
				12, 25
			)
			var color: Color
			if y <= grass_depth:
				color = grass
				if y == top_pad or edge:
					color = grass_outline
				elif y <= top_pad + 3:
					color = grass_light
				elif y >= grass_depth - 2:
					color = grass_dark
				elif (x * 5 + y * 3) % 9 == 0:
					color = grass_light
			else:
				var depth_ratio := float(body_y) / float(height)
				color = dirt.lerp(dirt_dark, clampf((depth_ratio - 0.24) / 0.76, 0.0, 1.0))
				var clump := sin(float(x) * 0.029 + float(body_y) * 0.051) * 0.5
				clump += sin(float(x) * 0.011 - float(body_y) * 0.023 + 1.3) * 0.5
				var grain := fmod(abs(sin(float(x) * 12.9898 + float(body_y) * 78.233) * 43758.5453), 1.0)
				if clump > 0.48:
					color = color.lightened(0.07)
				elif clump < -0.48:
					color = color.darkened(0.10)
				if grain > 0.94:
					color = dirt_light
				elif grain < 0.06:
					color = color.darkened(0.12)
				if x < 6 or x >= width - 6:
					color = color.darkened(0.10)
				if y >= grass_depth and y < grass_depth + 6:
					color = color.darkened(0.14)
			img.set_pixel(x, y, color)

	# 草皮从边缘垂下来，形成更厚的冒险岛式草块。
	for side in range(2):
		var edge_x := 0 if side == 0 else width - 1
		var direction := 1 if side == 0 else -1
		for offset in range(9):
			var x := edge_x + direction * offset
			if x < 0 or x >= width:
				continue
			var drape := top_pad + 16 + int(sin(float(offset) * 0.7 + float(side)) * 3.0) + (8 - offset) / 2
			for y in range(top_pad, mini(body_bottom, drape)):
				if not _terrain_point_inside(x, y, body_top, height, width, floating, radius):
					continue
				var color := grass_dark
				if offset < 2:
					color = grass
				elif offset < 4:
					color = grass.lightened(0.08)
				img.set_pixel(x, y, color)

	# 草顶上方留出细碎草叶，让边缘不再像硬纸片。
	for x in range(2, width - 2):
		var blade_seed := fmod(abs(sin(float(x) * 43.71) * 9187.31), 1.0)
		if blade_seed > 0.48:
			var blade_height := 1 + int(blade_seed * 2.9)
			for blade_y in range(top_pad - blade_height, top_pad):
				if _terrain_point_inside(x, blade_y, body_top, height, width, floating, radius):
					continue
				img.set_pixel(x, blade_y, grass_dark if blade_y == top_pad - blade_height else grass)

	# 浮空岛底部改成有粗细变化的根须，而不是三根直线。
	if floating:
		for index in range(5):
			var base_x := int(width * (0.16 + float(index) * 0.17))
			var root_length := 9 + (index * 5) % 9
			for tail_y in range(body_bottom, body_bottom + root_length):
				var progress := float(tail_y - body_bottom) / float(root_length)
				var sway := int(sin(progress * 5.0 + float(index) * 1.7) * (2.0 + progress * 2.0))
				var root_x := clampi(base_x + sway, 2, width - 3)
				var root_width := 3 - int(progress * 2.0)
				for root_offset in range(root_width):
					if _terrain_point_inside(root_x + root_offset, tail_y, body_top, height, width, floating, radius):
						continue
					img.set_pixel(root_x + root_offset, tail_y, root_dark if root_offset == 0 else root)

	return ImageTexture.create_from_image(img)

func _terrain_sprite_offset(height: int, floating: bool) -> float:
	var top_pad := 7 if floating else 6
	var terrain_height := top_pad + height + (24 if floating else 0)
	return -float(height) * 0.5 - float(top_pad) + float(terrain_height) * 0.5

func _terrain_point_inside(x: int, y: int, top: int, height: int, width: int, floating: bool, radius: int) -> bool:
	var body_y := y - top
	if body_y < 0 or body_y >= height or x < 0 or x >= width:
		return false
	var nearest_x := clampi(x, radius, width - 1 - radius)
	var nearest_y := clampi(y, top + radius, top + height - 1 - radius) if floating else clampi(y, top + radius, top + height - 1)
	if floating:
		nearest_y = clampi(y, top + radius, top + height - 1 - radius)
	else:
		nearest_y = clampi(y, top + radius, top + height - 1)
	return Vector2(float(x - nearest_x), float(y - nearest_y)).length() <= float(radius)

func _create_ground_fill_texture(width: int, height: int, theme := {}) -> ImageTexture:
	width = maxi(TILE_SIZE, width)
	height = maxi(TILE_SIZE, height)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var random := RandomNumberGenerator.new()
	random.seed = hash("ground-fill-%d-%d" % [width, height])
	var dirt := _theme_color(theme, "ground_body", Palette.DIRT)
	var dirt_dark := _theme_color(theme, "ground_dark", Palette.DIRT_DARK)
	var dirt_light := dirt.lightened(0.16)
	var stone := _theme_color(theme, "landmark_a", Palette.STONE)
	var root := _theme_color(theme, "landmark_b", Palette.WOOD)

	for y in range(height):
		var depth := float(y) / float(height)
		var color := dirt.lerp(dirt_dark, clampf(depth * 1.25, 0.0, 1.0))
		if y < 12:
			color = color.darkened(0.16)
		elif y < 28:
			color = color.darkened(0.06)
		for x in range(width):
			var band := sin(float(x) * 0.017 + float(y) * 0.031) * 0.5
			band += sin(float(x) * 0.006 - float(y) * 0.013 + 1.1) * 0.5
			var pixel := color
			if band > 0.56:
				pixel = pixel.lightened(0.035)
			elif band < -0.56:
				pixel = pixel.darkened(0.045)
			var grain := fmod(abs(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453), 1.0)
			if grain > 0.96:
				pixel = dirt_light
			elif grain < 0.04:
				pixel = pixel.darkened(0.10)
			image.set_pixel(x, y, pixel)

	for index in range(clampi(width / 150, 4, 18)):
		var stone_x := random.randi_range(16, width - 20)
		var stone_y := random.randi_range(30, height - 18)
		var stone_size := random.randf_range(3.0, 7.0)
		_fill_ellipse(image, Vector2(stone_x, stone_y), Vector2(stone_size, stone_size * 0.65), stone.darkened(0.15))
		_fill_ellipse(image, Vector2(stone_x - 1, stone_y - 1), Vector2(stone_size * 0.5, stone_size * 0.35), stone)
	for index in range(clampi(width / 110, 5, 22)):
		var root_x := random.randi_range(12, width - 12)
		var root_y := random.randi_range(24, height - 24)
		var root_height := random.randi_range(18, 48)
		for y in range(root_y, mini(height - 4, root_y + root_height)):
			var sway := int(sin(float(y - root_y) * 0.18 + float(index)) * 2.0)
			image.set_pixel(root_x + sway, y, root.darkened(0.28))
			if y % 4 == 0:
				image.set_pixel(root_x + sway + 1, y, root)

	return ImageTexture.create_from_image(image)

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
