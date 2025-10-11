extends Node2D

@export var normal_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene
var spawn_timer = 0.0
var spawn_interval = 3.0  # 每3秒生成一个敌人
var enemy_count = 0  # 敌人计数器
var game_line_y: float = 0

func _ready():
	# 加入分组，便于在游戏结束时统一管理
	add_to_group("spawners")

	# 加载普通怪物场景
	if ResourceLoader.exists("res://Enemy.tscn"):
		normal_enemy_scene = preload("res://Enemy.tscn")
	else:
		print("错误：Enemy.tscn 文件不存在！")
	
	# 加载Boss怪物场景
	if ResourceLoader.exists("res://BossEnemy.tscn"):
		boss_enemy_scene = preload("res://BossEnemy.tscn")
	else:
		print("错误：BossEnemy.tscn 文件不存在！")

func set_game_line(line_y: float):
	game_line_y = line_y

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	# 检查是否已经有Boss存在
	var existing_boss = get_tree().get_first_node_in_group("boss_enemies")
	
	var is_boss = false
	var enemy_scene = null
	
	if existing_boss:
		# 如果Boss存在，不生成任何怪物
		return
	else:
		# 增加敌人计数
		enemy_count += 1
		
		# 第三个敌人必须是Boss
		if enemy_count == 3:
			is_boss = true
			enemy_scene = boss_enemy_scene
		else:
			# 其他位置生成普通敌人
			is_boss = false
			enemy_scene = normal_enemy_scene
	
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
	var spawn_pos = Vector2()
	
	if is_boss:
		# Boss固定在屏幕右侧，与玩家同一水平线
		spawn_pos = Vector2(screen_size.x - 100, game_line_y - 50)
	else:
		# 普通怪物只从右侧生成，与玩家同一水平线
		spawn_pos = Vector2(screen_size.x + 50, game_line_y - 50)
	
	enemy.position = spawn_pos
	if enemy.has_method("set_game_line"):
		enemy.set_game_line(game_line_y)
