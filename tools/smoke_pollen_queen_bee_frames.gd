extends SceneTree

func _init() -> void:
	var prefix := "pollen_queen"
	var form := "bee"
	var frames := BossAssetLibrary.load_frames(prefix, form)
	if frames == null:
		print("SMOKE_FAIL: load_frames returned null (missing frames or load error)")
		var base := "res://assets/sprites/monsters/%s/%s_%s" % [prefix, prefix, form]
		var states := {
			"idle": 6, "move": 6, "attack": 7, "skill": 8, "hurt": 3, "evolve": 8, "death": 6
		}
		for state in states:
			var missing := []
			for index in range(states[state]):
				var path := "%s_%s_%02d.png" % [base, state, index]
				if not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
					missing.append(path.get_file())
			if not missing.is_empty():
				print("  missing %s: %s" % [state, ", ".join(missing)])
			else:
				print("  ok %s (%d)" % [state, states[state]])
		quit(1)
		return
	print("SMOKE_PASS: loaded %d animations" % frames.get_animation_names().size())
	for anim in frames.get_animation_names():
		print("  %s frames=%d speed=%s loop=%s" % [
			anim,
			frames.get_frame_count(anim),
			frames.get_animation_speed(anim),
			frames.get_animation_loop(anim)
		])
	quit(0)
