extends Node

signal hp_changed(current_hp: int, max_hp: int)
signal exp_changed(current_exp: int, required_exp: int, level: int)
signal coins_changed(coins: int)
signal checkpoint_reached(position: Vector2)
signal player_died
signal level_completed
signal zone_changed(zone_id: String)
signal map_state_changed
signal respawn_requested(zone_id: String, position: Vector2)
signal equipment_changed
signal equipment_gained(weapon_id: String, armor_id: String, region_id: String)
signal boss_defeated(region_id: String)

const BASE_MAX_HP := 100
const BASE_REQUIRED_EXP := 100
const INITIAL_ZONE_ID := "meadow"
const INITIAL_MAP_ID := "meadow_1"
const EQUIPMENT_SCRIPT := preload("res://scripts/items/equipment_library.gd")

var max_hp := BASE_MAX_HP
var current_hp := BASE_MAX_HP
var level_hp_bonus := 0
var current_exp := 0
var required_exp := BASE_REQUIRED_EXP
var current_level := 1
var coins := 0
var score := 0
var kills := 0
var deaths := 0
var total_coin_pickups := 0
var collected_coin_pickups := 0
var current_zone_id := INITIAL_ZONE_ID
var current_map_id := INITIAL_MAP_ID
var current_region_id := "meadow"
var discovered_zones: Array[String] = [INITIAL_ZONE_ID]
var zone_checkpoints := {}
var checkpoint_zone_id := INITIAL_ZONE_ID
var checkpoint_position := Vector2(120, 460)
var owned_equipment: Array[String] = ["grass_blade", "none_armor"]
var equipped_weapon_id := "grass_blade"
var equipped_armor_id := "none_armor"
var defeated_bosses: Array[String] = []
var elapsed_time := 0.0
var final_time := 0.0
var level_finished := false
# 点击开始/重开后是否先走加载界面：由 title_screen、game_screens 置位，world_map 消费。
var pending_loading_screen := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	reset_run()

func _process(delta: float) -> void:
	if not level_finished:
		elapsed_time += delta

func reset_run() -> void:
	max_hp = BASE_MAX_HP
	current_hp = max_hp
	level_hp_bonus = 0
	current_exp = 0
	required_exp = BASE_REQUIRED_EXP
	current_level = 1
	coins = 0
	score = 0
	kills = 0
	deaths = 0
	total_coin_pickups = 0
	collected_coin_pickups = 0
	current_zone_id = INITIAL_ZONE_ID
	current_map_id = INITIAL_MAP_ID
	current_region_id = "meadow"
	discovered_zones = [INITIAL_ZONE_ID]
	zone_checkpoints = {}
	checkpoint_zone_id = INITIAL_ZONE_ID
	checkpoint_position = Vector2(120, 460)
	owned_equipment = ["grass_blade", "none_armor"]
	equipped_weapon_id = "grass_blade"
	equipped_armor_id = "none_armor"
	defeated_bosses = []
	elapsed_time = 0.0
	final_time = 0.0
	level_finished = false
	_emit_all()

func _emit_all() -> void:
	hp_changed.emit(current_hp, max_hp)
	exp_changed.emit(current_exp, required_exp, current_level)
	coins_changed.emit(coins)

func damage_player(amount: int) -> void:
	if level_finished or current_hp <= 0:
		return
	var armor := get_equipment(equipped_armor_id)
	var reduction := float(armor.damage_reduction) if armor != null else 0.0
	var final_amount := maxi(1, int(round(float(amount) * (1.0 - reduction))))
	current_hp = maxi(0, current_hp - final_amount)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		deaths += 1
		player_died.emit()

func heal_player(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func add_experience(amount: int) -> void:
	if level_finished:
		return
	current_exp += amount
	while current_exp >= required_exp:
		current_exp -= required_exp
		current_level += 1
		required_exp = int(required_exp * 1.45)
		level_hp_bonus += 10
		_recalculate_max_hp()
		current_hp = max_hp
	exp_changed.emit(current_exp, required_exp, current_level)
	hp_changed.emit(current_hp, max_hp)

func register_coin_pickups(count: int) -> void:
	total_coin_pickups += count

func activate_zone(zone_id: String, spawn_position: Vector2) -> void:
	if zone_id.is_empty():
		return
	if not discovered_zones.has(zone_id):
		discovered_zones.append(zone_id)
	current_zone_id = zone_id
	checkpoint_zone_id = zone_id
	if not zone_checkpoints.has(zone_id):
		zone_checkpoints[zone_id] = spawn_position
	checkpoint_position = zone_checkpoints[zone_id]
	zone_changed.emit(zone_id)
	map_state_changed.emit()

func activate_map(map_id: String, spawn_position: Vector2) -> void:
	var maps := load("res://scripts/world/world_maps.gd")
	var metadata: Dictionary = maps.map_metadata(map_id)
	current_map_id = map_id
	current_region_id = str(metadata.get("region_id", "meadow"))
	activate_zone(map_id, spawn_position)

func get_equipment(id_value: String) -> EquipmentData:
	return EQUIPMENT_SCRIPT.create(id_value)

func get_current_weapon() -> EquipmentData:
	return get_equipment(equipped_weapon_id)

func get_current_armor() -> EquipmentData:
	return get_equipment(equipped_armor_id)

func owns_equipment(id_value: String) -> bool:
	return owned_equipment.has(id_value)

func grant_boss_rewards(region_id: String) -> bool:
	if defeated_bosses.has(region_id):
		return false
	var metadata: Dictionary = _region_metadata(region_id)
	var weapon_id := str(metadata.get("weapon", "grass_blade"))
	var armor_id := str(metadata.get("armor", "none_armor"))
	for item_id in [weapon_id, armor_id]:
		if not owned_equipment.has(item_id):
			owned_equipment.append(item_id)
	defeated_bosses.append(region_id)
	equipment_gained.emit(weapon_id, armor_id, region_id)
	boss_defeated.emit(region_id)
	equipment_changed.emit()
	map_state_changed.emit()
	return true

func is_boss_defeated(region_id: String) -> bool:
	return defeated_bosses.has(region_id)

func boss_count() -> int:
	return defeated_bosses.size()

func equip(id_value: String) -> bool:
	if not owns_equipment(id_value):
		return false
	var item := get_equipment(id_value)
	if item == null:
		return false
	if item.slot == "weapon":
		equipped_weapon_id = id_value
	elif item.slot == "armor":
		equipped_armor_id = id_value
		_recalculate_max_hp()
		current_hp = mini(current_hp, max_hp)
	else:
		return false
	equipment_changed.emit()
	return true

func _region_metadata(region_id: String) -> Dictionary:
	var maps := load("res://scripts/world/world_maps.gd")
	return maps.REGIONS.get(region_id, {})

func _recalculate_max_hp() -> void:
	var armor := get_equipment(equipped_armor_id)
	var hp_bonus := int(armor.hp_bonus) if armor != null else 0
	max_hp = BASE_MAX_HP + level_hp_bonus + hp_bonus

func add_coin(value: int = 1) -> void:
	if level_finished:
		return
	coins += value
	collected_coin_pickups += 1
	score += value * 10
	coins_changed.emit(coins)

func add_coin_reward(value: int) -> void:
	if level_finished:
		return
	coins += value
	score += value * 10
	coins_changed.emit(coins)

func register_kill() -> void:
	kills += 1
	score += 50

func set_checkpoint(position: Vector2) -> void:
	return set_zone_checkpoint(current_zone_id, position)

func set_zone_checkpoint(zone_id: String, position: Vector2) -> void:
	if zone_checkpoints.get(zone_id, Vector2.INF).distance_squared_to(position) < 4.0:
		return
	zone_checkpoints[zone_id] = position
	checkpoint_zone_id = zone_id
	checkpoint_position = position
	checkpoint_reached.emit(position)

func respawn_from_checkpoint() -> void:
	if current_hp > 0:
		return
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	respawn_requested.emit(checkpoint_zone_id, checkpoint_position)

func complete_level() -> void:
	if level_finished:
		return
	level_finished = true
	final_time = elapsed_time
	level_completed.emit()

func get_formatted_time(value := -1.0) -> String:
	var shown := final_time if value < 0.0 else value
	var minutes := int(shown) / 60
	var seconds := int(shown) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_rating() -> String:
	var coin_ratio := 1.0
	if total_coin_pickups > 0:
		coin_ratio = float(collected_coin_pickups) / float(total_coin_pickups)
	var score_value := coin_ratio * 100.0
	score_value += maxi(0, 240 - int(final_time)) * 0.2
	score_value -= deaths * 8.0
	if score_value >= 130.0:
		return "S"
	elif score_value >= 110.0:
		return "A"
	elif score_value >= 90.0:
		return "B"
	return "C"
