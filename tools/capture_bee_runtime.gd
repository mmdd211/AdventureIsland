extends SceneTree

# Runtime visual capture: load via BossAssetLibrary, composite game-scale (0.82) frames.
# Writes data/monsters/raw/qa_runtime_capture.png

func _init() -> void:
	var frames := BossAssetLibrary.load_frames("pollen_queen", "bee")
	if frames == null:
		print("CAPTURE_FAIL: load_frames null")
		quit(1)
		return
	var states := ["idle", "move", "attack", "skill", "hurt", "evolve", "death"]
	var cell := 192
	var scale := 0.82
	var gs := int(cell * scale)
	var pad := 6
	var label_h := 18
	var max_frames := 8
	var cols := max_frames
	var rows := states.size()
	var w := pad + cols * (gs + pad)
	var h := pad + rows * (gs + label_h + pad)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.12, 0.13, 0.15, 1.0))
	for ri in range(rows):
		var state: String = states[ri]
		var n: int = frames.get_frame_count(state)
		for ci in range(n):
			var tex: Texture2D = frames.get_frame_texture(state, ci)
			if tex == null:
				continue
			var src: Image = tex.get_image()
			if src == null:
				continue
			src = src.duplicate()
			src.resize(gs, gs, Image.INTERPOLATE_NEAREST)
			var x0 := pad + ci * (gs + pad)
			var y0 := pad + ri * (gs + label_h + pad)
			img.blit_rect(src, Rect2i(0, 0, gs, gs), Vector2i(x0, y0))
	# labels are skipped (bitmap font unavailable headless); layout is row-per-state
	var out_path := ProjectSettings.globalize_path("res://data/monsters/raw/qa_runtime_capture.png")
	var err := img.save_png(out_path)
	if err != OK:
		print("CAPTURE_FAIL: save ", err)
		quit(1)
		return
	print("CAPTURE_PASS ", out_path, " ", img.get_size())
	# also dump per-state first-frame sizes via load path
	for state in states:
		var n2: int = frames.get_frame_count(state)
		var t0: Texture2D = frames.get_frame_texture(state, 0)
		var im0: Image = t0.get_image()
		var op := 0
		if im0:
			var px := im0.get_data()
			# count non-zero alpha
			for i in range(3, px.size(), 4):
				if px[i] > 128:
					op += 1
		print("  ", state, " frames=", n2, " tex=", t0.get_size(), " opaque0=", op)
	quit(0)
