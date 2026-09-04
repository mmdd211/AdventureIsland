class_name BossFormData
extends Resource

@export var id := "form"
@export var display_name := "形态"
@export var max_health := 380
@export var contact_damage := 14
@export var collision := Vector2(84, 104)
@export var move_speed := 80.0
@export var gravity_enabled := true
@export var basic_attack := "charge"
@export var skills: PackedStringArray = []
