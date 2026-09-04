extends SceneTree

const DataCatalogScript := preload("res://scripts/systems/data_catalog.gd")
const LocalizationScript := preload("res://scripts/systems/localization_system.gd")

var catalog: Node
var localization: Node

func _init() -> void:
	catalog = DataCatalogScript.new()
	catalog._ready()
	localization = LocalizationScript.new()
	_check()

func _check() -> void:
	var failures := 0

	for region_id in ["meadow", "forest", "grove", "canyon", "ruins", "gate"]:
		var region := catalog.region(region_id) as RegionData
		if region == null:
			printerr("Missing region: %s" % region_id)
			failures += 1
			continue
		if region.maps.is_empty():
			printerr("Region has no maps: %s" % region_id)
			failures += 1
		if region.boss == null or region.boss.forms.is_empty():
			printerr("Region has no boss forms: %s" % region_id)
			failures += 1
		for map_id in region.map_ids:
			if catalog.map(map_id) == null:
				printerr("Missing map: %s" % map_id)
				failures += 1
			elif catalog.map_metadata(map_id).is_empty():
				printerr("Invalid map metadata: %s" % map_id)
				failures += 1

	for item_id in ["grass_blade", "star_edge", "sky_armor"]:
		if catalog.equipment(item_id) == null:
			printerr("Missing equipment: %s" % item_id)
			failures += 1

	for enemy_id in ["mushroom", "slime", "sky_knight"]:
		var enemy := catalog.enemy(enemy_id) as EnemyData
		if enemy == null or enemy.max_health <= 0:
			printerr("Invalid enemy: %s" % enemy_id)
			failures += 1

	var health := HealthComponent.new()
	var death_count := [0]
	health.died.connect(func(): death_count[0] += 1)
	health.setup(10, 10)
	if not health.damage(4):
		printerr("HealthComponent failed to apply damage.")
		failures += 1
	if health.current_health != 6:
		printerr("HealthComponent damage value mismatch.")
		failures += 1
	health.heal(2)
	health.damage(100)
	if health.current_health != 0 or death_count[0] != 1:
		printerr("HealthComponent death flow mismatch.")
		failures += 1

	var status := StatusEffectComponent.new()
	status.setup(status)
	if not status.apply("slow", 1.0) or not status.has_effect("slow"):
		printerr("StatusEffectComponent failed to apply status.")
		failures += 1
	status._process(1.2)
	if status.has_effect("slow"):
		printerr("StatusEffectComponent failed to expire status.")
		failures += 1


	for region_id in ["meadow", "forest"]:
		var boss: BossData = catalog.region(region_id).boss
		for form in boss.forms:
			if form.collision.x <= 0.0 or form.collision.y <= 0.0 or form.max_health <= 0:
				printerr("Invalid boss form: %s/%s" % [region_id, form.id])
				failures += 1

	if catalog.map_order().size() != 21:
		printerr("Expected 21 maps, got %d" % catalog.map_order().size())
		failures += 1
	for map_id in catalog.map_order():
		var map := catalog.map(map_id) as MapData
		if map == null or map.scene_path.is_empty():
			printerr("Missing scene path: %s" % map_id)
			failures += 1
			continue
		if not FileAccess.file_exists(ProjectSettings.globalize_path(map.scene_path)):
			printerr("Missing zone scene: %s" % map.scene_path)
			failures += 1

	localization.language = "en"
	if localization.tr_key("start") != "Start Adventure":
		printerr("Localization English table failed.")
		failures += 1
	localization.language = "zh"
	if localization.tr_key("start") != "开始冒险":
		printerr("Localization Chinese table failed.")
		failures += 1

	var boss_source := FileAccess.open("res://scripts/monsters/elite_boss.gd", FileAccess.READ)
	var boss_code := boss_source.get_as_text() if boss_source else ""
	if not boss_code.contains("enum BossState") or not boss_code.contains("transition_state"):
		printerr("EliteBoss state machine missing.")
		failures += 1

	var boss_frames := BossAssetLibrary.load_frames("pollen_queen", "bee")
	if boss_frames == null or not boss_frames.has_animation("idle"):
		printerr("Boss asset library failed to load pollen queen frames.")
		failures += 1

	if failures == 0:
		print("DataCatalog smoke check passed.")
	else:
		printerr("DataCatalog smoke check failed with %d issue(s)." % failures)
	quit(failures)
