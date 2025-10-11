extends CharacterBody2D

var can_deflect = true
var deflect_cooldown = 0.5
var deflect_force = 600
var move_speed = 200
var info_panel: Control = null

# 音效控制
var hit_sound_played = false  # 防止受击音效重复播放

# 管理器引用
# var time_stop_effect: Node = null  # 时停功能暂时注释

# GameEntity 功能
var game_line_y: float = 0

# 时停能量条系统 - 暂时注释
# var max_energy: float = 100.0
# var current_energy: float = 100.0
# var energy_regen_rate: float = 5.0  # 每秒恢复5点
# var deflect_energy_gain: float = 30.0  # 弹反获得30点能量
# var energy_bar: ColorRect = null
# var energy_bar_container: Control = null

func _ready():
	# 添加到player组
	add_to_group("player")
	
	# 设置玩家颜色为蓝色
	$ColorRect.color = Color.BLUE
	
	# 初始化能量条引用 - 暂时注释
	# call_deferred("_initialize_energy_bar")

func set_info_panel(panel: Control):
	"""设置信息面板引用"""
	info_panel = panel



# func set_time_stop_effect(effect: Node):
# 	"""设置时停特效引用"""
# 	time_stop_effect = effect

func set_game_line(line_y: float):
	game_line_y = line_y
	# 设置玩家位置到屏幕左侧，线的上方
	var screen_size = get_viewport().get_visible_rect().size
	position = Vector2(100, game_line_y - 50)  # 左侧100像素，线上方50像素

func _physics_process(delta):
	# 能量恢复 - 暂时注释
	# if current_energy < max_energy:
	# 	current_energy = min(current_energy + energy_regen_rate * delta, max_energy)
	# 	_update_energy_bar()
	
	# 玩家左右移动
	var input_dir = 0
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		input_dir -= 1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		input_dir += 1
	
	# 设置水平速度
	velocity.x = input_dir * move_speed
	
	# 垂直方向保持在游戏线上
	velocity.y = 0
	
	# 移动
	move_and_slide()
	
	# 限制玩家在屏幕范围内
	var screen_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 50, screen_size.x - 50)
	position.y = game_line_y - 50  # 保持在线上方
	
	# 检测与敌人的碰撞
	# 检测敌人碰撞（距离检测）
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			var collision_distance = 25.0  # 碰撞检测距离（减小到25像素，给弹反更多机会）
			
			# 检查敌人是否被弹反（在deflected组中）
			if enemy.is_in_group("deflected"):
				continue  # 跳过已被弹反的敌人
			
			if distance <= collision_distance:
				# 🎵 播放受击音效（只播放一次）
				if not hit_sound_played:
					print("💥 玩家受击，播放音效")
					AudioManager.play_hit_sound()
					hit_sound_played = true
				if info_panel:
					info_panel.show_warning_message("💥 被敌人撞到了！游戏结束！")
				game_over()
				return

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		deflect()

# func trigger_time_stop_on_success(deflected_count: int):
# 	"""弹反成功时触发时停特效"""
# 	if deflected_count > 0 and time_stop_effect and can_use_timestop():
# 		# ⏸️ 只有弹反成功且能量条满时才触发时停特效（传递玩家位置作为冲击点）
# 		time_stop_effect.trigger_time_stop(global_position)
# 		# 使用时停后消耗所有能量
# 		current_energy = 0.0
# 		_update_energy_bar()
# 		print("⏸️ 时停触发！能量消耗完毕")

func deflect():
	"""弹反功能"""
	print("🛡️ deflect() 函数被调用")
	
	if not can_deflect:
		print("❌ 弹反冷却中，无法执行")
		if info_panel:
			info_panel.show_warning_message("⏳ 弹反冷却中，请稍等...")
		return
	
	print("✅ 开始执行弹反")
	can_deflect = false
	
	# 视觉反馈 - 改变颜色
	$ColorRect.color = Color.YELLOW
	
	# 更新状态显示
	if info_panel:
		info_panel.update_deflect_status(false)
	
	# 检测附近的敌人并弹反
	var deflect_range = 80.0  # 弹反范围
	var enemies = get_tree().get_nodes_in_group("enemies")
	var deflected_count = 0
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= deflect_range:
				print("🎯 弹反敌人，距离: " + str(distance))
				
				# 🎵 播放弹反音效
				AudioManager.play_deflect_sound()
				
				# 将敌人加入deflected组
				enemy.add_to_group("deflected")
				
				# 给敌人一个向右的推力
				if enemy.has_method("apply_central_impulse"):
					var push_force = Vector2(deflect_force, -200)  # 向右上推
					enemy.apply_central_impulse(push_force)
					print("💨 对敌人施加推力: " + str(push_force))
				
				deflected_count += 1
	
	if deflected_count > 0:
		print("✅ 成功弹反 " + str(deflected_count) + " 个敌人")
		if info_panel:
			info_panel.show_success_message("🛡️ 弹反成功！击退了 " + str(deflected_count) + " 个敌人")
		
		# 增加能量 - 暂时注释
		# current_energy = min(current_energy + deflect_energy_gain, max_energy)
		# _update_energy_bar()
		# print("⚡ 弹反成功，获得 " + str(deflect_energy_gain) + " 点能量，当前能量: " + str(current_energy))
	
	# 🎯 只有弹反成功才触发时停 - 暂时注释
	# trigger_time_stop_on_success(deflected_count)
	
	# 冷却时间后恢复
	var tree = get_tree()
	if tree:
		await tree.create_timer(deflect_cooldown).timeout
	can_deflect = true
	$ColorRect.color = Color.BLUE
	
	# 更新状态显示
	if info_panel:
		info_panel.update_deflect_status(true)

func game_over():
	var tree = get_tree()
	if not tree:
		print("Error: Scene tree is null, cannot show game over")
		return

	# 禁止进一步输入/移动
	set_physics_process(false)
	can_deflect = false

	# 调用主节点显示失败界面
	var main_node = tree.get_first_node_in_group("main")
	if not main_node:
		main_node = tree.current_scene
	if main_node and main_node.has_method("show_game_over"):
		main_node.show_game_over()
	else:
		print("Warning: Main node not found or show_game_over missing")

# 能量条系统函数 - 暂时注释
# func _initialize_energy_bar():
# 	"""初始化能量条引用"""
# 	var tree = get_tree()
# 	if tree:
# 		energy_bar_container = tree.get_first_node_in_group("energy_bar_container")
# 		if not energy_bar_container:
# 			# 通过路径查找能量条
# 			var main_node = tree.get_first_node_in_group("main")
# 			if not main_node:
# 				main_node = tree.current_scene
# 			if main_node:
# 				energy_bar_container = main_node.get_node_or_null("UI/EnergyBarContainer")
# 				if energy_bar_container:
# 					energy_bar = energy_bar_container.get_node_or_null("EnergyBar")
# 					_update_energy_bar()

# func _update_energy_bar():
# 	"""更新能量条显示"""
# 	if energy_bar and energy_bar_container:
# 		var energy_percentage = current_energy / max_energy
# 		energy_bar.scale.x = energy_percentage

# func add_energy(amount: float):
# 	"""增加能量"""
# 	current_energy = min(current_energy + amount, max_energy)
# 	_update_energy_bar()

# func can_use_timestop() -> bool:
# 	"""检查是否可以使用时停"""
# 	return current_energy >= max_energy
