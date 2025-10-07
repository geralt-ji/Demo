extends Node2D

# 游戏线的Y坐标（屏幕中央）
var game_line_y: float
var info_panel: Control

func _ready():
	# 设置背景色
	RenderingServer.set_default_clear_color(Color(0.2, 0.3, 0.4))  # 深蓝灰色背景
	
	# 计算游戏线位置（屏幕中央）
	var screen_size = get_viewport().get_visible_rect().size
	game_line_y = screen_size.y / 2
	
	# 创建信息播报窗口
	create_info_panel()
	
	# 通知子节点游戏线位置
	if has_node("Player"):
		$Player.set_game_line(game_line_y)
		$Player.set_info_panel(info_panel)  # 传递信息面板引用
	if has_node("EnemySpawner"):
		$EnemySpawner.set_game_line(game_line_y)

func create_info_panel():
	"""创建信息播报窗口"""
	# 创建主容器
	info_panel = Control.new()
	info_panel.name = "InfoPanel"
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	info_panel.size.y = 120
	
	# 先添加脚本（在添加子节点之前）
	var script = load("res://InfoPanel.gd")
	info_panel.set_script(script)
	
	# 创建背景面板
	var bg_panel = Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_panel.modulate = Color(0, 0, 0, 0.7)  # 半透明黑色背景
	info_panel.add_child(bg_panel)
	
	# 创建垂直布局容器
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	info_panel.add_child(vbox)
	
	# 创建信息标签（临时消息）
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = ""
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(info_label)
	
	# 创建状态标签（持续状态）
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "游戏开始 - 使用A/D键移动，空格键弹反"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.modulate = Color.CYAN
	vbox.add_child(status_label)
	
	# 最后添加到场景树
	add_child(info_panel)

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