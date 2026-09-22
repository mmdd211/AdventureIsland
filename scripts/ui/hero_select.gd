extends Control

const VIEW_W := 1280.0
const VIEW_H := 720.0

var _index := 0
var _cards: Array = []

func _ready() -> void:
	AudioManager.play_music("title")
	LocalizationSystem.language_changed.connect(func(_l): get_tree().reload_current_scene.call_deferred())
	_apply_localized_text()
	_build_cards()
	_connect_buttons()
	_select_index(clampi(PlayerAssetLibrary.HERO_IDS.find(GameState.selected_hero_id), 0, PlayerAssetLibrary.HERO_IDS.size() - 1))
	%ConfirmButton.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.keycode == KEY_LEFT:
		_select_index(wrapi(_index - 1, 0, _cards.size()))
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_RIGHT:
		_select_index(wrapi(_index + 1, 0, _cards.size()))
		get_viewport().set_input_as_handled()
	elif key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_J]:
		_confirm()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE:
		_back()
		get_viewport().set_input_as_handled()

func _apply_localized_text() -> void:
	%TitleLabel.text = LocalizationSystem.tr_key("hero_select_title")
	%ConfirmButton.text = LocalizationSystem.tr_key("hero_select_confirm")
	%BackButton.text = LocalizationSystem.tr_key("hero_select_back")

func _connect_buttons() -> void:
	%ConfirmButton.pressed.connect(_confirm)
	%BackButton.pressed.connect(_back)

func _build_cards() -> void:
	for child in %CardRow.get_children():
		child.queue_free()
	_cards.clear()
	for hero_id in PlayerAssetLibrary.HERO_IDS:
		var card := _make_card(str(hero_id))
		%CardRow.add_child(card)
		_cards.append({"id": str(hero_id), "root": card})

func _make_card(hero_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 380)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_index(PlayerAssetLibrary.HERO_IDS.find(hero_id))
	)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(256, 256)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = _preview_texture(hero_id)
	box.add_child(portrait)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = LocalizationSystem.tr_key(PlayerAssetLibrary.hero_name_key(hero_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	box.add_child(name_label)
	return panel

func _preview_texture(hero_id: String) -> Texture2D:
	var frames := PlayerAssetLibrary.frames(hero_id)
	if frames == null or not frames.has_animation("idle") or frames.get_frame_count("idle") == 0:
		return null
	return frames.get_frame_texture("idle", 0)

func _select_index(index: int) -> void:
	_index = clampi(index, 0, _cards.size() - 1)
	for i in _cards.size():
		var root: PanelContainer = _cards[i]["root"]
		var selected := i == _index
		root.modulate = Color(1, 1, 1, 1.0) if selected else Color(0.78, 0.82, 0.88, 0.92)
		root.scale = Vector2(1.06, 1.06) if selected else Vector2.ONE
		root.pivot_offset = root.size * 0.5

func _confirm() -> void:
	var hero_id := str(_cards[_index]["id"])
	GameState.set_selected_hero_id(hero_id)
	GameState.reset_run()
	GameState.pending_loading_screen = true
	get_tree().change_scene_to_file("res://scenes/levels/world_map.tscn")

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
