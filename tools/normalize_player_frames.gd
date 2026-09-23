extends SceneTree

const SOURCE_DIR := "res://data/player/cleaned"
const OUTPUT_DIR := "res://assets/sprites/player/cat_girl"
const FRAME_SIZE := Vector2i(256, 256)
const TARGET_BASELINE := 244
const TARGET_HEAD_ANCHOR_X := 140
const ALPHA_THRESHOLD := 10
const RUN_SCALE := 1.16
const ATTACK_SCALE := 1.28
const COMPONENT_MARGIN := 28
const MIN_COMPONENT_AREA := 6

const FRAME_NAMES := [
	"frame-1.png", "frame-2.png", "frame-3.png", "frame-4.png",
	"run-frame-1.png", "run-frame-2.png", "run-frame-3.png", "run-frame-4.png",
	"run-frame-5.png", "run-frame-6.png", "run-frame-7.png", "run-frame-8.png",
	"jump-takeoff-frame-1.png", "jump-takeoff-frame-2.png",
	"jump-takeoff-frame-3.png", "jump-takeoff-frame-4.png",
	"fall-frame-1.png", "fall-frame-2.png", "fall-frame-3.png", "fall-frame-4.png",
	"landing-frame-1.png", "landing-frame-2.png", "landing-frame-3.png", "landing-frame-4.png",
	"attack1-frame-1.png", "attack1-frame-2.png", "attack1-frame-3.png", "attack1-frame-4.png",
	"attack2-frame-1.png", "attack2-frame-2.png", "attack2-frame-3.png", "attack2-frame-4.png",
	"hurt-frame-1.png", "hurt-frame-2.png", "hurt-frame-3.png", "hurt-frame-4.png",
	"death-frame-1.png", "death-frame-2.png", "death-frame-3.png", "death-frame-4.png",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var processed := 0
	for file_name in FRAME_NAMES:
		if _normalize(file_name):
			processed += 1
	print("normalized %d player frames" % processed)
	quit(0 if processed == FRAME_NAMES.size() else 1)


func _normalize(file_name: String) -> bool:
	var source_path: String = ProjectSettings.globalize_path(SOURCE_DIR.path_join(file_name))
	var source: Image = Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("missing player source frame: %s" % source_path)
		return false

	var image: Image = source
	image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var labels := PackedInt32Array()
	labels.resize(width * height)
	labels.fill(-1)
	var component_sizes: Array[int] = []
	var component_rects: Array[Rect2i] = []

	# Label connected opaque regions. Isolated border speckles then become
	# removable without confusing the character's dark-purple hair for a key.
	for y in range(height):
		for x in range(width):
			var start: int = y * width + x
			if labels[start] != -1 or image.get_pixel(x, y).a * 255.0 <= ALPHA_THRESHOLD:
				continue
			var label: int = component_sizes.size()
			var queue: Array[int] = [start]
			labels[start] = label
			var head := 0
			var count := 0
			var min_x := x
			var max_x := x
			var min_y := y
			var max_y := y
			while head < queue.size():
				var index: int = queue[head]
				head += 1
				var px: int = index % width
				var py: int = index / width
				count += 1
				min_x = mini(min_x, px)
				max_x = maxi(max_x, px)
				min_y = mini(min_y, py)
				max_y = maxi(max_y, py)
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx: int = px + dx
						var ny: int = py + dy
						if nx < 0 or nx >= width or ny < 0 or ny >= height:
							continue
						var next: int = ny * width + nx
						if labels[next] == -1 and image.get_pixel(nx, ny).a * 255.0 > ALPHA_THRESHOLD:
							labels[next] = label
							queue.append(next)
			component_sizes.append(count)
			component_rects.append(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))

	if component_sizes.is_empty():
		push_error("empty player frame after alpha filtering: %s" % file_name)
		return false

	var main_label := 0
	for i in range(1, component_sizes.size()):
		if component_sizes[i] > component_sizes[main_label]:
			main_label = i
	var main_rect: Rect2i = component_rects[main_label]
	var keep_rect := Rect2i(
		main_rect.position.x - COMPONENT_MARGIN,
		main_rect.position.y - COMPONENT_MARGIN,
		main_rect.size.x + COMPONENT_MARGIN * 2,
		main_rect.size.y + COMPONENT_MARGIN * 2
	)
	var output := Image.create(FRAME_SIZE.x, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)

	var kept_min_x := width
	var kept_max_x := -1
	var kept_min_y := height
	var kept_max_y := -1
	for y in range(height):
		for x in range(width):
			var label: int = labels[y * width + x]
			if label < 0:
				continue
			# Generated character art can split eyes, hands, shoes, and weapon pixels
			# into separate components because of transparent gaps. Keep the main
			# silhouette plus nearby components; discard only distant border debris.
			var keep_component := label == main_label or (
				component_sizes[label] >= MIN_COMPONENT_AREA and
				keep_rect.intersects(component_rects[label])
			)
			if not keep_component:
				continue
			var color: Color = image.get_pixel(x, y)
			if color.a * 255.0 <= ALPHA_THRESHOLD:
				continue
			output.set_pixel(x, y, color)
			kept_min_x = mini(kept_min_x, x)
			kept_max_x = maxi(kept_max_x, x)
			kept_min_y = mini(kept_min_y, y)
			kept_max_y = maxi(kept_max_y, y)

	if kept_max_x < 0:
		push_error("no retained pixels in player frame: %s" % file_name)
		return false

	# The supplied run cycle was authored noticeably smaller than the idle
	# cycle. Scale only that animation around the feet and head anchor so the
	# character keeps the same on-screen size while the pose remains intact.
	var content_scale := 1.0
	if file_name.begins_with("run-frame-"):
		content_scale = RUN_SCALE
	elif file_name.begins_with("attack1-frame-") or file_name.begins_with("attack2-frame-"):
		content_scale = ATTACK_SCALE
	if content_scale != 1.0:
		output = _scale_from_feet(output, kept_min_x, kept_max_x, kept_min_y, kept_max_y, content_scale)
		kept_min_x = 0
		kept_max_x = FRAME_SIZE.x - 1
		kept_min_y = 0
		kept_max_y = FRAME_SIZE.y - 1

		var scaled_bounds := _alpha_bounds(output)
		kept_min_x = scaled_bounds.position.x
		kept_min_y = scaled_bounds.position.y
		kept_max_x = scaled_bounds.end.x - 1
		kept_max_y = scaled_bounds.end.y - 1

	# Keep the feet and head anchor stable so texture swaps do not bob, shrink,
	# or slide the character sideways.
	var shift_y := TARGET_BASELINE - kept_max_y
	var head_anchor_x := _find_head_anchor_x(output, kept_min_y, kept_max_y)
	var shift_x := TARGET_HEAD_ANCHOR_X - head_anchor_x
	if shift_y != 0 or shift_x != 0:
		var aligned := Image.create(FRAME_SIZE.x, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
		aligned.fill(Color.TRANSPARENT)
		for y in range(FRAME_SIZE.y):
			var target_y := y + shift_y
			if target_y < 0 or target_y >= FRAME_SIZE.y:
				continue
			for x in range(FRAME_SIZE.x):
				var target_x := x + shift_x
				if target_x < 0 or target_x >= FRAME_SIZE.x:
					continue
				var color: Color = output.get_pixel(x, y)
				if color.a > 0.0:
					aligned.set_pixel(target_x, target_y, color)
		output = aligned

	var output_path: String = ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name))
	var error: Error = output.save_png(output_path)
	if error != OK:
		push_error("failed to save normalized frame: %s" % output_path)
		return false
	return true


func _scale_from_feet(image: Image, min_x: int, max_x: int, min_y: int, max_y: int, scale: float) -> Image:
	var source_rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	var cropped := image.get_region(source_rect)
	var scaled_size := Vector2i(
		maxi(1, roundi(float(cropped.get_width()) * scale)),
		maxi(1, roundi(float(cropped.get_height()) * scale))
	)
	cropped.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)

	var result := Image.create(FRAME_SIZE.x, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var source_head_x := _find_head_anchor_x(image, min_y, max_y)
	var scaled_head_x := roundi(float(source_head_x - min_x) * scale)
	var paste_x := TARGET_HEAD_ANCHOR_X - scaled_head_x
	var paste_y := TARGET_BASELINE - scaled_size.y
	result.blit_rect(cropped, Rect2i(0, 0, scaled_size.x, scaled_size.y), Vector2i(paste_x, paste_y))
	return result


func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var max_x := -1
	var min_y := image.get_height()
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.0:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _find_head_anchor_x(image: Image, min_y: int, max_y: int) -> int:
	var band_bottom := mini(max_y, min_y + 54)
	var min_x := image.get_width()
	var max_x := -1
	for y in range(min_y, band_bottom + 1):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
	if max_x < 0:
		return image.get_width() / 2
	return (min_x + max_x) / 2
