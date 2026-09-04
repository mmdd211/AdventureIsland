class_name ZoneObjectData
extends Resource

@export_enum("ground", "platform", "one_way_platform", "enemy", "pickup", "checkpoint", "spring", "spike", "moving_platform", "crumbling_platform", "portal", "boss", "darkness") var kind := "ground"
@export var position: Vector2 = Vector2.ZERO
@export var size: Vector2 = Vector2.ZERO
@export var label := ""
@export var value := 0
@export var float_value := 0.0
@export var one_way := false
@export var target_zone_id := ""
@export var target_portal_id := ""
@export var lock_region_id := ""
@export var travel := Vector2.ZERO
@export var period := 3.0
@export var phase := 0.0
