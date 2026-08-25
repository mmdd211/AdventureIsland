extends Node

var level: Node2D

func _ready() -> void:
	var packed := load("res://scenes/levels/world01.tscn") as PackedScene
	level = packed.instantiate()
	add_child(level)
	await get_tree().create_timer(0.45).timeout
	_check_structure()
	await _check_checkpoints()
	await _check_mechanics()
	await _check_completion()
	print("WORLD01_CHECK COMPLETE")
	get_tree().quit(0)

func _check_structure() -> void:
	_assert(level.name == "World01", "World01 loaded")
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	_assert(player != null, "World01 player exists")
	var grounds := 0
	var static_platforms := 0
	var checkpoints := 0
	var springs := 0
	var spikes := 0
	var moving_platforms := 0
	var crumble_platforms := 0
	for child in level.get_children():
		if String(child.name).begins_with("Ground"):
			grounds += 1
		elif String(child.name).begins_with("PlatformMoving"):
			moving_platforms += 1
		elif String(child.name).begins_with("PlatformCrumble"):
			crumble_platforms += 1
		elif String(child.name).begins_with("Platform"):
			static_platforms += 1
		elif String(child.name).begins_with("Checkpoint"):
			checkpoints += 1
		elif String(child.name).begins_with("Spring"):
			springs += 1
		elif String(child.name).begins_with("Spikes"):
			spikes += 1
	_assert(grounds >= 4, "World01 has distinct ground sections")
	_assert(static_platforms >= 12, "World01 has platform routes")
	_assert(checkpoints == 3, "World01 has three checkpoints")
	_assert(springs >= 1 and spikes >= 2, "World01 has spring and spike hazards")
	_assert(moving_platforms == 3 and crumble_platforms >= 1, "World01 has moving and crumbling platforms")
	_assert(level.get_node_or_null("WorldBackground") != null, "World01 has parallax background")
	_assert(level.get_node("WorldBackground").get_child_count() >= 5, "Background has five parallax layers")
	var spring_model := _find_by_prefix("Spring") as Node2D
	_assert(spring_model != null and spring_model.get_node_or_null("SpringSprite") != null, "Spring has pixel model")
	_assert(GameState.total_coin_pickups >= 20, "World01 registers collectible coins")
	_assert(GameState.collected_coin_pickups == 0, "Coin counter starts empty")

func _check_checkpoints() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var checkpoint_count := 0
	for child in level.get_children():
		if not String(child.name).begins_with("Checkpoint"):
			continue
		checkpoint_count += 1
		player.velocity = Vector2.ZERO
		player.global_position = child.global_position
		await get_tree().create_timer(0.18).timeout
		_assert(child.activated, "Checkpoint %d activates" % checkpoint_count)
		_assert(GameState.checkpoint_position.distance_to(child.global_position) < 60.0,
			"Checkpoint %d saves respawn state" % checkpoint_count)

func _check_mechanics() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var mover := level.get_node("PlatformMoving1") as Node2D
	var mover_x := mover.global_position.x
	player.velocity = Vector2.ZERO
	player.global_position = mover.global_position + Vector2(0, -38)
	await get_tree().create_timer(0.55).timeout
	_assert(absf(mover.global_position.x - mover_x) > 18.0, "Moving platform travels")
	_assert(absf(player.global_position.x - mover.global_position.x) < 42.0, "Moving platform carries player")

	var spring := _find_by_prefix("Spring") as Area2D
	player.invulnerable_timer = 0.0
	player.velocity = Vector2.ZERO
	player.global_position = spring.global_position + Vector2(0, -28)
	await get_tree().create_timer(0.14).timeout
	_assert(player.velocity.y <= -500.0, "Spring launches player")

	var crumble := level.get_node("PlatformCrumble1") as StaticBody2D
	player.invulnerable_timer = 0.0
	player.velocity = Vector2.ZERO
	player.global_position = crumble.global_position + Vector2(0, -32)
	await get_tree().create_timer(0.34).timeout
	_assert(crumble.get("triggered") == true, "Crumbling platform collapses")

	var spikes := _find_by_prefix("Spikes") as Area2D
	player.invulnerable_timer = 0.0
	GameState.heal_player(GameState.max_hp)
	var health_before := GameState.current_hp
	player.velocity = Vector2.ZERO
	player.global_position = spikes.global_position + Vector2(0, -28)
	await get_tree().create_timer(0.22).timeout
	_assert(GameState.current_hp < health_before, "Spike strip damages once per interval")

func _find_by_prefix(prefix: String) -> Node:
	for child in level.get_children():
		if String(child.name).begins_with(prefix):
			return child
	return null

func _check_completion() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var portal := level.get_node("Portal") as Area2D
	var screens := level.get_node("GameScreens")
	player.global_position = portal.global_position
	await get_tree().create_timer(0.25).timeout
	_assert(GameState.level_finished, "Portal finishes World01")
	_assert(get_tree().paused, "Completion pauses gameplay")
	_assert(screens.complete_panel.visible, "Completion screen appears")
	_assert(GameState.get_rating() in ["S", "A", "B", "C"], "Completion rating exists")

func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		get_tree().quit(1)
