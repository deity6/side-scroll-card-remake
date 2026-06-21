extends Control
## 战斗场景主控制器
## 管理战斗UI布局、手牌查找表排列、拖拽出牌、回合流程、胜利/失败结算

# --- 子场景引用 ---
const BATTLE_CARD_SCENE: PackedScene = preload("res://scenes/battle_card.tscn")
const CARD_Z_STEP: int = 1
const CARD_ENTRY_Z: int = 10

# --- 状态 ---
var battle: BattleState = null
var gbr: Node = null  # GlobalBattleRequest 引用
## 手牌节点列表
var _hand_card_nodes: Array = []
## 当前选中的卡牌索引
var _selected_card_index: int = -1
## 当前悬浮的卡牌索引
var _hovered_index: int = -1
## 入场动画锁：入场期间忽略悬浮信号，避免 _position_cards 与入场动画冲突
var _entry_animating: bool = false

## 根据手牌顺序设置父卡牌层级，给每张卡预留足够 z 段，避免子节点穿透相邻卡牌。
func _card_stack_z(index: int) -> int:
	return index * CARD_Z_STEP

## 发牌/抽牌飞入时使用前景层级，保证新卡从现有手牌上方插入。
func _card_entry_z(_index: int) -> int:
	return CARD_ENTRY_Z

# --- 胜利面板经验/升级动画状态 ---
## 进入战斗前的经验值/等级/升级门槛（用于胜利面板动画起点）
var _pre_exp: int = 0
var _pre_level: int = 1
var _pre_exp_to_next: int = 20

# --- UI节点引用 ---
@onready var enemy_sprite: TextureRect = %EnemySprite
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_armor_label: Label = %PlayerArmorLabel
@onready var player_ap_label: Label = %PlayerAPLabel
@onready var hand_container: Control = %HandContainer
@onready var end_turn_button: Button = %EndTurnButton
@onready var back_button: Button = %BackButton
@onready var deck_count_label: Label = %DeckCountLabel
@onready var discard_count_label: Label = %DiscardCountLabel
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_desc_label: Label = %ResultDescLabel
@onready var result_confirm_button: Button = %ResultConfirmButton
@onready var result_retry_button: Button = %ResultRetryButton
@onready var turn_label: Label = %TurnLabel
@onready var equip_container: HBoxContainer = %EquipContainer
@onready var debug_line_edit: LineEdit = %DebugLineEdit
@onready var debug_add_button: Button = %DebugAddButton
@onready var debug_hp_edit: LineEdit = %DebugHpEdit
@onready var debug_hp_button: Button = %DebugHpButton
@onready var debug_shuffle_button: Button = %DebugShuffleButton
@onready var debug_ap_edit: LineEdit = %DebugApEdit
@onready var debug_ap_button: Button = %DebugApButton
@onready var exp_bar: ProgressBar = %ExpBar
@onready var exp_label: Label = %ExpLabel
@onready var level_up_label: Label = %LevelUpLabel

func _ready() -> void:
	gbr = get_node_or_null("/root/GlobalBattleRequest")
	battle = BattleState.new()
	battle.state_changed.connect(_on_state_changed)
	battle.battle_won.connect(_on_battle_won)
	battle.battle_lost.connect(_on_battle_lost)
	battle.card_played.connect(_on_card_played)
	battle.equip_triggered.connect(_on_equip_triggered)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	back_button.pressed.connect(_on_back_pressed)
	result_confirm_button.pressed.connect(_on_confirm_pressed)
	result_retry_button.pressed.connect(_on_retry_pressed)
	result_panel.visible = false
	if debug_add_button:
		debug_add_button.pressed.connect(_on_debug_add_pressed)
	if debug_hp_button:
		debug_hp_button.pressed.connect(_on_debug_hp_pressed)
	if debug_shuffle_button:
		debug_shuffle_button.pressed.connect(_on_debug_shuffle_pressed)
	if debug_ap_button:
		debug_ap_button.pressed.connect(_on_debug_ap_pressed)
	_load_battle_data()
	_create_hand_ui()

# 从全局请求加载战斗数据
func _load_battle_data() -> void:
	if gbr and gbr.has_request:
		var enemy_hp: int = gbr.get_enemy_max_hp()
		battle.setup(gbr.player_hp, gbr.player_max_hp, gbr.ap,
			gbr.deck, enemy_hp, gbr.equipment, gbr.hand_limit)
	else:
		var test_deck: Array = CardPool.new().get_default_player_deck()
		battle.setup(52, 52, 3, test_deck, 25)
	_refresh_all()

func _refresh_all() -> void:
	_refresh_enemy()
	_refresh_player()
	_refresh_pile_counts()
	_refresh_equip()
	turn_label.text = "回合 %d" % battle.turn

func _refresh_enemy() -> void:
	enemy_hp_bar.max_value = battle.enemy_max_hp
	enemy_hp_bar.value = battle.enemy_hp
	enemy_hp_label.text = "%d/%d" % [battle.enemy_hp, battle.enemy_max_hp]
	if gbr and gbr.has_request:
		match gbr.node_type:
			0: enemy_name_label.text = "普通敌人"
			1: enemy_name_label.text = "精英敌人"
			2: enemy_name_label.text = "BOSS"
	else:
		enemy_name_label.text = "测试敌人"

func _refresh_player() -> void:
	player_hp_bar.max_value = battle.player_max_hp
	player_hp_bar.value = battle.player_hp
	player_hp_label.text = "HP: %d/%d" % [battle.player_hp, battle.player_max_hp]
	if battle.player_armor > 0:
		player_armor_label.text = "护甲: %d" % battle.player_armor
		player_armor_label.visible = true
	else:
		player_armor_label.visible = false
	player_ap_label.text = "AP: %d" % battle.ap

## 获取手牌上限（优先从 GlobalBattleRequest 读取，否则默认10）
func _get_hand_limit() -> int:
	if gbr and gbr.hand_limit > 0:
		return gbr.hand_limit
	return 10

## 调试输出三个牌堆状态（抽牌堆/手牌/弃牌堆 的 ID + 数量）
func _debug_print_status() -> void:
	var draw_ids: Array = battle.get_draw_pile_ids()
	var hand_ids: Array = battle.get_hand_ids()
	var discard_ids: Array = battle.get_discard_pile_ids()
	print("[Debug] 抽牌堆(%d): %s" % [draw_ids.size(), ",".join(draw_ids)])
	print("[Debug] 手牌(%d): %s" % [hand_ids.size(), ",".join(hand_ids)])
	print("[Debug] 弃牌堆(%d): %s" % [discard_ids.size(), ",".join(discard_ids)])

## 刷新底部信息栏：牌库数 + 手牌数/上限
func _refresh_pile_counts() -> void:
	deck_count_label.text = "牌库: %d" % battle.get_draw_pile_size()
	# 底部中央显示手牌数/上限（替代弃牌堆信息）
	discard_count_label.text = "%d/%d" % [battle.hand.size(), _get_hand_limit()]

func _refresh_equip() -> void:
	for child in equip_container.get_children():
		child.queue_free()
	for eq in battle.equipment:
		var lbl := Label.new()
		lbl.text = str(eq.get("name", "?"))
		lbl.add_theme_font_size_override("font_size", 10)
		equip_container.add_child(lbl)

# ============================================================
# 手牌排列（查找表方案，参考 STS2 HandPosHelper）
# ============================================================

## 计算第 index 张卡的目标位置、角度、缩放（考虑悬浮效果）
func _get_card_target(index: int, n: int) -> Dictionary:
	if n <= 0:
		return {"pos": Vector2.ZERO, "angle": 0.0, "scale": Vector2.ONE}

	# 从查找表获取基础位置和角度
	var offset: Vector2 = BattleConfig.get_hand_position(n, index)
	var angle_deg: float = BattleConfig.get_hand_angle(n, index)

	# 计算基准点：HandContainer 底部中心
	var base_pos: Vector2 = Vector2(hand_container.size.x / 2.0, hand_container.size.y)

	# 悬浮效果：被悬浮的卡上移，两侧卡向外推开
	var pos: Vector2 = base_pos + offset
	if index == _hovered_index:
		pos.y -= BattleConfig.HOVER_LIFT
	elif _hovered_index >= 0:
		# 两侧卡牌被推开
		var side: int = 1 if index > _hovered_index else -1
		var dist: float = absf(float(index - _hovered_index))
		var push: float = BattleConfig.HOVER_PUSH_AWAY * side * minf(dist, 2.0) / 2.0
		pos.x += push

	# 缩放：悬浮卡稍大
	var s: Vector2 = Vector2.ONE
	if index == _hovered_index:
		s = Vector2(BattleConfig.HOVER_SCALE, BattleConfig.HOVER_SCALE)

	# 转为左上角坐标（position 是 Control 的左上角）
	var top_left: Vector2 = pos - Vector2(BattleConfig.CARD_WIDTH / 2.0, BattleConfig.CARD_HEIGHT / 2.0)

	return {
		"pos": top_left,
		"angle": angle_deg,
		"scale": s
	}

## 将所有手牌排列到目标位置
func _position_cards(animate: bool = false) -> void:
	var n: int = _hand_card_nodes.size()
	if n == 0:
		return
	for i: int in range(n):
		var card = _hand_card_nodes[i]
		if card.is_dragging:
			continue  # 拖拽中不参与排列
		var target: Dictionary = _get_card_target(i, n)
		if animate:
			# 重置可见性和透明度
			card.modulate.a = 1.0
			card.visible = true
			var tw: Tween = create_tween()
			tw.set_parallel(true)
			tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(card, "position", target["pos"], BattleConfig.HAND_POSITION_DURATION)
			tw.tween_property(card, "rotation", deg_to_rad(target["angle"]), BattleConfig.HAND_POSITION_DURATION)
			tw.tween_property(card, "scale", target["scale"], BattleConfig.HAND_POSITION_DURATION)
		else:
			card.position = target["pos"]
			card.rotation = deg_to_rad(target["angle"])
			card.scale = target["scale"]
			card.modulate.a = 1.0
			card.visible = true
		card.z_index = _card_stack_z(i)

# ============================================================
# 手牌 UI 管理
# ============================================================

## 清除所有手牌节点
func _clear_hand() -> void:
	for card in _hand_card_nodes:
		card.queue_free()
	_hand_card_nodes.clear()
	_selected_card_index = -1
	_hovered_index = -1

## 创建手牌 UI（逐张从右侧弧线入场）
func _create_hand_ui() -> void:
	_entry_animating = true
	_clear_hand()
	var n: int = battle.hand.size()
	# 生成所有卡牌节点，先放在入场起点
	for i: int in range(n):
		var card_node = _create_card_node(battle.hand[i], i)
		_hand_card_nodes.append(card_node)
		card_node.position = BattleConfig.CARD_ENTRY_ORIGIN
		card_node.modulate.a = 0.0
		card_node.z_index = _card_entry_z(i)
	# 逐张延迟播放弧线入场动画
	for i: int in range(n):
		var card_node = _hand_card_nodes[i]
		var target: Dictionary = _get_card_target(i, n)
		var start_pos: Vector2 = BattleConfig.CARD_ENTRY_ORIGIN
		var end_pos: Vector2 = target["pos"]
		var arc_h: float = BattleConfig.CARD_ENTRY_ARC_HEIGHT
		var mid_pos: Vector2 = Vector2((start_pos.x + end_pos.x) / 2.0, minf(start_pos.y, end_pos.y) - arc_h)
		# 使用 tween间隔实现延迟：chain 一个空 tween
		var tw: Tween = create_tween()
		if i > 0:
			tw.tween_interval(i * BattleConfig.CARD_ENTRY_STAGGER)
		tw.tween_property(card_node, "modulate:a", 1.0, 0.15)
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_method(func(t: float, _card = card_node, _s = start_pos, _m = mid_pos, _e = end_pos):
			var p0: Vector2 = _s.lerp(_m, t)
			var p1: Vector2 = _m.lerp(_e, t)
			_card.position = p0.lerp(p1, t)
		, 0.0, 1.0, BattleConfig.CARD_ENTRY_DURATION)
		tw.parallel().tween_property(card_node, "rotation", deg_to_rad(target["angle"]), BattleConfig.CARD_ENTRY_DURATION)
		tw.parallel().tween_property(card_node, "scale", target["scale"], BattleConfig.CARD_ENTRY_DURATION)
		tw.tween_callback(func(_card = card_node, _idx = i): _card.z_index = _card_stack_z(_idx))

	# 入场动画全部结束后解锁，悬浮信号恢复生效
	var _unlock_delay: float = n * BattleConfig.CARD_ENTRY_STAGGER + BattleConfig.CARD_ENTRY_DURATION + 0.05
	var _unlock_tw: Tween = create_tween()
	_unlock_tw.tween_interval(_unlock_delay)
	_unlock_tw.tween_callback(func(): _entry_animating = false)

## 公共抽牌方法：从牌库抽取 count 张牌加入手牌，并播放增量动画
## 所有需要给玩家加牌的逻辑（debug、卡牌效果等）都应调用此方法，保持调用链一致
func _draw_cards_to_hand(count: int) -> void:
	var hand_before: int = battle.hand.size()
	var limit: int = _get_hand_limit()
	var drawn: int = battle.draw_cards(count)
	if drawn > 0:
		_refresh_hand(true)
	# 计算被自动弃除的牌数（请求量 - 实际抽到量，排除牌库不足的情况）
	var overflow: int = (hand_before + count) - limit
	if overflow > 0 and drawn > 0:
		# 有牌被超出上限自动弃除
		var kept: int = limit - hand_before
		if kept < 0:
			kept = 0
		_show_toast("手牌已满（%d/%d），%d张牌已自动弃除" % [battle.hand.size(), limit, overflow])
	elif battle.hand.size() >= limit:
		# 手牌刚好达到上限（无超出）
		_show_toast("手牌已满（%d/%d）" % [battle.hand.size(), limit])
	_refresh_pile_counts()

## 创建单个卡牌节点
func _create_card_node(card_data: Dictionary, index: int):
	var card_node = BATTLE_CARD_SCENE.instantiate()
	hand_container.add_child(card_node)
	card_node.setup(card_data, index)
	card_node.set_playable(battle.can_play_card(index))
	card_node.card_selected.connect(_on_card_selected)
	card_node.card_dropped.connect(_on_card_dropped)
	card_node.card_hovered.connect(_on_card_hovered)
	card_node.card_unhovered.connect(_on_card_unhovered)
	return card_node

## 刷新手牌显示（增量模式：已有卡牌重新排列，新卡从入场点滑入）
func _refresh_hand(animate: bool = true) -> void:
	var old_count: int = _hand_card_nodes.size()
	var new_total: int = battle.hand.size()
	# 如果手牌减少或清空，走全量刷新
	if new_total <= old_count:
		_clear_hand()
		for i: int in range(new_total):
			var card_node = _create_card_node(battle.hand[i], i)
			_hand_card_nodes.append(card_node)
		if animate:
			_position_cards(true)
		else:
			_position_cards(false)
		return
	# 手牌增加：保留已有节点，只新增超出部分
	for i: int in range(old_count, new_total):
		var card_node = _create_card_node(battle.hand[i], i)
		card_node.position = BattleConfig.CARD_ENTRY_ORIGIN
		card_node.modulate.a = 0.0
		card_node.z_index = _card_entry_z(i)
		_hand_card_nodes.append(card_node)
	# 所有卡重新排列（已有卡平滑移动，新卡弧线入场）
	if animate:
		var n: int = _hand_card_nodes.size()
		# 先让已有卡移动到新位置
		for i: int in range(old_count):
			var card = _hand_card_nodes[i]
			if card.is_dragging:
				continue
			var target: Dictionary = _get_card_target(i, n)
			var tw: Tween = create_tween()
			tw.set_parallel(true)
			tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(card, "position", target["pos"], BattleConfig.HAND_POSITION_DURATION)
			tw.tween_property(card, "rotation", deg_to_rad(target["angle"]), BattleConfig.HAND_POSITION_DURATION)
			tw.tween_property(card, "scale", target["scale"], BattleConfig.HAND_POSITION_DURATION)
			card.z_index = _card_stack_z(i)
		# 新卡弧线入场
		for i: int in range(old_count, n):
			var card_node = _hand_card_nodes[i]
			var stagger_idx: int = i - old_count
			var target: Dictionary = _get_card_target(i, n)
			var start_pos: Vector2 = BattleConfig.CARD_ENTRY_ORIGIN
			var end_pos: Vector2 = target["pos"]
			var arc_h: float = BattleConfig.CARD_ENTRY_ARC_HEIGHT
			var mid_pos: Vector2 = Vector2((start_pos.x + end_pos.x) / 2.0, minf(start_pos.y, end_pos.y) - arc_h)
			var tw: Tween = create_tween()
			if stagger_idx > 0:
				tw.tween_interval(stagger_idx * BattleConfig.CARD_ENTRY_STAGGER)
			tw.tween_property(card_node, "modulate:a", 1.0, 0.15)
			tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tw.tween_method(func(t: float, _card = card_node, _s = start_pos, _m = mid_pos, _e = end_pos):
				var p0: Vector2 = _s.lerp(_m, t)
				var p1: Vector2 = _m.lerp(_e, t)
				_card.position = p0.lerp(p1, t)
			, 0.0, 1.0, BattleConfig.CARD_ENTRY_DURATION)
			tw.parallel().tween_property(card_node, "rotation", deg_to_rad(target["angle"]), BattleConfig.CARD_ENTRY_DURATION)
			tw.parallel().tween_property(card_node, "scale", target["scale"], BattleConfig.CARD_ENTRY_DURATION)
			tw.tween_callback(func(_card = card_node, _idx = i): _card.z_index = _card_stack_z(_idx))
	else:
		_position_cards(false)

## 移除指定索引的卡牌节点
func _remove_card_by_index(index: int) -> void:
	for i in range(_hand_card_nodes.size()):
		if _hand_card_nodes[i].card_index == index:
			_hand_card_nodes[i].queue_free()
			_hand_card_nodes.remove_at(i)
			break
	# 重新编号剩余卡牌
	for i in range(_hand_card_nodes.size()):
		_hand_card_nodes[i].card_index = i
	# 用新数据刷新显示
	for i in range(mini(_hand_card_nodes.size(), battle.hand.size())):
		_hand_card_nodes[i].setup(battle.hand[i], i)
		_hand_card_nodes[i].set_playable(battle.can_play_card(i))

# ============================================================
# 信号回调
# ============================================================

func _on_card_selected(index: int) -> void:
	for card in _hand_card_nodes:
		card.set_selected(false)
	if _selected_card_index == index:
		_selected_card_index = -1
	else:
		_selected_card_index = index
		_hand_card_nodes[index].set_selected(true)

func _on_card_dropped(index: int, zone: String) -> void:
	if zone == "play":
		battle.play_card(index)
		_remove_card_by_index(index)
		_position_cards(true)
		_refresh_all()
		# 出牌后刷新所有剩余手牌的可用状态（行动力可能变化）
		for i in range(_hand_card_nodes.size()):
			_hand_card_nodes[i].set_playable(battle.can_play_card(i))
		_debug_print_status()
	elif zone == "return":
		_position_cards(true)

func _on_card_hovered(index: int) -> void:
	_hovered_index = index
	# 入场动画期间不触发重新排列，避免与入场动画冲突
	if not _entry_animating:
		_position_cards(true)

func _on_card_unhovered() -> void:
	_hovered_index = -1
	if not _entry_animating:
		_position_cards(true)

# ============================================================
# Debug 加牌按钮
# ============================================================

## debug 加牌按钮回调
## 输入数字 N 并点击"加牌"，复用公共抽牌方法 _draw_cards_to_hand
func _on_debug_add_pressed() -> void:
	var input_text: String = debug_line_edit.text.strip_edges()
	if not input_text.is_valid_int():
		return
	var count: int = int(input_text)
	if count <= 0:
		return
	_draw_cards_to_hand(count)

## debug 血量修改按钮回调
## 输入数字 N：正数加血，负数扣血（例如 +2 或 -2）
## 血量不低于0，不高于最大HP
func _on_debug_hp_pressed() -> void:
	var input_text: String = debug_hp_edit.text.strip_edges()
	if not input_text.is_valid_int():
		return
	var delta: int = int(input_text)
	if delta == 0:
		return
	battle.player_hp = clampi(battle.player_hp + delta, 0, battle.player_max_hp)
	_refresh_all()
	for i in range(_hand_card_nodes.size()):
		_hand_card_nodes[i].set_playable(battle.can_play_card(i))

## debug 行动力修改按钮回调
## 输入数字 N：正数增加行动力，负数减少行动力
## 上限 max_action_points，下限 0
func _on_debug_ap_pressed() -> void:
	var input_text: String = debug_ap_edit.text.strip_edges()
	if not input_text.is_valid_int():
		return
	var delta: int = int(input_text)
	if delta == 0:
		return
	var new_ap: int = battle.ap + delta
	var max_ap: int = battle.max_action_points
	if new_ap > max_ap:
		_show_toast("行动力已满（%d/%d）" % [battle.ap, max_ap])
		return
	if new_ap < 0:
		_show_toast("行动力不足（0/%d）" % [max_ap])
		return
	battle.ap = new_ap
	_refresh_all()
	# 刷新所有手牌的可用状态（与出牌后一致）
	for i in range(_hand_card_nodes.size()):
		_hand_card_nodes[i].set_playable(battle.can_play_card(i))
	_debug_print_status()

## debug 洗牌按钮回调
## 将弃牌堆所有卡牌洗回抽牌堆，刷新牌库显示
## 如果牌库和弃牌堆都为空，弹出提示
func _on_debug_shuffle_pressed() -> void:
	if battle.get_discard_pile_size() == 0:
		_show_toast("弃牌堆为空，无需洗牌")
		return
	var count: int = battle.shuffle_discard_to_draw()
	_refresh_pile_counts()
	_debug_print_status()
	_show_toast("洗入 %d 张牌到牌库" % count)

# ============================================================
# 回合结束
# ============================================================

func _on_end_turn_pressed() -> void:
	end_turn_button.disabled = true
	battle.discard_hand()
	battle.start_new_turn()
	_refresh_hand(true)
	_refresh_all()
	_debug_print_status()
	end_turn_button.disabled = false

# ============================================================
# 状态刷新回调
# ============================================================

func _on_state_changed() -> void:
	_refresh_enemy()
	_refresh_player()
	_refresh_pile_counts()
	_refresh_equip()
	turn_label.text = "回合 %d" % battle.turn

func _on_card_played(_card: Dictionary) -> void:
	pass

func _on_equip_triggered(_equip_name: String, _value: int) -> void:
	pass

# ============================================================
# ============================================================
# 气泡提示（非交互式，从屏幕中部渐显->停留->渐隐消失）
# ============================================================

## 显示一条气泡提示信息
## text: 提示文字，显示在屏幕中上部
func _show_toast(text: String) -> void:
	var toast_label := Label.new()
	toast_label.text = text
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 18)
	# 半透明黑色背景面板
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(toast_label)
	# 初始位置：屏幕中部偏上
	panel.position = Vector2(
		(get_viewport_rect().size.x - panel.size.x) / 2.0,
		BattleConfig.TOAST_TARGET_Y - 30.0
	)
	panel.modulate.a = 0.0
	add_child(panel)
	# 动画：渐入 -> 停留 -> 渐隐 -> 移除
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, BattleConfig.TOAST_FADE_IN)
	tw.tween_property(panel, "position:y", BattleConfig.TOAST_TARGET_Y, 0.3)
	tw.tween_interval(BattleConfig.TOAST_DURATION)
	tw.tween_property(panel, "modulate:a", 0.0, BattleConfig.TOAST_FADE_OUT)
	tw.tween_callback(panel.queue_free)

# 胜利/失败
# ============================================================

## 战斗胜利经验奖励动画 + 升级循环
## 在 _on_battle_won 中调用，动画结束后按钮才可用
func _animate_exp_reward() -> void:
	if not gbr:
		return
	# 禁用按钮，动画期间不可操作
	result_confirm_button.disabled = true
	# 获取奖励经验
	var reward: int = gbr.result_exp
	if reward <= 0:
		result_confirm_button.disabled = false
		return
	# 显示奖励文字
	result_desc_label.text = "获得 %d 经验值, %d 金币" % [reward, gbr.result_gold]
	# 初始化经验条
	var current_exp: int = _pre_exp
	var current_level: int = _pre_level
	var current_to_next: int = _pre_exp_to_next
	exp_bar.max_value = current_to_next
	exp_bar.value = current_exp
	exp_label.text = "%d/%d" % [current_exp, current_to_next]
	level_up_label.visible = false
	# 计算总经验（当前 + 奖励）
	var total_exp: int = current_exp + reward
	# --- 阶段1：动画增长经验条 ---
	var tween := create_tween()
	var target_val: float = minf(float(total_exp), float(current_to_next))
	tween.tween_property(exp_bar, "value", target_val, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		exp_label.text = "%d/%d" % [int(exp_bar.value), current_to_next]
	)
	await tween.finished
	# --- 阶段2：判断是否升级（可能多次） ---
	while total_exp >= current_to_next:
		exp_bar.value = current_to_next
		exp_label.text = "%d/%d" % [current_to_next, current_to_next]
		# 闪烁效果
		var flash := create_tween()
		flash.tween_property(exp_bar, "modulate:a", 0.3, 0.15)
		flash.tween_property(exp_bar, "modulate:a", 1.0, 0.15)
		flash.tween_property(exp_bar, "modulate:a", 0.3, 0.15)
		flash.tween_property(exp_bar, "modulate:a", 1.0, 0.15)
		await flash.finished
		# 等级+1，扣减经验，更新升级门槛
		total_exp -= current_to_next
		current_level += 1
		current_to_next = int(current_to_next * 1.5)
		# 显示升级提示
		level_up_label.visible = true
		level_up_label.text = "升级! Lv.%d | 最大HP+5, 魔力+1" % current_level
		# 经验条重置
		exp_bar.max_value = current_to_next
		exp_bar.value = 0.0
		exp_label.text = "0/%d" % current_to_next
		# 剩余经验再播一次增长
		if total_exp > 0:
			var tween2 := create_tween()
			tween2.tween_property(exp_bar, "value", float(total_exp), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween2.tween_callback(func():
				exp_label.text = "%d/%d" % [int(exp_bar.value), current_to_next]
			)
			await tween2.finished
	# --- 回写最终状态到 gbr ---
	gbr.result_level = current_level
	gbr.result_exp_value = total_exp
	gbr.result_exp_to_next = current_to_next
	# 计算升级带来的属性变化（与 adventure_player_state._level_up 保持一致）
	var level_diff: int = current_level - _pre_level
	if level_diff > 0:
		gbr.result_max_hp = gbr.player_max_hp + level_diff * 5
		gbr.result_max_mana = 2 + level_diff  # 初始 max_mana=2，每级+1
	result_confirm_button.disabled = false



func _on_battle_won() -> void:
	result_panel.visible = true
	# 初始化经验动画状态
	if gbr:
		_pre_exp = gbr.player_exp
		_pre_level = gbr.player_level
		_pre_exp_to_next = gbr.player_exp_to_next
	# 显示奖励文字
	var exp_reward: int = 0
	var gold_reward: int = 0
	if gbr:
		exp_reward = gbr.get_reward_exp()
		gold_reward = gbr.get_reward_gold()
	result_desc_label.text = "获得 %d 经验值, %d 金币" % [exp_reward, gold_reward]
	result_confirm_button.visible = true
	result_retry_button.visible = false
	# 播放经验奖励动画
	# 设置奖励经验值（动画函数需要此值）
	if gbr:
		gbr.result_exp = gbr.get_reward_exp()
		gbr.result_gold = gbr.get_reward_gold()
	_animate_exp_reward()

func _on_battle_lost() -> void:
	result_panel.visible = true
	result_title_label.text = "战斗失败..."
	result_desc_label.text = "你被击败了..."
	result_confirm_button.visible = false
	result_retry_button.visible = true
	# 失败时也记录HP
	if gbr:
		gbr.result_player_hp = battle.player_hp
		gbr.result_ap = battle.ap

func _on_confirm_pressed() -> void:
	if gbr:
		gbr.result = "win"
		gbr.result_exp = gbr.get_reward_exp()
		gbr.result_gold = gbr.get_reward_gold()
		gbr.result_player_hp = battle.player_hp
		gbr.result_ap = battle.ap
	get_tree().change_scene_to_file("res://scenes/adventure_scene.tscn")

func _on_retry_pressed() -> void:
	if gbr:
		gbr.set_retry()
		gbr.result_player_hp = 0  # 重试时恢复初始HP
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")

func _on_back_pressed() -> void:
	# 强行退出战斗，不算胜利也不算失败
	if gbr:
		gbr.result = ""
	get_tree().change_scene_to_file("res://scenes/adventure_scene.tscn")
