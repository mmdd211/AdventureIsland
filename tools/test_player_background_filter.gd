extends SceneTree

const SOURCE_DIR := "res://data/player"
const OUTPUT_DIR := "res://output/player_filter_test"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for file_name in ["run-frame-5.png", "run-frame-8.png", "landing-frame-1.png", "attack1-frame-2.png"]:
		_filter_frame(file_name)
	quit()

func _filter_frame(file_name: String) -> void:
	var image := Image.load_from_file("%s/%s" % [SOURCE_DIR, file_name])
	if image == null:
		return
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var seed_min := Vector2i(width, height)
	var seed_max := Vector2i(-1, -1)
	var seed_mask := []
	seed_mask.resize(width * height)
	seed_mask.fill(false)

	# The colorful, non-chroma pixels are reliable subject anchors. Dark purple
	# pixels are deliberately excluded here because the background uses a very
	# similar color to the hair.
	for y in range(height):
		for x in range(width):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.03 or _is_magenta(pixel) or _is_dark_background(pixel) or _is_near_white(pixel):
				continue
			seed_mask[y * width + x] = true

	if seed_max.x < 0:
		return

	# Keep the largest connected colorful subject island. Background fragments
	# are scattered, while the face, shirt, hands, and weapon form the useful
	# anchor for locating the dark hair and outline pixels.
	var visited := []
	visited.resize(width * height)
	visited.fill(false)
	var best_area := 0
	for start in range(width * height):
		if not seed_mask[start] or visited[start]:
			continue
		var queue := [start]
		visited[start] = true
		var area := 0
		var component_min := Vector2i(width, height)
		var component_max := Vector2i(-1, -1)
		while not queue.is_empty():
			var index: int = queue.pop_back()
			var px := index % width
			var py := index / width
			area += 1
			component_min.x = mini(component_min.x, px)
			component_min.y = mini(component_min.y, py)
			component_max.x = maxi(component_max.x, px)
			component_max.y = maxi(component_max.y, py)
			for offset in [-1, 1, -width, width, -width - 1, -width + 1, width - 1, width + 1]:
				var next: int = index + offset
				if next < 0 or next >= width * height or visited[next] or not seed_mask[next]:
					continue
				var nx: int = next % width
				var ny: int = next / width
				if abs(nx - px) > 1 or abs(ny - py) > 1:
					continue
				visited[next] = true
				queue.append(next)
		if area > best_area:
			best_area = area
			seed_min = component_min
			seed_max = component_max

	var margin := 16
	var roi_min := Vector2i(maxi(0, seed_min.x - margin), maxi(0, seed_min.y - margin))
	var roi_max := Vector2i(mini(width - 1, seed_max.x + margin), mini(height - 1, seed_max.y + margin))
	var output := Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y in range(height):
		for x in range(width):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.03 or _is_magenta(pixel):
				continue
			var inside_roi := x >= roi_min.x and x <= roi_max.x and y >= roi_min.y and y <= roi_max.y
			if _is_dark_background(pixel) and not inside_roi:
				continue
			output.set_pixel(x, y, pixel)

	var destination := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name])
	output.save_png(destination)
	print(file_name, " seeds=", seed_min, "..", seed_max, " roi=", roi_min, "..", roi_max)

func _is_magenta(pixel: Color) -> bool:
	var red := int(pixel.r * 255.0)
	var green := int(pixel.g * 255.0)
	var blue := int(pixel.b * 255.0)
	var peak := maxi(red, blue)
	return peak >= 72 and green <= 225 and red - green >= 24 and blue - green >= 24

func _is_dark_background(pixel: Color) -> bool:
	var red := int(pixel.r * 255.0)
	var green := int(pixel.g * 255.0)
	var blue := int(pixel.b * 255.0)
	return red >= 24 and red <= 70 and green <= 48 and blue >= 30 and blue <= 85 and blue - green >= 12

func _is_near_white(pixel: Color) -> bool:
	return pixel.r > 0.92 and pixel.g > 0.92 and pixel.b > 0.92
