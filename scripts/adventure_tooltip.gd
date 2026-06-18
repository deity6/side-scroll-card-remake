extends PanelContainer

# ============================================================
# 冒险模式 - 气泡提示框
# 长按属性图标时显示的详细描述浮窗
# ============================================================

# 延迟设置的文本（_ready之前调用set_text时缓存）
var _pending_text: String = ""

@onready var label: Label = %Label  # 提示文本标签

func _ready() -> void:
	# _ready时将延迟缓存的文本应用到标签
	if _pending_text and label:
		label.text = _pending_text
		_pending_text = ""

# 设置提示文本（支持在实例化后立即调用）
func set_text(value: String) -> void:
	_pending_text = value
	if label:
		label.text = value
		# 重置尺寸以适配文本内容
		size = Vector2.ZERO
		reset_size()
