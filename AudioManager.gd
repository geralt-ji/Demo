extends Node

"""
音效管理器 - 负责游戏中所有音效的播放
使用方法：AudioManager.play_deflect_sound()
"""

# 音效播放器
var deflect_player: AudioStreamPlayer
var hit_player: AudioStreamPlayer

# 音效资源
var deflect_sound: AudioStream
var hit_sound: AudioStream

# 状态变量
var is_initialized: bool = false
var audio_enabled: bool = true

func _ready():
	print("🎵 AudioManager 初始化...")
	setup_audio_players()
	load_audio_resources()
	is_initialized = true
	print("✅ AudioManager 初始化完成")

func setup_audio_players():
	"""设置音效播放器"""
	print("🔧 设置音效播放器...")
	
	# 创建弹反音效播放器
	deflect_player = AudioStreamPlayer.new()
	deflect_player.name = "DeflectPlayer"
	deflect_player.volume_db = 0.0
	deflect_player.bus = "Master"
	add_child(deflect_player)
	
	# 创建受击音效播放器
	hit_player = AudioStreamPlayer.new()
	hit_player.name = "HitPlayer"
	hit_player.volume_db = 0.0
	hit_player.bus = "Master"
	add_child(hit_player)
	
	print("✅ 音效播放器设置完成")

func load_audio_resources():
	"""加载音效资源"""
	print("📂 加载音效资源...")
	
	# 加载弹反音效
	deflect_sound = load("res://sounds/deflect.mp3")
	if deflect_sound:
		deflect_player.stream = deflect_sound
		print("✅ 弹反音效加载成功")
	else:
		print("❌ 弹反音效加载失败")
	
	# 加载受击音效
	hit_sound = load("res://sounds/hit.ogg")
	if hit_sound:
		hit_player.stream = hit_sound
		print("✅ 受击音效加载成功")
	else:
		print("❌ 受击音效加载失败")

func play_deflect_sound():
	"""播放弹反音效"""
	if not audio_enabled or not is_initialized:
		return
	
	if deflect_player and deflect_player.stream:
		deflect_player.play()

func play_hit_sound():
	"""播放受击音效"""
	if not audio_enabled or not is_initialized:
		return
	
	if hit_player and hit_player.stream:
		hit_player.play()

func set_volume(volume_db: float):
	"""设置音量"""
	if deflect_player:
		deflect_player.volume_db = volume_db
	if hit_player:
		hit_player.volume_db = volume_db

func enable_audio():
	"""启用音效"""
	audio_enabled = true

func disable_audio():
	"""禁用音效"""
	audio_enabled = false

func is_audio_enabled() -> bool:
	"""检查音效是否启用"""
	return audio_enabled and is_initialized