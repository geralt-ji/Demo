extends Node

"""
音效管理器单例 - 统一管理游戏中的所有音效
使用方法：AudioManager.play_deflect_sound()
"""

# 音效播放器节点
var deflect_player: AudioStreamPlayer
var hit_player: AudioStreamPlayer

# 音效资源
var deflect_sound: AudioStream
var hit_sound: AudioStream

# 音效状态
var is_initialized: bool = false
var audio_enabled: bool = true

func _ready():
	"""初始化音效管理器"""
	if not is_initialized:
		setup_audio_players()
		load_audio_resources()
		is_initialized = true
		print("🎵 音效管理器单例初始化完成")

func setup_audio_players():
	"""设置音效播放器"""
	# 创建弹反音效播放器
	deflect_player = AudioStreamPlayer.new()
	deflect_player.name = "DeflectPlayer"
	deflect_player.volume_db = 0  # 可调整音量
	add_child(deflect_player)
	
	# 创建受击音效播放器
	hit_player = AudioStreamPlayer.new()
	hit_player.name = "HitPlayer"
	hit_player.volume_db = 0  # 可调整音量
	add_child(hit_player)

func load_audio_resources():
	"""加载音效资源"""
	# 尝试加载弹反音效
	if ResourceLoader.exists("res://sounds/deflect.ogg"):
		deflect_sound = load("res://sounds/deflect.ogg")
		deflect_player.stream = deflect_sound
	else:
		print("警告：弹反音效文件不存在，请添加 sounds/deflect.ogg")
	
	# 尝试加载受击音效
	if ResourceLoader.exists("res://sounds/hit.ogg"):
		hit_sound = load("res://sounds/hit.ogg")
		hit_player.stream = hit_sound
	else:
		print("警告：受击音效文件不存在，请添加 sounds/hit.ogg")

func play_deflect_sound():
	"""播放弹反音效"""
	if not audio_enabled or not is_initialized:
		return
	
	if is_instance_valid(deflect_player) and deflect_player.stream:
		if not deflect_player.playing:  # 避免重复播放
			deflect_player.play()
			print("🎵 播放弹反音效")
	else:
		print("⚠️ 弹反音效未加载或播放器无效")

func play_hit_sound():
	"""播放受击音效"""
	if not audio_enabled or not is_initialized:
		return
	
	if is_instance_valid(hit_player) and hit_player.stream:
		if not hit_player.playing:  # 避免重复播放
			hit_player.play()
			print("🎵 播放受击音效")
	else:
		print("⚠️ 受击音效未加载或播放器无效")

func set_volume(volume_db: float):
	"""设置音效音量"""
	if deflect_player:
		deflect_player.volume_db = volume_db
	if hit_player:
		hit_player.volume_db = volume_db

func stop_all_sounds():
	"""停止所有音效"""
	if is_instance_valid(deflect_player):
		deflect_player.stop()
	if is_instance_valid(hit_player):
		hit_player.stop()

func enable_audio():
	"""启用音效"""
	audio_enabled = true
	print("🔊 音效已启用")

func disable_audio():
	"""禁用音效"""
	audio_enabled = false
	stop_all_sounds()
	print("🔇 音效已禁用")

func is_audio_enabled() -> bool:
	"""检查音效是否启用"""
	return audio_enabled and is_initialized

func get_deflect_player() -> AudioStreamPlayer:
	"""获取弹反音效播放器（用于高级控制）"""
	return deflect_player

func get_hit_player() -> AudioStreamPlayer:
	"""获取受击音效播放器（用于高级控制）"""
	return hit_player