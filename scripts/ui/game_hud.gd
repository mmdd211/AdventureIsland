# 游戏 HUD 脚本
extends CanvasLayer

# 节点引用
var level_label: Label = null
var score_label: Label = null
var hp_bar: ProgressBar = null
var hp_value: Label = null
var exp_bar: ProgressBar = null
var exp_value: Label = null

# 玩家数据
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
	# 获取节点引用
	var top_panel = get_node_or_null("TopPanel")
	if top_panel:
		var margin = top_panel.get_node_or_null("MarginContainer")
		if margin:
			var vbox = margin.get_node_or_null("VBoxContainer")
			if vbox:
				var top_row = vbox.get_node_or_null("TopRow")
				if top_row:
					level_label = top_row.get_node_or_null("LevelLabel")
					score_label = top_row.get_node_or_null("ScoreLabel")

				var hp_container = vbox.get_node_or_null("HPContainer")
				if hp_container:
					hp_bar = hp_container.get_node_or_null("HPBar")
					hp_value = hp_container.get_node_or_null("HPValue")

				var exp_container = vbox.get_node_or_null("EXPContainer")
				if exp_container:
					exp_bar = exp_container.get_node_or_null("EXPBar")
					exp_value = exp_container.get_node_or_null("EXPValue")

	print("HUD 已就绪")

func _process(_delta: float) -> void:
	# 从 GameManager 获取分数
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		score = gm.score

	# 更新显示
	_update_display()

func _update_display() -> void:
	if level_label:
		level_label.text = "Lv.%d" % current_level

	if score_label:
		score_label.text = "分数: %d" % score

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

## 增加经验值
func add_experience(amount: int) -> void:
	current_exp += amount
	print("获得经验: ", amount, " 当前经验: ", current_exp)

	# 检查升级
	while current_exp >= max_exp:
		_level_up()

## 升级
func _level_up() -> void:
	current_exp -= max_exp
	current_level += 1
	max_exp = int(max_exp * 1.5)  # 每级经验需求增加 50%
	max_hp += 10  # 每级增加 10 HP
	current_hp = max_hp  # 升级回满血

	# 播放升级音效
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_level_up()

	print("升级！当前等级: ", current_level)

## 受到伤害
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	print("受到伤害: ", amount, " 剩余HP: ", current_hp)

	if current_hp <= 0:
		print("玩家死亡！")

## 恢复生命
func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	print("恢复生命: ", amount, " 当前HP: ", current_hp)
