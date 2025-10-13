extends RigidBody2D

var velocity: Vector2 = Vector2.ZERO
var lifetime = 5.0  # 子弹存活时间
var is_deflected = false  # 是否被弹反
var deflected_speed_multiplier = 2.5  # 反弹后的速度倍数

func _ready():
	add_to_group("bullets")
	
	# 设置子弹颜色为橙色
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color(1.0, 0.5, 0.0)  # 橙色
		color_rect.size = Vector2(15, 8)  # 小一些的子弹
	
	# 禁用重力
	gravity_scale = 0
	
	# 设置生存时间
	var scene_tree = get_tree()
	if scene_tree:
		await scene_tree.create_timer(lifetime).timeout
		if is_instance_valid(self):
			queue_free()

func set_velocity(new_velocity: Vector2):
	"""设置子弹速度"""
	velocity = new_velocity
	linear_velocity = velocity

func deflect(player_position: Vector2 = Vector2.ZERO):
	"""子弹被弹反"""
	if is_deflected:
		return  # 已经被弹反过了，不再处理
	
	is_deflected = true
	
	# 改变子弹颜色为蓝色，表示被弹反
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color.CYAN  # 青色表示被弹反的子弹
	
	# 如果没有提供玩家位置，使用简单的反转
	if player_position == Vector2.ZERO:
		velocity.x = -velocity.x * deflected_speed_multiplier
	else:
		# 计算从子弹到玩家的方向向量
		var to_player = (player_position - global_position).normalized()
		
		# 计算入射向量（子弹当前运动方向）
		var incident = velocity.normalized()
		
		# 计算反射向量：R = I - 2 * (I · N) * N
		# 这里N是法向量，我们使用从子弹指向玩家的方向作为"反射面"的法向量
		var normal = to_player
		var reflected = incident - 2 * incident.dot(normal) * normal
		
		# 设置新的速度（保持原速度大小并加速）
		var original_speed = velocity.length()
		velocity = reflected * original_speed * deflected_speed_multiplier
	
	linear_velocity = velocity
	
	print("🔄 子弹被弹反，新速度: " + str(velocity))

func _physics_process(delta):
	# 保持子弹速度
	linear_velocity = velocity
	
	# 检测与玩家的碰撞
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= 20.0:  # 子弹碰撞检测距离
			# 触发玩家受击
			if not player.hit_sound_played:
				print("💥 子弹击中玩家，播放音效")
				AudioManager.play_hit_sound()
				player.hit_sound_played = true
			
			if player.info_panel:
				player.info_panel.show_warning_message("💥 被子弹击中了！")
			
			# 对玩家造成1点伤害
			if player.has_method("take_damage"):
				player.take_damage(1)
			
			queue_free()  # 销毁子弹
			return
	
	# 检查是否飞出屏幕左侧
	var screen_size = get_viewport().get_visible_rect().size
	if global_position.x < -50:
		queue_free()

func _on_body_entered(body):
	"""碰撞检测回调（由场景文件信号连接调用）"""
	print("🔍 子弹碰撞检测: " + str(body.name) + ", 是否被弹反: " + str(is_deflected))
	print("🔍 碰撞对象所在组: " + str(body.get_groups()))
	
	if body.name == "Player" and not is_deflected:
		# 只有未被弹反的子弹才能伤害玩家
		print("💥 子弹碰撞玩家")
		AudioManager.play_hit_sound()
		
		# 对玩家造成1点伤害
		if body.has_method("take_damage"):
			body.take_damage(1)
		
		queue_free()  # 销毁子弹
	elif is_deflected and body.name == "Enemy":
		# 被弹反的子弹只能击中近战敌人
		print("🎯 弹反子弹击中近战敌人: " + str(body.name))
		print("🔍 敌人当前生命值: " + str(body.current_health))
		AudioManager.play_hit_sound()
		
		# 对近战敌人造成1点伤害
		if body.has_method("take_damage"):
			body.take_damage(1)
			print("✅ 对近战敌人造成1点伤害，敌人剩余生命值: " + str(body.current_health))
		else:
			print("❌ 近战敌人没有take_damage方法")
		
		queue_free()  # 销毁子弹
	elif not is_deflected and (body.name == "RangedEnemy" or body.name == "BossEnemy"):
		# 未被弹反的子弹只能击中远程敌人和Boss
		print("🎯 普通子弹击中远程敌人/Boss: " + str(body.name))
		print("🔍 敌人当前生命值: " + str(body.current_health))
		AudioManager.play_hit_sound()
		
		# 对远程敌人/Boss造成1点伤害
		if body.has_method("take_damage"):
			body.take_damage(1)
			print("✅ 对远程敌人/Boss造成1点伤害，敌人剩余生命值: " + str(body.current_health))
		else:
			print("❌ 远程敌人/Boss没有take_damage方法")
		
		queue_free()  # 销毁子弹
	else:
		print("⚠️ 碰撞条件不满足 - 玩家: " + str(body.name == "Player") + ", 未弹反: " + str(not is_deflected) + ", 敌人类型: " + str(body.name) + ", 已弹反: " + str(is_deflected))

func _on_area_2d_body_entered(body):
	"""Area2D碰撞检测回调"""
	# 调用主要的碰撞处理函数
	_on_body_entered(body)