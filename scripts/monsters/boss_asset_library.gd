class_name BossAssetLibrary
extends RefCounted

const BOSS_FRAME_STATES := {
	"idle": [6, 8.0, true],
	"move": [6, 10.0, true],
	"attack": [7, 14.0, false],
	"skill": [8, 12.0, false],
	"hurt": [3, 14.0, false],
	"evolve": [8, 5.0, false],
	"death": [6, 8.0, false],
}

# Optional per-skill clips: loaded only when every frame file exists.
# Do not put these in BOSS_FRAME_STATES — missing files would null the whole form.
const OPTIONAL_ANIMATIONS := {
	"skill_bees": [8, 12.0, false],
	"skill_barrel_spill": [8, 12.0, false],
	"skill_cap_bulwark": [8, 12.0, false],
}

static func load_frames(resource_prefix: String, form_id: String) -> SpriteFrames:
	var base_path := "res://assets/sprites/monsters/%s/%s_%s" % [resource_prefix, resource_prefix, form_id]
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for state in BOSS_FRAME_STATES:
		var settings: Array = BOSS_FRAME_STATES[state]
		frames.add_animation(state)
		frames.set_animation_speed(state, float(settings[1]))
		frames.set_animation_loop(state, bool(settings[2]))
		for index in range(int(settings[0])):
			var texture_path := "%s_%s_%02d.png" % [base_path, state, index]
			if not FileAccess.file_exists(ProjectSettings.globalize_path(texture_path)):
				return null
			var image := Image.new()
			if image.load(ProjectSettings.globalize_path(texture_path)) != OK:
				return null
			frames.add_frame(state, ImageTexture.create_from_image(image))
	for state in OPTIONAL_ANIMATIONS:
		_try_add_optional_animation(frames, base_path, state, OPTIONAL_ANIMATIONS[state])
	return frames

static func _try_add_optional_animation(frames: SpriteFrames, base_path: String, state: String, settings: Array) -> void:
	var count := int(settings[0])
	var paths: Array[String] = []
	for index in range(count):
		var texture_path := "%s_%s_%02d.png" % [base_path, state, index]
		if not FileAccess.file_exists(ProjectSettings.globalize_path(texture_path)):
			return
		paths.append(texture_path)
	if frames.has_animation(state):
		frames.remove_animation(state)
	frames.add_animation(state)
	frames.set_animation_speed(state, float(settings[1]))
	frames.set_animation_loop(state, bool(settings[2]))
	for texture_path in paths:
		var image := Image.new()
		if image.load(ProjectSettings.globalize_path(texture_path)) != OK:
			frames.remove_animation(state)
			return
		frames.add_frame(state, ImageTexture.create_from_image(image))
