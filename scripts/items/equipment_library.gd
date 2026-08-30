class_name EquipmentLibrary
extends RefCounted

static func create(id: String) -> EquipmentData:
	var result := EquipmentData.new()
	result.id = id
	match id:
		"grass_blade":
			result.slot = "weapon"
			result.display_name = "草叶短刃"
			result.description = "初始武器"
			result.combo_damage = [10, 14]
			result.icon_color = Color("8ed45a")
		"petal_blade":
			result.slot = "weapon"
			result.display_name = "花刃短剑"
			result.description = "更轻的花瓣斩击"
			result.combo_damage = [13, 18]
			result.reach_bonus = 4.0
			result.attack_speed = 1.05
			result.icon_color = Color("ff7ca8")
		"spore_edge":
			result.slot = "weapon"
			result.display_name = "孢子长刃"
			result.description = "更长攻击距离"
			result.combo_damage = [16, 22]
			result.reach_bonus = 10.0
			result.icon_color = Color("4fae4d")
		"glow_hook":
			result.slot = "weapon"
			result.display_name = "荧光钩刃"
			result.description = "攻速更快"
			result.combo_damage = [19, 26]
			result.reach_bonus = 8.0
			result.attack_speed = 1.12
			result.icon_color = Color("7ff4c9")
		"gale_rock":
			result.slot = "weapon"
			result.display_name = "风岩重刃"
			result.description = "击退更强"
			result.combo_damage = [23, 31]
			result.reach_bonus = 10.0
			result.attack_speed = 0.92
			result.knockback = 1.8
			result.icon_color = Color("d7a64b")
		"rune_blade":
			result.slot = "weapon"
			result.display_name = "符文战刃"
			result.description = "新增第三段连击"
			result.combo_damage = [26, 36, 44]
			result.reach_bonus = 12.0
			result.special = "third_combo"
			result.icon_color = Color("a9d36d")
		"star_edge":
			result.slot = "weapon"
			result.display_name = "星辉天刃"
			result.description = "第二段附带星辉冲击"
			result.combo_damage = [31, 42]
			result.reach_bonus = 16.0
			result.attack_speed = 1.08
			result.special = "star_impact"
			result.icon_color = Color("68d8ff")
		"none_armor":
			result.slot = "armor"
			result.display_name = "无防具"
			result.icon_color = Color("5f6870")
		"moss_light":
			result.slot = "armor"
			result.display_name = "苔花轻甲"
			result.description = "HP+10，减伤5%"
			result.hp_bonus = 10
			result.damage_reduction = 0.05
			result.icon_color = Color("67c95a")
		"mushroom_shell":
			result.slot = "armor"
			result.display_name = "菌壳护甲"
			result.description = "HP+20，减伤8%"
			result.hp_bonus = 20
			result.damage_reduction = 0.08
			result.icon_color = Color("d94837")
		"root_weave":
			result.slot = "armor"
			result.display_name = "根须披甲"
			result.description = "HP+30，减伤10%"
			result.hp_bonus = 30
			result.damage_reduction = 0.10
			result.icon_color = Color("4bb489")
		"gale_plate":
			result.slot = "armor"
			result.display_name = "风哨胸甲"
			result.description = "HP+40，减伤12%"
			result.hp_bonus = 40
			result.damage_reduction = 0.12
			result.icon_color = Color("e8574b")
		"rune_armor":
			result.slot = "armor"
			result.display_name = "遗迹符甲"
			result.description = "HP+50，减伤15%"
			result.hp_bonus = 50
			result.damage_reduction = 0.15
			result.icon_color = Color("777487")
		"sky_armor":
			result.slot = "armor"
			result.display_name = "天穹圣甲"
			result.description = "HP+70，减伤18%"
			result.hp_bonus = 70
			result.damage_reduction = 0.18
			result.icon_color = Color("61d6ff")
	return result
