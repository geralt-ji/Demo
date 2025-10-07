extends RigidBody2D

# 敌人属性
var speed = 250
var game_line_y: float = 0  # GameEntity 功能：游戏线位置

func _ready():
	add_to_group("enemies")
	add_to_group("normal_enemies")
	
	# 安全获取ColorRect节点 - 小怪设置
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color(1.0, 0.5, 0.5)  # 浅红色，区别于Boss
		color_rect.size = Vector2(40, 40)  # 比Boss小一些
	
	# 禁用重力，让敌人水平移动
	gravity_scale = 0
	
	# 10秒后自动销毁
	var scene_tree = get_tree()
	if scene_tree:
		await scene_tree.create_timer(10.0).timeout
		if is_instance_valid(self):
			queue_free()

func set_game_line(line_y: float):
	game_line_y = line_y
	position.y = game_line_y
	
	# 设置水平移动方向（只从右侧往左侧移动）
	linear_velocity = Vector2(-speed, 0)

func _physics_process(delta):
	# 确保敌人与玩家在同一水平线上
	position.y = game_line_y - 50  # 与玩家相同的Y轴位置
	
	# 保持水平移动
	if linear_velocity.x == 0:
		# 如果速度为0，重新设置移动方向
		var viewport = get_viewport()
		if viewport:
			var screen_size = viewport.get_visible_rect().size
			var screen_center_x = screen_size.x / 2
			
			if position.x < screen_center_x:
				linear_velocity = Vector2(speed, 0)
			else:
				linear_velocity = Vector2(-speed, 0)

func _on_body_entered(body):
	if body.name == "Player":
		# 直接触发玩家死亡
		if not body.hit_sound_played:
			print("💥 敌人撞击玩家，播放音效")
			AudioManager.play_hit_sound()
			body.hit_sound_played = true
		body.game_over()
