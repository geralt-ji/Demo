extends RigidBody2D

var speed = 250
var game_line_y: float = 0

func _ready():
	add_to_group("enemies")
	$ColorRect.color = Color.RED
	
	# 禁用重力，让敌人水平移动
	gravity_scale = 0
	
	# 10秒后自动销毁
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(self):
		queue_free()

func set_game_line(line_y: float):
	game_line_y = line_y
	position.y = game_line_y
	
	# 设置水平移动方向（朝向屏幕中央）
	var screen_size = get_viewport().get_visible_rect().size
	var screen_center_x = screen_size.x / 2
	
	if position.x < screen_center_x:
		# 从左侧来，向右移动
		linear_velocity = Vector2(speed, 0)
	else:
		# 从右侧来，向左移动
		linear_velocity = Vector2(-speed, 0)

func _physics_process(delta):
	# 确保敌人始终在线上
	position.y = game_line_y

func _on_body_entered(body):
	if body.name == "Player":
		# 触发玩家死亡检测
		body._on_body_entered(self)
