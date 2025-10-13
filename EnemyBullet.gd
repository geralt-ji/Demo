extends RigidBody2D

var velocity: Vector2 = Vector2.ZERO
var lifetime = 5.0  # 子弹存活时间
var is_deflected = false  # 是否被弹反
var deflected_speed_multiplier = 2.5  # 反弹后的速度倍数
var use_gravity = false  # 是否使用重力（抛物线效果）

func _ready():
	add_to_group("enemy_bullets")
	
	# 设置敌人子弹颜色为红色
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color(0.8, 0.2, 0.2)  # 红色
		color_rect.size = Vector2(15, 8)
	
	# 根据 use_gravity 设置重力
	if use_gravity:
		gravity_scale = 0.5  # 轻微重力，实现抛物线效果
	else:
		gravity_scale = 0  # 禁用重力，直线飞行
	
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

func set_gravity(enable: bool):
	"""设置是否使用重力"""
	use_gravity = enable
	if enable:
		gravity_scale = 0.5  # 轻微重力，实现抛物线效果
	else:
		gravity_scale = 0  # 禁用重力，直线飞行

func deflect(player_position: Vector2 = Vector2.ZERO):
	"""敌人子弹被弹反 - 按原弹道返回"""
	if is_deflected:
		return  # 已经被弹反过了，不再处理
	
	is_deflected = true
	
	# 改变子弹颜色为青色，表示被弹反
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color.CYAN  # 青色表示被弹反的敌人子弹
	
	# 按原弹道返回：简单地反转X方向速度
	velocity.x = -velocity.x * deflected_speed_multiplier
	# Y方向保持不变，确保是固定弹道
	
	linear_velocity = velocity
	
	print("🔄 敌人子弹被弹反，按原弹道返回，新速度: " + str(velocity))

func _physics_process(delta):
	# 保持子弹速度
	linear_velocity = velocity
	
	# 检查是否飞出屏幕左侧
	var screen_size = get_viewport().get_visible_rect().size
	if global_position.x < -50:
		queue_free()

func _on_body_entered(body):
	"""碰撞检测回调 - 敌人子弹的碰撞逻辑"""
	print("🔍 敌人子弹碰撞检测: " + str(body.name) + ", 是否被弹反: " + str(is_deflected))
	print("🔍 碰撞对象所在组: " + str(body.get_groups()))
	
	if body.name == "Player" and not is_deflected:
		# 未被弹反的敌人子弹击中玩家
		print("💥 敌人子弹击中玩家")
		AudioManager.play_hit_sound()
		
		# 对玩家造成1点伤害
		if body.has_method("take_damage"):
			body.take_damage(1)
		
		if body.info_panel:
			body.info_panel.show_warning_message("💥 被敌人子弹击中了！")
		
		queue_free()  # 销毁子弹
	elif is_deflected and (body.name == "RangedEnemy" or body.name == "BossEnemy" or body.name == "Enemy"):
		# 被弹反的敌人子弹击中敌人
		print("🎯 弹反的敌人子弹击中敌人: " + str(body.name))
		AudioManager.play_hit_sound()
		
		# 对敌人造成1点伤害
		if body.has_method("take_damage"):
			body.take_damage(1)
			print("✅ 弹反的敌人子弹对敌人造成1点伤害")
		
		queue_free()  # 销毁子弹
	else:
		print("⚠️ 敌人子弹碰撞条件不满足 - 目标: " + str(body.name) + ", 是否弹反: " + str(is_deflected))