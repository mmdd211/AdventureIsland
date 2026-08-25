extends Node

var frame := 0
var level: Node
var player: CharacterBody2D
var split_expected := false
var split_before_kills := 0
var slime_contact_damage := 0
var mushroom_target: Node

func _ready() -> void:
	var packed := load("res://scenes/levels/test_level.tscn") as PackedScene
	level = packed.instantiate()
	add_child(level)
	call_deferred("_find_nodes")

func _find_nodes() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		_assert(false, "Player not found")
		return

func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		20:
			_assert(GameState.max_hp == 100, "GameState HP initialized")
			_assert(get_tree().get_nodes_in_group("enemies").size() >= 3, "Expected at least three enemies")
			_assert(player.get_node_or_null("PixelAnimator") != null, "Player pixel sprite generated")
			var first_enemy: Node = get_tree().get_first_node_in_group("enemies")
			_assert(first_enemy != null and first_enemy.get_node_or_null("PixelSprite") != null, "Enemy pixel sprite generated")
			_prepare_mushroom_hit()
		32:
			_test_mushroom_hit()
		40:
			_test_snail_positions()
		60:
			var slime := _find_enemy("slime")
			_assert(slime != null, "Slime exists")
			if slime:
				split_expected = true
				split_before_kills = GameState.kills
				slime_contact_damage = slime.data.contact_damage
				slime.die()
		75:
			if split_expected:
				_check_slime_split()
		90:
			_test_player_damage()
		110:
			_test_mini_becomes_vulnerable()
		112:
			_test_mini_jump_chase()
		120:
			_finish()

func _prepare_mushroom_hit() -> void:
	var enemy := _find_enemy("mushroom")
	_assert(enemy != null, "Mushroom exists")
	if enemy == null:
		return
	mushroom_target = enemy
	player.global_position = enemy.global_position + Vector2(-55, 0)
	player.facing_direction = 1

func _test_mushroom_hit() -> void:
	if mushroom_target == null or not is_instance_valid(mushroom_target):
		_assert(false, "Mushroom target lost")
		return
	var enemy: Node = mushroom_target
	player.attack_timer = player.attack_duration - 0.10
	player.attack_stage = 1
	player._process_attack_hits()
	_assert(enemy.health < enemy.data.max_health, "Mushroom attack hit")

func _test_snail_positions() -> void:
	var snail := _find_enemy("snail")
	_assert(snail != null, "Snail exists")
	if snail == null:
		return
	snail.direction = 1
	var front_health: int = snail.health
	snail.take_damage(10, snail.global_position + Vector2(-40, 0))
	_assert(snail.health == front_health - 2, "Snail frontal guard reduced damage")
	var back_health: int = snail.health
	snail.take_damage(10, snail.global_position + Vector2(40, 0))
	_assert(snail.health == back_health - 20, "Snail rear damage doubled")

func _check_slime_split() -> void:
	var mini_count := 0
	var protected_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_mini") == true:
			mini_count += 1
			_assert(enemy.data.contact_damage == slime_contact_damage, "Mini inherits slime contact damage")
			_assert(enemy.data.move_speed >= 100.0, "Mini has increased movement speed")
			if enemy.get("spawn_grace_timer") > 0.0:
				protected_count += 1
	_assert(mini_count >= 2, "Slime split into two minis")
	_assert(protected_count == mini_count, "Spawned minis get split protection")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_mini") == true:
			var health: int = enemy.health
			enemy.take_damage(14)
			_assert(enemy.health == health, "Split protection prevents same-swing damage")
			break
	_assert(GameState.kills > split_before_kills, "Enemy kill registered")
	_assert(GameState.total_coin_pickups >= 2, "Slime coin drops registered")
	print("PHASE3_CHECK: mini_slimes=%d kills=%d" % [mini_count, GameState.kills])

func _test_player_damage() -> void:
	var before := GameState.current_hp
	player.invulnerable_timer = 0.0
	player.take_damage(12, player.global_position + Vector2(40, 0))
	_assert(GameState.current_hp == before - 12, "Player damage applied")
	_assert(player.invulnerable_timer > 0.0, "Player invulnerability applied")
	print("PHASE3_CHECK: hp=%d deaths=%d" % [GameState.current_hp, GameState.deaths])

func _test_mini_becomes_vulnerable() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_mini") == true and enemy.get("spawn_grace_timer") <= 0.0:
			var health: int = enemy.health
			enemy.take_damage(1)
			_assert(enemy.health == health - 1, "Mini becomes vulnerable after protection")
			return
	_assert(false, "Protected mini available for vulnerability check")

func _test_mini_jump_chase() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("is_mini") == true and enemy.is_on_floor():
			player.global_position = enemy.global_position + Vector2(-90, 0)
			enemy.velocity = Vector2.ZERO
			enemy.hop_timer = 0.0
			enemy._process_patrol(1.0 / 60.0)
			_assert(absf(enemy.velocity.x) >= 250.0, "Mini chase jump has increased speed")
			_assert(enemy.velocity.y <= -390.0, "Mini uses jump chase like large slime")
			return
	_assert(false, "Landed mini available for jump-chase check")

func _find_enemy(kind_value: String) -> Node:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("enemy_kind") == kind_value and enemy.get("is_dead") == false:
			return enemy
	return null

func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		get_tree().quit(1)

func _finish() -> void:
	print("PHASE3_CHECK COMPLETE")
	get_tree().quit(0)
