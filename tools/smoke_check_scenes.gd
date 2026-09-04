extends Node

const KNOWN_KINDS := [
	"ground", "platform", "one_way_platform", "enemy", "pickup", "checkpoint",
	"spring", "spike", "moving_platform", "crumbling_platform", "portal", "boss", "darkness",
]

func _ready() -> void:
	var failures := 0
	for map_id in DataCatalog.map_order():
		var map := DataCatalog.map(map_id) as MapData
		if map == null or map.scene_path.is_empty():
			printerr("Missing scene path: %s" % map_id)
			failures += 1
			continue
		var packed := load(map.scene_path) as PackedScene
		if packed == null:
			printerr("Zone scene failed to load: %s" % map.scene_path)
			failures += 1
			continue
		var zone := packed.instantiate() as Node
		if zone == null:
			printerr("Zone scene failed to instantiate: %s" % map_id)
			failures += 1
			continue

		var script := zone.get_script() as Script
		if script == null or script.resource_path != "res://scripts/world/zone_builder.gd":
			printerr("Zone root script is not ZoneBuilder: %s" % map_id)
			failures += 1

		var layout := zone.get("layout") as ZoneLayout
		if layout == null or layout.objects.is_empty():
			printerr("Zone layout missing or empty: %s" % map_id)
			failures += 1
			zone.free()
			continue

		var min_x := INF
		var max_x := -INF
		for object in layout.objects:
			if not KNOWN_KINDS.has(object.kind):
				printerr("Unknown layout object kind %s in %s" % [object.kind, map_id])
				failures += 1
			# 地面横向范围必须落在 MapData 宽度加左/右墙 40px 容差内。
			if object.kind == "ground":
				min_x = minf(min_x, object.position.x - object.size.x * 0.5)
				max_x = maxf(max_x, object.position.x + object.size.x * 0.5)
		if min_x == INF or max_x == -INF:
			printerr("Zone layout has no ground objects: %s" % map_id)
			failures += 1
		elif min_x < -40.0 or max_x > map.width + 40.0:
			printerr("Zone layout ground out of MapData bounds: %s (%.0f..%.0f, width %.0f)" % [map_id, min_x, max_x, map.width])
			failures += 1

		zone.free()

	if failures == 0:
		print("Zone scene smoke check passed.")
	else:
		printerr("Zone scene smoke check failed with %d issue(s)." % failures)
	get_tree().quit(failures)
