extends RigidBody2D

# Boss属性
var dash_speed = 1600  # 增加2倍速度
var dash_cooldown = 3.0
var dash_warning_time = 1.0
var game_line_y: float = 0
var is_dashing = false
var can_dash = true
var warning_line: Line2D = null
var fixed_position_x: float

func _ready():
	add_to_group("enemies")
	add_to_group("boss_enemies")
	
	# 设置Boss颜色为深红色
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.color = Color(0.8, 0.1, 0.1)  # 深红色
		# Boss比普通怪物大一些
		color_rect.size = Vector2(60, 60)
	
	# 禁用重力
	gravity_scale = 0
	
	# 设置固定位置在屏幕右侧
	var viewport = get_viewport()
	if viewport:
		var screen_size = viewport.get_visible_rect().size
		fixed_position_x = screen_size.x - 100  # 距离右边缘100像素
	
	# 创建警告线
	create_warning_line()
	
	# 开始冲刺循环
	start_dash_cycle()
	
	# 15秒后自动销毁（比普通怪物存活时间长）
	var scene_tree = get_tree()
	if scene_tree:
		await scene_tree.create_timer(15.0).timeout
		if is_instance_valid(self):
			queue_free()

func create_warning_line():
	"""创建红色警告线"""
	warning_line = Line2D.new()
	warning_line.width = 5.0
	warning_line.default_color = Color.RED
	warning_line.visible = false
	add_child(warning_line)

func set_game_line(line_y: float):
	game_line_y = line_y
	position.y = game_line_y - 50  # 与玩家相同的Y轴位置
	position.x = fixed_position_x

func start_dash_cycle():
	"""开始冲刺循环"""
	while is_instance_valid(self) and can_dash:
		await get_tree().create_timer(dash_cooldown).timeout
		if is_instance_valid(self) and can_dash:
			await perform_dash()

func perform_dash():
	"""执行冲刺攻击"""
	if is_dashing or not can_dash:
		return
	
	# 显示警告线
	show_warning_line()
	
	# 等待警告时间
	await get_tree().create_timer(dash_warning_time).timeout
	
	if not is_instance_valid(self):
		return
	
	# 隐藏警告线
	hide_warning_line()
	
	# 开始冲刺
	is_dashing = true
	var target_x = 50  # 冲刺到屏幕左侧
	linear_velocity = Vector2(-dash_speed, 0)
	
	# 等待冲刺完成或撞到边界
	var dash_time = 0.0
	var max_dash_time = 2.0
	
	while is_dashing and dash_time < max_dash_time and position.x > target_x:
		await get_tree().process_frame
		dash_time += get_process_delta_time()
	
	# 冲刺结束，返回原位
	is_dashing = false
	linear_velocity = Vector2.ZERO
	
	# 缓慢返回固定位置
	var tween = create_tween()
	tween.tween_property(self, "position:x", fixed_position_x, 1.0)

func show_warning_line():
	"""显示红色警告线"""
	if warning_line:
		# 设置警告线从Boss位置到屏幕左侧
		warning_line.clear_points()
		warning_line.add_point(Vector2.ZERO)  # 相对于Boss的位置
		warning_line.add_point(Vector2(-position.x + 50, 0))  # 到屏幕左侧
		warning_line.visible = true

func hide_warning_line():
	"""隐藏警告线"""
	if warning_line:
		warning_line.visible = false

func _physics_process(delta):
	# 确保Boss与玩家在同一水平线上（除非正在冲刺）
	if not is_dashing:
		position.y = game_line_y - 50  # 与玩家相同的Y轴位置
		position.x = fixed_position_x
	
	# 检测与玩家的碰撞（扩大检测范围，因为玩家在线上方）
	var player = get_tree().get_first_node_in_group("player")
	if player and is_dashing:
		var distance = global_position.distance_to(player.global_position)
		if distance <= 60:  # 扩大碰撞检测范围
			# 直接触发玩家死亡
			if not player.hit_sound_played:
				print("💥 Boss撞击玩家，播放音效")
				AudioManager.play_hit_sound()
				player.hit_sound_played = true
			player.game_over()