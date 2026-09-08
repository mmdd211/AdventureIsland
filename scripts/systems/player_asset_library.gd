class_name PlayerAssetLibrary
extends RefCounted

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const HERO_ANIMATIONS := {
	"idle": {
		"fps": 6.0,
		"loop": true,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -1),
		"frames": [
			"res://data/player/normalized/frame-1.png",
			"res://data/player/normalized/frame-2.png",
			"res://data/player/normalized/frame-3.png",
			"res://data/player/normalized/frame-4.png",
		],
	},
	"run": {
		"fps": 10.0,
		"loop": true,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -4),
		# 只用与 idle 同批次（木剑）的 run-1~4；run-5~8 为另一生成批次
		# （红剑+猫尾+比例不一致），混用会导致武器闪变与脚底悬浮。
		"frames": [
			"res://data/player/normalized/run-frame-1.png",
			"res://data/player/normalized/run-frame-2.png",
			"res://data/player/normalized/run-frame-3.png",
			"res://data/player/normalized/run-frame-4.png",
		],
	},
	"walk": {
		"fps": 10.0,
		"loop": true,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -4),
		"frames": [
			"res://data/player/normalized/run-frame-1.png",
			"res://data/player/normalized/run-frame-2.png",
			"res://data/player/normalized/run-frame-3.png",
			"res://data/player/normalized/run-frame-4.png",
		],
	},
	"jump": {
		"fps": 12.0,
		"loop": false,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -1),
		"frames": [
			"res://data/player/normalized/jump-takeoff-frame-1.png",
			"res://data/player/normalized/jump-takeoff-frame-2.png",
			"res://data/player/normalized/jump-takeoff-frame-3.png",
			"res://data/player/normalized/jump-takeoff-frame-4.png",
		],
	},
	"fall": {
		"fps": 10.0,
		"loop": true,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -1),
		"frames": [
			"res://data/player/normalized/fall-frame-1.png",
			"res://data/player/normalized/fall-frame-2.png",
			"res://data/player/normalized/fall-frame-3.png",
			"res://data/player/normalized/fall-frame-4.png",
		],
	},
	"landing": {
		"fps": 14.0,
		"loop": false,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -3),
		"frames": [
			"res://data/player/normalized/landing-frame-1.png",
			"res://data/player/normalized/landing-frame-2.png",
			"res://data/player/normalized/landing-frame-3.png",
			"res://data/player/normalized/landing-frame-4.png",
		],
	},
	"attack1": {
		"fps": 14.0,
		"loop": false,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -3),
		"frames": [
			"res://data/player/normalized/attack1-frame-1.png",
			"res://data/player/normalized/attack1-frame-2.png",
			"res://data/player/normalized/attack1-frame-3.png",
			"res://data/player/normalized/attack1-frame-4.png",
		],
	},
	"attack2": {
		"fps": 14.0,
		"loop": false,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -3),
		"frames": [
			"res://data/player/normalized/attack2-frame-1.png",
			"res://data/player/normalized/attack2-frame-2.png",
			"res://data/player/normalized/attack2-frame-3.png",
			"res://data/player/normalized/attack2-frame-4.png",
		],
	},
	"hurt": {
		"fps": 12.0,
		"loop": false,
		"display_scale": 0.25,
		"display_offset": Vector2(0, -5),
		"frames": [
			"res://data/player/normalized/hurt-frame-1.png",
			"res://data/player/normalized/hurt-frame-2.png",
			"res://data/player/normalized/hurt-frame-3.png",
			"res://data/player/normalized/hurt-frame-4.png",
		],
	},
	"death": {
		"fps": 6.0,
		"loop": false,
		"display_scale": 0.25,
		"display_offset": Vector2(0, 0),
		"frames": [
			"res://data/player/normalized/death-frame-1.png",
			"res://data/player/normalized/death-frame-2.png",
			"res://data/player/normalized/death-frame-3.png",
			"res://data/player/normalized/death-frame-4.png",
		],
	},
}

const HERO_FRAME_SIZE := Vector2(256, 256)
const HERO_DISPLAY_SIZE := Vector2(64, 64)

# ===== 少年冒险者配色 =====
# 头发
const HAIR := Color("1a1a2e")
const HAIR_HIGHLIGHT := Color("2d2d44")
const HAIR_LIGHT := Color("4a4a66")
# 皮肤
const SKIN := Color("f0d0a0")
const SKIN_LIGHT := Color("f8e0b8")
const SKIN_SHADOW := Color("d0a870")
const SKIN_DEEP := Color("b89060")
const BLUSH := Color("f0a098")
# 眼睛
const EYE_WHITE := Color("ffffff")
const EYE_PUPIL := Color("1a1a2e")
const EYE_SHINE := Color("ffffff")
# 外套
const JACKET := Color("4a9e5e")
const JACKET_LIGHT := Color("5cb870")
const JACKET_DARK := Color("2d7040")
const JACKET_DEEP := Color("1e5830")
# 内衬
const INNER := Color("f0ede8")
const INNER_SHADOW := Color("d8d4cc")
# 护腕
const WRIST := Color("8b6040")
const WRIST_DARK := Color("6b4520")
const WRIST_LIGHT := Color("a07850")
# 腰带
const BELT := Color("6b4520")
const BELT_LIGHT := Color("8b6040")
const BUCKLE := Color("d4a830")
const BUCKLE_SHINE := Color("f0d070")
# 药水
const POTION := Color("27ae60")
const POTION_LIGHT := Color("3ddc84")
const POTION_CAP := Color("8b6040")
# 短裤
const SHORTS := Color("2a3a2a")
const SHORTS_LIGHT := Color("3a4a3a")
const SHORTS_DARK := Color("1a2a1a")
# 靴子
const BOOTS := Color("6b4520")
const BOOTS_DARK := Color("4a2810")
const BOOTS_LIGHT := Color("8b6030")
const BOOT_STRAP := Color("5a3a1a")
const BOOT_METAL := Color("b0b8c0")
# 披风
const CAPE := Color("4a9e5e")
const CAPE_DARK := Color("2d7040")
const CAPE_LIGHT := Color("5cb870")
# 木剑
const WOOD := Color("a08060")
const WOOD_DARK := Color("7a5a3a")
const WOOD_LIGHT := Color("c0a078")
const IRON := Color("b0b8c0")
const IRON_SHINE := Color("d0d8e0")
const GUARD_COLOR := Color("d4a830")
const HANDLE_COLOR := Color("5b3020")
# 特效
const SLASH_FX := Color("fff0a0")

static func frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for animation_name in HERO_ANIMATIONS:
		var config: Dictionary = HERO_ANIMATIONS[animation_name]
		sf.add_animation(animation_name)
		sf.set_animation_speed(animation_name, config["fps"])
		sf.set_animation_loop(animation_name, config["loop"])
		for path in config["frames"]:
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			if image == null or image.is_empty():
				push_error("player frame could not be loaded: %s" % path)
				continue
			sf.add_frame(animation_name, ImageTexture.create_from_image(image))
	return sf

static func animation_config(animation_name: String):
	if not HERO_ANIMATIONS.has(animation_name):
		return null
	return HERO_ANIMATIONS[animation_name]

static func texture() -> ImageTexture:
	return pose_texture("idle_a")

static func pose_texture(pose: String) -> ImageTexture:
	var img := Image.create(48, 40, false, Image.FORMAT_RGBA8)

	# 解析姿态参数
	var cape_sway := 0
	var body_lean := 0
	var l_arm := 0  # 0=down, 1=forward, -1=back, 2=up
	var r_arm := 0
	var l_leg := 0  # 0=standing, 1=forward, -1=back
	var r_leg := 0
	var sword_state := 0  # 0=on_back, 1=half_draw, 2=fully_drawn
	var attack_flash := false

	match pose:
		"idle_a":
			pass
		"idle_b":
			cape_sway = 1
		"walk_a":
			l_arm = 1; r_arm = -1; l_leg = 1; r_leg = -1
		"walk_b":
			l_arm = 0; r_arm = 0
		"walk_c":
			l_arm = -1; r_arm = 1; l_leg = -1; r_leg = 1
		"walk_d":
			l_arm = 1; r_arm = -1; l_leg = 1; r_leg = -1
		"walk_e":
			l_arm = 0; r_arm = 0
		"walk_f":
			l_arm = -1; r_arm = 1; l_leg = -1; r_leg = 1
		"jump":
			l_arm = 2; r_arm = 2
		"fall":
			l_arm = 2; r_arm = 2; cape_sway = -1
		"attack_wind":
			sword_state = 1; r_arm = 3
		"attack_slash":
			sword_state = 2; r_arm = 1; attack_flash = true
		"attack_follow":
			sword_state = 2; r_arm = 1
		"hurt":
			l_arm = 2; r_arm = -1; body_lean = -1

	# 绘制顺序（从后到前）
	_draw_cape(img, pose, cape_sway)
	_draw_sword_back(img, pose, sword_state)
	_draw_body(img, pose, body_lean)
	_draw_arms(img, pose, l_arm, r_arm, body_lean, sword_state)
	_draw_legs(img, pose, l_leg, r_leg, body_lean)
	_draw_head(img, pose, body_lean)
	_draw_belt_bag(img, pose, body_lean)

	if attack_flash:
		_draw_slash(img)

	return ImageTexture.create_from_image(img)

# ===== 头部（少年风格）=====
static func _draw_head(img: Image, _pose: String, lean: int) -> void:
	var hx := 17 + lean
	var hy := 2

	# 蓬松黑发（不规则边缘）
	# 头发主体
	sr(img, hx, hy, 12, 5, HAIR)
	sr(img, hx - 1, hy + 1, 14, 4, HAIR)
	sr(img, hx + 1, hy, 10, 2, HAIR_HIGHLIGHT)
	sr(img, hx + 2, hy + 1, 3, 2, HAIR_LIGHT)

	# 呆毛（向上翘起的头发）
	sr(img, hx + 4, hy - 2, 2, 3, HAIR)
	sr(img, hx + 4, hy - 3, 1, 2, HAIR_HIGHLIGHT)
	sr(img, hx + 8, hy - 1, 2, 2, HAIR)
	sr(img, hx + 8, hy - 2, 1, 1, HAIR_HIGHLIGHT)

	# 刘海（遮住额头，层次感）
	sr(img, hx - 1, hy + 3, 14, 2, HAIR)
	sr(img, hx, hy + 4, 3, 1, HAIR_HIGHLIGHT)
	sr(img, hx + 5, hy + 3, 2, 1, HAIR_HIGHLIGHT)
	sr(img, hx + 9, hy + 4, 2, 1, HAIR_LIGHT)

	# 脸部（圆润）
	sr(img, hx + 1, hy + 5, 10, 9, SKIN)
	sr(img, hx + 2, hy + 5, 8, 1, SKIN_LIGHT)  # 额头高光
	sr(img, hx + 1, hy + 12, 10, 2, SKIN_SHADOW)  # 下巴阴影
	sr(img, hx, hy + 6, 1, 7, SKIN_SHADOW)  # 左脸阴影
	sr(img, hx + 11, hy + 6, 1, 7, SKIN_SHADOW)  # 右脸阴影

	# 脸颊红晕
	sr(img, hx + 1, hy + 10, 2, 1, BLUSH)
	sr(img, hx + 9, hy + 10, 2, 1, BLUSH)

	# 大眼睛（参考图风格：黑瞳孔占大面积）
	sr(img, hx + 3, hy + 7, 3, 4, EYE_WHITE)  # 左眼白
	sr(img, hx + 3, hy + 7, 3, 3, EYE_PUPIL)  # 左瞳孔
	sr(img, hx + 4, hy + 7, 1, 1, EYE_SHINE)  # 左反光

	sr(img, hx + 7, hy + 7, 3, 4, EYE_WHITE)  # 右眼白
	sr(img, hx + 7, hy + 7, 3, 3, EYE_PUPIL)  # 右瞳孔
	sr(img, hx + 8, hy + 7, 1, 1, EYE_SHINE)  # 右反光

	# 眉毛（短而直）
	sr(img, hx + 3, hy + 6, 3, 1, HAIR)
	sr(img, hx + 7, hy + 6, 3, 1, HAIR)

	# 小嘴巴
	sr(img, hx + 5, hy + 11, 2, 1, Color("d08070"))
	sr(img, hx + 5, hy + 12, 2, 1, Color("c07060"))

	# 脖子
	sr(img, hx + 3, hy + 14, 6, 1, SKIN)

# ===== 身体（冒险外套）=====
static func _draw_body(img: Image, _pose: String, lean: int) -> void:
	var bx := 16 + lean
	var by := 17

	# 外套主体
	sr(img, bx, by, 14, 10, JACKET)
	sr(img, bx + 1, by, 12, 2, JACKET_LIGHT)  # 肩部高光
	sr(img, bx + 2, by + 3, 10, 1, JACKET_LIGHT)  # 胸部高光
	sr(img, bx, by + 8, 14, 2, JACKET_DEEP)  # 底部阴影
	sr(img, bx, by, 2, 10, JACKET_DARK)  # 左侧阴影
	sr(img, bx + 12, by, 2, 10, JACKET_DARK)  # 右侧阴影

	# V领（露出白色内衬）
	sr(img, bx + 5, by, 4, 1, INNER)
	sr(img, bx + 4, by + 1, 6, 1, INNER)
	sr(img, bx + 5, by + 1, 4, 1, INNER_SHADOW)

	# 外套装饰线条
	sr(img, bx + 6, by + 2, 1, 7, JACKET_DARK)
	sr(img, bx + 8, by + 2, 1, 7, JACKET_DARK)

	# 袖子接缝
	sr(img, bx, by + 3, 2, 1, JACKET_DARK)
	sr(img, bx + 12, by + 3, 2, 1, JACKET_DARK)

# ===== 手臂 =====
static func _draw_arms(img: Image, _pose: String, l_arm: int, r_arm: int, lean: int, sword_state: int) -> void:
	var ax_l := 13 + lean
	var ax_r := 29 + lean
	var ay := 19

	# 左臂
	match l_arm:
		0:  # 下垂
			sr(img, ax_l, ay, 3, 6, JACKET)
			sr(img, ax_l, ay, 1, 6, JACKET_LIGHT)
			sr(img, ax_l, ay + 6, 3, 2, WRIST)
			sr(img, ax_l, ay + 6, 1, 1, WRIST_LIGHT)
			sr(img, ax_l, ay + 8, 3, 2, SKIN)
		1:  # 前摆
			sr(img, ax_l - 2, ay + 1, 4, 4, JACKET)
			sr(img, ax_l - 2, ay + 5, 3, 2, WRIST)
			sr(img, ax_l - 3, ay + 6, 3, 2, SKIN)
		-1:  # 后摆
			sr(img, ax_l + 2, ay + 1, 4, 4, JACKET)
			sr(img, ax_l + 4, ay + 5, 3, 2, WRIST)
			sr(img, ax_l + 5, ay + 6, 3, 2, SKIN)
		2:  # 上举
			sr(img, ax_l - 1, ay - 3, 3, 5, JACKET)
			sr(img, ax_l - 1, ay - 4, 3, 2, WRIST)
			sr(img, ax_l - 1, ay - 5, 3, 2, SKIN)

	# 右臂
	match r_arm:
		0:  # 下垂
			sr(img, ax_r, ay, 3, 6, JACKET)
			sr(img, ax_r + 2, ay, 1, 6, JACKET_DARK)
			sr(img, ax_r, ay + 6, 3, 2, WRIST)
			sr(img, ax_r, ay + 8, 3, 2, SKIN)
		1:  # 前伸（攻击）
			sr(img, ax_r, ay + 1, 5, 4, JACKET)
			sr(img, ax_r, ay + 5, 4, 2, WRIST)
			sr(img, ax_r + 3, ay + 6, 3, 2, SKIN)
			if sword_state == 2:
				_draw_sword_in_hand(img, ax_r + 5, ay + 5)
		-1:  # 后摆
			sr(img, ax_r - 2, ay + 1, 4, 4, JACKET)
			sr(img, ax_r - 3, ay + 5, 3, 2, WRIST)
			sr(img, ax_r - 4, ay + 6, 3, 2, SKIN)
		2:  # 上举
			sr(img, ax_r + 1, ay - 3, 3, 5, JACKET)
			sr(img, ax_r + 1, ay - 4, 3, 2, WRIST)
			sr(img, ax_r + 1, ay - 5, 3, 2, SKIN)
		3:  # 后拉蓄力
			sr(img, ax_r + 2, ay + 1, 4, 4, JACKET)
			sr(img, ax_r + 4, ay + 5, 3, 2, WRIST)
			sr(img, ax_r + 5, ay + 6, 3, 2, SKIN)

# ===== 腿部（短裤+靴子）=====
static func _draw_legs(img: Image, pose: String, l_leg: int, r_leg: int, lean: int) -> void:
	var lx := 18 + lean
	var ly := 27

	match pose:
		"jump":
			sr(img, lx - 1, ly, 4, 5, SHORTS)
			sr(img, lx - 1, ly, 2, 2, SHORTS_LIGHT)
			sr(img, lx + 5, ly, 4, 5, SHORTS)
			sr(img, lx + 7, ly, 2, 2, SHORTS_DARK)
			sr(img, lx - 2, ly + 5, 5, 4, BOOTS)
			sr(img, lx - 2, ly + 5, 2, 2, BOOTS_LIGHT)
			sr(img, lx - 2, ly + 8, 5, 1, BOOTS_DARK)
			sr(img, lx, ly + 6, 1, 1, BOOT_METAL)
			sr(img, lx - 1, ly + 6, 4, 1, BOOT_STRAP)
			sr(img, lx + 4, ly + 5, 5, 4, BOOTS)
			sr(img, lx + 4, ly + 5, 2, 2, BOOTS_LIGHT)
			sr(img, lx + 4, ly + 8, 5, 1, BOOTS_DARK)
			sr(img, lx + 6, ly + 6, 1, 1, BOOT_METAL)
			sr(img, lx + 5, ly + 6, 4, 1, BOOT_STRAP)
		"fall":
			sr(img, lx, ly, 3, 6, SHORTS)
			sr(img, lx, ly, 1, 3, SHORTS_LIGHT)
			sr(img, lx + 5, ly, 3, 6, SHORTS)
			sr(img, lx + 7, ly, 1, 3, SHORTS_DARK)
			sr(img, lx - 1, ly + 6, 5, 4, BOOTS)
			sr(img, lx - 1, ly + 6, 2, 2, BOOTS_LIGHT)
			sr(img, lx - 1, ly + 9, 5, 1, BOOTS_DARK)
			sr(img, lx + 1, ly + 7, 1, 1, BOOT_METAL)
			sr(img, lx + 4, ly + 6, 5, 4, BOOTS)
			sr(img, lx + 4, ly + 6, 2, 2, BOOTS_LIGHT)
			sr(img, lx + 4, ly + 9, 5, 1, BOOTS_DARK)
			sr(img, lx + 6, ly + 7, 1, 1, BOOT_METAL)
		_:
			var llx := lx + l_leg
			var rlx := lx + 4 + r_leg
			# 左腿
			sr(img, llx, ly, 4, 5, SHORTS)
			sr(img, llx, ly, 2, 2, SHORTS_LIGHT)
			sr(img, llx, ly + 5, 5, 4, BOOTS)
			sr(img, llx, ly + 5, 2, 2, BOOTS_LIGHT)
			sr(img, llx, ly + 8, 5, 1, BOOTS_DARK)
			sr(img, llx + 1, ly + 6, 1, 1, BOOT_METAL)
			sr(img, llx, ly + 6, 4, 1, BOOT_STRAP)
			# 右腿
			sr(img, rlx, ly, 4, 5, SHORTS)
			sr(img, rlx + 2, ly, 2, 2, SHORTS_DARK)
			sr(img, rlx, ly + 5, 5, 4, BOOTS)
			sr(img, rlx, ly + 5, 2, 2, BOOTS_LIGHT)
			sr(img, rlx, ly + 8, 5, 1, BOOTS_DARK)
			sr(img, rlx + 1, ly + 6, 1, 1, BOOT_METAL)
			sr(img, rlx, ly + 6, 4, 1, BOOT_STRAP)

# ===== 披风 =====
static func _draw_cape(img: Image, pose: String, sway: int) -> void:
	var cx := 17
	var cy := 18

	match pose:
		"jump", "fall":
			sr(img, cx - 2 + sway, cy, 16, 8, CAPE)
			sr(img, cx - 1 + sway, cy + 8, 14, 4, CAPE_DARK)
			sr(img, cx + sway, cy + 11, 6, 3, CAPE_LIGHT)
			sr(img, cx + 8 + sway, cy + 11, 4, 2, CAPE_LIGHT)
		_:
			sr(img, cx + sway, cy, 14, 6, CAPE)
			sr(img, cx + 1 + sway, cy + 6, 12, 4, CAPE_DARK)
			sr(img, cx + 2 + sway, cy + 9, 8, 3, CAPE)
			sr(img, cx + 3 + sway, cy + 11, 4, 2, CAPE_LIGHT)

# ===== 背上木剑 =====
static func _draw_sword_back(img: Image, _pose: String, state: int) -> void:
	if state >= 1:
		return

	sr(img, 28, 8, 2, 18, WOOD_DARK)
	sr(img, 29, 8, 1, 18, WOOD)
	sr(img, 28, 25, 3, 2, IRON)
	sr(img, 29, 25, 1, 1, IRON_SHINE)
	sr(img, 27, 5, 3, 4, HANDLE_COLOR)
	sr(img, 28, 4, 2, 2, GUARD_COLOR)
	sr(img, 28, 3, 1, 1, BUCKLE_SHINE)

# ===== 手持剑 =====
static func _draw_sword_in_hand(img: Image, x: int, y: int) -> void:
	sr(img, x, y - 2, 2, 10, IRON)
	sr(img, x, y - 2, 1, 8, IRON_SHINE)
	sr(img, x, y - 3, 2, 2, IRON)
	sr(img, x - 1, y + 7, 4, 2, GUARD_COLOR)
	sr(img, x - 1, y + 7, 1, 1, BUCKLE_SHINE)
	sr(img, x, y + 9, 2, 3, HANDLE_COLOR)

# ===== 腰带和药水 =====
static func _draw_belt_bag(img: Image, _pose: String, lean: int) -> void:
	var bx := 16 + lean
	var by := 26

	sr(img, bx, by, 14, 2, BELT)
	sr(img, bx, by, 14, 1, BELT_LIGHT)
	sr(img, bx + 5, by, 4, 2, BUCKLE)
	sr(img, bx + 6, by, 2, 1, BUCKLE_SHINE)

	sr(img, bx - 2, by, 2, 4, POTION_CAP)
	sr(img, bx - 3, by + 2, 3, 4, POTION)
	sr(img, bx - 3, by + 2, 1, 2, POTION_LIGHT)

# ===== 斩击特效 =====
static func _draw_slash(img: Image) -> void:
	sr(img, 36, 14, 8, 1, SLASH_FX)
	sr(img, 38, 13, 6, 1, SLASH_FX.lightened(0.2))
	sr(img, 40, 15, 5, 1, SLASH_FX)
	sr(img, 37, 16, 4, 1, SLASH_FX.lightened(0.2))

# ===== 工具函数 =====
static func sr(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)

static func fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	sr(img, x, y, w, h, color)
