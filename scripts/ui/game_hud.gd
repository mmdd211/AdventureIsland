# 游戏 HUD 脚本（美化版）
extends CanvasLayer

var level_label: Label = null
var score_label: Label = null
var hp_bar: ProgressBar = null
var hp_value: Label = null
var exp_bar: ProgressBar = null
var exp_value: Label = null

var current_hp: int = 100
var max_hp: int = 100
var current_exp: int = 0
var max_exp: int = 100
var current_level: int = 1
var score: int = 0

func _ready() -> void:
	add_to_group("game_hud")
	call_deferred("_init_hud")

func _init_hud() -> void:
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		var margin = top_bar.get_node_or_null("Margin")
		if margin:
			var hbox = margin.get_node_or_null("HBox")
			if hbox:
				level_label = hbox.get_node_or_null("LevelLabel")
				var hp_container = hbox.get_node_or_null("HPContainer")
				if hp_container:
					var hp_row = hp_container.get_node_or_null("HPRow")
					if hp_row:
						hp_bar = hp_row.get_node_or_null("HPBar")
						hp_value = hp_row.get_node_or_null("HPValue")
					var exp_row = hp_container.get_node_or_null("EXPRow")
					if exp_row:
						exp_bar = exp_row.get_node_or_null("EXPBar")
						exp_value = exp_row.get_node_or_null("EXPValue")
				var score_container = hbox.get_node_or_null("ScoreContainer")
				if score_container:
					score_label = score_container.get_node_or_null("ScoreLabel")

	print("HUD 已就绪")

func _process(_delta: float) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		score = gm.score
	_update_display()

func _update_display() -> void:
	if level_label:
		level_label.text = "Lv.%d" % current_level
	if score_label:
		score_label.text = str(score)
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if hp_value:
		hp_value.text = "%d/%d" % [current_hp, max_hp]
	if exp_bar:
		exp_bar.max_value = max_exp
		exp_bar.value = current_exp
	if exp_value:
		exp_value.text = "%d/%d" % [current_exp, max_exp]

func add_experience(amount: int) -> void:
	current_exp += amount
	print("获得经验: ", amount, " 当前经验: ", current_exp)
	while current_exp >= max_exp:
		_level_up()

func _level_up() -> void:
	current_exp -= max_exp
	current_level += 1
	max_exp = int(max_exp * 1.5)
	max_hp += 10
	current_hp = max_hp

	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_level_up()

	print("升级！当前等级: ", current_level)

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	print("受到伤害: ", amount, " 剩余HP: ", current_hp)
	if current_hp <= 0:
		print("玩家死亡！")

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	print("恢复生命: ", amount, " 当前HP: ", current_hp)
