extends CanvasLayer

var zone_banner_tween: Tween
var zone_banner_style: StyleBoxFlat

func _ready() -> void:
	%CoinIcon.texture = PixelStyleManager.make_coin_texture()
	# 复制一份独立样式，避免横幅运行时改边框色污染共享样式资源。
	zone_banner_style = %ZoneBanner.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	%ZoneBanner.add_theme_stylebox_override("panel", zone_banner_style)
	_refresh_equipment_icons()
	GameState.zone_changed.connect(_show_zone_banner)
	GameState.hp_changed.connect(func(current, maximum): _refresh(current, maximum))
	GameState.exp_changed.connect(func(_current, _required, _level): _refresh(GameState.current_hp, GameState.max_hp))
	GameState.coins_changed.connect(func(_coins): _refresh(GameState.current_hp, GameState.max_hp))
	GameState.equipment_changed.connect(_refresh_equipment_icons)
	_refresh(GameState.current_hp, GameState.max_hp)

func _process(_delta: float) -> void:
	%TimeLabel.text = GameState.get_formatted_time(GameState.elapsed_time)
	_refresh(GameState.current_hp, GameState.max_hp)

func _show_zone_banner(zone_id: String) -> void:
	if DataCatalog.map_order().find(zone_id) < 0:
		return
	var metadata := DataCatalog.map_metadata(str(zone_id))
	var theme: Dictionary = metadata.get("theme", {})
	%BannerLabel.text = "%s · %s" % [metadata.get("region_name", ""), metadata.get("display_name", "")]
	var accent := Color("ffd700")
	if theme.has("accent"):
		accent = Color(str(theme.accent))
	zone_banner_style.border_color = accent
	%BannerLabel.add_theme_color_override("font_color", accent.darkened(0.28))
	%ZoneBanner.visible = true
	%ZoneBanner.modulate.a = 0.0
	if zone_banner_tween:
		zone_banner_tween.kill()
	zone_banner_tween = create_tween()
	zone_banner_tween.tween_property(%ZoneBanner, "modulate:a", 1.0, 0.18)
	zone_banner_tween.tween_interval(1.35)
	zone_banner_tween.tween_property(%ZoneBanner, "modulate:a", 0.0, 0.34)
	zone_banner_tween.tween_callback(func(): %ZoneBanner.visible = false)

func _refresh(current_hp: int, max_hp: int) -> void:
	%HPBar.max_value = max_hp
	%HPBar.value = current_hp
	%HPValue.text = "%d / %d" % [current_hp, max_hp]
	%EXPBar.max_value = GameState.required_exp
	%EXPBar.value = GameState.current_exp
	%EXPValue.text = "Lv.%d  %d/%d" % [GameState.current_level, GameState.current_exp, GameState.required_exp]
	%LevelLabel.text = "Lv.%d" % GameState.current_level
	%CoinLabel.text = "%d / %d" % [GameState.collected_coin_pickups, GameState.total_coin_pickups]
	%ScoreLabel.text = "SCORE %d" % GameState.score

func _refresh_equipment_icons() -> void:
	%WeaponIcon.texture = PixelStyleManager.make_equipment_texture(GameState.equipped_weapon_id)
	%ArmorIcon.texture = PixelStyleManager.make_equipment_texture(GameState.equipped_armor_id)
