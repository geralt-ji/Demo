extends Node
class_name GameEntity

"""
游戏实体基类 - 统一管理游戏对象的通用功能
所有游戏对象（玩家、敌人、生成器等）都应继承此类
"""

# 游戏线Y坐标
var game_line_y: float = 0.0

# 屏幕尺寸缓存
var _cached_screen_size: Vector2
var _screen_size_dirty: bool = true

signal game_line_changed(new_y: float)

func _ready():
	"""基类初始化"""
	# 监听视窗大小变化
	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# 缓存屏幕尺寸
	_update_screen_size_cache()

func set_game_line(line_y: float):
	"""设置游戏线位置"""
	if game_line_y != line_y:
		game_line_y = line_y
		_on_game_line_changed()
		game_line_changed.emit(line_y)

func get_game_line() -> float:
	"""获取游戏线位置"""
	return game_line_y

func get_screen_size() -> Vector2:
	"""获取屏幕尺寸（带缓存优化）"""
	if _screen_size_dirty:
		_update_screen_size_cache()
	return _cached_screen_size

func get_screen_center() -> Vector2:
	"""获取屏幕中心点"""
	var size = get_screen_size()
	return Vector2(size.x / 2, size.y / 2)

func is_position_on_screen(pos: Vector2, margin: float = 0.0) -> bool:
	"""检查位置是否在屏幕范围内"""
	var size = get_screen_size()
	return pos.x >= -margin and pos.x <= size.x + margin and \
		   pos.y >= -margin and pos.y <= size.y + margin

func clamp_position_to_screen(pos: Vector2, margin: float = 25.0) -> Vector2:
	"""将位置限制在屏幕范围内"""
	var size = get_screen_size()
	return Vector2(
		clamp(pos.x, margin, size.x - margin),
		clamp(pos.y, margin, size.y - margin)
	)

func _on_game_line_changed():
	"""游戏线位置改变时的回调（子类可重写）"""
	pass

func _on_viewport_size_changed():
	"""视窗大小改变时的回调"""
	_screen_size_dirty = true
	_update_screen_size_cache()

func _update_screen_size_cache():
	"""更新屏幕尺寸缓存"""
	if get_viewport():
		_cached_screen_size = get_viewport().get_visible_rect().size
		_screen_size_dirty = false
	else:
		_cached_screen_size = Vector2(1024, 600)  # 默认尺寸