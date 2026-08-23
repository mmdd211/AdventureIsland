# 音效管理器（自动生成简单音效）
extends Node

# 音效播放器
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.volume_db = -10  # 音量
	add_child(sfx_player)
	print("音效管理器已就绪")

## 播放跳跃音效（高音短促）
func play_jump() -> void:
	_play_tone(800, 0.1, 0.3)

## 播放攻击音效（中音）
func play_attack() -> void:
	_play_tone(400, 0.15, 0.5)

## 播放命中音效（低音）
func play_hit() -> void:
	_play_tone(200, 0.2, 0.6)

## 播放收集金币音效（上升音阶）
func play_coin() -> void:
	_play_tone(600, 0.1, 0.4)
	await get_tree().create_timer(0.05).timeout
	_play_tone(900, 0.1, 0.4)

## 播放升级音效（上升和弦）
func play_level_up() -> void:
	_play_tone(400, 0.2, 0.5)
	await get_tree().create_timer(0.1).timeout
	_play_tone(500, 0.2, 0.5)
	await get_tree().create_timer(0.1).timeout
	_play_tone(600, 0.3, 0.5)

## 播放受伤音效（低沉）
func play_hurt() -> void:
	_play_tone(150, 0.3, 0.7)

## 播放敌人死亡音效
func play_enemy_death() -> void:
	_play_tone(300, 0.2, 0.5)
	await get_tree().create_timer(0.05).timeout
	_play_tone(200, 0.2, 0.5)

## 播放传送门音效
func play_portal() -> void:
	_play_tone(500, 0.15, 0.4)
	await get_tree().create_timer(0.08).timeout
	_play_tone(700, 0.15, 0.4)
	await get_tree().create_timer(0.08).timeout
	_play_tone(1000, 0.2, 0.4)

## 内部方法：播放指定频率的音调
func _play_tone(freq: float, duration: float, volume: float) -> void:
	# 创建音频流生成器
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = duration + 0.1

	# 创建播放器
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	add_child(player)

	player.play()

	# 生成音频数据
	var playback = player.get_stream_playback()
	if playback:
		var frames = int(22050 * duration)
		var phase = 0.0
		var increment = freq / 22050.0

		for i in range(frames):
			var sample = sin(phase * TAU) * 0.8  # 正弦波
			playback.push_frame(Vector2(sample, sample))
			phase = fmod(phase + increment, 1.0)

	# 等待播放完成
	await get_tree().create_timer(duration).timeout
	player.queue_free()
