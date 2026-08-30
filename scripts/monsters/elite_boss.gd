extends CharacterBody2D

const Palette := preload("res://scripts/systems/pixel_palette.gd")
const ENEMY_SCENE := preload("res://scenes/monsters/basic_enemy.tscn")
const WORLD_MAPS := preload("res://scripts/world/world_maps.gd")
const BOSS_ANIMATOR := preload("res://scripts/monsters/boss_animator.gd")

var region_id := "meadow"
var data := {}
var health := 380
var max_health := 380
var stage := 1
var stage_count := 2
var direction := -1
var attack_timer := 2.0
var state_timer := 0.0
var is_dead := false
var attacking := false
var gravity := 1550.0
var attack_index := 0
var body_visual: ColorRect
var health_fill: ColorRect
var boss_animator: AnimatedSprite2D
var ring_effect: Line2D
var gravity_enabled := true
var contact_damage := 14
var move_speed := 110.0
var charge_speed := 430.0
var attack_interval := 1.8
var body_color := Color.WHITE
var attacks: Array[String] = ["charge"]
var skills: Array[String] = ["pollen_swarm"]
var basic_attack := "charge"
var skill_index := 0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("elite_boss")
	_load_data()
	_build_body()
	_build_pixel_sprite()
	health = max_health

func _load_data() -> void:
	var maps := load("res://scripts/world/world_maps.gd")
	var region: Dictionary = maps.REGIONS.get(region_id, {})
	var boss: Dictionary = region.get("boss", {})
	data = boss
	max_health = int(boss.get("max_health", 380))
	stage_count = int(boss.get("stage_count", 2))
	contact_damage = int(boss.get("contact_damage", 14))
	move_speed = float(boss.get("move_speed", 110.0))
	charge_speed = float(boss.get("charge_speed", 430.0))
	attack_interval = float(boss.get("attack_interval", 1.8))
	body_color = Color(str(boss.get("body_color", Palette.YELLOW)))
	attacks.clear()
	for attack in boss.get("attacks", []):
		attacks.append(str(attack))
	skills.clear()
	for skill in boss.get("skills", []):
		skills.append(str(skill))
	if skills.is_empty():
		skills.append("pollen_swarm")
	basic_attack = str(boss.get("basic_attack", "charge"))

func _build_body() -> void:
	var size: Vector2 = Vector2(84, 104)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	add_child(shape)
	body_visual = ColorRect.new()
	body_visual.name = "Visual"
	body_visual.position = -size * 0.5
	body_visual.size = size
	body_visual.color = body_color
	body_visual.visible = false
	add_child(body_visual)
	var damage_area := Area2D.new()
	damage_area.name = "DamageArea"
	damage_area.collision_layer = 0
	damage_area.collision_mask = 1
	var damage_shape := CollisionShape2D.new()
	var damage_rectangle := RectangleShape2D.new()
	damage_rectangle.size = size + Vector2(12, 8)
	damage_shape.shape = damage_rectangle
	damage_area.add_child(damage_shape)
	add_child(damage_area)
	var bar_background := ColorRect.new()
	bar_background.position = Vector2(-66, -102)
	bar_background.size = Vector2(132, 9)
	bar_background.color = Color(0, 0, 0, 0.68)
	bar_background.z_index = 20
	add_child(bar_background)
	health_fill = ColorRect.new()
	health_fill.position = Vector2(-64, -101)
	health_fill.size = Vector2(128, 7)
	health_fill.color = Palette.RED
	health_fill.z_index = 21
	add_child(health_fill)
	_update_health_bar()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var player := _find_player()
	_update_stage()
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

func _update_stage() -> void:
	var ratio := float(health) / float(max_health)
	var next_stage := 1
	if stage_count >= 3:
		next_stage = 3 if ratio <= 0.33 else (2 if ratio <= 0.66 else 1)
	elif ratio <= 0.5:
		next_stage = 2
	if next_stage != stage:
		stage = next_stage
		_show_text("阶段 %d" % stage, Palette.YELLOW_LIGHT)
		_create_stage_ring()
		attack_timer = maxf(attack_timer, 0.55)

func _follow_player(player: Node2D, delta: float) -> void:
	var distance := absf(player.global_position.x - global_position.x)
	if distance > 90.0:
		velocity.x = move_toward(velocity.x, direction * move_speed * (1.0 + float(stage - 1) * 0.18), 900.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	move_and_slide()

func _perform_attack(player: Node2D) -> void:
	var use_skill := skill_index % 2 == 1
	var attack := str(skills[skill_index % skills.size()]) if use_skill else basic_attack
	attack_index += 1
	skill_index += 1
	attacking = true
	state_timer = 0.78 if use_skill else 0.55
	boss_animator.play_action("skill" if use_skill else "attack")
	await get_tree().create_timer(0.26 if use_skill else 0.20).timeout
	if is_dead:
		attacking = false
		return
	if use_skill:
		_execute_skill(attack, player)
	else:
		_execute_basic_attack(attack, player)
	attack_timer = attack_interval / (1.0 + float(stage - 1) * 0.28)
	_flash()
	await get_tree().create_timer(0.30).timeout
	if not is_dead:
		attacking = false

func _execute_basic_attack(attack: String, player: Node2D) -> void:
	match attack:
		"projectile":
			_fire_projectiles(player)
			state_timer = 0.55
		"ambush":
			_spawn_root_burst(player.global_position.x)
			state_timer = 0.55
		_:
			velocity.x = direction * charge_speed * (1.0 + float(stage - 1) * 0.16)
			state_timer = 0.45
	attack_timer = attack_interval / (1.0 + float(stage - 1) * 0.28)

func _execute_skill(skill: String, player: Node2D) -> void:
	match skill:
		"pollen_swarm":
			_show_text("花粉女王·花粉蜂群", Palette.YELLOW_LIGHT)
			_summon_minions("pollen_bee", 4)
			_fire_radial_projectiles(8, 300.0, maxi(6, contact_damage - 5), Color("ffe066"))
			state_timer = 0.78
		"royal_charge":
			_show_text("花粉女王·皇家冲锋", Palette.YELLOW_LIGHT)
			velocity.x = direction * charge_speed * (1.35 + float(stage - 1) * 0.18)
			state_timer = 0.52
		"spore_burst":
			_show_text("巨菇守卫·孢子爆发", Palette.YELLOW_LIGHT)
			_fire_radial_projectiles(14, 275.0, maxi(7, contact_damage - 4), Color("8ed45a"))
			state_timer = 0.76
		"guard_charge":
			_show_text("巨菇守卫·菌甲冲锋", Palette.YELLOW_LIGHT)
			velocity.x = direction * charge_speed * (1.25 + float(stage - 1) * 0.20)
			state_timer = 0.54
		"root_prison":
			_show_text("低语根王·根须囚牢", Color("7ff4c9"))
			for offset in [-110.0, 0.0, 110.0]:
				_spawn_root_burst(player.global_position.x + offset)
			state_timer = 0.80
		"spore_wave":
			_show_text("低语根王·荧光孢子", Color("7ff4c9"))
			_fire_radial_projectiles(12, 320.0, maxi(8, contact_damage - 4), Color("7ff4c9"))
			state_timer = 0.76
		"rock_rain":
			_show_text("峡谷岩鹰·落石风暴", Palette.YELLOW_LIGHT)
			for index in range(8):
				var x: float = clampf(player.global_position.x + randf_range(-230.0, 230.0), global_position.x - 640.0, global_position.x + 640.0)
				_spawn_falling_projectile(x, 430.0 + stage * 35.0, maxi(8, contact_damage - 4))
			state_timer = 0.80
		"gale_dive":
			_show_text("峡谷岩鹰·风啸俯冲", Palette.YELLOW_LIGHT)
			global_position += Vector2(direction * 120.0, -45.0)
			velocity.x = direction * charge_speed * (1.55 + float(stage - 1) * 0.18)
			state_timer = 0.58
		"rune_ring":
			_show_text("符文石像·符文环阵", Color("a9d36d"))
			_teleport_away(player)
			_fire_radial_projectiles(16, 330.0, maxi(9, contact_damage - 4), Color("a9d36d"))
			state_timer = 0.82
		"blink_volley":
			_show_text("符文石像·闪现弹幕", Color("a9d36d"))
			_teleport_away(player)
			_fire_projectiles(player, 6, 415.0 + stage * 30.0)
			state_timer = 0.72
		"star_gate":
			_show_text("天穹守门人·星门开启", Color("61d6ff"))
			_fire_radial_projectiles(18, 350.0, maxi(10, contact_damage - 4), Color("61d6ff"))
			_summon_minions("star_wisp", 2, "天穹守门人·星浮灵", false)
			state_timer = 0.86
		"void_rain":
			_show_text("天穹守门人·虚空之雨", Color("61d6ff"))
			for index in range(10):
				var x: float = clampf(player.global_position.x + randf_range(-280.0, 280.0), global_position.x - 680.0, global_position.x + 680.0)
				_spawn_falling_projectile(x, 465.0 + stage * 35.0, maxi(10, contact_damage - 4))
			state_timer = 0.84
	attack_timer = attack_interval / (1.0 + float(stage - 1) * 0.28)
	attack_timer = attack_interval / (1.0 + float(stage - 1) * 0.28)

func _summon_minions(kind: String, desired_count: int, message := "召唤援军", show_message := true) -> void:
	var existing := get_tree().get_nodes_in_group("boss_minions").size()
	var count := mini(desired_count, maxi(0, 8 - existing))
	for index in range(count):
		var minion := ENEMY_SCENE.instantiate()
		minion.set("enemy_kind", kind)
		minion.set_meta("region_id", region_id)
		minion.set_meta("difficulty", int(WORLD_MAPS.region(region_id).get("difficulty", 1)))
		minion.add_to_group("boss_minions")
		get_parent().add_child(minion)
		minion.global_position = global_position + Vector2(-165.0 + index * 110.0, -35.0)
		minion.set("spawn_grace_timer", 0.38)
	if show_message:
		_show_text(message, Palette.WHITE)

func _fire_projectiles(player: Node2D, projectile_count := 4, speed := 380.0) -> void:
	var base_angle := global_position.angle_to_point(player.global_position)
	for index in range(projectile_count):
		var angle := base_angle + (float(index) - float(projectile_count - 1) * 0.5) * 0.20
		_spawn_projectile(angle, speed)

func _fire_radial_projectiles(count: int, speed: float, damage: int, color: Color) -> void:
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		_spawn_projectile(angle, speed, damage, global_position, color)

func _spawn_falling_projectile(x_position: float, speed: float, damage: int) -> void:
	for index in range(1):
		var projectile := Area2D.new()
		projectile.collision_layer = 0
		projectile.collision_mask = 1
		projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
		projectile.set("direction", Vector2.DOWN)
		projectile.set("speed", speed)
		projectile.set("damage", damage)
		projectile.set("lifetime", 1.35)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(18, 24)
		shape.shape = rectangle
		projectile.add_child(shape)
		var visual := ColorRect.new()
		visual.position = Vector2(-8, -11)
		visual.size = Vector2(16, 22)
		visual.color = body_color.lightened(0.18)
		projectile.add_child(visual)
		get_parent().add_child(projectile)
		projectile.global_position = Vector2(x_position, 120.0)

func _spawn_projectile(angle: float, speed: float, damage := 8, origin := Vector2.ZERO, color := Color.WHITE) -> void:
	var projectile := Area2D.new()
	projectile.name = "BossProjectile"
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
	projectile.set("speed", speed)
	projectile.set("direction", Vector2.from_angle(angle))
	projectile.set("damage", damage)
	projectile.set("lifetime", 2.4)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20, 20)
	shape.shape = rectangle
	projectile.add_child(shape)
	var visual := ColorRect.new()
	visual.position = Vector2(-8, -8)
	visual.size = Vector2(16, 16)
	visual.color = body_color.lightened(0.18) if color == Color.WHITE else color
	projectile.add_child(visual)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(direction * 50.0, -10.0) if origin == Vector2.ZERO else origin

func _spawn_root_burst(x_position: float) -> void:
	for offset in [-90.0, 0.0, 90.0]:
		var projectile := Area2D.new()
		projectile.collision_layer = 0
		projectile.collision_mask = 1
		projectile.set_script(load("res://scripts/monsters/enemy_projectile.gd"))
		projectile.set("speed", 520.0)
		projectile.set("direction", Vector2.UP)
		projectile.set("damage", maxi(4, contact_damage - 5))
		projectile.set("lifetime", 0.55)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(18, 34)
		shape.shape = rectangle
		projectile.add_child(shape)
		var visual := ColorRect.new()
		visual.position = Vector2(-8, -16)
		visual.size = Vector2(16, 32)
		visual.color = body_color.darkened(0.18)
		projectile.add_child(visual)
		projectile.global_position = Vector2(x_position + offset, 580.0)
		get_parent().add_child(projectile)

func _teleport_away(player: Node2D) -> void:
	var side := -1.0 if player.global_position.x > global_position.x else 1.0
	global_position += Vector2(side * 240.0, -20.0)
	_create_stage_ring()

func _apply_contact_damage(player: Node2D) -> void:
	if player == null or is_dead:
		return
	var damage_area := get_node_or_null("DamageArea") as Area2D
	if damage_area == null:
		return
	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.call("take_damage", contact_damage, global_position)

func take_damage(amount: int, source_position := Vector2.ZERO) -> void:
	if is_dead:
		return
	health = maxi(0, health - amount)
	AudioManager.play_sfx("hit")
	boss_animator.play_state("hurt")
	_flash()
	_update_health_bar()
	if health <= 0:
		_defeat()

func apply_knockback(_source_position: Vector2) -> void:
	pass

func _defeat() -> void:
	if is_dead:
		return
	is_dead = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	velocity = Vector2.ZERO
	_cleanup_minions()
	GameState.grant_boss_rewards(region_id)
	AudioManager.play_sfx("enemy_death")
	boss_animator.play_death()
	_show_text("守卫陨落", Palette.YELLOW_LIGHT)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.65)
	tween.tween_callback(queue_free)

func _cleanup_minions() -> void:
	for minion in get_tree().get_nodes_in_group("boss_minions"):
		minion.queue_free()

func _update_health_bar() -> void:
	if health_fill:
		health_fill.size.x = 128.0 * clampf(float(health) / float(max_health), 0.0, 1.0)

func _update_visual() -> void:
	if boss_animator:
		boss_animator.stage = stage
		boss_animator.direction = direction
	if ring_effect:
		ring_effect.rotation += get_physics_process_delta_time() * 1.5

func _flash() -> void:
	modulate = Color(2.2, 2.2, 2.2)
	get_tree().create_timer(0.07).timeout.connect(func(): modulate = Color.WHITE)

func _build_pixel_sprite() -> void:
	boss_animator = AnimatedSprite2D.new()
	boss_animator.name = "BossAnimator"
	boss_animator.set_script(BOSS_ANIMATOR)
	boss_animator.region_id = region_id
	add_child(boss_animator)

func _create_stage_ring() -> void:
	ring_effect = Line2D.new()
	ring_effect.closed = true
	ring_effect.width = 4.0
	ring_effect.default_color = body_color
	ring_effect.z_index = 90
	var points := PackedVector2Array()
	for index in range(18):
		points.append(Vector2.from_angle(TAU * float(index) / 18.0) * 78.0)
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
	label.position = Vector2(-48, -98)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 36.0, 0.65)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(label.queue_free)

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if players.size() > 0 else null
