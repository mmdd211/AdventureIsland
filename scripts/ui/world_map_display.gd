extends Control

const WorldZones := preload("res://scripts/world/world_zones.gd")

@export var compact := true

const TILE_SIZE := Vector2(138, 86)
const TILE_POSITIONS := {
	"meadow": Vector2(24, 250),
	"forest": Vector2(224, 250),
	"grove": Vector2(446, 42),
	"canyon": Vector2(446, 250),
	"ruins": Vector2(698, 42),
	"gate": Vector2(736, 250),
}

var pulse_time := 0.0
var last_shown_zones: Array = []
var last_player_marker_visible := false
var last_terrain_rect_count := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	GameState.zone_changed.connect(func(_zone_id): queue_redraw())
	GameState.map_state_changed.connect(queue_redraw)

func _process(delta: float) -> void:
	pulse_time = fmod(pulse_time + delta, TAU)
	queue_redraw()

func _draw() -> void:
	last_player_marker_visible = false
	last_terrain_rect_count = 0
	if compact:
		last_shown_zones = [GameState.current_zone_id]
		_draw_zone_tile(Rect2(Vector2(4, 4), size - Vector2(8, 8)), GameState.current_zone_id, true)
		return
	last_shown_zones = WorldZones.ORDER.duplicate()

	var points := {}
	for zone_id in WorldZones.ORDER:
		points[zone_id] = TILE_POSITIONS[zone_id] + TILE_SIZE * 0.5
	for connection in WorldZones.CONNECTIONS:
		var from_id: String = connection.from_zone
		var to_id: String = connection.to_zone
		var known := _is_known(from_id) or _is_known(to_id)
		var color := Color(0.18, 0.28, 0.36, 0.75) if not known else Color(Color("61d6ff"), 0.55)
		if GameState.current_zone_id == from_id or GameState.current_zone_id == to_id:
			color = Color(Color("ffd700"), 0.9)
		_draw_pixel_path(points[from_id], points[to_id], color)
	for zone_id in WorldZones.ORDER:
		_draw_zone_tile(Rect2(TILE_POSITIONS[zone_id], TILE_SIZE), zone_id, false)

func _draw_zone_tile(rect: Rect2, zone_id: String, show_player: bool) -> void:
	var metadata: Dictionary = WorldZones.METADATA[zone_id]
	var theme: Dictionary = metadata.theme
	var known := _is_known(zone_id)
	var current := zone_id == GameState.current_zone_id
	var sky := Color(str(theme.sky_top)) if known else Color(0.12, 0.17, 0.22)
	var ground := Color(str(theme.ground_grass)) if known else Color(0.23, 0.29, 0.32)
	var body := Color(str(theme.ground_body)) if known else Color(0.14, 0.17, 0.20)
	var accent := Color(str(theme.accent)) if known else Color(0.27, 0.32, 0.36)

	draw_rect(rect, Color(0, 0, 0, 0.55 if known else 0.72))
	var inset := Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4))
	_draw_pixel_band(inset, sky.darkened(0.16), sky.lightened(0.12), 0.60)
	var terrain := Rect2(inset.position.x + 6.0, inset.get_center().y, inset.size.x - 12.0, inset.size.y * 0.38)
	draw_rect(Rect2(terrain.position, Vector2(terrain.size.x, 2)), accent.lightened(0.18))
	draw_rect(terrain, ground.darkened(0.18))
	draw_rect(Rect2(terrain.position + Vector2(0, 2), Vector2(terrain.size.x, terrain.size.y * 0.60)), body.darkened(0.16))
	if known:
		last_terrain_rect_count += _draw_collision_terrain(rect, zone_id, ground, body)
	_draw_motif_pixels(inset, theme, known)

	if compact or current:
		_draw_portals(rect, accent, known)
	if known:
		last_player_marker_visible = true
		_draw_player_marker(_player_marker_position(rect, metadata), current, show_player)
	else:
		_draw_centered_text("?", rect.get_center() + Vector2(0, 2), 21, Color(1, 1, 1, 0.72))

	var border := accent if current else Color(1, 1, 1, 0.28 if known else 0.10)
	if current:
		border.a = 0.64 + sin(pulse_time * 5.0) * 0.24
	_draw_pixel_border(rect, border, 3)
	if not compact or known:
		_draw_centered_text(metadata.display_name, rect.position + Vector2(rect.size.x * 0.5, rect.size.y + 9), 12, Color.WHITE if known else Color(1, 1, 1, 0.38))

func _draw_pixel_band(rect: Rect2, color_a: Color, color_b: Color, split_ratio: float) -> void:
	var split_y := floorf(rect.position.y + rect.size.y * split_ratio)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, split_y - rect.position.y)), color_a)
	draw_rect(Rect2(Vector2(rect.position.x, split_y), Vector2(rect.size.x, rect.end.y - split_y)), color_b)

func _draw_motif_pixels(rect: Rect2, theme: Dictionary, known: bool) -> void:
	var accent := Color(str(theme.accent)) if known else Color(0.22, 0.27, 0.31)
	if not known:
		for index in range(6):
			var x := rect.position.x + 18.0 + float(index) * maxf(18.0, rect.size.x / 7.0)
			var y := rect.position.y + 16.0 + float(index % 2) * 5.0
			draw_rect(Rect2(x, y, 2, 2), accent)
		return

	var motif: String = theme.metadata.get("motif", "")
	match motif:
		"bright_pastoral":
			for index in range(6):
				var x := rect.position.x + 18.0 + float(index) * rect.size.x / 6.5
				var y := rect.position.y + 18.0 + float(index % 2) * 6.0
				draw_rect(Rect2(x, y, 3, 3), accent)
				draw_rect(Rect2(x - 1, y + 1, 5, 1), accent)
		"mushroom_canopy":
			for index in range(5):
				var x := rect.position.x + 20.0 + float(index) * rect.size.x / 5.5
				draw_rect(Rect2(x, rect.position.y + 16.0, 7, 4), Color(str(theme.landmark_b)))
				draw_rect(Rect2(x + 2, rect.position.y + 4.0, 3, 13), Color(str(theme.landmark_a)))
		"glowing_roots":
			for index in range(7):
				var x := rect.position.x + 14.0 + float(index) * rect.size.x / 7.5
				var height := 8.0 + float(index % 3) * 2.0
				draw_rect(Rect2(x, rect.position.y + 6.0, 1.5, height), accent)
				draw_rect(Rect2(x - 1, rect.position.y + 6.0 + height, 3, 3), accent.lightened(0.22))
		"wind_mesas":
			for index in range(4):
				var y := rect.position.y + 14.0 + float(index) * 9.0
				draw_rect(Rect2(rect.position.x + 10.0, y, rect.size.x - 14.0 - float(index) * 9.0, 1.5), accent)
		"mossy_arches":
			for index in range(4):
				var x := rect.position.x + 18.0 + float(index) * rect.size.x / 4.5
				draw_rect(Rect2(x, rect.position.y + 8.0, 6, 12), Color(str(theme.landmark_a)))
				draw_rect(Rect2(x - 2, rect.position.y + 6.0, 10, 3), Color(str(theme.landmark_b)))
		_:
			for index in range(10):
				var x := rect.position.x + 10.0 + float(index * 11 % int(maxf(28.0, rect.size.x - 18.0)))
				var y := rect.position.y + 7.0 + float(index * 5 % 28)
				draw_rect(Rect2(x, y, 2, 2), accent.lightened(0.25))
				if index % 3 == 0:
					draw_rect(Rect2(x - 1, y + 1, 4, 1), accent.lightened(0.25))

func _draw_portals(rect: Rect2, color: Color, known: bool) -> void:
	if not known:
		return
	var zone = _zone_node(GameState.current_zone_id)
	if zone == null:
		return
	for portal in zone.find_children("*", "Area2D", true, false):
		if not portal.has_signal("travel_requested"):
			continue
		var ratio: float = portal.position.x / maxf(zone.zone_width, 1.0)
		var cx: float = rect.position.x + 6.0 + ratio * (rect.size.x - 12.0)
		var cy: float = rect.end.y - 14.0
		_draw_pixel_diamond(Vector2(cx, cy), 4, color)

func _draw_player_marker(marker_pos: Vector2, current: bool, show_player: bool) -> void:
	if not show_player and not current:
		return
	var x := marker_pos.x
	var y := marker_pos.y
	draw_rect(Rect2(x - 3, y - 5, 6, 9), Color(0, 0, 0, 0.86))
	draw_rect(Rect2(x - 2, y - 4, 4, 3), Color("e84855"))
	draw_rect(Rect2(x - 2, y, 4, 5), Color("61a6ff"))
	draw_rect(Rect2(x - 4, y - 1, 2, 2), Color.WHITE)
	draw_rect(Rect2(x + 2, y - 1, 2, 2), Color.WHITE)
	if current:
		var radius := 8.0 + sin(pulse_time * 5.0) * 1.5
		_draw_pixel_border(Rect2(marker_pos - Vector2(radius, radius), Vector2(radius * 2, radius * 2)), Color("ffd700"), 1)

func _player_marker_position(rect: Rect2, metadata: Dictionary) -> Vector2:
	var zone = _zone_node(str(metadata.id))
	if zone != null:
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			var local_x: float = player.global_position.x - zone.global_position.x
			var ratio := clampf(local_x / maxf(zone.zone_width, 1.0), 0.04, 0.96)
			return Vector2(rect.position.x + 7.0 + ratio * (rect.size.x - 14.0), rect.end.y - 18.0)
	return rect.position + rect.size * 0.5

func _draw_collision_terrain(rect: Rect2, zone_id: String, ground: Color, body: Color) -> int:
	var zone = _zone_node(zone_id)
	if zone == null:
		return 0

	var drawn := 0
	var scale_x := (rect.size.x - 10.0) / maxf(zone.zone_width, 1.0)
	var scale_y := rect.size.y / 630.0
	var world_y_min := 160.0
	var world_y_max := 790.0
	for body_node in zone.get_children():
		var body_name := String(body_node.name)
		if not body_name.begins_with("Ground") and not body_name.begins_with("Platform"):
			continue
		var collider = body_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collider == null or not (collider.shape is RectangleShape2D):
			continue
		var shape_size: Vector2 = collider.shape.size
		var body_local: Vector2 = body_node.position
		var top_left := body_local - shape_size * 0.5
		var map_position := Vector2(
			rect.position.x + 5.0 + top_left.x * scale_x,
			rect.position.y + 4.0 + (top_left.y - world_y_min) * (rect.size.y - 8.0) / (world_y_max - world_y_min)
		)
		var map_size := Vector2(maxi(4, int(round(shape_size.x * scale_x))), maxi(2, int(round(shape_size.y * scale_y))))
		var color := ground if body_name.begins_with("Ground") else body.lightened(0.30)
		draw_rect(Rect2(map_position, map_size), color)
		draw_rect(Rect2(map_position, Vector2(map_size.x, 1.5)), color.lightened(0.28))
		drawn += 1
	return drawn

func _draw_pixel_path(from_point: Vector2, to_point: Vector2, color: Color) -> void:
	var delta := to_point - from_point
	var steps := maxi(1, int(maxf(absf(delta.x), absf(delta.y)) / 14.0))
	for step in range(steps + 1):
		var point := from_point.lerp(to_point, float(step) / float(steps));
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), color)

func _draw_pixel_diamond(center: Vector2, radius: int, color: Color) -> void:
	for row in range(-radius, radius + 1):
		var width := radius - absi(row)
		for column in range(-width, width + 1):
			draw_rect(Rect2(center + Vector2(column, row), Vector2(1, 1)), color)

func _draw_pixel_border(rect: Rect2, color: Color, thickness: int) -> void:
	for index in range(thickness):
		draw_rect(rect.grow(-float(index)), color, false, 1.0)

func _draw_centered_text(text_value: String, center: Vector2, font_size: int, color: Color) -> void:
	var width := maxf(size.x * 0.5, 110.0)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - width * 0.5, center.y + font_size * 0.36), text_value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _zone_node(zone_id: String):
	for node in get_tree().get_nodes_in_group("world_zone"):
		if str(node.get("zone_id")) == zone_id:
			return node
	return null

func _is_known(zone_id: String) -> bool:
	return GameState.discovered_zones.has(zone_id)
