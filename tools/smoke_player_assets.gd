extends SceneTree


func _init() -> void:
	var frames := PlayerAssetLibrary.frames()
	var expected := {
		"idle": 4,
		"run": 8,
		"walk": 8,
		"jump": 4,
		"fall": 4,
		"landing": 4,
		"attack1": 4,
		"attack2": 4,
		"hurt": 4,
		"death": 4,
	}
	var failed := false
	for animation_name in expected:
		if not frames.has_animation(animation_name):
			push_error("missing animation: %s" % animation_name)
			failed = true
			continue
		var count := frames.get_frame_count(animation_name)
		if count != expected[animation_name]:
			push_error("%s expected %d frames, got %d" % [animation_name, expected[animation_name], count])
			failed = true
		for frame_index in range(count):
			if frames.get_frame_texture(animation_name, frame_index) == null:
				push_error("%s frame %d has no texture" % [animation_name, frame_index])
				failed = true
	if failed:
		quit(1)
		return
	print("player assets smoke check passed")
	quit(0)
