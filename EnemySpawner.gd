extends Node2D

@export var enemy_scene: PackedScene
var spawn_timer = 0.0
var spawn_interval = 3.0  # 每3秒生成一个敌人
var game_line_y: float = 0

func _ready():
	enemy_scene = preload("res://Enemy.tscn")

func set_game_line(line_y: float):
	game_line_y = line_y

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	
	var screen_size = get_viewport().get_visible_rect().size
	
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
	enemy.set_game_line(game_line_y)
