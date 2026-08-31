extends CharacterBody2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")
const ENEMY_SCENE := preload("res://scenes/monsters/basic_enemy.tscn")
const WORLD_MAPS := preload("res://scripts/world/world_maps.gd")
const BOSS_ANIMATOR := preload("res://scripts/monsters/boss_animator.gd")
const TELEGRAPH := preload("res://scripts/monsters/boss_telegraph.gd")
const BOSS_HUD := preload("res://scenes/ui/boss_hud_bar.tscn")

var region_id := "meadow"
var map_id := "meadow_3"
var data := {}
var forms: Array = []
var form_index := 0
var form_data := {}
var form_health := 1
var form_max_health := 1
var stage := 1
var stage_count := 2
var direction := -1
var attack_timer := 1.8
var state_timer := 0.0
var is_dead := false
var evolving := false
var attacking := false
var gravity := 1550.0
var attack_index := 0
var collision_shape: CollisionShape2D
var damage_shape: CollisionShape2D
var boss_animator: AnimatedSprite2D
var boss_hud: CanvasLayer
var ring_effect: Line2D
var gravity_enabled := true
var contact_damage := 14
var move_speed := 88.0
var charge_speed := 430.0
var attack_interval := 1.7
var body_color := Color.WHITE
var attacks: Array[String] = ["bee_sting"]
var skills: Array[String] = ["pollen_cloud", "bee_tide"]
var basic_attack := "bee_sting"

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("elite_boss")
	_load_data()
	_build_body()
	_build_hud()
	_build_pixel_sprite()
	_apply_form(0, false)
	GameState.zone_changed.connect(_update_hud_visibility)
	GameState.map_state_changed.connect(_update_hud_visibility)
	_update_hud_visibility()

func _load_data() -> void:
	var maps := load("res://scripts/world/world_maps.gd")
	var region: Dictionary = maps.REGIONS.get(region_id, {})
	var boss: Dictionary = region.get("boss", {})
	data = boss
	forms = boss.get("forms", []).duplicate(true)
	if forms.is_empty():
		forms = [{"display_name": boss.get("display_name", "Boss"), "max_health": 380, "contact_damage": 14, "collision": Vector2(84, 104), "move_speed": 80.0, "basic_attack": "charge", "skills": ["pollen_swarm"]}]
	stage_count = forms.size()

func _build_body() -> void:
	collision_shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(84, 104)
	collision_shape.shape = rectangle
	add_child(collision_shape)
	damage_shape = CollisionShape2D.new()
	var damage_rectangle := RectangleShape2D.new()
	damage_rectangle.size = Vector2(96, 112)
	damage_shape.shape = damage_rectangle
	var damage_area := Area2D.new()
	damage_area.name = "DamageArea"
	damage_area.collision_layer = 0
	damage_area.collision_mask = 1
	damage_area.add_child(damage_shape)
	add_child(damage_area)

func _build_hud() -> void:
	boss_hud = BOSS_HUD.instantiate()
	add_child(boss_hud)
	boss_hud.bind(str(data.get("display_name", "Boss")), region_id)
	boss_hud.visible = false

func _build_pixel_sprite() -> void:
	boss_animator = AnimatedSprite2D.new()
	boss_animator.name = "BossAnimator"
	boss_animator.set_script(BOSS_ANIMATOR)
	boss_animator.region_id = region_id
	boss_animator.form_id = str(_form_metadata(0).get("id", "bee"))
	add_child(boss_animator)

func _form_metadata(index: int) -> Dictionary:
	if index >= 0 and index < forms.size() and typeof(forms[index]) == TYPE_DICTIONARY:
		return forms[index]
	return {}

func _apply_form(index: int, announce := true) -> void:
	form_index = clampi(index, 0, forms.size() - 1)
	form_data = _form_metadata(form_index)
	form_max_health = int(form_data.get("max_health", 380))
	form_health = form_max_health
	contact_damage = int(form_data.get("contact_damage", 14))
	move_speed = float(form_data.get("move_speed", 80.0))
	gravity_enabled = bool(form_data.get("gravity_enabled", true))
	attacks.clear()
	attacks.append(str(form_data.get("basic_attack", "charge")))
	skills.clear()
	for skill in form_data.get("skills", []):
		skills.append(str(skill))
	if collision_shape and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = form_data.get("collision", Vector2(84, 104))
	if damage_shape and damage_shape.shape is RectangleShape2D:
		(damage_shape.shape as RectangleShape2D).size = form_data.get("collision", Vector2(84, 104)) + Vector2(12, 10)
	if boss_animator:
		boss_animator.set_form(str(form_data.get("id", "bee")))
		boss_animator.offset.y = -6.0
	stage = form_index + 1
	if boss_hud:
		boss_hud.set_form(str(form_data.get("display_name", "形态")), form_index, forms.size())
		boss_hud.set_health(form_health, form_max_health)
	if announce:
		_show_text("%s · %s" % [data.get("display_name", "Boss"), form_data.get("display_name", "")], Color(Palette.YELLOW_LIGHT))

func _physics_process(delta: float) -> void:
	if is_dead or evolving:
		return
	var player := _find_player()
	if gravity_enabled:
		if not is_on_floor():
			velocity.y = minf(velocity.y + gravity * delta, 920.0)
		else:
			velocity.y = 0.0
	attack_timer = maxf(0.0, attack_timer - delta)
	state_timer = maxf(0.0, state_timer - delta)
	if player != null:
		direction = 1 if player.global_position.x > global_position.x else -1
		if not attacking and attack_timer <= 0.0 and state_timer <= 0.0:
			_perform_attack(player)
		elif state_timer <= 0.0:
			_follow_player(player, delta)
		else:
			move_and_slide()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
	_apply_contact_damage(player)
	_update_health_bar()
	_update_visual()

func _follow_player(player: Node2D, delta: float) -> void:
	var distance := absf(player.global_position.x - global_position.x)
	if distance > 100.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, 900.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	move_and_slide()

func _perform_attack(player: Node2D) -> void:
	var use_skill := attack_index % 2 == 1
	var attack := str(skills[attack_index % skills.size()]) if use_skill else basic_attack
	attack_index += 1
	attacking = true
	state_timer = 0.82 if use_skill else 0.58
	boss_animator.play_action("skill" if use_skill else "attack")
	await get_tree().create_timer(0.28 if use_skill else 0.20).timeout
	if is_dead or evolving:
		attacking = false
		return
	if use_skill:
		_execute_skill(attack, player)
	else:
		_execute_basic_attack(attack, player)
	attack_timer = attack_interval / (1.0 + float(stage - 1) * 0.24)
	_flash()
	await get_tree().create_timer(0.28).timeout
	if not is_dead and not evolving:
		attacking = false

func _execute_basic_attack(attack: String, player: Node2D) -> void:
	match attack:
		"spore_spit":
			for index in range(3):
				_spawn_projectile(global_position.angle_to_point(player.global_position) + (index - 1) * 0.18, 365.0, contact_damage - 2, global_position + Vector2(direction * 40, -10), Color("8ed45a"))
		"bee_sting":
			for index in range(3):
				_spawn_projectile(global_position.angle_to_point(player.global_position) + (index - 1) * 0.14, 405.0, contact_damage - 2, global_position + Vector2(direction * 40, -10), Color("ffe066"))
		"fan_strike":
			for wave in range(3):
				_delayed_call(wave * 0.11, func():
					for index in range(4):
						_spawn_projectile(global_position.angle_to_point(player.global_position) + (index - 1.5) * 0.20, 430.0, contact_damage - 2, global_position + Vector2(direction * 40, -10), Color("ff9ec4"))
				)
		"tendril_slam":
			for offset in [-105.0, 0.0, 105.0]:
				_spawn_telegraph("circle", player.global_position + Vector2(offset, 0), Vector2(76, 76), 0.42, Color("7ff4c9"))
				_delayed_call(0.42, func(): _spawn_root_burst(player.global_position.x + offset, Color("7ff4c9")))
		"dark_wave":
			for index in range(5):
				_spawn_projectile(global_position.angle_to_point(player.global_position) + (index - 2) * 0.13, 340.0, contact_damage - 2, global_position + Vector2(direction * 30, -12), Color("7ff4c9"))
		"talon_gust":
			global_position += Vector2(direction * 95.0, 0.0)
			for index in range(4):
				_spawn_projectile(global_position.angle_to_point(player.global_position) + (index - 1.5) * 0.15, 440.0, contact_damage - 2, global_position, Color("ffe066"))
		"stone_smash":
			_spawn_telegraph("line", global_position + Vector2(direction * 150.0, 0), Vector2(240, 54), 0.40, Color("a9d36d"))
			_delayed_call(0.40, func():
				for index in range(7):
					_spawn_projectile(global_position.angle_to_point(player.global_position) + (index - 3) * 0.16, 325.0, contact_damage - 2, global_position, Color("a9d36d"))
			)
		"rune_slash":
			for index in range(3):
				_delayed_call(index * 0.09, func():
					_spawn_projectile(global_position.angle_to_point(player.global_position), 460.0, contact_damage - 1, global_position, Color("a9d36d"))
				)
		"tail_wave":
			for wave in range(3):
				_delayed_call(wave * 0.13, func():
					for index in range(7):
						_spawn_projectile(PI + wave * 0.09 + (index - 3) * 0.12, 340.0, contact_damage - 2, global_position, Color("61d6ff"))
				)
		"great_slash":
			_spawn_telegraph("line", global_position + Vector2(direction * 170.0, 0), Vector2(300, 58), 0.36, Color("61d6ff"))
			_delayed_call(0.36, func():
				for index in range(6):
					_spawn_projectile(global_position.angle_to_point(player.global_position) + (index - 2.5) * 0.12, 470.0, contact_damage - 1, global_position, Color("fff0a6"))
			)
		_:
			_fire_projectiles(player)
	state_timer = 0.58

func _execute_skill(skill: String, player: Node2D) -> void:
	match skill:
		"pollen_cloud":
			_show_text("巨花蜂后·花粉云", Color("ffe066"))
			for index in range(7):
				var x: float = clampf(player.global_position.x + randf_range(-220.0, 220.0), global_position.x - 580.0, global_position.x + 580.0)
				_spawn_telegraph("circle", Vector2(x, 470.0), Vector2(72, 72), 0.45, Color("ffe066"))
				_delayed_call(0.45, func(): _spawn_root_burst(x, Color("ffe066")))
			state_timer = 0.82
		"bee_tide":
			_show_text("巨花蜂后·蜂群围猎", Color("ffe066"))
			_summon_minions("pollen_bee", 4)
			state_timer = 0.80
		"petal_paths":
			_show_text("花冠舞姬·花瓣迷径", Color("ff9ec4"))
			var safe := randi_range(0, 3)
			for lane in range(4):
				if lane == safe:
					continue
				_spawn_telegraph("line", Vector2(global_position.x + (lane - 1.5) * 300.0, 500.0), Vector2(180, 250), 0.58, Color("ff9ec4"))
				_delayed_call(0.58, func():
					for index in range(6):
						_spawn_projectile(PI * 0.5 + (index - 2.5) * 0.12, 385.0, contact_damage - 1, Vector2(global_position.x + (lane - 1.5) * 300.0, 280.0), Color("ff9ec4"))
				)
			state_timer = 0.90
		"royal_bees":
			_show_text("花冠舞姬·王室蜂舞", Color("ff9ec4"))
			_summon_minions("pollen_bee", 2)
			_fire_radial_projectiles(9, 330.0, contact_damage - 2, global_position, Color("ff9ec4"))
			state_timer = 0.78
		"spore_pool":
			_show_text("巨孢菌龟·孢子池", Color("8ed45a"))
			for offset in [-160.0, 0.0, 160.0]:
				_spawn_telegraph("circle", player.global_position + Vector2(offset, 0), Vector2(96, 96), 0.52, Color("8ed45a"))
				_delayed_call(0.52, func(): _spawn_root_burst(player.global_position.x + offset, Color("8ed45a")))
			state_timer = 0.84
		"shell_roll":
			_show_text("巨孢菌龟·菌壳冲撞", Color("8ed45a"))
			velocity.x = direction * charge_speed * 1.25
			state_timer = 0.68
		"barrel_spill":
			_show_text("酒馆守门人·孢子酒桶", Color("8ed45a"))
			for wave in range(5):
				_delayed_call(wave * 0.08, func(): _spawn_projectile(direction * PI * 0.5 + randf_range(-0.18, 0.18), 320.0, contact_damage - 1, global_position + Vector2(direction * 40, -10), Color("8ed45a")))
			state_timer = 0.74
		"cap_bulwark":
			_show_text("酒馆守门人·菌盖壁垒", Color("8ed45a"))
			for offset in [-115.0, 0.0, 115.0]:
				_spawn_telegraph("circle", global_position + Vector2(offset, -10), Vector2(84, 84), 0.50, Color("f2d7a6"))
				_delayed_call(0.50, func(): _fire_radial_projectiles(5, 290.0, contact_damage - 2, global_position + Vector2(offset, -10), Color("8ed45a")))
			state_timer = 0.82
		"root_veins":
			_show_text("根须巢母·根刺地脉", Color("7ff4c9"))
			for index in range(5):
				var x: float = player.global_position.x + (index - 2) * 105.0
				_spawn_telegraph("circle", Vector2(x, 480.0), Vector2(70, 70), 0.35 + index * 0.13, Color("7ff4c9"))
				_delayed_call(0.35 + index * 0.13, func(): _spawn_root_burst(x, Color("7ff4c9")))
			state_timer = 0.92
		"dark_mist":
			_show_text("根须巢母·暗息幕帘", Color("7ff4c9"))
			for index in range(9):
				_spawn_projectile(PI * 0.5 + (index - 4) * 0.16, 265.0, contact_damage - 2, global_position + Vector2(0, -10), Color("7ff4c9"))
			state_timer = 0.78
		"whisper_judgment":
			_show_text("低语主教·低语审判", Color("7ff4c9"))
			for index in range(3):
				var point: Vector2 = player.global_position + Vector2((index - 1) * 130.0, -20.0)
				_spawn_telegraph("circle", point, Vector2(68, 68), 0.55, Color("7ff4c9"))
				_delayed_call(0.55, func(): _fire_radial_projectiles(5, 315.0, contact_damage - 1, point, Color("7ff4c9")))
			state_timer = 0.86
		"root_prison":
			_show_text("低语主教·根牢", Color("7ff4c9"))
			_spawn_telegraph("circle", player.global_position, Vector2(105, 105), 0.62, Color("7ff4c9"))
			_delayed_call(0.62, func():
				for offset in [-70.0, 0.0, 70.0]:
					_spawn_root_burst(player.global_position.x + offset, Color("7ff4c9"))
			)
			state_timer = 0.90
		"stone_feathers":
			_show_text("岩翼石鹰·落石羽", Color("ffe066"))
			for index in range(8):
				var x: float = clampf(player.global_position.x + randf_range(-250.0, 250.0), global_position.x - 620.0, global_position.x + 620.0)
				_spawn_telegraph("circle", Vector2(x, 485.0), Vector2(58, 58), 0.38 + index * 0.07, Color("ffe066"))
				_delayed_call(0.38 + index * 0.07, func(): _spawn_falling_projectile(x, 430.0 + stage * 32.0, contact_damage - 2))
			state_timer = 0.90
		"hawk_roar":
			_show_text("岩翼石鹰·鹰啸冲击", Color("ffe066"))
			_spawn_telegraph("line", global_position + Vector2(direction * 180.0, 0), Vector2(330, 72), 0.45, Color("ffe066"))
			_delayed_call(0.45, func():
				for index in range(10):
					_spawn_projectile(0.0 if direction > 0 else PI + (index - 5) * 0.045, 395.0, contact_damage - 2, global_position, Color("ffe066"))
			)
			state_timer = 0.82
		"arrow_rain":
			_show_text("风哨猎手·风哨箭雨", Color("ffe066"))
			for wave in range(3):
				_delayed_call(wave * 0.24, func():
					for index in range(6):
						var x: float = player.global_position.x + (index - 2.5) * 110.0 + wave * 45.0
						_spawn_falling_projectile(x, 465.0, contact_damage - 2)
				)
			state_timer = 0.88
		"dive_line":
			_show_text("风哨猎手·鹰啸俯冲", Color("ffe066"))
			_spawn_telegraph("line", global_position + Vector2(direction * 190.0, 0), Vector2(350, 64), 0.48, Color("ffe066"))
			_delayed_call(0.48, func(): velocity.x = direction * charge_speed * 1.5)
			state_timer = 0.64
		"chain_burst":
			_show_text("苔石守卫像·苔石锁链", Color("a9d36d"))
			for index in range(4):
				_spawn_projectile(TAU * float(index) / 4.0 + PI * 0.25, 340.0, contact_damage - 2, global_position, Color("a9d36d"))
			state_timer = 0.72
		"tomb_drop":
			_show_text("苔石守卫像·石棺压顶", Color("a9d36d"))
			for index in range(6):
				var x: float = clampf(player.global_position.x + randf_range(-210.0, 210.0), global_position.x - 640.0, global_position.x + 640.0)
				_spawn_telegraph("line", Vector2(x, 500.0), Vector2(65, 180), 0.50 + index * 0.09, Color("a9d36d"))
				_delayed_call(0.50 + index * 0.09, func(): _spawn_falling_projectile(x, 475.0, contact_damage - 1))
			state_timer = 0.94
		"board_pulse":
			_show_text("符文贤者·符文棋盘", Color("a9d36d"))
			for index in range(8):
				if index % 2 == 0:
					continue
				var x: float = global_position.x - 330.0 + (index % 4) * 220.0
				var y: float = 420.0 + int(index / 4.0) * 105.0
				_spawn_telegraph("line", Vector2(x, y), Vector2(150, 78), 0.60, Color("a9d36d"))
				_delayed_call(0.60, func(): _spawn_root_burst(x, Color("a9d36d")))
			state_timer = 0.90
		"rune_chain":
			_show_text("符文贤者·贤者锁链", Color("a9d36d"))
			for index in range(4):
				var point: Vector2 = player.global_position + Vector2.from_angle(TAU * float(index) / 4.0) * 105.0
				_spawn_projectile(global_position.angle_to_point(point), 385.0, contact_damage - 1, global_position, Color("a9d36d"))
			state_timer = 0.74
		"void_whirl":
			_show_text("虚空星鲸·虚空涡流", Color("61d6ff"))
			for index in range(15):
				_delayed_call(index * 0.05, func(): _spawn_projectile(TAU * float(index) / 15.0, 310.0, contact_damage - 2, global_position, Color("61d6ff")))
			state_timer = 0.92
		"star_tide":
			_show_text("虚空星鲸·星鲸下潜", Color("61d6ff"))
			_spawn_telegraph("line", player.global_position, Vector2(330, 170), 0.62, Color("61d6ff"))
			_delayed_call(0.62, func():
				for index in range(9):
					_spawn_falling_projectile(player.global_position.x + (index - 4) * 48.0, 500.0, contact_damage - 1)
			)
			state_timer = 0.88
		"rift_blade":
			_show_text("星门审判者·星门裂隙", Color("61d6ff"))
			for side in [-1.0, 1.0]:
				_spawn_telegraph("line", global_position + Vector2(side * 210.0, -10), Vector2(70, 230), 0.55, Color("61d6ff"))
				_delayed_call(0.55, func():
					for index in range(5):
						_spawn_projectile(0.0 if side > 0 else PI + (index - 2) * 0.07, 430.0, contact_damage - 1, global_position + Vector2(side * 180.0, -10), Color("61d6ff"))
				)
			state_timer = 0.80
		"judgment_pillars":
			_show_text("星门审判者·天穹审判", Color("61d6ff"))
			var safe := randi_range(0, 2)
			for column in range(3):
				if column == safe:
					continue
				_spawn_telegraph("line", Vector2(player.global_position.x + (column - 1) * 240.0, 500.0), Vector2(110, 250), 0.72, Color("fff0a6"))
				_delayed_call(0.72, func(): _spawn_falling_projectile(player.global_position.x + (column - 1) * 240.0, 510.0, contact_damage))
			state_timer = 0.96
	attack_timer = attack_interval / (1.0 + float(stage - 1) * 0.24)

func _summon_minions(kind: String, desired_count: int, message := "召唤援军", show_message := true) -> void:
	var existing := get_tree().get_nodes_in_group("boss_minions").size()
	var count := mini(desired_count, maxi(0, 8 - existing))
	for index in range(count):
		var minion := ENEMY_SCENE.instantiate()
		minion.set("enemy_kind", kind)
		minion.set("is_boss_minion", true)
		minion.set_meta("region_id", region_id)
		minion.set_meta("difficulty", int(WORLD_MAPS.region(region_id).get("difficulty", 1)))
		minion.add_to_group("boss_minions")
		get_parent().add_child(minion)
		var angle := TAU * (float(index) + 0.28) / float(maxi(1, count))
		var radius := 185.0 + 45.0 * float(index % 2)
		minion.global_position = global_position + Vector2(cos(angle) * radius, -36.0 + sin(angle) * 26.0)
		minion.set("spawn_grace_timer", 0.48)
		PixelStyleManager.apply_enemy_style(minion)
	if show_message:
		_show_text(message, Color(Palette.WHITE))

func _fire_projectiles(player: Node2D, projectile_count := 4, speed := 380.0) -> void:
	var base_angle := global_position.angle_to_point(player.global_position)
	for index in range(projectile_count):
		var angle := base_angle + (float(index) - float(projectile_count - 1) * 0.5) * 0.20
		_spawn_projectile(angle, speed)

func _fire_radial_projectiles(count: int, speed: float, damage: int, origin: Vector2, color: Color) -> void:
	for index in range(count):
		_spawn_projectile(TAU * float(index) / float(count), speed, damage, origin, color)

func _spawn_projectile(angle: float, speed: float, damage := 8, origin := Vector2.ZERO, color := Color.WHITE) -> void:
	var projectile := Area2D.new()
	projectile.name = "BossProjectile"
	projectile.add_to_group("boss_projectile")
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
	projectile.set("speed", speed)
	projectile.set("direction", Vector2.from_angle(angle))
	projectile.set("damage", damage)
	projectile.set("lifetime", 2.5)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(18, 18)
	shape.shape = rectangle
	projectile.add_child(shape)
	_add_boss_projectile_visual(projectile, body_color.lightened(0.18) if color == Color.WHITE else color, "petal" if color == Color("f27a62") or color == Color("ff9ec4") else "pollen", angle)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(direction * 45.0, -10.0) if origin == Vector2.ZERO else origin

func _spawn_falling_projectile(x_position: float, speed: float, damage: int, color := Color.WHITE) -> void:
	var projectile := Area2D.new()
	projectile.add_to_group("boss_projectile")
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
	projectile.set("direction", Vector2.DOWN)
	projectile.set("speed", speed)
	projectile.set("damage", damage)
	projectile.set("lifetime", 1.35)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16, 22)
	shape.shape = rectangle
	projectile.add_child(shape)
	_add_boss_projectile_visual(projectile, body_color.lightened(0.18) if color == Color.WHITE else color, "petal" if color == Color("f27a62") or color == Color("ff9ec4") else "pollen", PI * 0.5)
	get_parent().add_child(projectile)
	projectile.global_position = Vector2(x_position, 120.0)

func _spawn_root_burst(x_position: float, color := Color.WHITE) -> void:
	for offset in [-32.0, 0.0, 32.0]:
		var projectile := Area2D.new()
		projectile.add_to_group("boss_projectile")
		projectile.collision_layer = 0
		projectile.collision_mask = 1
		projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
		projectile.set("speed", 510.0)
		projectile.set("direction", Vector2.UP)
		projectile.set("damage", maxi(5, contact_damage - 4))
		projectile.set("lifetime", 0.52)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(16, 32)
		shape.shape = rectangle
		projectile.add_child(shape)
		_add_boss_projectile_visual(projectile, body_color.darkened(0.18) if color == Color.WHITE else color, "petal" if color == Color("f27a62") or color == Color("ff9ec4") else "pollen", -PI * 0.5)
		get_parent().add_child(projectile)
		projectile.global_position = Vector2(x_position + offset, 585.0)

func _add_boss_projectile_visual(projectile: Area2D, color: Color, kind: String, rotation := 0.0) -> void:
	var visual := Node2D.new()
	visual.name = "PixelProjectile"
	visual.rotation = rotation
	if kind == "petal":
		var outline := Polygon2D.new()
		outline.polygon = PackedVector2Array([Vector2(-13, 0), Vector2(-4, -8), Vector2(10, -5), Vector2(15, 0), Vector2(7, 7), Vector2(-5, 8)])
		outline.color = Color("4a2418")
		visual.add_child(outline)
		var petal := Polygon2D.new()
		petal.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(-3, -5), Vector2(9, -3), Vector2(11, 0), Vector2(5, 4), Vector2(-4, 5)])
		petal.color = color
		visual.add_child(petal)
		var vein := Line2D.new()
		vein.points = PackedVector2Array([Vector2(-5, 1), Vector2(7, -1)])
		vein.width = 2.0
		vein.default_color = Color("ffd08a")
		visual.add_child(vein)
	else:
		var outline := Polygon2D.new()
		outline.polygon = PackedVector2Array([Vector2(-11, 0), Vector2(-6, -8), Vector2(5, -10), Vector2(12, -3), Vector2(10, 7), Vector2(1, 11), Vector2(-9, 7)])
		outline.color = Color("4a2418")
		visual.add_child(outline)
		var pollen := Polygon2D.new()
		pollen.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(-4, -5), Vector2(4, -6), Vector2(8, -2), Vector2(7, 5), Vector2(0, 7), Vector2(-6, 4)])
		pollen.color = color
		visual.add_child(pollen)
		var core := Polygon2D.new()
		core.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(4, 3), Vector2(-2, 4)])
		core.color = Color("fff0b0")
		visual.add_child(core)
	var trail := Line2D.new()
	trail.points = PackedVector2Array([Vector2(-16, 0), Vector2(-27, 0)])
	trail.width = 3.0
	trail.default_color = Color(color, 0.42)
	visual.add_child(trail)
	projectile.add_child(visual)

func _spawn_telegraph(kind: String, point: Vector2, telegraph_size: Vector2, duration: float, color: Color) -> void:
	var telegraph := Node2D.new()
	telegraph.set_script(TELEGRAPH)
	get_parent().add_child(telegraph)
	telegraph.global_position = point
	telegraph.setup(kind, telegraph_size, duration, color)

func _delayed_call(delay: float, action: Callable) -> void:
	get_tree().create_timer(delay).timeout.connect(func():
		if is_instance_valid(self) and not is_dead:
			action.call()
	)

func _teleport_away(player: Node2D) -> void:
	var side := -1.0 if player.global_position.x > global_position.x else 1.0
	global_position += Vector2(side * 240.0, -20.0)
	_create_stage_ring()

func _apply_contact_damage(player: Node2D) -> void:
	if player == null or is_dead or evolving:
		return
	var damage_area := get_node_or_null("DamageArea") as Area2D
	if damage_area == null:
		return
	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.call("take_damage", contact_damage, global_position)

func take_damage(amount: int, source_position := Vector2.ZERO) -> void:
	if is_dead or evolving:
		return
	form_health = maxi(0, form_health - amount)
	AudioManager.play_sfx("hit")
	boss_animator.play_state("hurt")
	_flash()
	_update_health_bar()
	if form_health <= 0:
		if form_index >= forms.size() - 1:
			_defeat()
		else:
			_begin_evolution()

func apply_knockback(_source_position := Vector2.ZERO) -> void:
	pass

func _begin_evolution() -> void:
	if evolving or is_dead:
		return
	evolving = true
	attacking = false
	velocity = Vector2.ZERO
	_cleanup_minions()
	_cleanup_projectiles()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	boss_animator.play_action("evolve", "idle")
	boss_hud.show_evolution("进化")
	_show_text("区域Boss · 觉醒", Color(Palette.YELLOW_LIGHT))
	await get_tree().create_timer(1.35).timeout
	_apply_form(form_index + 1, true)
	set_deferred("collision_layer", 4)
	set_deferred("collision_mask", 18)
	await get_tree().create_timer(0.25).timeout
	boss_hud.hide_evolution()
	evolving = false
	attacking = false
	attack_timer = 1.0

func _defeat() -> void:
	if is_dead:
		return
	is_dead = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	velocity = Vector2.ZERO
	_cleanup_minions()
	_cleanup_projectiles()
	GameState.grant_boss_rewards(region_id)
	AudioManager.play_sfx("enemy_death")
	boss_animator.play_death()
	_show_text("守卫陨落", Palette.YELLOW_LIGHT)
	boss_hud.visible = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.75)
	tween.tween_callback(queue_free)

func _cleanup_minions() -> void:
	for minion in get_tree().get_nodes_in_group("boss_minions"):
		minion.queue_free()

func _cleanup_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("boss_projectile"):
		projectile.queue_free()

func _update_health_bar() -> void:
	if boss_hud:
		boss_hud.set_health(form_health, form_max_health)

func _update_hud_visibility(_zone_id := "") -> void:
	var is_current := GameState.current_map_id == map_id or GameState.current_zone_id == map_id
	if boss_hud:
		boss_hud.visible = is_current and not is_dead

func _update_visual() -> void:
	if boss_animator:
		boss_animator.stage = stage
		boss_animator.direction = direction
	if ring_effect:
		ring_effect.rotation += get_physics_process_delta_time() * 1.5

func _flash() -> void:
	modulate = Color(2.2, 2.2, 2.2)
	get_tree().create_timer(0.07).timeout.connect(func(): modulate = Color.WHITE)

func _create_stage_ring() -> void:
	ring_effect = Line2D.new()
	ring_effect.closed = true
	ring_effect.width = 4.0
	ring_effect.default_color = body_color
	ring_effect.z_index = 90
	var points := PackedVector2Array()
	for index in range(18):
		points.append(Vector2.from_angle(TAU * float(index) / 18.0) * 82.0)
	ring_effect.points = points
	add_child(ring_effect)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring_effect, "scale", Vector2(2.8, 2.0), 0.45)
	tween.tween_property(ring_effect, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(ring_effect.queue_free)

func _show_text(text_value: String, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 190
	add_child(label)
	label.position = Vector2(-55, -112)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 36.0, 0.65)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(label.queue_free)

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if players.size() > 0 else null
