extends CharacterBody2D

var can_deflect = true
var deflect_cooldown = 0.5
var deflect_force = 600
var game_line_y: float = 0
var move_speed = 200
var info_panel: Control = null

func _ready():
	# 设置玩家颜色为蓝色
	$ColorRect.color = Color.BLUE

func set_info_panel(panel: Control):
	"""设置信息面板引用"""
	info_panel = panel

func set_game_line(line_y: float):
	game_line_y = line_y
	# 设置玩家位置到线上中央
	var screen_size = get_viewport().get_visible_rect().size
	position = Vector2(screen_size.x / 2, game_line_y)

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
	
	# 确保玩家始终在线上
	position.y = game_line_y
	
	# 限制玩家在屏幕范围内
	var screen_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 25, screen_size.x - 25)
	
	# 检测与敌人的碰撞 - 使用slide_collision
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies") and not collider.is_in_group("deflected"):
			if info_panel:
				info_panel.show_warning_message("💥 被敌人撞到了！游戏结束！")
			game_over()
			return
	
	# 额外的距离检测 - 防止碰撞检测遗漏
	var collision_distance = 30.0  # 碰撞距离阈值
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_in_group("deflected"):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= collision_distance:
				if info_panel:
					info_panel.show_warning_message("💥 被敌人撞到了！游戏结束！")
				game_over()
				return

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		deflect()

func deflect():
	if not can_deflect:
		if info_panel:
			info_panel.show_warning_message("⏳ 弹反冷却中，请稍等...")
		return
	
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
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_in_group("deflected"):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= deflect_range:
				# 计算弹反方向（反向）
				var direction = (enemy.global_position - global_position).normalized()
				enemy.linear_velocity = -direction * deflect_force  # 反向弹飞
				enemy.add_to_group("deflected")
				deflected_count += 1
				
				# 添加视觉效果 - 让被弹反的敌人变色
				if enemy.has_node("ColorRect"):
					enemy.get_node("ColorRect").color = Color.ORANGE
	
	# 播报弹反结果
	if info_panel:
		if deflected_count > 0:
			info_panel.show_success_message("✨ 弹反成功！击退了 " + str(deflected_count) + " 个敌人")
		else:
			info_panel.show_message("🎯 弹反释放，但没有击中敌人")
	
	# 冷却时间后恢复
	await get_tree().create_timer(deflect_cooldown).timeout
	can_deflect = true
	$ColorRect.color = Color.BLUE
	
	# 更新状态显示
	if info_panel:
		info_panel.update_deflect_status(true)

func game_over():
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
