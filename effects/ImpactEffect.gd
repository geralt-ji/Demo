extends Node2D

"""
冲击波特效 - 使用现成的Earth-Impact动画序列
自动加载所有25帧特效图片并播放动画
"""

# 特效组件
var impact_animation: AnimatedSprite2D
var particle_system: CPUParticles2D

# 特效资源
var impact_textures: Array[Texture2D] = []
var effect_duration: float = 1.0
var animation_speed: float = 25.0  # 25帧每秒，播放1秒

func _ready():
	"""初始化特效组件"""
	# 确保特效在时停期间也能正常播放
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	load_impact_textures()
	setup_animated_sprite()
	setup_particle_effect()

func load_impact_textures():
	"""加载所有冲击特效纹理"""
	print("🎨 开始加载冲击特效纹理...")
	
	# 加载所有5个文件夹中的图片
	for folder_num in range(1, 6):  # 文件夹 1-5
		for frame_num in range(1, 6):  # 每个文件夹5帧
			var global_frame = (folder_num - 1) * 5 + frame_num
			var texture_path = "res://effects/textures/%d/Earth-Impact_%02d.png" % [folder_num, global_frame]
			
			if ResourceLoader.exists(texture_path):
				var texture = load(texture_path)
				if texture:
					impact_textures.append(texture)
					print("✅ 加载纹理: %s" % texture_path)
				else:
					print("❌ 加载失败: %s" % texture_path)
			else:
				print("❌ 文件不存在: %s" % texture_path)
	
	print("📊 总共加载了 %d 帧特效" % impact_textures.size())

func setup_animated_sprite():
	"""设置动画精灵"""
	if impact_textures.size() == 0:
		print("❌ 没有找到特效纹理，无法创建动画")
		return
	
	impact_animation = AnimatedSprite2D.new()
	impact_animation.name = "ImpactAnimation"
	add_child(impact_animation)
	
	# 创建SpriteFrames资源
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("impact")
	
	# 添加所有帧
	for i in range(impact_textures.size()):
		sprite_frames.add_frame("impact", impact_textures[i])
	
	# 设置动画速度
	sprite_frames.set_animation_speed("impact", animation_speed)
	sprite_frames.set_animation_loop("impact", false)  # 不循环播放
	
	impact_animation.sprite_frames = sprite_frames
	impact_animation.visible = false
	
	# 连接动画完成信号
	impact_animation.animation_finished.connect(_on_animation_finished)
	
	print("✅ 动画精灵设置完成，包含 %d 帧" % impact_textures.size())

func setup_particle_effect():
	"""设置额外的粒子特效"""
	particle_system = CPUParticles2D.new()
	particle_system.name = "ParticleSystem"
	add_child(particle_system)
	
	# 配置粒子参数
	particle_system.emitting = false
	particle_system.amount = 20
	particle_system.lifetime = 0.8
	particle_system.one_shot = true
	
	# 发射形状
	particle_system.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particle_system.emission_sphere_radius = 30.0
	
	# 粒子运动
	particle_system.direction = Vector2(0, -1)
	particle_system.spread = 360.0
	particle_system.initial_velocity_min = 80.0
	particle_system.initial_velocity_max = 200.0
	
	# 粒子外观
	particle_system.scale_amount_min = 0.3
	particle_system.scale_amount_max = 1.0
	particle_system.color = Color(1.0, 0.8, 0.4, 0.8)  # 橙黄色

func play_impact_effect(pos: Vector2, scale_factor: float = 1.0):
	"""播放冲击特效"""
	global_position = pos
	
	print("💥 播放冲击特效在位置: %s" % str(pos))
	
	# 播放主要的动画特效
	if impact_animation and impact_textures.size() > 0:
		impact_animation.visible = true
		impact_animation.scale = Vector2(scale_factor, scale_factor)
		impact_animation.play("impact")
		print("🎬 开始播放动画，缩放: %s" % str(scale_factor))
	
	# 播放粒子特效作为补充
	if particle_system:
		particle_system.restart()
		print("✨ 启动粒子特效")

func _on_animation_finished():
	"""动画完成回调"""
	print("🏁 冲击特效动画播放完成")
	if impact_animation:
		impact_animation.visible = false

func set_animation_speed(speed: float):
	"""设置动画播放速度"""
	animation_speed = speed
	if impact_animation and impact_animation.sprite_frames:
		impact_animation.sprite_frames.set_animation_speed("impact", speed)

func set_effect_scale(scale_factor: float):
	"""设置特效缩放"""
	if impact_animation:
		impact_animation.scale = Vector2(scale_factor, scale_factor)