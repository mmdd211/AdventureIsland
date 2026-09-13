extends SceneTree

# Verify bee-only facing inversion via static helpers (no scene/tree needed).

func _init() -> void:
	var script := load("res://scripts/monsters/boss_animator.gd")
	if script == null:
		print("FACE_FAIL: cannot load boss_animator.gd")
		quit(1)
		return
	var fails := 0
	var cases := [
		["meadow", "bee", 1, false],
		["meadow", "bee", -1, true],
		["meadow", "dancer", 1, true],
		["meadow", "dancer", -1, false],
		["forest", "turtle", 1, true],
		["forest", "turtle", -1, false],
	]
	for c in cases:
		var flip: bool = script.compute_flip_h(c[0], c[1], c[2])
		var expected: bool = c[3]
		var ok := flip == expected
		print("  %s/%s dir=%s flip=%s expected=%s %s" % [c[0], c[1], c[2], flip, expected, "OK" if ok else "FAIL"])
		if not ok:
			fails += 1
	if fails == 0:
		print("FACE_PASS")
		quit(0)
	else:
		print("FACE_FAIL count=", fails)
		quit(1)
