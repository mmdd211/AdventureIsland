extends CanvasLayer

var shown_health := 1.0

func _ready() -> void:
	visible = false

func bind(boss_name: String, _region_id: String) -> void:
	%NameLabel.text = boss_name
	visible = true

func set_form(form_name: String, form_index: int, form_total: int) -> void:
	%FormLabel.text = "%d/%d · %s" % [form_index + 1, form_total, form_name]
	%Fill.color = Color("ffd166") if form_index == 0 else Color("ff6a70")

func set_health(current: float, maximum: float) -> void:
	shown_health = clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	%Fill.size.x = 514.0 * shown_health

func show_evolution(message: String) -> void:
	%EvolveLabel.text = message
	%EvolveLabel.visible = true

func hide_evolution() -> void:
	%EvolveLabel.visible = false
