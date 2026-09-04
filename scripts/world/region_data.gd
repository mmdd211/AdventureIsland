class_name RegionData
extends Resource

@export var id := ""
@export var display_name := ""
@export var difficulty := 1
@export var theme: Dictionary = {}
@export var weapon_id := ""
@export var armor_id := ""
@export var map_ids: PackedStringArray = []
@export var maps: Array[MapData] = []
@export var boss: BossData

func map(map_id: String) -> MapData:
	for item in maps:
		if item != null and item.id == map_id:
			return item
	return null
