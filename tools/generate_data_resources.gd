extends SceneTree

const WorldMaps := preload("res://scripts/world/world_maps.gd")
const EquipmentLibrary := preload("res://scripts/items/equipment_library.gd")
const EnemyLibrary := preload("res://scripts/monsters/enemy_library.gd")

const MAP_SCENES := {
	"meadow_1": "res://scenes/levels/zone_meadow_1.tscn",
	"meadow_2": "res://scenes/levels/zone_meadow_2.tscn",
	"meadow_3": "res://scenes/levels/zone_meadow_3.tscn",
	"forest_1": "res://scenes/levels/zone_forest_1.tscn",
	"forest_2": "res://scenes/levels/zone_forest_2.tscn",
	"forest_3": "res://scenes/levels/zone_forest_3.tscn",
	"forest_4": "res://scenes/levels/zone_forest_4.tscn",
	"grove_1": "res://scenes/levels/zone_grove_1.tscn",
	"grove_2": "res://scenes/levels/zone_grove_2.tscn",
	"grove_3": "res://scenes/levels/zone_grove_3.tscn",
	"canyon_1": "res://scenes/levels/zone_canyon_1.tscn",
	"canyon_2": "res://scenes/levels/zone_canyon_2.tscn",
	"canyon_3": "res://scenes/levels/zone_canyon_3.tscn",
	"canyon_4": "res://scenes/levels/zone_canyon_4.tscn",
	"ruins_1": "res://scenes/levels/zone_ruins_1.tscn",
	"ruins_2": "res://scenes/levels/zone_ruins_2.tscn",
	"ruins_3": "res://scenes/levels/zone_ruins_3.tscn",
	"ruins_4": "res://scenes/levels/zone_ruins_4.tscn",
	"gate_1": "res://scenes/levels/zone_gate_1.tscn",
	"gate_2": "res://scenes/levels/zone_gate_2.tscn",
	"gate_3": "res://scenes/levels/zone_gate_3.tscn",
}

const EQUIPMENT_IDS := [
	"grass_blade", "petal_blade", "spore_edge", "glow_hook", "gale_rock", "rune_blade", "star_edge",
	"none_armor", "moss_light", "mushroom_shell", "root_weave", "gale_plate", "rune_armor", "sky_armor",
]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/regions")
	DirAccess.make_dir_recursive_absolute("res://data/equipment")
	DirAccess.make_dir_recursive_absolute("res://data/enemies")
	DirAccess.make_dir_recursive_absolute("res://data/maps")
	var region_by_id := {}
	var map_by_id := {}
	var offset_cursor := 0.0

	for region_id in WorldMaps.REGION_ORDER:
		var source: Dictionary = WorldMaps.REGIONS[region_id]
		var region := RegionData.new()
		region.id = str(source.id)
		region.display_name = str(source.display_name)
		region.difficulty = int(source.difficulty)
		region.theme = source.theme.duplicate(true)
		region.weapon_id = str(source.weapon)
		region.armor_id = str(source.armor)
		var source_boss: Dictionary = source.boss
		var boss := BossData.new()
		boss.id = str(source_boss.id)
		boss.region_id = region.id
		boss.resource_prefix = str(source_boss.id)
		boss.display_name = str(source_boss.display_name)
		boss.body_color = Color(str(source_boss.body_color))
		for form_source in source_boss.forms:
			var form := BossFormData.new()
			form.id = str(form_source.id)
			form.display_name = str(form_source.display_name)
			form.max_health = int(form_source.max_health)
			form.contact_damage = int(form_source.contact_damage)
			form.collision = form_source.collision
			form.move_speed = float(form_source.move_speed)
			form.gravity_enabled = bool(form_source.get("gravity_enabled", true))
			form.basic_attack = str(form_source.basic_attack)
			form.skills = PackedStringArray(form_source.skills)
			boss.forms.append(form)
		boss.stage_count = boss.forms.size()
		region.boss = boss
		region_by_id[region.id] = region

	for map_id in WorldMaps.ORDER:
		var metadata: Dictionary = WorldMaps.map_metadata(map_id)
		var map := MapData.new()
		map.id = map_id
		map.display_name = str(metadata.display_name)
		map.region_id = str(metadata.region_id)
		map.width = float(WorldMaps.MAP_WIDTHS.get(map_id, 2400.0))
		map.offset_x = offset_cursor
		if MAP_SCENES.has(map_id):
			map.scene_path = MAP_SCENES[map_id]
		offset_cursor += map.width
		var region := region_by_id[map.region_id] as RegionData
		region.map_ids.append(map_id)
		region.maps.append(map)
		map_by_id[map_id] = map

	for region_id in WorldMaps.REGION_ORDER:
		var path := "res://data/regions/%s.tres" % region_id
		var error := ResourceSaver.save(region_by_id[region_id], path)
		if error != OK:
			push_error("Failed to save region %s: %d" % [region_id, error])

	var weapons := EquipmentCatalog.new()
	var armors := EquipmentCatalog.new()
	for item_id in EQUIPMENT_IDS:
		var item := EquipmentLibrary.create(item_id)
		if item.slot == "weapon":
			weapons.items.append(item)
		else:
			armors.items.append(item)
	_save_resource(weapons, "res://data/equipment/weapons.tres")
	_save_resource(armors, "res://data/equipment/armors.tres")

	var enemies := EnemyCatalog.new()
	for kind in EnemyLibrary.ids():
		enemies.items.append(EnemyLibrary.create(kind))
	_save_resource(enemies, "res://data/enemies/enemies.tres")

	for map_id in WorldMaps.ORDER:
		_save_resource(map_by_id[map_id], "res://data/maps/%s.tres" % map_id)
	quit()

func _save_resource(resource: Resource, path: String) -> void:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Failed to save %s: %d" % [path, error])
