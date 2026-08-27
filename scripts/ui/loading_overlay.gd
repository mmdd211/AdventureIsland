# 加载界面：点击开始游戏后覆盖全屏，伴随世界分阶段搭建与资源加载。
# 加载期间主场景处于暂停状态，本层自身 PROCESS_MODE_ALWAYS，动画照常播放。
extends CanvasLayer

const WORLD_ZONES := preload("res://scripts/world/world_zones.gd")
const Palette := preload("res://scripts/systems/pixel_palette.gd")

const VIEW_W := 1280.0
const VIEW_H := 720.0
const BAR_WIDTH := 520.0
const BAR_HEIGHT := 26.0
const TIP_INTERVAL := 2.4

const TIPS := [
	"大史莱姆被击败后会分裂成两只小史莱姆，别被它们包夹。",
	"踩中蜗牛背部能造成双倍伤害，正面攻击只会击退它。",
	"按 Tab 打开世界地图，随时查看六大区域与当前位置。",
	"触碰检查点即可保存进度，失足坠落也会在附近复活。",
	"冲刺过程中处于无敌状态，用它穿越缺口或躲开敌人。",
	"收集金币能提高通关评价，绕点远路也值得。",
]

var _root: Control
var _stage_label: Label
var _percent_label: Label
var _fill: ColorRect
var _fill_shine: ColorRect
var _tip_label: Label
var _slimes: Array = []

var _target_progress := 0.0
var _shown_progress := 0.0
var _time := 0.0
var _tip_index := 0
var _tip_timer := 0.0
var _finishing := false

var _bar_origin := Vector2((VIEW_W - BAR_WIDTH) / 2.0, 404.0)
var _fill_inner_w := BAR_WIDTH - 6.0
var _fill_inner_h := BAR_HEIGHT - 6.0

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("loading_screen")
	_build_scene()
	set_stage("正在准备冒险…")
	set_progress(0.0)

func set_stage(text: String) -> void:
	if _stage_label:
		_stage_label.text = text

func set_progress(value: float) -> void:
	_target_progress = clampf(value, 0.0, 1.0)

func finish() -> void:
	# 进度走满后淡出并移除自身。
	if _finishing:
		return
	_finishing = true
	_target_progress = 1.0
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.35).set_delay(0.2)
	await tween.finished
	queue_free()

func _process(delta: float) -> void:
	_time += delta
	# 显示进度平滑逼近目标进度，避免进度条跳变。
	_shown_progress = lerpf(_shown_progress, _target_progress, 1.0 - exp(-6.0 * delta))
	if absf(_shown_progress - _target_progress) < 0.0005:
		_shown_progress = _target_progress
	_update_bar()
	_update_slimes()
	_update_tip(delta)

func _build_scene() -> void:
	_root = Control.new()
	_root.name = "LoadingRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var theme: Dictionary = WORLD_ZONES.THEME_MEADOW
	var sky_top := Color(str(theme["sky_top"]))
	var sky_bottom := Color(str(theme["sky_bottom"]))
	var far_color := Color(str(theme["far"]))
	var near_color := Color(str(theme["near"]))
	var grass_color := Color(str(theme["ground_grass"]))
	var accent := Color(str(theme["accent"]))

	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.texture = _make_gradient_texture(sky_top, sky_bottom)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.position = Vector2.ZERO
	sky.size = Vector2(VIEW_W, VIEW_H)
	_root.add_child(sky)

	var sun := ColorRect.new()
	sun.color = accent
	sun.position = Vector2(950, 84)
	sun.size = Vector2(110, 110)
	_root.add_child(sun)

	_add_cloud(_root, Vector2(170, 110), 1.0)
	_add_cloud(_root, Vector2(430, 176), 0.7)
	_add_cloud(_root, Vector2(740, 122), 0.85)

	var far_hills := ColorRect.new()
	far_hills.color = far_color
	far_hills.position = Vector2(0, 430)
	far_hills.size = Vector2(VIEW_W, 150)
	_root.add_child(far_hills)
	_add_hill_bumps(_root, far_color, 430.0, [
		[90.0, 366.0, 240.0], [440.0, 386.0, 180.0],
		[800.0, 358.0, 280.0], [1130.0, 392.0, 150.0],
	])

	var near_hills := ColorRect.new()
	near_hills.color = near_color
	near_hills.position = Vector2(0, 495)
	near_hills.size = Vector2(VIEW_W, 85)
	_root.add_child(near_hills)
	_add_hill_bumps(_root, near_color, 495.0, [
		[220.0, 452.0, 300.0], [640.0, 462.0, 240.0], [1010.0, 448.0, 260.0],
	])

	var grass := ColorRect.new()
	grass.color = grass_color
	grass.position = Vector2(0, 575)
	grass.size = Vector2(VIEW_W, VIEW_H - 575.0)
	_root.add_child(grass)

	var title := Label.new()
	title.text = "冒险岛物语"
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Palette.OUTLINE)
	title.add_theme_color_override("font_outline_color", Palette.WHITE)
	title.add_theme_constant_override("outline_size", 14)
	title.position = Vector2(0, 150)
	title.size = Vector2(VIEW_W, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(title)

	_stage_label = Label.new()
	_stage_label.name = "StageLabel"
	_stage_label.add_theme_font_size_override("font_size", 22)
	_stage_label.add_theme_color_override("font_color", Color("173a52"))
	_stage_label.add_theme_color_override("font_outline_color", Palette.WHITE)
	_stage_label.add_theme_constant_override("outline_size", 5)
	_stage_label.position = Vector2(0, 330)
	_stage_label.size = Vector2(VIEW_W, 32)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_stage_label)

	var border := ColorRect.new()
	border.color = Palette.OUTLINE
	border.position = _bar_origin - Vector2(4, 4)
	border.size = Vector2(BAR_WIDTH + 8, BAR_HEIGHT + 8)
	_root.add_child(border)

	var bg := ColorRect.new()
	bg.color = Color("2a1a12")
	bg.position = _bar_origin
	bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_root.add_child(bg)

	_fill = ColorRect.new()
	_fill.color = Palette.GRASS
	_fill.position = _bar_origin + Vector2(3, 3)
	_fill.size = Vector2(0, _fill_inner_h)
	_root.add_child(_fill)

	_fill_shine = ColorRect.new()
	_fill_shine.color = Color(1, 1, 1, 0.28)
	_fill_shine.position = _bar_origin + Vector2(3, 5)
	_fill_shine.size = Vector2(0, 5)
	_root.add_child(_fill_shine)

	_percent_label = Label.new()
	_percent_label.add_theme_font_size_override("font_size", 20)
	_percent_label.add_theme_color_override("font_color", Palette.OUTLINE)
	_percent_label.add_theme_color_override("font_outline_color", Palette.WHITE)
	_percent_label.add_theme_constant_override("outline_size", 4)
	_percent_label.position = Vector2(0, _bar_origin.y + BAR_HEIGHT + 14)
	_percent_label.size = Vector2(VIEW_W, 28)
	_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_percent_label)

	var slime_tex: Texture2D = PixelStyleManager.make_enemy_texture("slime")
	for i in 3:
		var slime := TextureRect.new()
		slime.texture = slime_tex
		slime.stretch_mode = TextureRect.STRETCH_SCALE
		slime.size = Vector2(slime_tex.get_width(), slime_tex.get_height()) * 3.0
		slime.position = Vector2(_bar_origin.x - 8.0, _bar_origin.y - slime.size.y - 8.0)
		_root.add_child(slime)
		_slimes.append(slime)

	_tip_label = Label.new()
	_tip_label.add_theme_font_size_override("font_size", 18)
	_tip_label.add_theme_color_override("font_color", Color("173a25"))
	_tip_label.add_theme_color_override("font_outline_color", Palette.CLOUD_SHADE)
	_tip_label.add_theme_constant_override("outline_size", 5)
	_tip_label.position = Vector2(0, 620)
	_tip_label.size = Vector2(VIEW_W, 28)
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_tip_label)
	_tip_label.text = "提示：" + TIPS[0]

func _update_bar() -> void:
	var width := _fill_inner_w * clampf(_shown_progress, 0.0, 1.0)
	_fill.size.x = width
	_fill_shine.size.x = width
	_percent_label.text = "%d%%" % int(roundf(_shown_progress * 100.0))

func _update_slimes() -> void:
	# 三只史莱姆沿着进度条填充前沿弹跳。
	var edge_x := _bar_origin.x + clampf(_shown_progress, 0.0, 1.0) * BAR_WIDTH
	for i in _slimes.size():
		var slime: TextureRect = _slimes[i]
		var bounce := absf(sin(_time * 5.2 + i * 0.9)) * 12.0
		var sx := edge_x - 24.0 - i * 40.0
		sx = maxf(sx, _bar_origin.x - 8.0)
		slime.position = Vector2(sx, _bar_origin.y - slime.size.y - 8.0 - bounce)

func _update_tip(delta: float) -> void:
	_tip_timer += delta
	if _tip_timer >= TIP_INTERVAL:
		_tip_timer = 0.0
		_tip_index = (_tip_index + 1) % TIPS.size()
		_tip_label.text = "提示：" + TIPS[_tip_index]
	var phase := _tip_timer / TIP_INTERVAL
	_tip_label.modulate.a = clampf(phase * 5.0, 0.0, 1.0) * clampf((1.0 - phase) * 5.0, 0.0, 1.0)

func _make_gradient_texture(top: Color, bottom: Color) -> Texture2D:
	var img := Image.create(2, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var c := top.lerp(bottom, float(y) / 63.0)
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	return ImageTexture.create_from_image(img)

func _add_cloud(parent: Control, pos: Vector2, scale_factor: float) -> void:
	var cloud := Control.new()
	cloud.position = pos
	cloud.scale = Vector2(scale_factor, scale_factor)
	parent.add_child(cloud)
	var main := ColorRect.new()
	main.color = Palette.CLOUD
	main.position = Vector2.ZERO
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

func _add_hill_bumps(parent: Control, color: Color, base_y: float, bumps: Array) -> void:
	for bump in bumps:
		var rect := ColorRect.new()
		rect.color = color
		rect.position = Vector2(bump[0], bump[1])
		rect.size = Vector2(bump[2], base_y - bump[1] + 4.0)
		parent.add_child(rect)
