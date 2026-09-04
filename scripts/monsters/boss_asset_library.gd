class_name BossAssetLibrary
extends RefCounted

const BOSS_FRAME_STATES := {
	"idle": [6, 8.0, true],
	"move": [6, 10.0, true],
	"attack": [7, 14.0, false],
	"skill": [8, 12.0, false],
	"hurt": [3, 14.0, false],
	"evolve": [8, 8.0, false],
	"death": [6, 8.0, false],
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
	return frames
