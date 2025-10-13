extends RigidBody2D

# 敌人死亡信号
signal enemy_died

# 远程敌人属性
var shoot_interval = 2.0  # 射击间隔
var bullet_speed = 300  # 子弹速度
var game_line_y: float = 0
var fixed_position_x: float
var can_shoot = true
var bullet_scene: PackedScene
var max_health = 1
var current_health = 1
var health_label: Label

# 子弹限制
var current_bullet: Node = null  # 当前存在的子弹引用
var time_scale: float = 1.0  # 时停效果
var position_type: String = "parallel"  # 位置类型：parallel（平行）或 upper（上方）

func _ready():
	add_to_group("enemies")
	add_to_group("ranged_enemies")
	
	# 设置远程敌人颜色为紫色
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color(0.6, 0.2, 0.8)  # 紫色
		color_rect.size = Vector2(40, 40)
	
	# 创建生命值显示
	create_health_display()
	
	# 禁用重力
	gravity_scale = 0
	
	# 设置固定位置在屏幕右侧
	var viewport = get_viewport()
	if viewport:
		var screen_size = viewport.get_visible_rect().size
		fixed_position_x = screen_size.x - 80  # 距离右边缘80像素
	
	# 加载敌人子弹场景
	bullet_scene = preload("res://EnemyBullet.tscn")
	
	# 开始射击循环
	start_shooting_cycle()
	
	# 10秒后自动销毁
	var scene_tree = get_tree()
	if scene_tree:
		await scene_tree.create_timer(10.0).timeout
		if is_instance_valid(self):
			die()

func set_game_line(line_y: float):
	game_line_y = line_y

func set_position_type(type: String):
	"""设置位置类型，用于决定攻击模式"""
	position_type = type
	print("🎯 远程敌人位置类型设置为：" + type)
	position.y = game_line_y - 50  # 与玩家相同的Y轴位置
	position.x = fixed_position_x

func start_shooting_cycle():
	"""开始射击循环"""
	while is_instance_valid(self) and can_shoot:
		# 若被弹反，停止射击
		if is_in_group("deflected"):
			can_shoot = false
			break
		
		var tree = get_tree()
		if not tree:
			break
		
		await tree.create_timer(shoot_interval).timeout
		
		if is_instance_valid(self) and can_shoot and not is_in_group("deflected"):
			shoot_bullet()

func shoot_bullet():
	"""发射子弹 - 固定弹道"""
	if not bullet_scene or is_in_group("deflected"):
		return
	
	# 检查是否已有子弹存在
	if current_bullet and is_instance_valid(current_bullet):
		print("⏸️ 远程敌人已有子弹存在，跳过射击")
		return
	
	# 创建子弹实例
	var bullet = bullet_scene.instantiate()
	if not bullet:
		print("❌ 无法创建子弹实例")
		return
	
	# 设置子弹位置（从敌人中心位置发射）
	bullet.global_position = global_position
	
	# 根据位置类型设置子弹速度
	if bullet.has_method("set_velocity"):
		var velocity = Vector2()
		
		if position_type == "upper":
			# 上方敌人：抛物线攻击，向玩家位置发射
			var player = get_tree().get_first_node_in_group("player")
			if player:
				var direction = (player.global_position - global_position).normalized()
				# 添加重力效果的抛物线轨迹
				velocity = Vector2(direction.x * bullet_speed * 0.8, direction.y * bullet_speed * 0.6)
				print("🏹 上方敌人发射抛物线子弹")
			else:
				# 如果找不到玩家，使用默认向下的抛物线
				velocity = Vector2(-bullet_speed * 0.7, bullet_speed * 0.5)
		else:
			# 平行敌人：固定弹道，直线向左飞行
			velocity = Vector2(-bullet_speed, 0)
			print("🔫 平行敌人发射固定弹道子弹")
		
		bullet.set_velocity(velocity)
	
	# 为上方敌人的子弹启用重力（抛物线效果）
	if position_type == "upper" and bullet.has_method("set_gravity"):
		bullet.set_gravity(true)
	
	# 保存子弹引用
	current_bullet = bullet
	
	# 连接子弹的销毁信号，以便清除引用
	if bullet.has_signal("tree_exiting"):
		bullet.tree_exiting.connect(_on_bullet_destroyed)
	
	# 将敌人子弹添加到场景
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(bullet)
		print("🔫 远程敌人发射固定弹道子弹")

func _physics_process(delta):
	# 确保远程敌人保持在固定位置
	position.y = game_line_y - 50
	position.x = fixed_position_x

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

func _on_bullet_destroyed():
	"""子弹销毁时的回调"""
	current_bullet = null
	print("🔄 远程敌人的子弹已销毁，可以发射新子弹")

func die():
	"""死亡处理"""
	print("💀 远程怪物死亡")
	can_shoot = false  # 停止射击
	
	# 清除子弹引用
	current_bullet = null
	
	enemy_died.emit()
	queue_free()
	
	# 若被弹反，停止所有行为
	if is_in_group("deflected"):
		can_shoot = false
		# 被弹反后向右推出屏幕
		linear_velocity = Vector2(200, -100)