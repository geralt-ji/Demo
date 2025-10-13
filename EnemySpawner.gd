extends Node2D

@export var normal_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene
@export var ranged_enemy_scene: PackedScene

# 波次系统变量
var current_wave = 1
var max_waves = 3
var wave_enemies_spawned = 0
var wave_enemies_alive = 0
var wave_in_progress = false
var wave_finished = false

# 波次配置
var wave_configs = {
	1: {"type": "normal", "count": 3, "name": "第一波", "formation": "line"},
	2: {"type": "ranged", "count": 3, "name": "第二波", "formation": "mixed"},
	3: {"type": "boss", "count": 1, "name": "第三波", "formation": "single"}
}

var game_line_y: float = 0
var spawn_delay = 2.0  # 波次开始前的延迟
var spawn_timer = 0.0
var waiting_to_spawn = false

# 信号，用于通知UI更新
signal wave_started(wave_number: int, wave_name: String)
signal wave_completed(wave_number: int)
signal all_waves_completed()

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
	
	# 加载远程怪物场景
	if ResourceLoader.exists("res://RangedEnemy.tscn"):
		ranged_enemy_scene = preload("res://RangedEnemy.tscn")
	else:
		print("错误：RangedEnemy.tscn 文件不存在！")
	
	# 开始第一波
	start_next_wave()

func set_game_line(line_y: float):
	game_line_y = line_y

func _process(delta):
	# 如果正在等待生成，处理延迟
	if waiting_to_spawn:
		spawn_timer += delta
		if spawn_timer >= spawn_delay:
			spawn_wave_enemies()
			waiting_to_spawn = false
			spawn_timer = 0.0
		return
	
	# 如果波次进行中，检查是否所有敌人都死亡
	if wave_in_progress:
		check_wave_completion()

func start_next_wave():
	"""开始下一波"""
	if current_wave > max_waves:
		# 所有波次完成
		print("🎉 所有波次完成！")
		all_waves_completed.emit()
		return
	
	var wave_config = wave_configs[current_wave]
	print("🌊 " + wave_config["name"] + " 开始！")
	
	# 发送信号通知UI
	wave_started.emit(current_wave, wave_config["name"])
	
	# 重置波次状态
	wave_enemies_spawned = 0
	wave_enemies_alive = 0
	wave_in_progress = false
	wave_finished = false
	
	# 开始等待生成
	waiting_to_spawn = true
	spawn_timer = 0.0

func spawn_wave_enemies():
	"""生成当前波次的敌人"""
	var wave_config = wave_configs[current_wave]
	var enemy_type = wave_config["type"]
	var enemy_count = wave_config["count"]
	var formation = wave_config.get("formation", "single")
	
	match formation:
		"line":
			# 第一波：三个近战怪物紧随其后
			spawn_line_formation(enemy_type, enemy_count)
		"mixed":
			# 第二波：三个远程怪物，混合阵型
			spawn_mixed_formation(enemy_type, enemy_count)
		"single":
			# 第三波：单个Boss
			spawn_enemy(enemy_type, 0)
	
	wave_in_progress = true
	print("波次 " + str(current_wave) + " 敌人已生成，共 " + str(enemy_count) + " 个")

func spawn_line_formation(enemy_type: String, count: int):
	"""生成一列敌人，紧随其后"""
	for i in range(count):
		# 延迟生成，让敌人紧随其后
		await get_tree().create_timer(i * 0.5).timeout
		spawn_enemy(enemy_type, i)

func spawn_mixed_formation(enemy_type: String, count: int):
	"""生成混合阵型的远程敌人"""
	# 第一个：与玩家平行
	spawn_enemy(enemy_type, 0, "parallel")
	
	# 延迟生成上方的两个
	await get_tree().create_timer(0.3).timeout
	spawn_enemy(enemy_type, 1, "upper")
	
	await get_tree().create_timer(0.3).timeout
	spawn_enemy(enemy_type, 2, "upper")

func spawn_enemy(enemy_type: String, index: int = 0, position_type: String = "normal"):
	"""生成指定类型的敌人"""
	var enemy_scene = null
	
	match enemy_type:
		"normal":
			enemy_scene = normal_enemy_scene
		"ranged":
			enemy_scene = ranged_enemy_scene
		"boss":
			enemy_scene = boss_enemy_scene
	
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
	
	if enemy_type == "ranged":
		match position_type:
			"parallel":
				# 与玩家平行的远程怪物
				spawn_pos = Vector2(screen_size.x - 80, game_line_y - 50)
			"upper":
				# 上方的远程怪物，排成一列
				var upper_y = game_line_y - 150 - (index - 1) * 80  # index 1和2分别在不同高度
				spawn_pos = Vector2(screen_size.x - 80, upper_y)
			_:
				# 默认位置
				spawn_pos = Vector2(screen_size.x - 80, game_line_y - 50)
	elif enemy_type == "boss":
		# Boss固定在屏幕右侧，与玩家同一水平线
		spawn_pos = Vector2(screen_size.x - 100, game_line_y - 50)
	else:
		# 普通怪物（近战）从右侧生成，紧随其后
		var offset_x = index * 60  # 每个敌人间隔60像素
		spawn_pos = Vector2(screen_size.x + 50 + offset_x, game_line_y - 50)
	
	enemy.position = spawn_pos
	if enemy.has_method("set_game_line"):
		enemy.set_game_line(game_line_y)
	
	# 为远程敌人设置位置类型
	if enemy_type == "ranged" and enemy.has_method("set_position_type"):
		enemy.set_position_type(position_type)
	
	# 连接敌人死亡信号
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)
	
	wave_enemies_spawned += 1
	wave_enemies_alive += 1

func _on_enemy_died():
	"""敌人死亡回调"""
	wave_enemies_alive -= 1
	print("敌人死亡，剩余敌人：" + str(wave_enemies_alive))

func check_wave_completion():
	"""检查波次是否完成"""
	if wave_enemies_alive <= 0 and not wave_finished:
		wave_finished = true
		wave_in_progress = false
		
		print("✅ 波次 " + str(current_wave) + " 完成！")
		wave_completed.emit(current_wave)
		
		# 准备下一波
		current_wave += 1
		
		# 延迟开始下一波
		await get_tree().create_timer(2.0).timeout
		start_next_wave()

func get_current_wave() -> int:
	return current_wave

func get_wave_name() -> String:
	if current_wave <= max_waves:
		return wave_configs[current_wave]["name"]
	return "游戏完成"
