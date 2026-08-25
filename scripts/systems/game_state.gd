extends Node

signal hp_changed(current_hp: int, max_hp: int)
signal exp_changed(current_exp: int, required_exp: int, level: int)
signal coins_changed(coins: int)
signal checkpoint_reached(position: Vector2)
signal player_died
signal level_completed
signal respawn_requested(position: Vector2)

const BASE_MAX_HP := 100
const BASE_REQUIRED_EXP := 100

var max_hp := BASE_MAX_HP
var current_hp := BASE_MAX_HP
var current_exp := 0
var required_exp := BASE_REQUIRED_EXP
var current_level := 1
var coins := 0
var score := 0
var kills := 0
var deaths := 0
var total_coin_pickups := 0
var collected_coin_pickups := 0
var checkpoint_position := Vector2(120, 460)
var elapsed_time := 0.0
var final_time := 0.0
var level_finished := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	reset_run()

func _process(delta: float) -> void:
	if not level_finished:
		elapsed_time += delta

func reset_run() -> void:
	max_hp = BASE_MAX_HP
	current_hp = max_hp
	current_exp = 0
	required_exp = BASE_REQUIRED_EXP
	current_level = 1
	coins = 0
	score = 0
	kills = 0
	deaths = 0
	total_coin_pickups = 0
	collected_coin_pickups = 0
	checkpoint_position = Vector2(120, 460)
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
	current_hp = maxi(0, current_hp - amount)
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
		max_hp += 10
		current_hp = max_hp
	exp_changed.emit(current_exp, required_exp, current_level)
	hp_changed.emit(current_hp, max_hp)

func register_coin_pickups(count: int) -> void:
	total_coin_pickups += count

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
	if position.distance_squared_to(checkpoint_position) < 4.0:
		return
	checkpoint_position = position
	checkpoint_reached.emit(position)

func respawn_from_checkpoint() -> void:
	if current_hp > 0:
		return
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	respawn_requested.emit(checkpoint_position)

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
