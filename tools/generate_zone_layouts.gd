extends SceneTree

const WorldMaps := preload("res://scripts/world/world_maps.gd")


class LayoutRecorder extends RefCounted:
	var layout := ZoneLayout.new()
	var zone_id := ""
	var region_id := ""
	var display_name := ""
	var zone_width := 2400.0
	var zone_offset_x := 0.0
	var floor_top := 520.0
	var zone_theme := {}
	var map_index := 0
	var difficulty := 1
	var is_boss_map := false

	func _add_object(kind: String, position_value := Vector2.ZERO, size_value := Vector2.ZERO) -> ZoneObjectData:
		var object := ZoneObjectData.new()
		object.kind = kind
		object.position = position_value
		object.size = size_value
		layout.objects.append(object)
		return object

	func _checkpoint(position_value: Vector2) -> void:
		_add_object("checkpoint", position_value)

	func _ground(_index: int, position_value: Vector2, size_value: Vector2) -> void:
		_add_object("ground", position_value, size_value)

	func _static_platform(_index: int, position_value: Vector2, size_value: Vector2, one_way := false) -> void:
		var object := _add_object("platform", position_value, size_value)
		object.one_way = one_way

	func _one_way_platform(_index: int, position_value: Vector2, size_value: Vector2) -> void:
		_add_object("one_way_platform", position_value, size_value)

	func _moving_platform(label: String, position_value: Vector2, travel: Vector2, period: float, phase := 0.0) -> void:
		var object := _add_object("moving_platform", position_value)
		object.label = label
		object.travel = travel
		object.period = period
		object.phase = phase

	func _crumbling_platform(position_value: Vector2) -> void:
		_add_object("crumbling_platform", position_value)

	func _enemy(kind_value: String, position_value: Vector2) -> void:
		var object := _add_object("enemy", position_value)
		object.label = kind_value

	func _pickup(position_value: Vector2, pickup_type := "coin", amount := 1) -> void:
		var object := _add_object("pickup", position_value)
		object.label = pickup_type
		object.value = amount

	func _spring(position_value: Vector2) -> void:
		_add_object("spring", position_value)

	func _spike(position_value: Vector2, width_value: float) -> void:
		var object := _add_object("spike", position_value, Vector2(width_value, 22))

	func _portal(id: String, position_value: Vector2, destination_zone := "", destination_portal := "", _goal := false, lock_region := "") -> void:
		var object := _add_object("portal", position_value)
		object.label = id
		object.target_zone_id = destination_zone
		object.target_portal_id = destination_portal
		object.lock_region_id = lock_region

	func _darkness(_target_zone, amount: float) -> void:
		var object := _add_object("darkness")
		object.float_value = amount

	func _boss() -> void:
		_add_object("boss")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/layouts")
	DirAccess.make_dir_recursive_absolute("res://scenes/levels")
	var failures := 0
	for map_id in WorldMaps.ORDER:
		var recorder := LayoutRecorder.new()
		var metadata: Dictionary = WorldMaps.map_metadata(map_id)
		recorder.zone_id = map_id
		recorder.region_id = str(metadata.region_id)
		recorder.display_name = str(metadata.display_name)
		recorder.zone_width = float(metadata.width)
		recorder.zone_offset_x = float(metadata.offset_x)
		recorder.floor_top = 520.0
		recorder.zone_theme = metadata.theme
		recorder.map_index = int(metadata.map_index)
		recorder.difficulty = int(metadata.difficulty)
		recorder.is_boss_map = bool(metadata.is_boss)
		WorldMaps.build(recorder)
		print("%s generated %d objects" % [map_id, recorder.layout.objects.size()])
		if recorder.layout.objects.is_empty():
			var existing_layout := load("res://data/layouts/%s.tres" % map_id) as ZoneLayout
			if existing_layout == null or existing_layout.objects.is_empty():
				printerr("No objects generated or saved for %s" % map_id)
				failures += 1
				continue
			recorder.layout = existing_layout
			continue
		var layout_path := "res://data/layouts/%s.tres" % map_id
		var scene_path := "res://scenes/levels/zone_%s.tscn" % map_id
		recorder.layout.resource_path = layout_path
		if ResourceSaver.save(recorder.layout, layout_path) != OK:
			printerr("Failed to save layout %s" % layout_path)
			failures += 1
			continue
		if _save_scene(recorder.layout, scene_path) != OK:
			printerr("Failed to save scene %s" % scene_path)
			failures += 1
	if failures == 0:
		print("Generated %d zone layouts and scenes." % WorldMaps.ORDER.size())
	quit(failures)

func _save_scene(layout: ZoneLayout, scene_path: String) -> Error:
	var file := FileAccess.open(scene_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_line("[gd_scene load_steps=3 format=3]")
	file.store_line("")
	file.store_line("[ext_resource type=\"Script\" path=\"res://scripts/world/zone_builder.gd\" id=\"1_builder\"]")
	file.store_line("[ext_resource type=\"Resource\" path=\"%s\" id=\"2_layout\"]" % layout.resource_path)
	file.store_line("")
	file.store_line("[node name=\"ZoneScene\" type=\"Node2D\"]")
	file.store_line("script = ExtResource(\"1_builder\")")
	file.store_line("layout = ExtResource(\"2_layout\")")
	file.close()
	return OK
