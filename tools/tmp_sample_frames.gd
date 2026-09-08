extends SceneTree
func _init() -> void:
	for pair in [["run-frame-5.png", Vector2i(37,35)], ["run-frame-5.png", Vector2i(234,236)], ["run-frame-8.png", Vector2i(10,31)], ["run-frame-8.png", Vector2i(209,229)]]:
		var im := Image.load_from_file("res://data/player/" + pair[0])
		print(pair[0], " ", pair[1], " ", im.get_pixelv(pair[1]))
	quit()
