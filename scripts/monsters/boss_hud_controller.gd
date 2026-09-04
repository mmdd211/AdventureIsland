class_name BossHudController
extends RefCounted

const BOSS_HUD := preload("res://scenes/ui/boss_hud_bar.tscn")

var hud: CanvasLayer

func create(parent: Node, boss_name: String, region_id: String) -> void:
	hud = BOSS_HUD.instantiate()
	hud.name = "BossHud"
	hud.set_meta("region_id", region_id)
	parent.add_child(hud)
	bind(boss_name, region_id)

func bind(boss_name: String, _region_id: String) -> void:
	hud.bind(boss_name, _region_id)

func set_form(form_name: String, form_index: int, form_total: int) -> void:
	hud.set_form(form_name, form_index, form_total)

func set_health(current: float, maximum: float) -> void:
	hud.set_health(current, maximum)

func show_evolution(message: String) -> void:
	hud.show_evolution(message)

func hide_evolution() -> void:
	hud.hide_evolution()

func set_visible(value: bool) -> void:
	hud.visible = value
