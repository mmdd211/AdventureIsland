const THEME_MEADOW := {
	"sky_top": "8fd7ff", "sky_bottom": "f7f0b8", "far": "7f9d8a", "near": "3d8f4e",
	"accent": "ffcf4d", "ground_grass": "67c95a", "ground_body": "93613a",
	"ground_dark": "4f2f1d", "landmark_a": "ff7ca8", "landmark_b": "fff3a6",
	"metadata": {"motif": "bright_pastoral", "music_hint": "bright_pastoral"}
}
const THEME_FOREST := {
	"sky_top": "5fb7a7", "sky_bottom": "b8e6a4", "far": "2b7854", "near": "174d39",
	"accent": "e26a5a", "ground_grass": "4fae4d", "ground_body": "6c472c",
	"ground_dark": "352113", "landmark_a": "f2d7a6", "landmark_b": "d94837",
	"metadata": {"motif": "mushroom_canopy", "music_hint": "deep_forest"}
}
const THEME_GROVE := {
	"sky_top": "17324a", "sky_bottom": "336f6b", "far": "22564e", "near": "122d2e",
	"accent": "7ff4c9", "ground_grass": "4bb489", "ground_body": "3f5657",
	"ground_dark": "182e33", "landmark_a": "9fffe0", "landmark_b": "276d63",
	"metadata": {"motif": "glowing_roots", "music_hint": "whispering_cave"}
}
const THEME_CANYON := {
	"sky_top": "f6b15f", "sky_bottom": "ffe4a8", "far": "c7764c", "near": "74432f",
	"accent": "fff0d0", "ground_grass": "d7a64b", "ground_body": "925136",
	"ground_dark": "47231b", "landmark_a": "e8574b", "landmark_b": "ffe6a1",
	"metadata": {"motif": "wind_mesas", "music_hint": "whistling_gorge"}
}
const THEME_RUINS := {
	"sky_top": "7673b6", "sky_bottom": "c1b6e9", "far": "5d6091", "near": "34375e",
	"accent": "a9d36d", "ground_grass": "7bb36d", "ground_body": "777487",
	"ground_dark": "343346", "landmark_a": "d9d2ea", "landmark_b": "7bcf70",
	"metadata": {"motif": "mossy_arches", "music_hint": "ancient_stone"}
}
const THEME_GATE := {
	"sky_top": "14256f", "sky_bottom": "8cdfff", "far": "2e55b8", "near": "17337a",
	"accent": "ffffff", "ground_grass": "68d8ff", "ground_body": "3552b8",
	"ground_dark": "111b55", "landmark_a": "fff0a6", "landmark_b": "61d6ff",
	"metadata": {"motif": "sky_stars", "music_hint": "celestial_gate"}
}

const ORDER := ["meadow", "forest", "grove", "canyon", "ruins", "gate"]

const METADATA := {
	"meadow": {"id": "meadow", "display_name": "初始草原", "offset_x": 0.0, "width": 3200.0, "theme": THEME_MEADOW},
	"forest": {"id": "forest", "display_name": "蘑菇森林", "offset_x": 3200.0, "width": 4400.0, "theme": THEME_FOREST},
	"grove": {"id": "grove", "display_name": "低语树洞", "offset_x": 7600.0, "width": 3600.0, "theme": THEME_GROVE},
	"canyon": {"id": "canyon", "display_name": "风哨峡谷", "offset_x": 11200.0, "width": 4200.0, "theme": THEME_CANYON},
	"ruins": {"id": "ruins", "display_name": "苔石遗迹", "offset_x": 15400.0, "width": 4600.0, "theme": THEME_RUINS},
	"gate": {"id": "gate", "display_name": "天穹之门", "offset_x": 20000.0, "width": 4000.0, "theme": THEME_GATE},
}

const CONNECTIONS := [
	{"from_zone": "meadow", "from_portal": "right", "to_zone": "forest", "to_portal": "left"},
	{"from_zone": "forest", "from_portal": "left", "to_zone": "meadow", "to_portal": "right"},
	{"from_zone": "forest", "from_portal": "right", "to_zone": "canyon", "to_portal": "main_left"},
	{"from_zone": "canyon", "from_portal": "main_left", "to_zone": "forest", "to_portal": "right"},
	{"from_zone": "forest", "from_portal": "branch_right", "to_zone": "grove", "to_portal": "left"},
	{"from_zone": "grove", "from_portal": "left", "to_zone": "forest", "to_portal": "branch_right"},
	{"from_zone": "grove", "from_portal": "right", "to_zone": "canyon", "to_portal": "side_left"},
	{"from_zone": "canyon", "from_portal": "side_left", "to_zone": "grove", "to_portal": "right"},
	{"from_zone": "canyon", "from_portal": "right", "to_zone": "ruins", "to_portal": "left"},
	{"from_zone": "ruins", "from_portal": "left", "to_zone": "canyon", "to_portal": "right"},
	{"from_zone": "ruins", "from_portal": "right", "to_zone": "gate", "to_portal": "left"},
	{"from_zone": "gate", "from_portal": "left", "to_zone": "ruins", "to_portal": "right"},
]

static func build(zone) -> void:
	match zone.zone_id:
		"meadow": _build_meadow(zone)
		"forest": _build_forest(zone)
		"grove": _build_grove(zone)
		"canyon": _build_canyon(zone)
		"ruins": _build_ruins(zone)
		"gate": _build_gate(zone)

static func _build_meadow(zone) -> void:
	zone._checkpoint(Vector2(160, 470))
	zone._ground(1, Vector2(450, 535), Vector2(900, 30))
	zone._static_platform(1, Vector2(270, 430), Vector2(150, 16), true)
	zone._static_platform(2, Vector2(530, 360), Vector2(130, 14), true)
	zone._static_platform(3, Vector2(790, 290), Vector2(140, 14), true)
	zone._pickup(Vector2(790, 245))
	zone._pickup(Vector2(380, 480))
	zone._pickup(Vector2(650, 480))
	zone._enemy("mushroom", Vector2(720, 480))

	zone._ground(2, Vector2(1650, 535), Vector2(1100, 30))
	zone._checkpoint(Vector2(1260, 470))
	zone._static_platform(4, Vector2(1420, 405), Vector2(140, 14), true)
	zone._static_platform(5, Vector2(1740, 345), Vector2(150, 14), true)
	zone._static_platform(6, Vector2(2050, 415), Vector2(130, 14), true)
	zone._enemy("snail", Vector2(1560, 480))
	zone._enemy("slime", Vector2(1980, 480))
	for x in [1360.0, 1540.0, 1720.0, 1900.0]:
		zone._pickup(Vector2(x, 480))
	zone._pickup(Vector2(1740, 300), "heart", 25)

	zone._moving_platform("Meadow", Vector2(2250, 430), Vector2(145, 0), 3.1)
	zone._ground(3, Vector2(2800, 535), Vector2(800, 30))
	zone._checkpoint(Vector2(2480, 470))
	zone._static_platform(7, Vector2(2620, 410), Vector2(130, 14), true)
	zone._static_platform(8, Vector2(2920, 340), Vector2(140, 14), true)
	zone._enemy("mushroom", Vector2(2880, 480))
	zone._pickup(Vector2(2920, 295))
	zone._pickup(Vector2(3080, 480))
	zone._portal("right", Vector2(3110, 468), "forest", "left")

static func _build_forest(zone) -> void:
	zone._checkpoint(Vector2(170, 470))
	zone._portal("left", Vector2(95, 468), "meadow", "right")
	zone._ground(1, Vector2(500, 535), Vector2(1000, 30))
	zone._static_platform(1, Vector2(320, 425), Vector2(140, 14), true)
	zone._static_platform(2, Vector2(650, 350), Vector2(150, 14), true)
	zone._enemy("mushroom", Vector2(720, 480))
	zone._enemy("slime", Vector2(880, 480))
	for point in [Vector2(320, 380), Vector2(650, 305), Vector2(450, 480), Vector2(820, 480)]:
		zone._pickup(point)

	zone._ground(2, Vector2(1800, 535), Vector2(1200, 30))
	zone._checkpoint(Vector2(1360, 470))
	zone._spring(Vector2(1250, 507))
	zone._static_platform(3, Vector2(1580, 390), Vector2(150, 14), true)
	zone._static_platform(4, Vector2(1930, 315), Vector2(150, 14), true)
	zone._static_platform(5, Vector2(2270, 395), Vector2(140, 14), true)
	zone._enemy("snail", Vector2(1720, 480))
	zone._enemy("slime", Vector2(2180, 480))
	for x in [1480.0, 1760.0, 2050.0, 2350.0]:
		zone._pickup(Vector2(x, 480))
	zone._pickup(Vector2(1930, 270), "heart", 20)

	zone._ground(3, Vector2(3500, 535), Vector2(1800, 30))
	zone._checkpoint(Vector2(2720, 470))
	zone._static_platform(6, Vector2(3300, 390), Vector2(140, 14), true)
	zone._static_platform(7, Vector2(3560, 310), Vector2(140, 14), true)
	zone._static_platform(8, Vector2(3830, 240), Vector2(140, 14), true)
	zone._static_platform(9, Vector2(4150, 170), Vector2(260, 14), true)
	zone._enemy("mushroom", Vector2(3060, 480))
	zone._enemy("snail", Vector2(3660, 480))
	zone._enemy("slime", Vector2(3980, 480))
	for x in [2860.0, 3040.0, 3440.0, 3740.0]:
		zone._pickup(Vector2(x, 480))
	zone._pickup(Vector2(3830, 195))
	zone._portal("branch_right", Vector2(4180, 118), "grove", "left")
	zone._portal("right", Vector2(4310, 468), "canyon", "main_left")

static func _build_grove(zone) -> void:
	zone._checkpoint(Vector2(180, 470))
	zone._portal("left", Vector2(95, 468), "forest", "branch_right")
	zone._ground(1, Vector2(500, 535), Vector2(1000, 30))
	zone._one_way_platform(1, Vector2(360, 400), Vector2(140, 12))
	zone._one_way_platform(2, Vector2(680, 320), Vector2(150, 12))
	zone._enemy("slime", Vector2(700, 480))
	for point in [Vector2(360, 355), Vector2(680, 275), Vector2(500, 480)]:
		zone._pickup(point)

	zone._ground(2, Vector2(1750, 535), Vector2(1100, 30))
	zone._checkpoint(Vector2(1360, 470))
	zone._moving_platform("Grove", Vector2(1150, 400), Vector2(120, 45), 3.5, PI * 0.5)
	zone._static_platform(3, Vector2(1620, 370), Vector2(150, 14), true)
	zone._static_platform(4, Vector2(1960, 290), Vector2(150, 14), true)
	zone._enemy("mushroom", Vector2(1820, 480))
	zone._pickup(Vector2(1960, 245), "heart", 30)
	for x in [1520.0, 1780.0, 2080.0]:
		zone._pickup(Vector2(x, 480))

	zone._ground(3, Vector2(3000, 535), Vector2(1200, 30))
	zone._checkpoint(Vector2(2480, 470))
	zone._crumbling_platform(Vector2(2380, 450))
	zone._static_platform(5, Vector2(2700, 410), Vector2(140, 14), true)
	zone._static_platform(6, Vector2(3030, 330), Vector2(150, 14), true)
	zone._static_platform(7, Vector2(3330, 410), Vector2(130, 14), true)
	zone._enemy("snail", Vector2(2820, 480))
	zone._enemy("slime", Vector2(3200, 480))
	for x in [2620.0, 2900.0, 3180.0, 3400.0]:
		zone._pickup(Vector2(x, 480))
	zone._portal("right", Vector2(3510, 468), "canyon", "side_left")

static func _build_canyon(zone) -> void:
	zone._checkpoint(Vector2(220, 470))
	zone._portal("main_left", Vector2(95, 468), "forest", "right")
	zone._static_platform(1, Vector2(230, 170), Vector2(220, 14), true)
	zone._portal("side_left", Vector2(120, 118), "grove", "right")
	zone._ground(1, Vector2(520, 535), Vector2(1040, 30))
	zone._spring(Vector2(760, 507))
	zone._enemy("slime", Vector2(600, 480))
	zone._pickup(Vector2(230, 125))

	zone._moving_platform("CanyonA", Vector2(1090, 430), Vector2(155, 0), 3.4)
	zone._moving_platform("CanyonB", Vector2(1380, 390), Vector2(165, 0), 3.8, PI * 0.5)
	zone._ground(2, Vector2(1950, 535), Vector2(1300, 30))
	zone._checkpoint(Vector2(1370, 470))
	zone._spike(Vector2(1680, 515), 180)
	zone._spike(Vector2(2130, 515), 210)
	zone._one_way_platform(2, Vector2(1680, 410), Vector2(140, 12))
	zone._one_way_platform(3, Vector2(2130, 350), Vector2(140, 12))
	zone._enemy("mushroom", Vector2(1850, 480))
	zone._enemy("snail", Vector2(2280, 480))
	zone._pickup(Vector2(1680, 365))
	zone._pickup(Vector2(2130, 305))
	for x in [1450.0, 1830.0, 2020.0, 2400.0]:
		zone._pickup(Vector2(x, 480))

	zone._crumbling_platform(Vector2(2640, 460))
	zone._ground(3, Vector2(3400, 535), Vector2(1400, 30))
	zone._checkpoint(Vector2(2780, 470))
	zone._spring(Vector2(2920, 507))
	zone._static_platform(4, Vector2(3150, 375), Vector2(150, 14), true)
	zone._static_platform(5, Vector2(3520, 295), Vector2(160, 14), true)
	zone._enemy("slime", Vector2(3060, 480))
	zone._enemy("mushroom", Vector2(3620, 480))
	for x in [2980.0, 3260.0, 3620.0, 3880.0]:
		zone._pickup(Vector2(x, 480))
	zone._pickup(Vector2(3520, 250), "heart", 25)
	zone._portal("right", Vector2(4110, 468), "ruins", "left")

static func _build_ruins(zone) -> void:
	zone._checkpoint(Vector2(170, 470))
	zone._portal("left", Vector2(95, 468), "canyon", "right")
	zone._ground(1, Vector2(500, 535), Vector2(1000, 30))
	zone._spike(Vector2(700, 515), 190)
	zone._one_way_platform(1, Vector2(700, 410), Vector2(150, 12))
	zone._enemy("mushroom", Vector2(480, 480))
	zone._pickup(Vector2(700, 365))

	zone._ground(2, Vector2(1800, 535), Vector2(1400, 30))
	zone._checkpoint(Vector2(1160, 470))
	zone._moving_platform("RuinsA", Vector2(2540, 430), Vector2(150, 0), 3.2)
	zone._crumbling_platform(Vector2(2320, 450))
	zone._static_platform(2, Vector2(1530, 400), Vector2(140, 14), true)
	zone._static_platform(3, Vector2(1880, 320), Vector2(160, 14), true)
	zone._enemy("snail", Vector2(1660, 480))
	zone._enemy("slime", Vector2(2120, 480))
	for x in [1280.0, 1620.0, 1980.0, 2240.0]:
		zone._pickup(Vector2(x, 480))
	zone._pickup(Vector2(1880, 275), "heart", 20)

	zone._ground(3, Vector2(3300, 535), Vector2(1500, 30))
	zone._checkpoint(Vector2(2660, 470))
	zone._spring(Vector2(2780, 507))
	zone._spike(Vector2(3060, 515), 220)
	zone._one_way_platform(4, Vector2(3060, 390), Vector2(150, 12))
	zone._static_platform(5, Vector2(3380, 310), Vector2(150, 14), true)
	zone._static_platform(6, Vector2(3720, 400), Vector2(140, 14), true)
	zone._enemy("mushroom", Vector2(3180, 480))
	zone._enemy("slime", Vector2(3560, 480))
	for x in [2800.0, 3180.0, 3500.0, 3800.0]:
		zone._pickup(Vector2(x, 480))

	zone._ground(4, Vector2(4310, 535), Vector2(800, 30))
	zone._checkpoint(Vector2(3980, 470))
	zone._enemy("snail", Vector2(4180, 480))
	zone._pickup(Vector2(4320, 480))
	zone._portal("right", Vector2(4510, 468), "gate", "left")

static func _build_gate(zone) -> void:
	zone._checkpoint(Vector2(170, 470))
	zone._portal("left", Vector2(95, 468), "ruins", "right")
	zone._ground(1, Vector2(500, 535), Vector2(1000, 30))
	zone._spike(Vector2(680, 515), 200)
	zone._one_way_platform(1, Vector2(680, 400), Vector2(150, 12))
	zone._enemy("slime", Vector2(480, 480))
	zone._pickup(Vector2(680, 355))

	zone._ground(2, Vector2(1800, 535), Vector2(1400, 30))
	zone._checkpoint(Vector2(1160, 470))
	zone._moving_platform("GateA", Vector2(1080, 410), Vector2(140, 35), 3.0, PI * 0.5)
	zone._crumbling_platform(Vector2(1340, 450))
	zone._spike(Vector2(1720, 515), 220)
	zone._one_way_platform(2, Vector2(1720, 390), Vector2(150, 12))
	zone._enemy("mushroom", Vector2(1520, 480))
	zone._enemy("snail", Vector2(2040, 480))
	for x in [1240.0, 1560.0, 1880.0, 2180.0]:
		zone._pickup(Vector2(x, 480))
	zone._pickup(Vector2(1560, 320), "heart", 30)

	zone._ground(3, Vector2(3100, 535), Vector2(1800, 30))
	zone._checkpoint(Vector2(2480, 470))
	zone._spring(Vector2(2560, 507))
	zone._static_platform(3, Vector2(2800, 400), Vector2(150, 14), true)
	zone._static_platform(4, Vector2(3150, 315), Vector2(160, 14), true)
	zone._static_platform(5, Vector2(3500, 405), Vector2(150, 14), true)
	zone._enemy("slime", Vector2(2880, 480))
	zone._enemy("snail", Vector2(3280, 480))
	zone._enemy("mushroom", Vector2(3620, 480))
	for x in [2680.0, 3000.0, 3320.0, 3680.0]:
		zone._pickup(Vector2(x, 480))
	zone._portal("goal", Vector2(3910, 468), "", "", true)
