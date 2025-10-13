extends Control

var info_label: Label = null
var status_label: Label = null
var message_timer = 0.0
var message_duration = 2.0

func _ready():
	# 安全获取子节点引用
	await get_tree().process_frame  # 等待一帧确保所有节点都已创建
	info_label = get_node("VBoxContainer/InfoLabel")
	status_label = get_node("VBoxContainer/StatusLabel")
	
	# 设置初始状态
	show_status("游戏开始 - 使用A/D键移动，空格键弹反")

func _process(delta):
	# 消息自动消失计时器
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			clear_message()

func show_message(text: String, duration: float = 2.0):
	"""显示临时消息"""
	if info_label:
		info_label.text = text
		info_label.modulate = Color.WHITE
		message_timer = duration
		message_duration = duration

func show_success_message(text: String):
	"""显示成功消息（绿色）"""
	if info_label:
		info_label.text = text
		info_label.modulate = Color.GREEN
		message_timer = message_duration

func show_warning_message(text: String):
	"""显示警告消息（红色）"""
	if info_label:
		info_label.text = text
		info_label.modulate = Color.RED
		message_timer = message_duration

func show_status(text: String):
	"""显示持续状态信息"""
	if status_label:
		status_label.text = text
		status_label.modulate = Color.CYAN

func clear_message():
	"""清除临时消息"""
	if info_label:
		info_label.text = ""

func update_deflect_status(can_deflect: bool):
	"""更新弹反状态"""
	if can_deflect:
		show_status("弹反就绪 - 空格键弹反敌人")
	else:
		show_status("弹反冷却中...")

func show_e_key_prompt():
	"""显示E键击杀提示"""
	show_success_message("⏰ 时停中！按E键击杀敌人！")

func hide_e_key_prompt():
	"""隐藏E键击杀提示"""
	clear_message()
	show_status("弹反就绪 - 空格键弹反敌人")
