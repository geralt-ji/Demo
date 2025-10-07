extends Node2D

@export var enemy_scene: PackedScene
var spawn_timer = 0.0
var spawn_interval = 3.0  # 每3秒生成一个敌人
var game_line_y: float = 0

func _ready():
	if ResourceLoader.exists("res://Enemy.tscn"):
		enemy_scene = preload("res://Enemy.tscn")
	else:
		print("错误：Enemy.tscn 文件不存在！")

func set_game_line(line_y: float):
	game_line_y = line_y

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	if not enemy_scene:
		print("错误：enemy_scene 为空，无法生成敌人")
		return
		
	var enemy = enemy_scene.instantiate()
	if not enemy:
		print("错误：无法实例化敌人")
		return
		
	var parent = get_parent()
	if not parent:
		print("错误：无法获取父节点")
		enemy.queue_free()
		return
		
	parent.add_child(enemy)
	
	var viewport = get_viewport()
	if not viewport:
		print("错误：无法获取视口")
		enemy.queue_free()
		return
		
	var screen_size = viewport.get_visible_rect().size
	
	# 只从左右两侧生成敌人，都在游戏线上
	var spawn_from_left = randf() > 0.5
	var spawn_pos = Vector2()
	
	if spawn_from_left:
		# 从左侧生成
		spawn_pos = Vector2(-50, game_line_y)
	else:
		# 从右侧生成
		spawn_pos = Vector2(screen_size.x + 50, game_line_y)
	
	enemy.position = spawn_pos
	if enemy.has_method("set_game_line"):
		enemy.set_game_line(game_line_y)
