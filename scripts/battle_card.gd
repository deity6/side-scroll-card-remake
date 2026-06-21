extends Control
## 战斗手牌节点
## 负责卡牌显示、点击选中、拖拽出牌、悬浮预览。

signal card_selected(card_index: int)
signal card_dropped(card_index: int, zone: String)
signal card_hovered(card_index: int)
signal card_unhovered()

var card_data: Dictionary = {}
var card_index: int = -1

var is_playable: bool = true
var is_selected: bool = false
var is_hovered: bool = false
var is_dragging: bool = false
var _base_stack_z: int = 0
const CARD_FOREGROUND_Z: int = 10

var _drag_tracking: bool = false
var _drag_active: bool = false
var _drag_mouse_start: Vector2 = Vector2.ZERO
var _drag_card_start: Vector2 = Vector2.ZERO
## 鼠标在卡牌内的相对偏移，拖拽时保持抓取点稳定。
var _drag_offset: Vector2 = Vector2.ZERO
## 拖拽目标位置，卡牌通过 lerp 跟随。
var _drag_target_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD: float = 6.0

@onready var card_base: TextureRect = $CardBase
@onready var card_frame: TextureRect = $CardFrame
@onready var art_frame: TextureRect = $ArtFrame
@onready var card_name_label: RichTextLabel = $CardName/CardNameLabel
@onready var card_desc_label: RichTextLabel = $CardDescLabel
@onready var type_label_area: TextureRect = $TypeLabelArea
@onready var type_label: RichTextLabel = $TypeLabelArea/TypeLabel
@onready var cost_area: Control = $CostArea
@onready var cost_icon: TextureRect = $CostArea/CostIcon
@onready var cost_value: Label = $CostArea/CostValue
@onready var highlight_rect: Panel = $Highlight
@onready var shadow_rect: ColorRect = $ShadowOverlay

## 类型 -> 底板纹理映射，后续只需要替换这里即可统一换肤。
var _base_textures: Dictionary = {
	"attack": preload("res://assets/cards/battle_card_pet/card_base_attack_gold.png"),
	"action": preload("res://assets/cards/battle_card_pet/card_base_action_leaf.png"),
	"equip": preload("res://assets/cards/battle_card_pet/card_base_skill_gold.png"),
}

## 类型 -> 正面框纹理映射。
var _frame_textures: Dictionary = {
	"attack": preload("res://assets/cards/battle_card_pet/card_frame_attack_window.png"),
	"action": preload("res://assets/cards/battle_card_pet/card_frame_action_window.png"),
	"equip": preload("res://assets/cards/battle_card_pet/card_frame_action_window.png"),
}

func _ready() -> void:
	custom_minimum_size = Vector2(BattleConfig.CARD_WIDTH, BattleConfig.CARD_HEIGHT)
	pivot_offset = Vector2(BattleConfig.CARD_WIDTH / 2.0, BattleConfig.CARD_HEIGHT / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_configure_text_labels()
	call_deferred("_lock_size")

## 尺寸兜底：防止 layout 系统重算导致卡牌尺寸偏移。
func _lock_size() -> void:
	custom_minimum_size = Vector2(BattleConfig.CARD_WIDTH, BattleConfig.CARD_HEIGHT)
	set_deferred("size", Vector2(BattleConfig.CARD_WIDTH, BattleConfig.CARD_HEIGHT))
	modulate.a = BattleConfig.CARD_BASE_ALPHA
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	if card_base and not card_base.texture:
		card_base.texture = preload("res://assets/cards/battle_card_pet/card_base_attack_gold.png")
	if card_frame and not card_frame.texture:
		card_frame.texture = preload("res://assets/cards/battle_card_pet/card_frame_attack_window.png")
	if art_frame:
		art_frame.visible = false

## 统一 RichTextLabel 的裁剪和对齐，避免文字越过素材框。
func _configure_text_labels() -> void:
	for label: RichTextLabel in [card_name_label, card_desc_label, type_label]:
		if not label:
			continue
		label.bbcode_enabled = false
		label.scroll_active = false
		label.fit_content = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.clip_contents = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if card_name_label:
		card_name_label.add_theme_font_size_override("normal_font_size", 14)
	if card_desc_label:
		card_desc_label.add_theme_font_size_override("normal_font_size", 15)
	if type_label:
		type_label.add_theme_font_size_override("normal_font_size", 14)

func setup(p_data: Dictionary, p_index: int) -> void:
	card_data = p_data
	card_index = p_index
	_refresh_display()

## 悬浮检测，保留原有交互结构。
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
	if card_name_label:
		card_name_label.text = str(card_data.get("name", "?"))
	if card_desc_label:
		card_desc_label.text = str(card_data.get("description", ""))
	if type_label:
		type_label.text = _type_display_name(str(card_data.get("type", "")))
	var ap_cost: int = int(card_data.get("ap_cost", 0))
	if cost_value:
		cost_value.text = str(ap_cost) if ap_cost > 0 else ""
	if cost_icon:
		cost_icon.visible = ap_cost > 0
	_apply_card_base_texture()

## 根据卡牌类型切换底板纹理。
func _apply_card_base_texture() -> void:
	if not card_base:
		return
	var ctype: String = str(card_data.get("type", ""))
	card_base.texture = _base_textures.get(ctype, preload("res://assets/cards/battle_card_pet/card_base_attack_gold.png"))
	if card_frame:
		card_frame.texture = _frame_textures.get(ctype, preload("res://assets/cards/battle_card_pet/card_frame_attack_window.png"))
	modulate.a = BattleConfig.CARD_BASE_ALPHA

func _type_display_name(ctype: String) -> String:
	match ctype:
		"attack":
			return "攻击牌"
		"action":
			return "行动牌"
		"equip":
			return "装备牌"
	return "未知"

func set_playable(playable: bool) -> void:
	is_playable = playable
	if not playable:
		shadow_rect.visible = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_apply_card_base_texture()
		shadow_rect.visible = false
		mouse_filter = Control.MOUSE_FILTER_STOP

func set_selected(selected: bool) -> void:
	is_selected = selected
	if not selected and not is_dragging:
		_base_stack_z = z_index
	highlight_rect.visible = selected
	if selected:
		z_index = CARD_FOREGROUND_Z
	else:
		z_index = _base_stack_z

func set_hovered(hovered: bool) -> void:
	is_hovered = hovered

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_playable and not _drag_active:
				_drag_tracking = true
				_drag_active = false
				_drag_mouse_start = get_global_mouse_position()
				_drag_offset = get_global_mouse_position() - global_position
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
				_base_stack_z = z_index
				_drag_active = true
				is_dragging = true
				z_index = CARD_FOREGROUND_Z
				var tw := create_tween()
				tw.tween_property(self, "scale", Vector2(BattleConfig.DRAG_SCALE, BattleConfig.DRAG_SCALE), 0.1)
		if _drag_active:
			_drag_target_pos = get_global_mouse_position() - _drag_offset

func _on_click() -> void:
	card_selected.emit(card_index)

## 每帧用 lerp 跟随目标位置，保留弹性拖拽手感。
func _process(_delta: float) -> void:
	if is_dragging and _drag_active:
		global_position = global_position.lerp(_drag_target_pos, BattleConfig.DRAG_LERP_SPEED)

func _end_drag() -> void:
	is_dragging = false
	var card_bottom_y: float = global_position.y + BattleConfig.CARD_HEIGHT
	var screen_h: float = get_viewport_rect().size.y
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
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(self, "global_position", _drag_card_start, BattleConfig.DRAG_RETURN_DURATION)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, BattleConfig.DRAG_RETURN_DURATION * 0.5)
	tw.tween_callback(func():
		is_dragging = false
		z_index = _base_stack_z
		card_dropped.emit(card_index, "return")
	)

func reset_drag_state() -> void:
	_drag_tracking = false
	_drag_active = false
	is_dragging = false
	z_index = _base_stack_z
	modulate = Color.WHITE
