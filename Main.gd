extends Node2D

# 游戏线的Y坐标（屏幕中央）
var game_line_y: float
var info_panel: Control

# 管理器引用
var time_stop_effect: Node

# 失败界面引用
var game_over_panel: Control
var restart_button: Button

# 波次显示相关
var wave_label: Label

func _ready():
	# 设置背景色
	RenderingServer.set_default_clear_color(Color(0.2, 0.3, 0.4))  # 深蓝灰色背景
	
	# 计算游戏线位置（屏幕中央）
	var screen_size = get_viewport().get_visible_rect().size
	game_line_y = screen_size.y / 2

	# 将主节点加入组，便于其他脚本查找
	add_to_group("main")
	
	# 创建管理器
	create_managers()
	
	# 创建信息播报窗口
	create_info_panel()
	
	# 创建游戏结束界面
	create_game_over_panel()
	
	# 设置玩家的游戏线位置
	$Player.set_game_line(game_line_y)
	$Player.set_info_panel(info_panel)
	$Player.set_time_stop_effect(time_stop_effect)  # 传递时停特效
	
	# 连接时停效果的信号到InfoPanel
	if time_stop_effect:
		time_stop_effect.e_key_prompt_show.connect(info_panel.show_e_key_prompt)
		time_stop_effect.e_key_prompt_hide.connect(info_panel.hide_e_key_prompt)
	
	# 设置敌人生成器的游戏线位置
	$EnemySpawner.set_game_line(game_line_y)
	
	# 连接敌人生成器的信号
	$EnemySpawner.wave_started.connect(_on_wave_started)
	$EnemySpawner.wave_completed.connect(_on_wave_completed)
	$EnemySpawner.all_waves_completed.connect(_on_all_waves_completed)
	
	# 获取波次显示标签
	wave_label = $UI/WaveDisplay/WaveLabel

func create_info_panel():
	"""创建信息面板"""
	info_panel = Control.new()
	info_panel.name = "InfoPanel"
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	info_panel.size.y = 100
	
	# 设置脚本
	var info_script = load("res://InfoPanel.gd")
	info_panel.set_script(info_script)
	
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_panel.add_child(vbox)
	
	# 创建信息标签
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(info_label)
	
	# 创建状态标签
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(status_label)
	
	add_child(info_panel)

func create_game_over_panel():
	"""创建游戏结束面板"""
	game_over_panel = Control.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.visible = false
	# 设置为在暂停时也能处理输入
	game_over_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# 创建半透明背景
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.add_child(background)
	
	# 创建中央容器
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.add_child(center_container)
	
	# 创建垂直布局
	var vbox = VBoxContainer.new()
	center_container.add_child(vbox)
	
	# 游戏结束标题
	var title_label = Label.new()
	title_label.text = "游戏结束"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(title_label)
	
	# 添加间距
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	# 重新开始按钮
	restart_button = Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_button)
	
	add_child(game_over_panel)

func show_game_over():
	"""显示游戏结束界面"""
	# 暂停游戏
	get_tree().paused = true
	
	# 停止所有敌人生成器
	var spawners = get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		if spawner:
			spawner.set_process(false)
	
	# 显示游戏结束面板
	if game_over_panel:
		game_over_panel.visible = true
	if info_panel and info_panel.has_method("show_warning_message"):
		info_panel.show_warning_message("💀 游戏失败，点击重新开始")

func _on_restart_pressed():
	"""点击重新开始按钮，重载当前场景"""
	# 恢复游戏时间和暂停状态
	get_tree().paused = false
	Engine.time_scale = 1.0
	var tree = get_tree()
	if tree:
		tree.reload_current_scene()

func create_managers():
	"""创建特效管理器"""
	# 创建时停特效管理器
	time_stop_effect = Node.new()
	time_stop_effect.name = "TimeStopEffect"
	var timestop_script = load("res://effects/TimeStopEffect.gd")
	time_stop_effect.set_script(timestop_script)
	add_child(time_stop_effect)
	
	print("🎮 特效管理器已创建")
	print("🎵 AudioManager 单例已自动加载")

func _draw():
	# 绘制中央线条
	var screen_size = get_viewport().get_visible_rect().size
	var line_start = Vector2(0, game_line_y)
	var line_end = Vector2(screen_size.x, game_line_y)
	
	# 绘制白色线条，宽度为3像素
	draw_line(line_start, line_end, Color.WHITE, 3.0)
	
	# 绘制线条上的小标记点（每100像素一个）
	for x in range(0, int(screen_size.x), 100):
		var mark_start = Vector2(x, game_line_y - 10)
		var mark_end = Vector2(x, game_line_y + 10)
		draw_line(mark_start, mark_end, Color.YELLOW, 2.0)

# 波次信号处理函数
func _on_wave_started(wave_number: int, wave_name: String):
	"""波次开始时更新UI"""
	if wave_label:
		wave_label.text = wave_name
		wave_label.add_theme_color_override("font_color", Color.WHITE)
	
	if info_panel and info_panel.has_method("show_success_message"):
		info_panel.show_success_message("🌊 " + wave_name + " 开始！")

func _on_wave_completed(wave_number: int):
	"""波次完成时的处理"""
	if info_panel and info_panel.has_method("show_success_message"):
		info_panel.show_success_message("✅ 第" + str(wave_number) + "波完成！")

func _on_all_waves_completed():
	"""所有波次完成时的处理"""
	if wave_label:
		wave_label.text = "🎉 游戏胜利！"
		wave_label.add_theme_color_override("font_color", Color.GOLD)
	
	if info_panel and info_panel.has_method("show_success_message"):
		info_panel.show_success_message("🎉 恭喜！所有波次完成！")