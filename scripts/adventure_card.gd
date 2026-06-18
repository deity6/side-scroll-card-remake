extends PanelContainer

# ============================================================
# 冒险模式 - 节点卡片组件
# 三窗口中每个可交互的节点卡片
# 选中时边框发光，右上角显示关闭按钮
# 同一时间只能选中一张卡片
# ============================================================

signal card_selected(slot_index: int)
signal card_close_requested(slot_index: int)
signal card_action_requested(slot_index: int)

var title_label: Label
var desc_label: Label
var icon_rect: ColorRect
var action_button: Button
var close_button: Button

var slot_index: int = 0
var _title: String = ""
var _desc: String = ""
var _action_text: String = ""
var _icon_color: Color = Color(0.2, 0.2, 0.2, 1)
var _is_selected: bool = false
var _close_allowed: bool = true  # 是否允许显示关闭按钮

var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat

func _ready() -> void:
	title_label = $MarginContainer/VBoxContainer/TitleLabel
	desc_label = $MarginContainer/VBoxContainer/DescLabel
	icon_rect = $MarginContainer/VBoxContainer/IconRect
	action_button = $MarginContainer/VBoxContainer/ActionButton
	close_button = $CloseButton
	_create_styles()
	_sync_visual()
	gui_input.connect(_on_gui_input)
	# 连接子按钮信号
	if action_button:
		action_button.pressed.connect(func(): card_action_requested.emit(slot_index))
	if close_button:
		close_button.pressed.connect(func(): card_close_requested.emit(slot_index))

func _create_styles() -> void:
	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0, 0, 0, 0.3)
	_normal_style.set_corner_radius_all(8)
	_normal_style.set_content_margin_all(4)

	_selected_style = StyleBoxFlat.new()
	_selected_style.bg_color = Color(0, 0, 0, 0.3)
	_selected_style.set_corner_radius_all(8)
	_selected_style.set_content_margin_all(4)
	_selected_style.set_border_width_all(3)
	_selected_style.border_color = Color(1.0, 0.9, 0.4, 1.0)
	_selected_style.shadow_color = Color(1.0, 0.85, 0.2, 0.6)
	_selected_style.shadow_size = 10
	_selected_style.shadow_offset = Vector2.ZERO

func _sync_visual() -> void:
	if _is_selected and _selected_style:
		add_theme_stylebox_override("panel", _selected_style)
	elif _normal_style:
		add_theme_stylebox_override("panel", _normal_style)
	if title_label:
		title_label.text = _title
	if desc_label:
		desc_label.text = _desc
	if icon_rect:
		icon_rect.color = _icon_color
	if action_button:
		action_button.visible = _is_selected
		action_button.text = _action_text
	if close_button:
		close_button.visible = _is_selected and _close_allowed
		if _is_selected and _close_allowed:
			# 动态定位到卡片右上角
			var card_size := size
			close_button.position = Vector2(card_size.x - close_button.size.x - 4, 4)

func set_slot_index(value: int) -> void:
	slot_index = value

func set_title(text: String) -> void:
	_title = text
	if title_label:
		title_label.text = text

func set_desc(text: String) -> void:
	_desc = text
	if desc_label:
		desc_label.text = text

func set_icon_color(color: Color) -> void:
	_icon_color = color
	if icon_rect:
		icon_rect.color = color

func set_selected(value: bool) -> void:
	_is_selected = value
	_sync_visual()

func set_action_text(text: String) -> void:
	_action_text = text
	if action_button:
		action_button.text = text

func set_close_allowed(value: bool) -> void:
	_close_allowed = value

# 点击卡片面板：通知场景选中此卡片
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_selected.emit(slot_index)
