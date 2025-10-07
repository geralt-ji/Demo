extends CharacterBody2D

var can_deflect = true
var deflect_cooldown = 0.5
var deflect_force = 600
var move_speed = 200
var info_panel: Control = null

# 音效控制
var hit_sound_played = false  # 防止受击音效重复播放

# 管理器引用
var time_stop_effect: Node = null

# GameEntity 功能
var game_line_y: float = 0

func _ready():
	# 添加到player组
	add_to_group("player")
	
	# 设置玩家颜色为蓝色
	$ColorRect.color = Color.BLUE

func set_info_panel(panel: Control):
	"""设置信息面板引用"""
	info_panel = panel



func set_time_stop_effect(effect: Node):
	"""设置时停特效引用"""
	time_stop_effect = effect

func set_game_line(line_y: float):
	game_line_y = line_y
	# 设置玩家位置到屏幕左侧，线的上方
	var screen_size = get_viewport().get_visible_rect().size
	position = Vector2(100, game_line_y - 50)  # 左侧100像素，线上方50像素

func _physics_process(delta):
	# 玩家左右移动
	var input_dir = 0
	if Input.is_action_pressed("ui_left"):
		input_dir = -1
	elif Input.is_action_pressed("ui_right"):
		input_dir = 1
	
	velocity.x = input_dir * move_speed
	velocity.y = 0  # 确保玩家不会上下移动
	
	move_and_slide()
	
	# 确保玩家始终在线的上方
	position.y = game_line_y - 50
	
	# 限制玩家在屏幕左侧范围内
	var screen_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 25, screen_size.x / 2 - 25)  # 只能在屏幕左半部分移动
	
	# 检测与敌人的碰撞 - 使用slide_collision
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if not collision:
			continue
		
		var collider = collision.get_collider()
		if not collider or not is_instance_valid(collider):
			continue
			
		if collider.is_in_group("enemies") and not collider.is_in_group("deflected"):
			# 🎵 播放受击音效
			AudioManager.play_hit_sound()
			if info_panel:
				info_panel.show_warning_message("💥 被敌人撞到了！游戏结束！")
			game_over()
			return
	
	# 额外的距离检测 - 防止碰撞检测遗漏
	var collision_distance = 30.0  # 碰撞距离阈值
	var scene_tree = get_tree()
	if not scene_tree:
		return
		
	var enemies = scene_tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		if enemy.is_in_group("deflected"):
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
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

func trigger_time_stop_on_success(deflected_count: int):
	"""弹反成功时触发时停特效"""
	if deflected_count > 0 and time_stop_effect:
		# ⏸️ 只有弹反成功才触发时停特效（传递玩家位置作为冲击点）
		time_stop_effect.trigger_time_stop(global_position)

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
	var deflected_count = 0
	
	# 获取所有敌人并检查距离
	var scene_tree = get_tree()
	if not scene_tree:
		return
		
	var enemies = scene_tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		if enemy.is_in_group("deflected"):
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= deflect_range:
			# 计算弹反方向（反向）
			var direction = (enemy.global_position - global_position).normalized()
			if direction.length() > 0:  # 确保方向向量有效
				enemy.linear_velocity = -direction * deflect_force  # 反向弹飞
				enemy.add_to_group("deflected")
				deflected_count += 1
				
				# 🎵 播放弹反音效（只在真正弹反到怪物时播放）
				if deflected_count == 1:  # 只在第一次弹反时播放音效
					print("🎵 弹反成功，播放音效")
					AudioManager.play_deflect_sound()
				
				# 添加视觉效果 - 让被弹反的敌人变色
				if enemy.has_node("ColorRect"):
					enemy.get_node("ColorRect").color = Color.ORANGE
	
	# 播报弹反结果
	if info_panel:
		if deflected_count > 0:
			info_panel.show_success_message("✨ 弹反成功！击退了 " + str(deflected_count) + " 个敌人")
		else:
			info_panel.show_message("🎯 弹反释放，但没有击中敌人")
	
	# 🎯 只有弹反成功才触发时停
	trigger_time_stop_on_success(deflected_count)
	
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
	if tree:
		await tree.create_timer(1.0).timeout
		if tree and is_instance_valid(self):
			tree.reload_current_scene()
	else:
		print("Error: Scene tree is null, cannot reload scene")
