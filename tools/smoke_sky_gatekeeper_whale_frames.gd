extends SceneTree

func _init() -> void:
	var prefix := "sky_gatekeeper"
	var form := "whale"
	var frames := BossAssetLibrary.load_frames(prefix, form)
	if frames == null:
		print("SMOKE_FAIL: load_frames returned null")
		quit(1)
		return
	var expect := {
		"idle": 6, "move": 6, "attack": 7, "skill": 8, "hurt": 3, "evolve": 8, "death": 6
	}
	for state in expect:
		if not frames.has_animation(state) or frames.get_frame_count(state) != expect[state]:
			print("SMOKE_FAIL: %s bad" % state)
			quit(1)
			return
	print("SMOKE_WHALE_ALL_STATES_OK")
	quit(0)
