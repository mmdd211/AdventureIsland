# 游戏管理器（自动加载单例）
extends Node

var score: int = 0
var total_time: float = 0.0

func _ready() -> void:
	print("游戏管理器已就绪")

func _process(delta: float) -> void:
	total_time += delta

func add_score(amount: int) -> void:
	score += amount

func get_formatted_time() -> String:
	var minutes = int(total_time) / 60
	var seconds = int(total_time) % 60
	return "%02d:%02d" % [minutes, seconds]
