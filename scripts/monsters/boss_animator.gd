extends AnimatedSprite2D

var region_id := "meadow"
var stage := 1
var direction := -1
var visual_state := "idle"
var aura: Sprite2D

func _ready() -> void:
	name = "BossAnimator"
	sprite_frames = PixelStyleManager.make_boss_frames(region_id)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2(2.1, 2.1)
	z_index = 10
	_build_aura()
	animation_finished.connect(_on_animation_finished)
	play("idle")

func play_state(state: String) -> void:
	if visual_state == "death" or not sprite_frames.has_animation(state):
		return
	visual_state = state
	var looping := state in ["idle", "move"]
	if looping or not is_playing() or animation != state:
		play(state)

func play_action(state: String, next_state := "idle") -> void:
	if visual_state == "death":
		return
	visual_state = state
	play(state)
	var frames := maxi(1, sprite_frames.get_frame_count(state))
	var duration := frames / maxf(1.0, sprite_frames.get_animation_speed(state))
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(self) and visual_state == state:
			visual_state = next_state
			play(next_state)
	)

func play_death() -> void:
	visual_state = "death"
	play("death")

func _process(_delta: float) -> void:
	flip_h = direction > 0
	if aura:
		aura.flip_h = flip_h
		var pulse := 0.0
		if visual_state == "skill":
			pulse = 0.24 + sin(Time.get_ticks_msec() * 0.02) * 0.05
		elif visual_state == "attack":
			pulse = 0.18
		aura.modulate = Color(Color("ff6a70"), 0.0 + float(stage - 1) * 0.11 + pulse)
		aura.scale = Vector2(2.14 + stage * 0.03 + pulse * 0.18, 2.14 + stage * 0.03 + pulse * 0.18)
	if visual_state in ["idle", "move"] and not is_playing():
		play(visual_state)

func _on_animation_finished() -> void:
	if visual_state in ["attack", "skill", "hurt"]:
		visual_state = "idle"
		play("idle")

func _build_aura() -> void:
	aura = Sprite2D.new()
	aura.name = "StageAura"
	aura.texture = sprite_frames.get_frame_texture("idle", 0)
	aura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	aura.modulate = Color(Color("ff6a70"), 0.0)
	aura.z_index = 8
	add_child(aura)
