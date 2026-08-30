class_name BossData
extends Resource

@export var region_id := ""
@export var display_name := ""
@export var max_health := 380
@export var contact_damage := 14
@export var stage_count := 2
@export var move_speed := 110.0
@export var charge_speed := 430.0
@export var attack_interval := 1.8
@export var body_size := Vector2(72, 82)
@export var body_color := Color.WHITE
@export var attacks: Array[String] = ["charge"]
