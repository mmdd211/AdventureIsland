extends Node

signal language_changed(language: String)

const STRINGS := {
	"zh": {
		"app_title": "冒险岛物语",
		"app_subtitle": "横版冒险 · 六区域主题世界",
		"start": "开始冒险",
		"continue": "继续冒险",
		"quit": "离开",
		"settings": "设置",
		"close": "关闭",
		"controls_title": "按键设置",
		"music_volume": "音乐音量",
		"sfx_volume": "音效音量",
		"fullscreen": "全屏",
		"screen_shake": "画面震动",
		"hit_stop": "击中停顿",
		"reset": "还原",
		"press_key": "按新按键...",
		"not_set": "未设置",
		"action_move_left": "向左",
		"action_move_right": "向右",
		"action_jump": "跳跃",
		"action_attack": "攻击",
		"action_dash": "冲刺",
		"action_pause": "暂停",
		"action_debug_toggle": "调试",
		"action_toggle_map": "地图",
		"controls_hint": "A/D 移动   W/空格 跳跃   J 攻击   K/Shift 冲刺",
		"loading_preparing": "正在准备冒险…",
		"loading_music": "正在谱写冒险曲…",
		"loading_build": "正在搭建「%s」…",
		"loading_wake": "正在唤醒世界…",
		"loading_pixel": "正在描绘像素画…",
		"loading_go": "出发！",
		"tip_prefix": "提示：",
		"tip_slime": "大史莱姆被击败后会分裂成两只小史莱姆，别被它们包夹。",
		"tip_snail": "踩中蜗牛背部能造成双倍伤害，正面攻击只会击退它。",
		"tip_map": "按 Tab 打开世界地图，随时查看六大区域与当前位置。",
		"tip_checkpoint": "触碰检查点即可保存进度，失足坠落也会在附近复活。",
		"tip_dash": "冲刺过程中处于无敌状态，用它穿越缺口或躲开敌人。",
		"tip_coin": "收集金币能提高通关评价，绕点远路也值得。",
		"loading_title": "冒险岛物语",
		"pause": "暂停",
		"resume": "继续冒险",
		"restart": "重新开始",
		"equipment": "装备",
		"back_title": "返回标题",
		"death_title": "冒险失败",
		"respawn": "从检查点继续",
		"restart_level": "重新开始关卡",
		"complete_title": "世界通关！",
		"play_again": "再玩一次",
		"back": "返回",
		"reward_title": "战利品选择",
		"weapon": "武器",
		"armor": "防具",
		"equip_weapon": "装备武器",
		"equip_armor": "装备防具",
		"keep": "保留",
		"equipped": "已装备",
		"equip": "装备",
		"kept": "已保留",
		"state_equipped": "已装备",
		"state_owned": "可装备",
		"state_locked": "未获得",
		"complete_stats": "用时 %s\n金币 %d/%d（%d%%）\n击杀 %d\n死亡 %d\n评分 %s",
		"reward_continue": "继续冒险",
		"world_map_title": "冒险岛世界地图",
		"close_map": "关闭地图",
		"language": "语言",
		"evolution": "进化",
	},
	"en": {
		"app_title": "Adventure Isle Tale",
		"app_subtitle": "Side-scrolling adventure · Six regions",
		"start": "Start Adventure",
		"continue": "Continue",
		"quit": "Quit",
		"settings": "Settings",
		"close": "Close",
		"controls_title": "Controls",
		"music_volume": "Music Volume",
		"sfx_volume": "SFX Volume",
		"fullscreen": "Fullscreen",
		"screen_shake": "Screen Shake",
		"hit_stop": "Hit Stop",
		"reset": "Reset",
		"press_key": "Press a key...",
		"not_set": "Not set",
		"action_move_left": "Left",
		"action_move_right": "Right",
		"action_jump": "Jump",
		"action_attack": "Attack",
		"action_dash": "Dash",
		"action_pause": "Pause",
		"action_debug_toggle": "Debug",
		"action_toggle_map": "Map",
		"controls_hint": "A/D Move   W/Space Jump   J Attack   K/Shift Dash",
		"loading_preparing": "Preparing adventure...",
		"loading_music": "Composing adventure music...",
		"loading_build": "Building %s...",
		"loading_wake": "Waking the world...",
		"loading_pixel": "Painting pixel art...",
		"loading_go": "Go!",
		"tip_prefix": "Tip: ",
		"tip_slime": "Large slimes split into two smaller slimes when defeated.",
		"tip_snail": "Snails take double damage from behind; frontal attacks only knock them back.",
		"tip_map": "Press Tab to open the world map and track all six regions.",
		"tip_checkpoint": "Touch checkpoints to save progress; falls respawn nearby.",
		"tip_dash": "Dashing grants brief invulnerability; use it to cross gaps.",
		"tip_coin": "Collect coins to improve your clear rating.",
		"loading_title": "Adventure Isle Tale",
		"pause": "Paused",
		"resume": "Continue",
		"restart": "Restart",
		"equipment": "Equipment",
		"back_title": "Title",
		"death_title": "Adventure Failed",
		"respawn": "Continue Checkpoint",
		"restart_level": "Restart Level",
		"complete_title": "World Cleared!",
		"play_again": "Play Again",
		"back": "Back",
		"reward_title": "Choose Spoils",
		"weapon": "Weapon",
		"armor": "Armor",
		"equip_weapon": "Equip Weapon",
		"equip_armor": "Equip Armor",
		"keep": "Keep",
		"equipped": "Equipped",
		"equip": "Equip",
		"kept": "Kept",
		"state_equipped": "Equipped",
		"state_owned": "Owned",
		"state_locked": "Locked",
		"complete_stats": "Time %s\nCoins %d/%d (%d%%)\nKills %d\nDeaths %d\nRating %s",
		"reward_continue": "Continue",
		"world_map_title": "Adventure Isle Map",
		"close_map": "Close Map",
		"language": "Language",
		"evolution": "Evolve",
	},
}

@export var language := "zh"

func _ready() -> void:
	load_language()

func supported_languages() -> PackedStringArray:
	return PackedStringArray(STRINGS.keys())

func tr_key(key: String) -> String:
	var table: Dictionary = STRINGS.get(language, STRINGS.zh)
	return str(table.get(key, STRINGS.zh.get(key, key)))

func action_label(action: String) -> String:
	return tr_key("action_%s" % action)

func set_language(value: String) -> void:
	var next := value if supported_languages().has(value) else "zh"
	if next == language:
		return
	language = next
	save_language()
	language_changed.emit(language)

func save_language() -> void:
	var settings := FileAccess.open("user://adventure_island_language.json", FileAccess.WRITE)
	if settings == null:
		return
	settings.store_string(JSON.stringify({"version": 1, "language": language}, "\t"))
	settings.close()

func load_language() -> void:
	var path := "user://adventure_island_language.json"
	if not FileAccess.file_exists(path):
		return
	var settings := FileAccess.open(path, FileAccess.READ)
	if settings == null:
		return
	var parsed = JSON.parse_string(settings.get_as_text())
	settings.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		language = str(parsed.get("language", language))
