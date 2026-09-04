class_name EnemyLibrary
extends RefCounted

const ENEMY_DATA_SCRIPT := preload("res://scripts/monsters/enemy_data.gd")

static func create(kind: String) -> EnemyData:
	var result: EnemyData = ENEMY_DATA_SCRIPT.new()
	result.kind = kind
	result.behavior = behavior(kind)
	match kind:
		"snail":
			result.display_name = "蜗牛"
			result.max_health = 42
			result.move_speed = 32.0
			result.contact_damage = 10
			result.exp_reward = 30
			result.coin_reward = 4
			result.front_guard = true
			result.detection_range = 230.0
			result.charge_speed = 275.0
			result.windup_time = 0.48
		"slime":
			result.display_name = "史莱姆"
			result.max_health = 26
			result.move_speed = 28.0
			result.contact_damage = 8
			result.exp_reward = 22
			result.coin_reward = 2
			result.can_split = true
			result.detection_range = 280.0
		"pollen_bee":
			result.display_name = "花粉蜂"
			result.max_health = 34
			result.move_speed = 110.0
			result.contact_damage = 10
			result.detection_range = 260.0
			result.charge_speed = 300.0
		"thorn_roller":
			result.display_name = "荆棘滚虫"
			result.max_health = 62
			result.move_speed = 48.0
			result.contact_damage = 16
			result.detection_range = 240.0
			result.charge_speed = 330.0
		"spore_lobber":
			result.display_name = "孢子投手"
			result.max_health = 44
			result.move_speed = 18.0
			result.contact_damage = 10
			result.detection_range = 360.0
			result.status_on_contact = "slow"
			result.status_duration = 1.2
		"spore_puppet":
			result.display_name = "孢荚傀儡"
			result.max_health = 72
			result.move_speed = 55.0
			result.contact_damage = 14
			result.detection_range = 310.0
		"root_ambusher":
			result.display_name = "悬根伏击者"
			result.max_health = 58
			result.move_speed = 90.0
			result.contact_damage = 18
			result.detection_range = 180.0
		"glow_bat":
			result.display_name = "荧光蝠"
			result.max_health = 38
			result.move_speed = 130.0
			result.contact_damage = 12
			result.detection_range = 320.0
		"wind_falcon":
			result.display_name = "风隼"
			result.max_health = 46
			result.move_speed = 170.0
			result.contact_damage = 14
			result.detection_range = 380.0
			result.charge_speed = 420.0
		"rock_thrower":
			result.display_name = "沙岩投石兵"
			result.max_health = 86
			result.move_speed = 24.0
			result.contact_damage = 18
			result.detection_range = 420.0
		"moss_guard":
			result.display_name = "苔石守卫"
			result.max_health = 110
			result.move_speed = 34.0
			result.contact_damage = 22
			result.detection_range = 280.0
			result.front_guard = true
			result.charge_speed = 330.0
		"rune_weaver":
			result.display_name = "符文织师"
			result.max_health = 66
			result.move_speed = 40.0
			result.contact_damage = 14
			result.detection_range = 430.0
		"star_wisp":
			result.display_name = "星浮灵"
			result.max_health = 54
			result.move_speed = 100.0
			result.contact_damage = 16
			result.detection_range = 440.0
		"sky_knight":
			result.display_name = "天穹骑士"
			result.max_health = 128
			result.move_speed = 82.0
			result.contact_damage = 24
			result.detection_range = 340.0
			result.charge_speed = 470.0
		_:
			result.display_name = "蘑菇"
			result.kind = "mushroom"
			result.max_health = 58
			result.move_speed = 46.0
			result.contact_damage = 15
			result.exp_reward = 26
			result.coin_reward = 3
	return result

static func ids() -> PackedStringArray:
	return PackedStringArray([
		"mushroom", "snail", "slime", "pollen_bee", "thorn_roller", "spore_lobber", "spore_puppet",
		"root_ambusher", "glow_bat", "wind_falcon", "rock_thrower", "moss_guard", "rune_weaver",
		"star_wisp", "sky_knight",
	])

static func behavior(kind: String) -> String:
	match kind:
		"pollen_bee", "glow_bat", "wind_falcon", "star_wisp": return "flyer"
		"thorn_roller", "sky_knight", "wind_falcon": return "charger"
		"spore_lobber", "rock_thrower", "rune_weaver": return "caster"
		"root_ambusher": return "ambusher"
		"moss_guard": return "guard"
		_: return "patrol"
