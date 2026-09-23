extends SceneTree


func _init() -> void:
	var failed := false
	var expected := {
		"idle": 4,
		"run": 8,
		"jump": 4,
		"fall": 1,
		"fall_short": 1,
		"landing": 4,
		"attack1": 4,
		"attack2": 4,
		"hurt": 4,
		"death": 4,
	}
	for hero_id in PlayerAssetLibrary.HERO_IDS:
		var frames := PlayerAssetLibrary.frames(hero_id)
		for animation_name in expected:
			if not frames.has_animation(animation_name):
				push_error("%s missing animation: %s" % [hero_id, animation_name])
				failed = true
				continue
			var count := frames.get_frame_count(animation_name)
			if count < 1:
				push_error("%s %s has no frames" % [hero_id, animation_name])
				failed = true
				continue
			for frame_index in range(count):
				if frames.get_frame_texture(animation_name, frame_index) == null:
					push_error("%s %s frame %d has no texture" % [hero_id, animation_name, frame_index])
					failed = true
			# 双角色均应帧数精确；缺帧走回退说明交付不完整。
			if count != expected[animation_name]:
				push_error("%s %s expected %d frames, got %d" % [hero_id, animation_name, expected[animation_name], count])
				failed = true
	# 默认角色必须可精确解析；未知 id 回退。
	if PlayerAssetLibrary.resolve_hero_id("nope") != PlayerAssetLibrary.DEFAULT_HERO_ID:
		push_error("resolve_hero_id should fallback to default")
		failed = true
	if PlayerAssetLibrary.resolve_hero_id("light_swordsman") != "light_swordsman":
		push_error("resolve_hero_id should keep known hero")
		failed = true
	# hero_id 写入约定：快照键名固定（restore 缺省回退由 GameState 负责，此处只钉契约）。
	if PlayerAssetLibrary.DEFAULT_HERO_ID != "cat_girl" or PlayerAssetLibrary.HERO_IDS.size() < 2:
		push_error("hero catalog incomplete")
		failed = true
	if failed:
		quit(1)
		return
	print("player assets smoke check passed")
	quit(0)
