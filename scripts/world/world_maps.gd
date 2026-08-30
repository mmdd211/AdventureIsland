extends RefCounted

const BossDataScript := preload("res://scripts/items/boss_data.gd")

const REGION_ORDER := ["meadow", "forest", "grove", "canyon", "ruins", "gate"]

const THEME_MEADOW := {
	"sky_top": "8fd7ff", "sky_bottom": "f7f0b8", "far": "7f9d8a", "near": "3d8f4e",
	"accent": "ffcf4d", "ground_grass": "67c95a", "ground_body": "93613a",
	"ground_dark": "4f2f1d", "landmark_a": "ff7ca8", "landmark_b": "fff3a6",
	"metadata": {"motif": "bright_pastoral"}
}
const THEME_FOREST := {
	"sky_top": "5fb7a7", "sky_bottom": "b8e6a4", "far": "2b7854", "near": "174d39",
	"accent": "e26a5a", "ground_grass": "4fae4d", "ground_body": "6c472c",
	"ground_dark": "352113", "landmark_a": "f2d7a6", "landmark_b": "d94837",
	"metadata": {"motif": "mushroom_canopy"}
}
const THEME_GROVE := {
	"sky_top": "17324a", "sky_bottom": "336f6b", "far": "22564e", "near": "122d2e",
	"accent": "7ff4c9", "ground_grass": "4bb489", "ground_body": "3f5657",
	"ground_dark": "182e33", "landmark_a": "9fffe0", "landmark_b": "276d63",
	"metadata": {"motif": "glowing_roots"}
}
const THEME_CANYON := {
	"sky_top": "f6b15f", "sky_bottom": "ffe4a8", "far": "c7764c", "near": "74432f",
	"accent": "fff0d0", "ground_grass": "d7a64b", "ground_body": "925136",
	"ground_dark": "47231b", "landmark_a": "e8574b", "landmark_b": "ffe6a1",
	"metadata": {"motif": "wind_mesas"}
}
const THEME_RUINS := {
	"sky_top": "7673b6", "sky_bottom": "c1b6e9", "far": "5d6091", "near": "34375e",
	"accent": "a9d36d", "ground_grass": "7bb36d", "ground_body": "777487",
	"ground_dark": "343346", "landmark_a": "d9d2ea", "landmark_b": "7bcf70",
	"metadata": {"motif": "mossy_arches"}
}
const THEME_GATE := {
	"sky_top": "14256f", "sky_bottom": "8cdfff", "far": "2e55b8", "near": "17337a",
	"accent": "ffffff", "ground_grass": "68d8ff", "ground_body": "3552b8",
	"ground_dark": "111b55", "landmark_a": "fff0a6", "landmark_b": "61d6ff",
	"metadata": {"motif": "sky_stars"}
}

const REGIONS := {
	"meadow": {
		"id": "meadow", "display_name": "初始草原", "difficulty": 1,
		"map_count": 3, "theme": THEME_MEADOW,
		"weapon": "petal_blade", "armor": "moss_light",
		"boss": {"id": "pollen_queen", "display_name": "花粉女王", "max_health": 380, "contact_damage": 14, "stage_count": 2, "body_color": "ffcf4d", "basic_attack": "charge", "skills": ["pollen_swarm", "royal_charge"]}
	},
	"forest": {
		"id": "forest", "display_name": "蘑菇森林", "difficulty": 2,
		"map_count": 4, "theme": THEME_FOREST,
		"weapon": "spore_edge", "armor": "mushroom_shell",
		"boss": {"id": "mushroom_guardian", "display_name": "巨菇守卫", "max_health": 520, "contact_damage": 18, "stage_count": 2, "body_color": "e26a5a", "basic_attack": "projectile", "skills": ["spore_burst", "guard_charge"]}
	},
	"grove": {
		"id": "grove", "display_name": "低语树洞", "difficulty": 3,
		"map_count": 3, "theme": THEME_GROVE,
		"weapon": "glow_hook", "armor": "root_weave",
		"boss": {"id": "whisper_root", "display_name": "低语根王", "max_health": 720, "contact_damage": 22, "stage_count": 3, "body_color": "7ff4c9", "basic_attack": "ambush", "skills": ["root_prison", "spore_wave"]}
	},
	"canyon": {
		"id": "canyon", "display_name": "风哨峡谷", "difficulty": 4,
		"map_count": 4, "theme": THEME_CANYON,
		"weapon": "gale_rock", "armor": "gale_plate",
		"boss": {"id": "canyon_rock_eagle", "display_name": "峡谷岩鹰", "max_health": 980, "contact_damage": 26, "stage_count": 3, "body_color": "d7a64b", "basic_attack": "charge", "skills": ["rock_rain", "gale_dive"]}
	},
	"ruins": {
		"id": "ruins", "display_name": "苔石遗迹", "difficulty": 5,
		"map_count": 4, "theme": THEME_RUINS,
		"weapon": "rune_blade", "armor": "rune_armor",
		"boss": {"id": "rune_colossus", "display_name": "符文石像", "max_health": 1300, "contact_damage": 30, "stage_count": 3, "body_color": "7673b6", "basic_attack": "projectile", "skills": ["rune_ring", "blink_volley"]}
	},
	"gate": {
		"id": "gate", "display_name": "天穹之门", "difficulty": 6,
		"map_count": 3, "theme": THEME_GATE,
		"weapon": "star_edge", "armor": "sky_armor",
		"boss": {"id": "sky_gatekeeper", "display_name": "天穹守门人", "max_health": 1800, "contact_damage": 34, "stage_count": 3, "body_color": "68d8ff", "basic_attack": "charge", "skills": ["star_gate", "void_rain"]}
	}
}

const MAP_WIDTHS := {
	"meadow_1": 2400.0, "meadow_2": 2600.0, "meadow_3": 2100.0,
	"forest_1": 2500.0, "forest_2": 2700.0, "forest_3": 2600.0, "forest_4": 2100.0,
	"grove_1": 2500.0, "grove_2": 2700.0, "grove_3": 2100.0,
	"canyon_1": 2500.0, "canyon_2": 2700.0, "canyon_3": 2600.0, "canyon_4": 2100.0,
	"ruins_1": 2500.0, "ruins_2": 2700.0, "ruins_3": 2600.0, "ruins_4": 2100.0,
	"gate_1": 2500.0, "gate_2": 2700.0, "gate_3": 2000.0
}

const ORDER := [
	"meadow_1", "meadow_2", "meadow_3",
	"forest_1", "forest_2", "forest_3", "forest_4",
	"grove_1", "grove_2", "grove_3",
	"canyon_1", "canyon_2", "canyon_3", "canyon_4",
	"ruins_1", "ruins_2", "ruins_3", "ruins_4",
	"gate_1", "gate_2", "gate_3"
]

const MAP_NAMES := {
	"meadow_1": "迎风草原", "meadow_2": "花海沟壑", "meadow_3": "草原之心",
	"forest_1": "蘑菇前林", "forest_2": "菌帽栈道", "forest_3": "孢子湿地", "forest_4": "巨菇祭坛",
	"grove_1": "根须入口", "grove_2": "悬根回廊", "grove_3": "低语之心",
	"canyon_1": "风口裂谷", "canyon_2": "峡壁栈道", "canyon_3": "流沙石道", "canyon_4": "哨塔之巅",
	"ruins_1": "苔石前庭", "ruins_2": "水钟遗迹", "ruins_3": "回音长廊", "ruins_4": "星辉圣坛",
	"gate_1": "门阶浮岛", "gate_2": "群星回桥", "gate_3": "天穹之门"
}

const CONNECTIONS := [
	{"from": "meadow_1", "to": "meadow_2"}, {"from": "meadow_2", "to": "meadow_3"},
	{"from": "meadow_3", "to": "forest_1"}, {"from": "forest_1", "to": "forest_2"},
	{"from": "forest_2", "to": "forest_3"}, {"from": "forest_3", "to": "forest_4"},
	{"from": "forest_4", "to": "grove_1"}, {"from": "grove_1", "to": "grove_2"},
	{"from": "grove_2", "to": "grove_3"}, {"from": "grove_3", "to": "canyon_1"},
	{"from": "canyon_1", "to": "canyon_2"}, {"from": "canyon_2", "to": "canyon_3"},
	{"from": "canyon_3", "to": "canyon_4"}, {"from": "canyon_4", "to": "ruins_1"},
	{"from": "ruins_1", "to": "ruins_2"}, {"from": "ruins_2", "to": "ruins_3"},
	{"from": "ruins_3", "to": "ruins_4"}, {"from": "ruins_4", "to": "gate_1"},
	{"from": "gate_1", "to": "gate_2"}, {"from": "gate_2", "to": "gate_3"}
]

static var _offsets := {}

static func map_metadata(map_id: String) -> Dictionary:
	var region_id := region_id_for(map_id)
	var region: Dictionary = REGIONS[region_id]
	var width := float(MAP_WIDTHS.get(map_id, 2400.0))
	return {
		"id": map_id,
		"region_id": region_id,
		"region_name": str(region.display_name),
		"display_name": str(MAP_NAMES.get(map_id, map_id)),
		"theme": region.theme,
		"width": width,
		"offset_x": float(_offsets.get(map_id, 0.0)),
		"map_index": ORDER.find(map_id) + 1,
		"region_index": REGION_ORDER.find(region_id) + 1,
		"is_boss": map_id.ends_with("_3") or map_id.ends_with("_4"),
		"difficulty": int(region.difficulty)
	}

static func region_id_for(map_id: String) -> String:
	return map_id.rsplit("_", true, 1)[0]

static func region(region_id: String) -> Dictionary:
	return REGIONS.get(region_id, {})

static func initialize_offsets() -> void:
	_offsets.clear()
	var cursor := 0.0
	for map_id in ORDER:
		_offsets[map_id] = cursor
		cursor += float(MAP_WIDTHS.get(map_id, 2400.0))

static func next_map(map_id: String) -> String:
	var index := ORDER.find(map_id)
	if index < 0 or index >= ORDER.size() - 1:
		return ""
	return str(ORDER[index + 1])

static func previous_map(map_id: String) -> String:
	var index := ORDER.find(map_id)
	if index <= 0:
		return ""
	return str(ORDER[index - 1])

static func ui_position(map_id: String) -> Vector2:
	var index := ORDER.find(map_id)
	var column := index % 7
	var row := int(index / 7.0)
	return Vector2(18.0 + column * 126.0, 22.0 + row * 148.0)

static func build(zone) -> void:
	var map_id := str(zone.zone_id)
	match map_id:
		"meadow_1": _build_meadow_1(zone)
		"meadow_2": _build_meadow_2(zone)
		"meadow_3": _build_meadow_3(zone)
		"forest_1": _build_forest_1(zone)
		"forest_2": _build_forest_2(zone)
		"forest_3": _build_forest_3(zone)
		"forest_4": _build_forest_4(zone)
		"grove_1": _build_grove_1(zone)
		"grove_2": _build_grove_2(zone)
		"grove_3": _build_grove_3(zone)
		"canyon_1": _build_canyon_1(zone)
		"canyon_2": _build_canyon_2(zone)
		"canyon_3": _build_canyon_3(zone)
		"canyon_4": _build_canyon_4(zone)
		"ruins_1": _build_ruins_1(zone)
		"ruins_2": _build_ruins_2(zone)
		"ruins_3": _build_ruins_3(zone)
		"ruins_4": _build_ruins_4(zone)
		"gate_1": _build_gate_1(zone)
		"gate_2": _build_gate_2(zone)
		"gate_3": _build_gate_3(zone)

static func _base(zone, enemies: Array, coins: Array, platforms: Array) -> void:
	zone._checkpoint(Vector2(160, 470))
	zone._ground(1, Vector2(620, 535), Vector2(1240, 30))
	var width: float = zone.zone_width
	zone._ground(2, Vector2((width + 1000.0) * 0.5, 535), Vector2(width - 1200.0, 30))
	for platform in platforms:
		zone._static_platform(int(platform[0]), Vector2(float(platform[1]), float(platform[2])), Vector2(float(platform[3]), 14), bool(platform[4]))
	for position_value in coins:
		zone._pickup(Vector2(float(position_value[0]), float(position_value[1])))
	for entry in enemies:
		var enemy_position: Vector2 = entry[1]
		zone._enemy(str(entry[0]), enemy_position)

static func _boss_arena(zone, enemy_kinds: Array) -> void:
	zone._checkpoint(Vector2(180, 470))
	var width: float = zone.zone_width
	zone._ground(1, Vector2(width * 0.5 + 20.0, 535), Vector2(width - 40.0, 30))
	_platform_line(zone, Vector2(620, 360), 3, 260.0)
	for x in [720.0, 1000.0, 1280.0]:
		zone._pickup(Vector2(x, 480))
	for kind in enemy_kinds:
		zone._enemy(str(kind), Vector2(zone.zone_width - 320.0, 480))
	zone._boss()

static func _platform_line(zone, start: Vector2, count: int, spacing: float) -> void:
	for index in range(count):
		zone._static_platform(index + 1, start + Vector2(spacing * index, 0.0), Vector2(140, 14), true)

static func _build_meadow_1(zone) -> void:
	_base(zone, [
		["mushroom", Vector2(760, 480)], ["pollen_bee", Vector2(1180, 360)]
	], [[420, 480], [760, 300], [1180, 300], [1540, 480]], [
		[1, 420, 420, 140, true], [2, 760, 350, 150, true], [3, 1180, 350, 150, true]
	])
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_meadow_2(zone) -> void:
	_base(zone, [
		["thorn_roller", Vector2(700, 480)], ["mushroom", Vector2(1320, 480)], ["pollen_bee", Vector2(1700, 340)]
	], [[520, 480], [900, 340], [1320, 280], [1700, 280], [2050, 480]], [
		[1, 520, 420, 140, true], [2, 900, 390, 150, true], [3, 1320, 330, 160, true], [4, 1700, 330, 150, true]
	])
	zone._moving_platform("Meadow", Vector2(1960, 430), Vector2(150, 0), 3.1)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_meadow_3(zone) -> void:
	_boss_arena(zone, ["pollen_bee"])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left", false, "meadow")

static func _build_forest_1(zone) -> void:
	_base(zone, [
		["spore_lobber", Vector2(800, 470)], ["mushroom", Vector2(1260, 480)], ["spore_puppet", Vector2(1680, 480)]
	], [[500, 480], [800, 360], [1260, 310], [1680, 340], [2050, 480]], [
		[1, 500, 410, 140, true], [2, 800, 410, 150, true], [3, 1260, 360, 150, true], [4, 1680, 390, 150, true]
	])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_forest_2(zone) -> void:
	_base(zone, [
		["spore_lobber", Vector2(660, 470)], ["spore_puppet", Vector2(1120, 480)], ["slime", Vector2(1560, 480)], ["mushroom", Vector2(1960, 480)]
	], [[480, 480], [660, 350], [1120, 300], [1560, 330], [1960, 330]], [
		[1, 480, 410, 140, true], [2, 660, 400, 150, true], [3, 1120, 350, 160, true], [4, 1560, 380, 150, true], [5, 1960, 380, 150, true]
	])
	zone._spring(Vector2(880, 507))
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_forest_3(zone) -> void:
	_base(zone, [
		["spore_puppet", Vector2(700, 480)], ["spore_lobber", Vector2(1080, 470)], ["snail", Vector2(1440, 480)], ["spore_puppet", Vector2(1820, 480)]
	], [[520, 480], [700, 340], [1080, 300], [1440, 330], [1820, 330], [2100, 480]], [
		[1, 520, 400, 140, true], [2, 700, 390, 150, true], [3, 1080, 350, 150, true], [4, 1440, 380, 150, true], [5, 1820, 380, 150, true]
	])
	zone._moving_platform("Forest", Vector2(1580, 430), Vector2(150, 40), 3.4)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_forest_4(zone) -> void:
	_boss_arena(zone, ["spore_puppet"])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left", false, "forest")

static func _build_grove_1(zone) -> void:
	_base(zone, [
		["root_ambusher", Vector2(760, 505)], ["glow_bat", Vector2(1140, 320)], ["slime", Vector2(1560, 480)]
	], [[480, 480], [760, 370], [1140, 270], [1560, 300]], [
		[1, 480, 420, 140, true], [2, 760, 420, 150, true], [3, 1140, 320, 150, true], [4, 1560, 350, 150, true]
	])
	zone._darkness(zone, 0.30)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_grove_2(zone) -> void:
	_base(zone, [
		["root_ambusher", Vector2(620, 505)], ["glow_bat", Vector2(980, 320)], ["root_ambusher", Vector2(1380, 505)], ["glow_bat", Vector2(1740, 300)]
	], [[500, 480], [620, 370], [980, 280], [1380, 340], [1740, 260]], [
		[1, 500, 410, 140, true], [2, 620, 420, 150, true], [3, 980, 330, 150, true], [4, 1380, 390, 150, true], [5, 1740, 310, 150, true]
	])
	zone._moving_platform("Grove", Vector2(1180, 420), Vector2(130, 55), 3.3)
	zone._darkness(zone, 0.36)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_grove_3(zone) -> void:
	_boss_arena(zone, ["glow_bat", "root_ambusher"])
	zone._darkness(zone, 0.42)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left", false, "grove")

static func _build_canyon_1(zone) -> void:
	_base(zone, [
		["wind_falcon", Vector2(780, 320)], ["mushroom", Vector2(1160, 480)], ["rock_thrower", Vector2(1580, 470)]
	], [[480, 480], [780, 280], [1160, 330], [1580, 350]], [
		[1, 480, 420, 140, true], [2, 780, 330, 150, true], [3, 1160, 380, 150, true], [4, 1580, 400, 150, true]
	])
	zone._spike(Vector2(1920, 515), 180)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_canyon_2(zone) -> void:
	_base(zone, [
		["wind_falcon", Vector2(680, 300)], ["rock_thrower", Vector2(1080, 470)], ["wind_falcon", Vector2(1520, 290)], ["mushroom", Vector2(1940, 480)]
	], [[500, 480], [680, 260], [1080, 320], [1520, 250], [1940, 320]], [
		[1, 500, 410, 140, true], [2, 680, 310, 150, true], [3, 1080, 370, 150, true], [4, 1520, 300, 150, true], [5, 1940, 370, 150, true]
	])
	zone._moving_platform("CanyonA", Vector2(1280, 420), Vector2(170, 0), 3.2)
	zone._spike(Vector2(1800, 515), 180)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_canyon_3(zone) -> void:
	_base(zone, [
		["rock_thrower", Vector2(660, 470)], ["wind_falcon", Vector2(1060, 290)], ["rock_thrower", Vector2(1480, 470)], ["wind_falcon", Vector2(1860, 280)]
	], [[520, 480], [660, 350], [1060, 250], [1480, 330], [1860, 250]], [
		[1, 520, 410, 140, true], [2, 660, 400, 150, true], [3, 1060, 300, 150, true], [4, 1480, 380, 150, true], [5, 1860, 300, 150, true]
	])
	zone._crumbling_platform(Vector2(1280, 450))
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_canyon_4(zone) -> void:
	_boss_arena(zone, ["wind_falcon"])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left", false, "canyon")

static func _build_ruins_1(zone) -> void:
	_base(zone, [
		["moss_guard", Vector2(720, 480)], ["rune_weaver", Vector2(1180, 470)], ["slime", Vector2(1600, 480)]
	], [[500, 480], [720, 360], [1180, 300], [1600, 330]], [
		[1, 500, 410, 140, true], [2, 720, 410, 150, true], [3, 1180, 350, 150, true], [4, 1600, 380, 150, true]
	])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_ruins_2(zone) -> void:
	_base(zone, [
		["moss_guard", Vector2(640, 480)], ["rune_weaver", Vector2(1040, 470)], ["moss_guard", Vector2(1460, 480)], ["rune_weaver", Vector2(1860, 470)]
	], [[500, 480], [640, 360], [1040, 300], [1460, 340], [1860, 300]], [
		[1, 500, 410, 140, true], [2, 640, 410, 150, true], [3, 1040, 350, 150, true], [4, 1460, 390, 150, true], [5, 1860, 350, 150, true]
	])
	zone._moving_platform("RuinsA", Vector2(1240, 430), Vector2(160, 0), 3.1)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_ruins_3(zone) -> void:
	_base(zone, [
		["rune_weaver", Vector2(660, 470)], ["moss_guard", Vector2(1080, 480)], ["rune_weaver", Vector2(1500, 470)], ["moss_guard", Vector2(1880, 480)]
	], [[520, 480], [660, 350], [1080, 300], [1500, 330], [1880, 300]], [
		[1, 520, 410, 140, true], [2, 660, 400, 150, true], [3, 1080, 350, 150, true], [4, 1500, 380, 150, true], [5, 1880, 350, 150, true]
	])
	zone._spike(Vector2(1300, 515), 180)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_ruins_4(zone) -> void:
	_boss_arena(zone, ["rune_weaver"])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left", false, "ruins")

static func _build_gate_1(zone) -> void:
	_base(zone, [
		["star_wisp", Vector2(760, 300)], ["slime", Vector2(1160, 480)], ["star_wisp", Vector2(1580, 280)]
	], [[500, 480], [760, 260], [1160, 330], [1580, 250]], [
		[1, 500, 410, 140, true], [2, 760, 310, 150, true], [3, 1160, 380, 150, true], [4, 1580, 300, 150, true]
	])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_gate_2(zone) -> void:
	_base(zone, [
		["star_wisp", Vector2(660, 290)], ["sky_knight", Vector2(1080, 480)], ["star_wisp", Vector2(1500, 280)], ["sky_knight", Vector2(1880, 480)]
	], [[500, 480], [660, 250], [1080, 320], [1500, 250], [1880, 320]], [
		[1, 500, 410, 140, true], [2, 660, 300, 150, true], [3, 1080, 370, 150, true], [4, 1500, 300, 150, true], [5, 1880, 370, 150, true]
	])
	zone._moving_platform("GateA", Vector2(1280, 420), Vector2(150, 45), 3.0)
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
	zone._portal("right", Vector2(zone.zone_width - 110, 468), next_map(str(zone.zone_id)), "left")

static func _build_gate_3(zone) -> void:
	_boss_arena(zone, ["star_wisp", "sky_knight"])
	zone._portal("left", Vector2(95, 468), previous_map(str(zone.zone_id)), "right")
