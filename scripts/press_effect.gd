class_name PressEffect
extends Node

# ============================================================
# 通用按下果冻效果组件
# 挂载到任意Control节点上，自动处理按下缩放+回弹动画
# 可在Inspector中调节所有参数，也可通过press_enabled开关
# ============================================================

# --- 导出属性（可在场景编辑器中调节）---
@export var press_enabled: bool = true            # 是否启用按下效果（总开关）
@export var press_down_scale: float = 0.92        # 按下时缩小到的比例
@export var press_bounce_scale: float = 0.95      # 弹回目标比例（回弹中间值）
@export var press_down_duration: float = 0.08     # 按下缩小动画时长（秒）
@export var press_up_duration: float = 0.15       # 松手弹回动画时长（秒）
@export var release_scale: float = 1.08           # 松手时弹起峰值比例
@export var release_duration: float = 0.3        # 松手回弹到1.0的时长（秒）
@export var use_elastic: bool = true              # 是否使用弹性曲线（果冻感）

# --- 内部状态 ---
var _target: Control = null       # 挂载的目标Control节点
var _tween: Tween = null          # 当前动画Tween

func _ready() -> void:
	_target = get_parent() as Control
	if not _target:
		push_warning("PressEffect: 父节点不是Control类型")
		return
	# 设置pivot到中心，确保缩放围绕中心点
	_target.pivot_offset = _target.custom_minimum_size / 2
	# 连接输入事件
	_target.gui_input.connect(_on_gui_input)

# --- 输入事件处理 ---
func _on_gui_input(event: InputEvent) -> void:
	if not press_enabled: return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_tween_down()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_tween_up()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_tween_down()
		elif not event.pressed:
			_tween_up()

# --- 动画 ---

# 按下缩小动画
func _tween_down() -> void:
	_kill_tween()
	_tween = create_tween()
	var trans := Tween.TRANS_QUAD if use_elastic else Tween.TRANS_LINEAR
	_tween.tween_property(_target, "scale", Vector2(press_down_scale, press_down_scale), press_down_duration).set_trans(trans).set_ease(Tween.EASE_OUT)
	if press_bounce_scale != press_down_scale:
		var trans2 := Tween.TRANS_ELASTIC if use_elastic else Tween.TRANS_LINEAR
		_tween.tween_property(_target, "scale", Vector2(press_bounce_scale, press_bounce_scale), press_up_duration).set_trans(trans2).set_ease(Tween.EASE_OUT)

# 松手弹回动画
func _tween_up() -> void:
	_kill_tween()
	_tween = create_tween()
	var trans := Tween.TRANS_QUAD if use_elastic else Tween.TRANS_LINEAR
	_tween.tween_property(_target, "scale", Vector2(release_scale, release_scale), press_down_duration).set_trans(trans).set_ease(Tween.EASE_OUT)
	var trans2 := Tween.TRANS_ELASTIC if use_elastic else Tween.TRANS_LINEAR
	_tween.tween_property(_target, "scale", Vector2.ONE, release_duration).set_trans(trans2).set_ease(Tween.EASE_OUT)

# 停止当前动画
func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

# --- 外部接口 ---

# 动态启用/禁用
func set_enabled(value: bool) -> void:
	press_enabled = value
	if not value:
		_kill_tween()

# 重新设置pivot（当目标尺寸变化后调用）
func refresh_pivot() -> void:
	if _target:
		_target.pivot_offset = _target.custom_minimum_size / 2
