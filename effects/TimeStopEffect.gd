extends Node

"""
小范围时停特效系统 - 处理弹反时的局部时间暂停效果
"""

# 时停状态
var is_time_stopped: bool = false
var original_time_scale: float = 1.0
var stop_duration: float = 1.0  # 时停持续时间（1秒）
var timestop_radius: float = 200.0  # 时停影响范围

# 视觉特效
var screen_overlay: ColorRect
var timestop_area_visual: ColorRect  # 时停区域视觉提示
var flash_effect: Tween  # 在Godot 4中通过create_tween()创建
var impact_effect: Node2D  # 冲击波特效
var timestop_center: Vector2 = Vector2.ZERO  # 时停中心位置

# 受影响的对象列表
var affected_objects: Array = []

signal time_stop_started
signal time_stop_ended
signal e_key_prompt_show  # 显示E键提示
signal e_key_prompt_hide  # 隐藏E键提示

func _ready():
	"""初始化时停特效系统"""
	setup_visual_effects()
	setup_impact_effect()

func setup_visual_effects():
	"""设置视觉特效"""
	# 创建屏幕覆盖层（时停时的视觉效果）
	screen_overlay = ColorRect.new()
	screen_overlay.name = "TimeStopOverlay"
	screen_overlay.color = Color(0.8, 0.8, 1.0, 0.0)  # 淡蓝色，初始透明
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_overlay)
	
	# 创建时停区域视觉提示（浅色圆形区域）
	timestop_area_visual = ColorRect.new()
	timestop_area_visual.name = "TimeStopAreaVisual"
	timestop_area_visual.color = Color(0.9, 0.9, 1.0, 0.3)  # 浅蓝色，半透明
	timestop_area_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timestop_area_visual.visible = false
	add_child(timestop_area_visual)
	
	# 在Godot 4中，Tween通过create_tween()创建，不需要add_child
	# flash_effect 将在需要时通过 create_tween() 创建

func setup_impact_effect():
	"""设置冲击波特效"""
	# 加载冲击特效脚本
	var impact_script = load("res://effects/ImpactEffect.gd")
	if impact_script:
		impact_effect = impact_script.new()
		impact_effect.name = "ImpactEffect"
		add_child(impact_effect)
		print("✅ 冲击特效系统初始化完成")
	else:
		print("❌ 无法加载冲击特效脚本")

func trigger_time_stop(impact_position: Vector2 = Vector2.ZERO):
	"""触发小范围时停特效"""
	if is_time_stopped:
		return  # 防止重复触发
	
	print("⏸️ 小范围时停特效开始")
	is_time_stopped = true
	timestop_center = impact_position
	
	# 发出时停开始信号
	time_stop_started.emit()
	
	# 播放冲击波特效
	if impact_effect and impact_position != Vector2.ZERO:
		impact_effect.play_impact_effect(impact_position, 1.0)  # 1.0倍缩放
		print("💥 在位置 %s 播放冲击特效" % str(impact_position))
	
	# 显示时停区域视觉提示
	show_timestop_area(impact_position)
	
	# 开始视觉特效
	start_visual_effect()
	
	# 查找并减速范围内的对象
	slow_down_objects_in_range(impact_position)
	
	# 显示E键提示
	e_key_prompt_show.emit()
	
	# 使用 get_tree().create_timer 来创建计时器
	var timer = get_tree().create_timer(stop_duration)
	timer.timeout.connect(_end_time_stop)
	print("⏰ 小范围时停计时器启动，将在 %s 秒后恢复" % str(stop_duration))

func show_timestop_area(center_pos: Vector2):
	"""显示时停区域视觉提示"""
	if not timestop_area_visual:
		return
	
	# 设置圆形区域的位置和大小
	var area_size = timestop_radius * 2
	timestop_area_visual.size = Vector2(area_size, area_size)
	timestop_area_visual.position = center_pos - Vector2(timestop_radius, timestop_radius)
	timestop_area_visual.visible = true
	
	print("🔵 显示时停区域提示，中心: %s, 半径: %s" % [str(center_pos), str(timestop_radius)])

func slow_down_objects_in_range(center_pos: Vector2):
	"""减速范围内的对象"""
	affected_objects.clear()
	
	# 获取所有敌人和子弹
	var enemies = get_tree().get_nodes_in_group("enemies")
	var enemy_bullets = get_tree().get_nodes_in_group("enemy_bullets")
	
	# 检查敌人
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(center_pos)
			if distance <= timestop_radius:
				affected_objects.append(enemy)
				# 减速敌人（如果有相关方法）
				if enemy.has_method("set_time_scale"):
					enemy.set_time_scale(0.1)  # 减速到10%
				print("🐌 敌人 %s 进入时停范围，减速" % enemy.name)
	
	# 检查敌人子弹
	for bullet in enemy_bullets:
		if bullet and is_instance_valid(bullet):
			var distance = bullet.global_position.distance_to(center_pos)
			if distance <= timestop_radius:
				affected_objects.append(bullet)
				# 减速子弹
				if bullet.has_method("set_time_scale"):
					bullet.set_time_scale(0.1)  # 减速到10%
				elif "velocity" in bullet:
					bullet.velocity *= 0.1  # 直接减速
					bullet.linear_velocity *= 0.1
				print("🐌 子弹进入时停范围，减速")

func start_visual_effect():
	"""开始视觉特效"""
	# 闪光效果 - 在Godot 4中使用create_tween()
	flash_effect = create_tween()
	# 快速闪白
	flash_effect.tween_property(screen_overlay, "color:a", 0.2, 0.1)
	flash_effect.tween_property(screen_overlay, "color:a", 0.0, 0.4)

func _end_time_stop():
	"""结束小范围时停特效"""
	if not is_time_stopped:
		print("⚠️ 时停已经结束，跳过重复调用")
		return
	
	print("▶️ 小范围时停特效结束")
	is_time_stopped = false
	
	# 恢复受影响对象的速度
	restore_affected_objects()
	
	# 隐藏时停区域视觉提示
	if timestop_area_visual:
		timestop_area_visual.visible = false
	
	# 清除视觉效果
	if screen_overlay:
		screen_overlay.color.a = 0.0
	
	# 隐藏E键提示
	e_key_prompt_hide.emit()
	
	# 发出时停结束信号
	time_stop_ended.emit()

func restore_affected_objects():
	"""恢复受影响对象的正常速度"""
	for obj in affected_objects:
		if obj and is_instance_valid(obj):
			# 恢复敌人速度
			if "time_scale" in obj:
				obj.time_scale = 1.0  # 恢复正常速度
				
				# 如果是近战敌人且没有被击杀，让它退回
				if obj.is_in_group("normal_enemies") and obj.has_method("start_retreat"):
					obj.start_retreat()
					print("🔄 近战敌人 %s 开始退回" % obj.name)
				else:
					print("🔄 恢复敌人 %s 的正常速度" % obj.name)
			elif "velocity" in obj:
				# 恢复子弹速度（乘以10倍恢复）
				obj.velocity *= 10.0
				obj.linear_velocity *= 10.0
				print("🔄 恢复子弹 %s 的正常速度" % obj.name)
	
	affected_objects.clear()

func execute_e_key_kill():
	"""执行E键击杀范围内的敌人"""
	if not is_time_stopped:
		return false
	
	var killed_count = 0
	
	# 击杀范围内的敌人
	for obj in affected_objects:
		if obj and is_instance_valid(obj) and obj.is_in_group("enemies"):
			# 对敌人造成致命伤害
			if obj.has_method("take_damage"):
				obj.take_damage(999)  # 造成大量伤害确保击杀
				killed_count += 1
				print("⚡ E键击杀敌人: %s" % obj.name)
			elif obj.has_method("die"):
				obj.die()
				killed_count += 1
				print("⚡ E键击杀敌人: %s" % obj.name)
	
	if killed_count > 0:
		print("💀 E键击杀了 %d 个敌人" % killed_count)
		# 立即结束时停
		_end_time_stop()
		return true
	else:
		print("⚠️ 时停范围内没有敌人可击杀")
		return false

func set_stop_duration(duration: float):
	"""设置时停持续时间"""
	stop_duration = duration

func is_active() -> bool:
	"""检查时停是否激活"""
	return is_time_stopped

func force_end_time_stop():
	"""强制结束时停"""
	if is_time_stopped:
		_end_time_stop()