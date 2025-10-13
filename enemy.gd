extends RigidBody2D

# 敌人死亡信号
signal enemy_died

# 敌人属性
var speed = 250
var game_line_y: float = 0  # GameEntity 功能：游戏线位置
var max_health = 1
var current_health = 1
var health_label: Label

# 时停相关属性
var time_scale: float = 1.0
var is_retreating: bool = false
var original_speed: float = 250

func _ready():
	add_to_group("enemies")
	add_to_group("normal_enemies")
	
	# 安全获取ColorRect节点 - 小怪设置
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color(1.0, 0.5, 0.5)  # 浅红色，区别于Boss
		color_rect.size = Vector2(40, 40)  # 比Boss小一些
	
	# 创建生命值显示
	create_health_display()
	
	# 禁用重力，让敌人水平移动
	gravity_scale = 0
	
	# 10秒后自动销毁
	var scene_tree = get_tree()
	if scene_tree:
		await scene_tree.create_timer(10.0).timeout
		if is_instance_valid(self):
			die()

func set_game_line(line_y: float):
	game_line_y = line_y
	position.y = game_line_y
	
	# 设置水平移动方向（只从右侧往左侧移动）
	linear_velocity = Vector2(-speed, 0)

func _physics_process(delta):
	# 确保敌人与玩家在同一水平线上
	position.y = game_line_y - 50  # 与玩家相同的Y轴位置
	
	# 应用时停效果
	var effective_speed = speed * time_scale
	
	if is_retreating:
		# 退回模式：向右移动
		linear_velocity = Vector2(effective_speed, 0)
		
		# 检查是否已经退出屏幕
		var viewport = get_viewport()
		if viewport:
			var screen_size = viewport.get_visible_rect().size
			if position.x > screen_size.x + 50:
				# 重新开始正常移动
				is_retreating = false
				position.x = screen_size.x + 50  # 从右侧重新进入
				linear_velocity = Vector2(-effective_speed, 0)
	else:
		# 正常模式：向左移动
		if linear_velocity.x == 0 or abs(linear_velocity.x) != effective_speed:
			# 设置或更新移动速度
			linear_velocity = Vector2(-effective_speed, 0)

func create_health_display():
	"""创建生命值显示"""
	health_label = Label.new()
	health_label.text = str(current_health)
	health_label.position = Vector2(-10, -60)  # 在怪物头顶显示
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	health_label.add_theme_constant_override("shadow_offset_x", 1)
	health_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(health_label)

func take_damage(damage: int):
	"""受到伤害"""
	current_health -= damage
	update_health_display()
	
	if current_health <= 0:
		die()

func update_health_display():
	"""更新生命值显示"""
	if health_label:
		health_label.text = str(current_health)

func start_retreat():
	"""开始退回"""
	print("🔄 近战敌人开始退回")
	is_retreating = true

func die():
	"""死亡处理"""
	print("💀 近战怪物死亡")
	enemy_died.emit()
	queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		# 直接触发玩家死亡
		if not body.hit_sound_played:
			print("💥 敌人撞击玩家，播放音效")
			AudioManager.play_hit_sound()
			body.hit_sound_played = true
		
		# 对玩家造成1点伤害
		if body.has_method("take_damage"):
			body.take_damage(1)
		
		# 敌人撞击玩家后死亡
		die()
