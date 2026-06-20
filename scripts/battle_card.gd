extends PanelContainer
## 战斗手牌节点
## 负责：卡牌显示、点击选中、拖拽出牌、悬浮预览

# --- 信号 ---
signal card_selected(card_index: int)
signal card_dropped(card_index: int, zone: String)
signal card_hovered(card_index: int)
signal card_unhovered()

# --- 卡牌数据 ---
var card_data: Dictionary = {}
var card_index: int = -1

# --- 状态 ---
var is_playable: bool = true
var is_selected: bool = false
var is_hovered: bool = false
var is_dragging: bool = false

# --- 拖拽状态 ---
var _drag_tracking: bool = false
var _drag_active: bool = false
var _drag_mouse_start: Vector2 = Vector2.ZERO
var _drag_card_start: Vector2 = Vector2.ZERO
## 鼠标在卡牌内的相对偏移（点击时记录，拖拽时保持）
var _drag_offset: Vector2 = Vector2.ZERO
## 拖拽目标位置（鼠标位置 - 偏移），卡牌通过 lerp 跟随
var _drag_target_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD: float = 6.0

# --- UI 子节点引用 ---
var name_label: Label
var desc_label: Label
var cost_label: Label
var type_label: Label
var highlight_rect: Panel
var shadow_rect: ColorRect

func _ready() -> void:
	# 固定最小尺寸
	custom_minimum_size = Vector2(BattleConfig.CARD_WIDTH, BattleConfig.CARD_HEIGHT)
	# 旋转中心在卡牌中心
	pivot_offset = Vector2(BattleConfig.CARD_WIDTH / 2.0, BattleConfig.CARD_HEIGHT / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	# 延迟锁定最终尺寸（等一帧让 layout 计算完成后再强制覆盖）
	call_deferred("_lock_size")

## 彻底锁定卡牌尺寸，防止 layout 系统重新计算
func _lock_size() -> void:
	# 强制固定尺寸
	custom_minimum_size = Vector2(BattleConfig.CARD_WIDTH, BattleConfig.CARD_HEIGHT)
	size = Vector2(BattleConfig.CARD_WIDTH, BattleConfig.CARD_HEIGHT)
	# 设置默认透明度
	modulate.a = BattleConfig.CARD_BASE_ALPHA
	# 禁用所有 size flags
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# anchors 固定在左上角
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	# 禁止 grow
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN

func _build_ui() -> void:
	# 高亮边框（默认隐藏）
	highlight_rect = Panel.new()
	highlight_rect.name = "Highlight"
	highlight_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_rect.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.9, 0.3, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(BattleConfig.CARD_CORNER_RADIUS)
	highlight_rect.add_theme_stylebox_override("panel", style)
	add_child(highlight_rect)
	# 内容容器
	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var card_size := Vector2(BattleConfig.CARD_WIDTH, BattleConfig.CARD_HEIGHT)
	var margin: float = minf(card_size.x, card_size.y) * 0.03
	vbox.offset_left = margin
	vbox.offset_right = -margin
	vbox.offset_top = margin
	vbox.offset_bottom = -margin
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	# 字体大小按卡牌短边比例
	var base: float = minf(card_size.x, card_size.y)
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", int(base * 0.075))
	vbox.add_child(name_label)
	type_label = Label.new()
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", int(base * 0.05))
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(type_label)
	desc_label = Label.new()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", int(base * 0.058))
	vbox.add_child(desc_label)
	cost_label = Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", int(base * 0.058))
	vbox.add_child(cost_label)
	# 不可用状态阴影层（默认隐藏，set_playable 时控制）
	shadow_rect = ColorRect.new()
	shadow_rect.name = "ShadowOverlay"
	shadow_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow_rect.color = BattleConfig.CARD_DISABLED_SHADOW_COLOR
	shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_rect.visible = false
	add_child(shadow_rect)

func setup(p_data: Dictionary, p_index: int) -> void:
	card_data = p_data
	card_index = p_index
	_refresh_display()

## 悬浮检测
func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		if not is_selected and not is_dragging:
			is_hovered = true
			card_hovered.emit(card_index)
	elif what == NOTIFICATION_MOUSE_EXIT:
		if not is_selected and not is_dragging:
			is_hovered = false
			card_unhovered.emit()

func _refresh_display() -> void:
	name_label.text = str(card_data.get("name", "?"))
	desc_label.text = str(card_data.get("description", ""))
	type_label.text = _type_display_name(str(card_data.get("type", "")))
	var ap_cost: int = int(card_data.get("ap_cost", 0))
	if ap_cost > 0:
		cost_label.text = "AP: %d" % ap_cost
	else:
		cost_label.text = ""
	_apply_card_color()

func _apply_card_color() -> void:
	var ctype: String = str(card_data.get("type", ""))
	match ctype:
		"attack":
			modulate = Color(0.9, 0.3, 0.3, BattleConfig.CARD_BASE_ALPHA)
		"action":
			modulate = Color(0.3, 0.6, 0.9, BattleConfig.CARD_BASE_ALPHA)
		"equip":
			modulate = Color(0.4, 0.8, 0.4, BattleConfig.CARD_BASE_ALPHA)
		_:
			modulate = Color(0.6, 0.6, 0.6, BattleConfig.CARD_BASE_ALPHA)

func _type_display_name(ctype: String) -> String:
	match ctype:
		"attack": return "攻击牌"
		"action": return "行动牌"
		"equip": return "装备牌"
	return "未知"

func set_playable(playable: bool) -> void:
	is_playable = playable
	if not playable:
		# 不可用：降低透明度 + 显示阴影遮罩 + 禁止输入
		modulate.a = BattleConfig.CARD_DISABLED_DIM
		shadow_rect.visible = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		# 可用：恢复颜色 + 隐藏阴影 + 允许输入
		_apply_card_color()
		shadow_rect.visible = false
		mouse_filter = Control.MOUSE_FILTER_STOP

func set_selected(selected: bool) -> void:
	is_selected = selected
	highlight_rect.visible = selected

func set_hovered(hovered: bool) -> void:
	is_hovered = hovered

# ============================================================
# 输入处理
# ============================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_playable and not _drag_active:
				_drag_tracking = true
				_drag_active = false
				_drag_mouse_start = get_global_mouse_position()
				# 记录鼠标点击位置与卡牌 global_position 的偏移
				_drag_offset = get_global_mouse_position() - global_position
				# 记录卡牌初始全局位置（用于回弹）
				_drag_card_start = global_position
				accept_event()

func _input(event: InputEvent) -> void:
	if not _drag_tracking:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if _drag_active:
				_end_drag()
			elif is_playable:
				_on_click()
			_drag_tracking = false
			_drag_active = false
	elif event is InputEventMouseMotion:
		if not _drag_active:
			var delta: float = get_global_mouse_position().distance_to(_drag_mouse_start)
			if delta > DRAG_THRESHOLD:
				_drag_active = true
				is_dragging = true
				z_index = 100
				# 拖拽开始时放大
				var tw := create_tween()
				tw.tween_property(self, "scale", Vector2(BattleConfig.DRAG_SCALE, BattleConfig.DRAG_SCALE), 0.1)
		if _drag_active:
			# 计算目标位置：鼠标位置 - 点击时的相对偏移
			_drag_target_pos = get_global_mouse_position() - _drag_offset

func _on_click() -> void:
	card_selected.emit(card_index)

## 每帧用 lerp 跟随目标位置（弹感滞后）
func _process(_delta: float) -> void:
	if is_dragging and _drag_active:
		global_position = global_position.lerp(_drag_target_pos, BattleConfig.DRAG_LERP_SPEED)

func _end_drag() -> void:
	is_dragging = false
	# 获取卡牌底部中心点的全局Y坐标
	var card_bottom_y: float = global_position.y + BattleConfig.CARD_HEIGHT
	var screen_h: float = get_viewport_rect().size.y
	# 底部中心点Y < 屏幕高度一半 = 打出
	if card_bottom_y < screen_h * 0.5:
		_play_card_animation()
	else:
		_return_card_animation()

func _play_card_animation() -> void:
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(0.1, 0.1), BattleConfig.PLAY_DURATION)
	tw.parallel().tween_property(self, "modulate:a", 0.0, BattleConfig.PLAY_DURATION)
	tw.tween_callback(func():
		card_dropped.emit(card_index, "play")
	)

func _return_card_animation() -> void:
	z_index = card_index
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(self, "global_position", _drag_card_start, BattleConfig.DRAG_RETURN_DURATION)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, BattleConfig.DRAG_RETURN_DURATION * 0.5)
	tw.tween_callback(func():
		is_dragging = false
		card_dropped.emit(card_index, "return")
	)

func reset_drag_state() -> void:
	_drag_tracking = false
	_drag_active = false
	is_dragging = false
	z_index = card_index
	modulate = Color.WHITE
