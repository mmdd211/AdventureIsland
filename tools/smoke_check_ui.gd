extends Node

const UI_SCENES := {
	"res://scenes/ui/title_screen.tscn": [
		"SunGlow", "TitleLabel", "StartButton", "ContinueButton", "QuitButton",
		"SettingsButton", "SettingsPanel", "SettingsBox", "KeybindsBox",
		"CloseSettingsButton", "Scenery", "Decor", "Cloud1",
	],
	"res://scenes/ui/game_hud.tscn": [
		"HPBar", "HPValue", "EXPBar", "EXPValue", "LevelLabel", "CoinIcon",
		"CoinLabel", "ScoreLabel", "TimeLabel", "WeaponIcon", "ArmorIcon",
		"ZoneBanner", "BannerLabel",
	],
	"res://scenes/ui/game_screens.tscn": [
		"PauseDim", "DeathDim", "CompleteDim", "RewardDim", "EquipmentDim",
		"Stats", "ContinueButton", "WeaponColumn", "ArmorColumn",
	],
	"res://scenes/ui/loading_overlay.tscn": [
		"LoadingRoot", "Scenery", "StageLabel", "LoadingTitle", "BarFill",
		"PercentLabel", "TipLabel",
	],
	"res://scenes/ui/debug_ui.tscn": ["FPSLabel", "PosLabel", "StateLabel"],
	"res://scenes/ui/world_map_overlay.tscn": ["MapRoot", "Title", "MapDisplay", "CloseButton"],
	"res://scenes/ui/boss_hud_bar.tscn": ["NameLabel", "FormLabel", "Fill", "EvolveLabel"],
}

func _ready() -> void:
	var failures := 0
	for scene_path in UI_SCENES:
		var expected: Array = UI_SCENES[scene_path]
		var packed := load(scene_path) as PackedScene
		if packed == null:
			printerr("UI scene failed to load: %s" % scene_path)
			failures += 1
			continue
		var instance := packed.instantiate()
		if instance == null:
			printerr("UI scene failed to instantiate: %s" % scene_path)
			failures += 1
			continue
		add_child(instance)
		for node_name in expected:
			if instance.get_node_or_null(NodePath("%%%s" % str(node_name))) == null:
				printerr("UI scene missing unique node %%%s: %s" % [str(node_name), scene_path])
				failures += 1
		instance.queue_free()

	if failures == 0:
		print("UI scene smoke check passed.")
	else:
		printerr("UI scene smoke check failed with %d issue(s)." % failures)
	get_tree().quit(failures)
