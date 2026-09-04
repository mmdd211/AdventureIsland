extends CanvasLayer

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const VIEW_W := 1280.0
const VIEW_H := 720.0
const BAR_ORIGIN := Vector2(378.0, 404.0)
const BAR_WIDTH := 520.0
const TIP_INTERVAL := 2.4
const TIP_KEYS := ["tip_slime", "tip_snail", "tip_map", "tip_checkpoint", "tip_dash", "tip_coin"]

var _slimes: Array = []
var _target_progress := 0.0
var _shown_progress := 0.0
var _time := 0.0
var _tip_index := 0
var _tip_timer := 0.0
var _finishing := false

func _ready() -> void:
	add_to_group("loading_screen")
	_apply_localized_text()
	_populate_scenery()
	set_stage(LocalizationSystem.tr_key("loading_preparing"))
	set_progress(0.0)

func _apply_localized_text() -> void:
	%LoadingTitle.text = LocalizationSystem.tr_key("loading_title")

func set_stage(text: String) -> void:
	%StageLabel.text = text

func set_progress(value: float) -> void:
	_target_progress = clampf(value, 0.0, 1.0)

func finish() -> void:
	# 进度走满后淡出并移除自身。
	if _finishing:
		return
	_finishing = true
	_target_progress = 1.0
	var tween := create_tween()
	tween.tween_property(%LoadingRoot, "modulate:a", 0.0, 0.35).set_delay(0.2)
	await tween.finished
	queue_free()

func _process(delta: float) -> void:
	_time += delta
	_shown_progress = lerpf(_shown_progress, _target_progress, 1.0 - exp(-6.0 * delta))
	if absf(_shown_progress - _target_progress) < 0.0005:
		_shown_progress = _target_progress
	_update_bar()
	_update_slimes()
	_update_tip(delta)

func _populate_scenery() -> void:
	var meadow_region := DataCatalog.region("meadow")
	var theme: Dictionary = meadow_region.theme if meadow_region else DataCatalog.region_metadata("meadow").get("theme", {})
	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.texture = _make_gradient_texture(Color(str(theme["sky_top"])), Color(str(theme["sky_bottom"])))
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.position = Vector2.ZERO
	sky.size = Vector2(VIEW_W, VIEW_H)
	%Scenery.add_child(sky)

	var sun := ColorRect.new()
	sun.color = Color(str(theme["accent"]))
	sun.position = Vector2(950, 84)
	sun.size = Vector2(110, 110)
	%Scenery.add_child(sun)
	_add_cloud(Vector2(170, 110), 1.0)
	_add_cloud(Vector2(430, 176), 0.7)
	_add_cloud(Vector2(740, 122), 0.85)
	_add_hills(Color(str(theme["far"])), Vector2(0, 430), Vector2(VIEW_W, 150), [
		[90.0, 366.0, 240.0], [440.0, 386.0, 180.0],
		[800.0, 358.0, 280.0], [1130.0, 392.0, 150.0],
	])
	_add_hills(Color(str(theme["near"])), Vector2(0, 495), Vector2(VIEW_W, 85), [
		[220.0, 452.0, 300.0], [640.0, 462.0, 240.0], [1010.0, 448.0, 260.0],
	])
	var grass := ColorRect.new()
	grass.color = Color(str(theme["ground_grass"]))
	grass.position = Vector2(0, 575)
	grass.size = Vector2(VIEW_W, VIEW_H - 575.0)
	%Scenery.add_child(grass)

	var slime_tex: Texture2D = PixelStyleManager.make_enemy_texture("slime")
	for i in 3:
		var slime := TextureRect.new()
		slime.texture = slime_tex
		slime.stretch_mode = TextureRect.STRETCH_SCALE
		slime.size = Vector2(slime_tex.get_width(), slime_tex.get_height()) * 3.0
		slime.position = Vector2(BAR_ORIGIN.x - 8.0, BAR_ORIGIN.y - slime.size.y - 8.0)
		%Scenery.add_child(slime)
		_slimes.append(slime)
	_refresh_tip_label(0)

func _update_bar() -> void:
	var width := (BAR_WIDTH - 6.0) * clampf(_shown_progress, 0.0, 1.0)
	%BarFill.size.x = width
	%BarShine.size.x = width
	%PercentLabel.text = "%d%%" % int(roundf(_shown_progress * 100.0))

func _update_slimes() -> void:
	# 三只史莱姆沿着进度条填充前沿弹跳。
	var edge_x := BAR_ORIGIN.x + clampf(_shown_progress, 0.0, 1.0) * BAR_WIDTH
	for i in _slimes.size():
		var slime: TextureRect = _slimes[i]
		var bounce := absf(sin(_time * 5.2 + i * 0.9)) * 12.0
		var sx := maxf(edge_x - 24.0 - i * 40.0, BAR_ORIGIN.x - 8.0)
		slime.position = Vector2(sx, BAR_ORIGIN.y - slime.size.y - 8.0 - bounce)

func _update_tip(delta: float) -> void:
	_tip_timer += delta
	if _tip_timer >= TIP_INTERVAL:
		_tip_timer = 0.0
		_tip_index = (_tip_index + 1) % TIP_KEYS.size()
	_refresh_tip_label(_tip_index)

func _refresh_tip_label(index: int) -> void:
	%TipLabel.text = LocalizationSystem.tr_key("tip_prefix") + LocalizationSystem.tr_key(TIP_KEYS[index % TIP_KEYS.size()])
	var phase := _tip_timer / TIP_INTERVAL
	%TipLabel.modulate.a = clampf(phase * 5.0, 0.0, 1.0) * clampf((1.0 - phase) * 5.0, 0.0, 1.0)

func _make_gradient_texture(top: Color, bottom: Color) -> Texture2D:
	var img := Image.create(2, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var c := top.lerp(bottom, float(y) / 63.0)
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	return ImageTexture.create_from_image(img)

func _add_cloud(pos: Vector2, scale_factor: float) -> void:
	var cloud := Control.new()
	cloud.position = pos
	cloud.scale = Vector2(scale_factor, scale_factor)
	%Scenery.add_child(cloud)
	var main := ColorRect.new()
	main.color = Palette.CLOUD
	main.size = Vector2(150, 38)
	cloud.add_child(main)
	var top := ColorRect.new()
	top.color = Palette.CLOUD
	top.position = Vector2(34, -18)
	top.size = Vector2(74, 22)
	cloud.add_child(top)
	var shade := ColorRect.new()
	shade.color = Palette.CLOUD_SHADE
	shade.position = Vector2(0, 30)
	shade.size = Vector2(150, 8)
	cloud.add_child(shade)

func _add_hills(color: Color, base: Vector2, size: Vector2, bumps: Array) -> void:
	var band := ColorRect.new()
	band.color = color
	band.position = base
	band.size = size
	%Scenery.add_child(band)
	for bump in bumps:
		var rect := ColorRect.new()
		rect.color = color
		rect.position = Vector2(bump[0], bump[1])
		rect.size = Vector2(bump[2], base.y - bump[1] + 4.0)
		%Scenery.add_child(rect)
