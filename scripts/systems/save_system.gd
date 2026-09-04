extends Node

const SAVE_PATH := "user://adventure_island_save.json"
const SAVE_VERSION := 1

func _ready() -> void:
	GameState.checkpoint_reached.connect(func(_position): save_game())
	GameState.boss_defeated.connect(func(_region_id): save_game())

func has_save() -> bool:
	# 只把"能被当前版本解析"的存档当作有效存档，
	# 避免损坏/旧版本存档让标题屏显示一个点了没反应的继续按钮。
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return typeof(parsed) == TYPE_DICTIONARY and int(parsed.get("version", 0)) == SAVE_VERSION

func save_game() -> bool:
	var data := GameState.create_snapshot()
	data["saved_at"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: cannot write save file")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != SAVE_VERSION:
		return false
	return GameState.restore_snapshot(parsed)
