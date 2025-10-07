extends Node

"""
时停特效系统 - 处理弹反时的时间暂停效果
"""

# 时停状态
var is_time_stopped: bool = false
var original_time_scale: float = 1.0
var stop_duration: float = 3.0  # 时停持续时间（3秒）

# 视觉特效
var screen_overlay: ColorRect
var flash_effect: Tween  # 在Godot 4中通过create_tween()创建
var impact_effect: Node2D  # 冲击波特效

signal time_stop_started
signal time_stop_ended

func _ready():
	"""初始化时停特效系统"""
	setup_visual_effects()
	setup_impact_effect()

func setup_visual_effects():
	"""设置视觉特效"""
	# 创建屏幕覆盖层（时停时的视觉效果）
	screen_overlay = ColorRect.new()
	screen_overlay.name = "TimeStopOverlay"
	screen_overlay.color = Color(0.8, 0.8, 1.0, 0.0)  # 淡蓝色，初始透明
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_overlay)
	
	# 在Godot 4中，Tween通过create_tween()创建，不需要add_child
	# flash_effect 将在需要时通过 create_tween() 创建

func setup_impact_effect():
	"""设置冲击波特效"""
	# 加载冲击特效脚本
	var impact_script = load("res://effects/ImpactEffect.gd")
	if impact_script:
		impact_effect = impact_script.new()
		impact_effect.name = "ImpactEffect"
		add_child(impact_effect)
		print("✅ 冲击特效系统初始化完成")
	else:
		print("❌ 无法加载冲击特效脚本")

func trigger_time_stop(impact_position: Vector2 = Vector2.ZERO):
	"""触发时停特效"""
	if is_time_stopped:
		return  # 防止重复触发
	
	print("⏸️ 时停特效开始")
	is_time_stopped = true
	original_time_scale = Engine.time_scale
	
	# 发出时停开始信号
	time_stop_started.emit()
	
	# 播放冲击波特效
	if impact_effect and impact_position != Vector2.ZERO:
		impact_effect.play_impact_effect(impact_position, 1.5)  # 1.5倍缩放
		print("💥 在位置 %s 播放冲击特效" % str(impact_position))
	
	# 开始视觉特效
	start_visual_effect()
	
	# 设置时间缩放为很小的值而不是0（避免完全停止）
	Engine.time_scale = 0.01  # 极慢但不完全停止
	
	# 使用 get_tree().create_timer 来创建不受时间缩放影响的计时器
	var timer = get_tree().create_timer(stop_duration, true, false, true)  # 最后一个参数表示忽略时间缩放
	timer.timeout.connect(_end_time_stop)
	print("⏰ 时停计时器启动，将在 %s 秒后恢复" % str(stop_duration))

func start_visual_effect():
	"""开始视觉特效"""
	# 闪光效果 - 在Godot 4中使用create_tween()
	flash_effect = create_tween()
	# 快速闪白
	flash_effect.tween_property(screen_overlay, "color:a", 0.3, 0.1)
	flash_effect.tween_property(screen_overlay, "color:a", 0.1, 0.2)
	flash_effect.tween_property(screen_overlay, "color:a", 0.0, 0.7)

func _end_time_stop():
	"""结束时停特效"""
	if not is_time_stopped:
		print("⚠️ 时停已经结束，跳过重复调用")
		return
	
	print("▶️ 时停特效结束，恢复正常时间流速")
	is_time_stopped = false
	
	# 恢复时间缩放
	Engine.time_scale = original_time_scale
	print("🔄 时间缩放恢复到: %s" % str(original_time_scale))
	
	# 清除视觉效果
	if screen_overlay:
		screen_overlay.color.a = 0.0
	
	# 发出时停结束信号
	time_stop_ended.emit()

func set_stop_duration(duration: float):
	"""设置时停持续时间"""
	stop_duration = duration

func is_active() -> bool:
	"""检查时停是否激活"""
	return is_time_stopped

func force_end_time_stop():
	"""强制结束时停"""
	if is_time_stopped:
		_end_time_stop()