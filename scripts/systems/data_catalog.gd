extends Node

const REGION_RESOURCE_PATHS := [
	"res://data/regions/meadow.tres",
	"res://data/regions/forest.tres",
	"res://data/regions/grove.tres",
	"res://data/regions/canyon.tres",
	"res://data/regions/ruins.tres",
	"res://data/regions/gate.tres",
]
const EQUIPMENT_RESOURCE_PATHS := [
	"res://data/equipment/weapons.tres",
	"res://data/equipment/armors.tres",
]
const ENEMY_RESOURCE_PATHS := [
	"res://data/enemies/enemies.tres",
]

var _regions := {}
var _equipment := {}
var _enemies := {}
var _maps := {}
var _map_order := []

func _ready() -> void:
	_load_regions()
	_load_equipment()
	_load_enemies()

func _load_regions() -> void:
	_regions.clear()
	_maps.clear()
	for path in REGION_RESOURCE_PATHS:
		var resource := load(path) as RegionData
		if resource == null:
			push_error("DataCatalog: cannot load region resource %s" % path)
			continue
		_regions[resource.id] = resource
		for map_id in resource.map_ids:
			var map := resource.map(map_id)
			if map != null:
				_maps[map_id] = map
				_map_order.append(map_id)

func _load_equipment() -> void:
	_equipment.clear()
	for path in EQUIPMENT_RESOURCE_PATHS:
		var catalog := load(path) as EquipmentCatalog
		if catalog == null:
			push_error("DataCatalog: cannot load equipment catalog %s" % path)
			continue
		for item in catalog.items:
			_equipment[item.id] = item

func _load_enemies() -> void:
	_enemies.clear()
	for path in ENEMY_RESOURCE_PATHS:
		var catalog := load(path) as EnemyCatalog
		if catalog == null:
			push_error("DataCatalog: cannot load enemy catalog %s" % path)
			continue
		for enemy in catalog.items:
			_enemies[enemy.kind] = enemy

func region(region_id: String) -> RegionData:
	return _regions.get(region_id)

func regions() -> Array:
	return REGION_RESOURCE_PATHS.map(func(path): return load(path) as RegionData).filter(func(resource): return resource != null)

func map(map_id: String) -> MapData:
	return _maps.get(map_id)

func map_order() -> Array:
	return _map_order.duplicate()

func connections() -> Array:
	var result := []
	for index in range(_map_order.size() - 1):
		result.append({"from": _map_order[index], "to": _map_order[index + 1]})
	return result

func ui_position(map_id: String) -> Vector2:
	var index := _map_order.find(map_id)
	var column := index % 7
	var row := int(index / 7.0)
	return Vector2(18.0 + column * 126.0, 22.0 + row * 148.0)

func map_metadata(map_id: String) -> Dictionary:
	var map := self.map(map_id)
	if map == null:
		return {}
	var region := self.region(map.region_id)
	return {
		"id": map.id,
		"region_id": map.region_id,
		"region_name": region.display_name if region else "",
		"display_name": map.display_name,
		"theme": region.theme.duplicate(true) if region else {},
		"width": map.width,
		"offset_x": map.offset_x,
		"map_index": _map_order.find(map_id) + 1,
		"region_index": REGION_RESOURCE_PATHS.find("res://data/regions/%s.tres" % map.region_id) + 1,
		"is_boss": region != null and region.map_ids.size() > 0 and str(region.map_ids[region.map_ids.size() - 1]) == map_id,
		"difficulty": region.difficulty if region else 1,
	}

func region_metadata(region_id: String) -> Dictionary:
	var region := self.region(region_id)
	if region == null:
		return {}
	return {
		"id": region.id,
		"display_name": region.display_name,
		"difficulty": region.difficulty,
		"theme": region.theme.duplicate(true),
		"weapon": region.weapon_id,
		"armor": region.armor_id,
		"map_count": region.maps.size(),
		"boss": {
			"id": region.boss.id if region.boss else "",
			"display_name": region.boss.display_name if region.boss else "",
			"forms": region.boss.forms if region.boss else [],
		},
	}

func equipment(id_value: String) -> EquipmentData:
	var item := _equipment.get(id_value) as EquipmentData
	return item.duplicate(true) if item else null

func enemy(kind: String) -> EnemyData:
	var enemy := _enemies.get(kind) as EnemyData
	return enemy.duplicate(true) if enemy else null
