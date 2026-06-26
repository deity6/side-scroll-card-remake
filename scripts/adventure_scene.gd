extends Control

# ============================================================
# 冒险场景主控制器
# 管理三窗口节点选择界面、HUD显示、存档、气泡提示
# 核心流程：显示3个节点卡片 -> 玩家选择 -> 事件处理 -> 刷新UI
# ============================================================

# --- 常量 ---
const TOOLTIP_SCENE_PATH := "res://scenes/adventure_tooltip.tscn" # 气泡提示场景路径
# 战斗类节点类型集合（用于判断是否跳转战斗场景）
const BATTLE_TYPES: Array = [
	ChapterNodeManager.NodeType.BATTLE,
	ChapterNodeManager.NodeType.ELITE,
	ChapterNodeManager.NodeType.BOSS,
]

# 各节点类型对应的卡片颜色（色块显示）
const CARD_COLORS := {
	ChapterNodeManager.NodeType.BATTLE: Color(0.52, 0.20, 0.20, 1),    # 红色 - 普通战斗
	ChapterNodeManager.NodeType.ELITE: Color(0.70, 0.28, 0.10, 1),     # 橙红 - 精英战斗
	ChapterNodeManager.NodeType.BOSS: Color(0.64, 0.08, 0.08, 1),      # 深红 - BOSS
	ChapterNodeManager.NodeType.REST: Color(0.18, 0.52, 0.28, 1),      # 绿色 - 休息
	ChapterNodeManager.NodeType.SMITH: Color(0.32, 0.34, 0.38, 1),     # 灰色 - 铁匠
	ChapterNodeManager.NodeType.SHOP: Color(0.58, 0.50, 0.12, 1),      # 金色 - 商店
	ChapterNodeManager.NodeType.CHEST: Color(0.56, 0.42, 0.12, 1),     # 棕金 - 宝箱
	ChapterNodeManager.NodeType.NEXT_CHAPTER: Color(0.22, 0.36, 0.62, 1), # 蓝色 - 下一章
}

# --- 数据对象 ---
var chapter := AdventureState.new()   # 冒险状态管理器
var player: AdventurePlayerState      # 玩家状态引用

# --- 三窗口状态 ---
var _slot_card_data: Array = []       # 三个槽位当前显示的线路索引（-1=空）

# --- 气泡提示 ---
var _tooltip_scene: PackedScene = preload(TOOLTIP_SCENE_PATH)  # 提示场景预加载
var _active_tooltip: Node = null                               # 当前活跃的提示节点

# --- 三窗口槽位节点引用 ---
@onready var card_slot1: PanelContainer = %CardSlot1
@onready var card_slot2: PanelContainer = %CardSlot2
@onready var card_slot3: PanelContainer = %CardSlot3
# --- UI节点引用（%唯一名称绑定）---
@onready var chapter_label: Label = %ChapterLabel       # 章节标签（右上角）
@onready var gold_label: Label = %GoldLabel             # 金币显示（左上角）
@onready var remaining_label: Label = %RemainingLabel   # 剩余节点数（顶部居中）
@onready var card_pack_button: Button = %CardPackButton # 卡牌包按钮（左下角）
@onready var hp_bar: ProgressBar = %HpBar               # 血条
@onready var hp_label: Label = %HpLabel                 # 血量数字
@onready var exp_bar: ProgressBar = %ExpBar             # 经验条
@onready var exp_label: Label = %ExpLabel               # 经验数字
@onready var mana_button: Button = %ManaButton          # 魔力值按钮（右下角）
@onready var ap_button: Button = %ApButton              # 行动力按钮
@onready var limit_button: Button = %LimitButton        # 卡牌上限按钮
@onready var tooltip_anchor: Control = %TooltipAnchor   # 气泡提示锚点
@onready var back_button: Button = %BackButton          # 返回按钮

# 根据节点类型返回动作按钮文字
func _node_action_text(node_type: int) -> String:
	var t := node_type
	if t == ChapterNodeManager.NodeType.BATTLE: return "战斗"
	if t == ChapterNodeManager.NodeType.ELITE: return "精英战斗"
	if t == ChapterNodeManager.NodeType.BOSS: return "BOSS战斗"
	if t == ChapterNodeManager.NodeType.REST: return "休息恢复"
	if t == ChapterNodeManager.NodeType.SMITH: return "升级卡牌"
	if t == ChapterNodeManager.NodeType.SHOP: return "进入商店"
	if t == ChapterNodeManager.NodeType.CHEST: return "打开宝箱"
	if t == ChapterNodeManager.NodeType.NEXT_CHAPTER: return "前往下一章"
	return "?"

# 根据属性key返回气泡提示文本
func _tooltip_text(key: String) -> String:
	if key == "hp": return "当前生命值，归零后死亡"
	if key == "gold": return "金币，可在商店使用"
	if key == "mana": return "魔力值，每回合恢复"
	if key == "action_points": return "行动力，每回合可打出的条数"
	if key == "card_limit": return "卡牌上限，可持有的卡牌数"
	return ""

func _ready() -> void:
	# 为底部HUD按钮添加果冻按下效果
	_add_press_effect(back_button)
	_add_press_effect(card_pack_button)
	_add_press_effect(mana_button)
	_add_press_effect(ap_button)
	_add_press_effect(limit_button)
	# 连接按钮信号
	back_button.pressed.connect(_on_back_button_pressed)
	card_pack_button.gui_input.connect(_on_card_pack_gui_input)
	mana_button.gui_input.connect(_on_mana_gui_input)
	ap_button.gui_input.connect(_on_ap_gui_input)
	limit_button.gui_input.connect(_on_limit_gui_input)
	# 连接三张卡片的信号
	card_slot1.card_selected.connect(_on_card_selected)
	card_slot2.card_selected.connect(_on_card_selected)
	card_slot3.card_selected.connect(_on_card_selected)
	card_slot1.card_close_requested.connect(_on_card_close_requested)
	card_slot2.card_close_requested.connect(_on_card_close_requested)
	card_slot3.card_close_requested.connect(_on_card_close_requested)
	card_slot1.card_action_requested.connect(_on_card_action_requested)
	card_slot2.card_action_requested.connect(_on_card_action_requested)
	card_slot3.card_action_requested.connect(_on_card_action_requested)

	player = chapter.player
	# 尝试加载存档，否则开始新冒险
	var save_data = AdventureState.load_run()
	if save_data.size() > 0:
		chapter.deserialize(save_data)
	else:
		player.initialize()
		chapter.start_run(2)

	_apply_localization()  # 应用语言设置
	_refresh_hud()         # 刷新HUD显示
	_sync_ui()             # 同步三窗口卡片
	_debug_print_lines()   # [DEBUG] 打印三条线路节点顺序
	_handle_battle_return()  # 检查战斗返回结果

# 根据当前语言设置UI文本
func _apply_localization() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	var lang = sm.get_setting("language", "zh") if sm else "zh"
	if lang == "en":
		back_button.text = "Back"
		card_pack_button.text = "Deck"
		gold_label.text = "Gold: 0"
	else:
		back_button.text = "返回"
		card_pack_button.text = "卡牌包"
		gold_label.text = "金币: 0"

# 刷新底部HUD的所有数值显示
func _refresh_hud() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	var lang = sm.get_setting("language", "zh") if sm else "zh"
	if lang == "en":
		gold_label.text = "Gold: %d" % player.gold
		remaining_label.text = "Nodes left: %d" % chapter.chapter_manager.get_pool_size()
	else:
		gold_label.text = "金币: %d" % player.gold
		remaining_label.text = "剩余节点: %d" % chapter.chapter_manager.get_pool_size()
	# 血条
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	hp_label.text = "%d/%d" % [player.hp, player.max_hp]
	# 经验条
	exp_bar.max_value = player.exp_to_next
	exp_bar.value = player.experience
	exp_label.text = "%d/%d" % [player.experience, player.exp_to_next]
	# 右下角属性按钮
	mana_button.text = "%d" % player.mana
	ap_button.text = "%d" % player.action_points
	limit_button.text = "%d" % player.card_limit

# 同步UI：更新章节标签、三窗口卡片、隐藏气泡
func _sync_ui() -> void:
	chapter_label.text = chapter.chapter_label()
	_sync_cards()
	_hide_tooltip()

# 同步三窗口卡片显示
# slot_index 直接对应线路索引（槽位0=线路0，槽位1=线路1，槽位2=线路2）
func _sync_cards() -> void:
	var slots: Array[PanelContainer] = [card_slot1, card_slot2, card_slot3]
	_slot_card_data.clear()
	for i in range(3):
		var slot: PanelContainer = slots[i]
		var line_idx := i  # 槽位索引就是线路索引
		var cm := chapter.chapter_manager
		if cm.can_enter(line_idx):
			var node_type_val: int = cm.node_type(line_idx)
			_slot_card_data.append(line_idx)
			slot.visible = true
			slot.modulate.a = 1.0
			slot.set_slot_index(i)
			slot.set_title(cm.node_title(line_idx))
			slot.set_desc(cm.node_description(line_idx))
			slot.set_icon_color(CARD_COLORS.get(node_type_val, Color(0.2, 0.2, 0.2, 1)))
			slot.set_action_text(_node_action_text(node_type_val))
			slot.set_close_allowed(cm.is_close_allowed(line_idx))
		else:
			_slot_card_data.append(-1)
			slot.visible = true
			slot.modulate.a = 1.0
			slot.set_slot_index(i)
			slot.set_selected(false)
			slot.set_close_allowed(false)
			slot.modulate.a = 0.0

# --- 卡片交互处理 ---

# 卡片点击：同一时间只能选中一张卡片
func _on_card_selected(slot_idx: int) -> void:
	SoundManager.play_sfx_varied("adv_card_select")
	var slots: Array[PanelContainer] = [card_slot1, card_slot2, card_slot3]
	var clicked: PanelContainer = slots[slot_idx]
	# 如果点击的是已选中的卡片，取消选中
	if clicked._is_selected:
		clicked.set_selected(false)
		return
	# 先取消其他卡片的选中
	for slot in slots:
		if slot.visible:
			slot.set_selected(false)
	# 选中点击的卡片
	clicked.set_selected(true)

# 关闭按钮：销毁当前卡片并替换为下一张（跳过=无奖励，补充下一个节点）
func _on_card_close_requested(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _slot_card_data.size(): return
	SoundManager.play_sfx("adv_card_dismiss")
	var line_idx: int = _slot_card_data[slot_idx]
	if not chapter.chapter_manager.is_close_allowed(line_idx): return
	# 先取消选中状态
	var slots: Array[PanelContainer] = [card_slot1, card_slot2, card_slot3]
	var slot: PanelContainer = slots[slot_idx]
	slot.set_selected(false)
	# 播放销毁动画
	var tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property(slot, "scale", Vector2(0.5, 0.5), 0.2)
	tw.parallel().tween_property(slot, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		chapter.chapter_manager.resolve_skip(line_idx)  # 跳过节点（无奖励）
		# 重置卡片视觉状态（为下一个节点准备）
		slot.scale = Vector2.ONE
		slot.modulate.a = 1.0
		_sync_cards()  # 刷新所有卡片（补充下一个节点）
	)

# 动作按钮：进入节点事件（播放销毁动画后应用奖励并补充下一个节点）
func _on_card_action_requested(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _slot_card_data.size(): return
	SoundManager.play_sfx("adv_card_enter")
	var line_idx: int = _slot_card_data[slot_idx]
	if not chapter.chapter_manager.can_enter(line_idx): return
	var node_type := chapter.chapter_manager.node_type(line_idx)
	# 战斗类节点：跳转战斗场景
	if node_type in BATTLE_TYPES:
		_enter_battle(node_type, line_idx)
		return
	# 非战斗类节点：保持现有逻辑
	var slots: Array[PanelContainer] = [card_slot1, card_slot2, card_slot3]
	var slot: PanelContainer = slots[slot_idx]
	slot.set_selected(false)
	var tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property(slot, "scale", Vector2(0.5, 0.5), 0.15)
	tw.parallel().tween_property(slot, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		var resolved_type := chapter.chapter_manager.resolve_enter(line_idx)
		_apply_node_reward(resolved_type)
		slot.scale = Vector2.ONE
		slot.modulate.a = 1.0
		_sync_cards()
	)

# 进入战斗场景
func _enter_battle(node_type: int, line_idx: int) -> void:
	chapter.chapter_manager.resolve_enter(line_idx)
	AdventureState.save_run(chapter.serialize())
	var gbr = get_node_or_null("/root/GlobalBattleRequest")
	if gbr:
		gbr.set_request(node_type, player.hp, player.max_hp,
			player.action_points, player.deck, [])
		gbr.hand_limit = player.card_limit
		# 传入经验/等级数据（战斗胜利面板需要）
		gbr.player_exp = player.experience
		gbr.player_level = player.level
		gbr.player_exp_to_next = player.exp_to_next
		gbr.reward_exp = gbr.get_reward_exp()
		gbr.reward_gold = gbr.get_reward_gold()
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")

# 战斗返回后处理
func _handle_battle_return() -> void:
	var gbr = get_node_or_null("/root/GlobalBattleRequest")
	if not gbr or not gbr.has_request:
		return
	# 无论胜/负/退出，都回写战斗后的实际HP
	if gbr.result_player_hp > 0:
		player.hp = gbr.result_player_hp
	# 回写行动力（战斗中消耗的AP保留到下次战斗）
	if gbr.result_ap >= 0:
		player.action_points = gbr.result_ap
	# 回写战斗胜利面板计算后的经验/等级
	if gbr.result_level > 0:
		player.level = gbr.result_level
		player.experience = gbr.result_exp_value
		player.exp_to_next = gbr.result_exp_to_next
	# 回写升级带来的属性变化
	if gbr.result_max_hp > 0:
		player.max_hp = gbr.result_max_hp
		player.hp = mini(player.hp, player.max_hp)
	if gbr.result_max_mana > 0:
		player.max_mana = gbr.result_max_mana
		player.mana = player.max_mana
	# 胜利时额外发放奖励
	if gbr.result == "win":
		player.add_gold(gbr.result_gold)
	SoundManager.play_sfx("reward_gold")
	# 注意：经验/等级已由战斗面板计算并同步，不再重复 add_experience
	# 存档更新
	AdventureState.save_run(chapter.serialize())
	gbr.clear_request()
	_refresh_hud()
	_sync_cards()

# 根据节点类型应用奖励
func _apply_node_reward(node_type: int) -> void:
	# 播放节点对应音效
	if node_type == ChapterNodeManager.NodeType.REST:
		SoundManager.play_sfx("adv_rest_heal")
	elif node_type == ChapterNodeManager.NodeType.SMITH:
		SoundManager.play_sfx("adv_smith_craft")
	elif node_type == ChapterNodeManager.NodeType.SHOP:
		SoundManager.play_sfx("adv_shop_buy")
	elif node_type == ChapterNodeManager.NodeType.CHEST:
		SoundManager.play_sfx("adv_chest_open")
	elif node_type == ChapterNodeManager.NodeType.NEXT_CHAPTER:
		SoundManager.play_sfx("adv_chapter_advance")
	if node_type == ChapterNodeManager.NodeType.BATTLE:
		player.add_gold(5); player.add_experience(10)     # 普通战斗奖励
	elif node_type == ChapterNodeManager.NodeType.ELITE:
		player.add_gold(12); player.add_experience(20)    # 精英战斗奖励
	elif node_type == ChapterNodeManager.NodeType.BOSS:
		player.add_gold(30); player.add_experience(40)    # BOSS奖励
	elif node_type == ChapterNodeManager.NodeType.REST:
		player.heal(int(player.max_hp * 0.25))             # 恢复25%最大生命
	elif node_type == ChapterNodeManager.NodeType.CHEST:
		player.add_gold(8); player.add_experience(6)      # 宝箱奖励
	elif node_type == ChapterNodeManager.NodeType.SMITH:
		player.add_experience(5)                           # 铁匠经验奖励
	_refresh_hud()  # 刷新HUD数值

# --- 返回按钮 ---
func _on_back_button_pressed() -> void:
	SoundManager.play_sfx("ui_back")
	AdventureState.save_run(chapter.serialize())  # 自动存档
	# 整个冒险界面向右滑出屏幕
	var screen_w = get_viewport_rect().size.x
	var tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position:x", screen_w * 1.2, 0.35)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

# 为Control节点添加果冻按下效果组件
func _add_press_effect(node: Control) -> void:
	var pe = PressEffect.new()
	pe.press_down_scale = 0.92
	pe.press_bounce_scale = 0.95
	pe.release_scale = 1.05
	pe.release_duration = 0.25
	node.add_child(pe)

# 退出场景时自动存档
func _exit_tree() -> void:
	AdventureState.save_run(chapter.serialize())

# === 气泡提示系统（长按属性图标显示详细描述）===

# 卡牌包按钮长按提示
func _on_card_pack_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_tooltip_at(card_pack_button, "卡牌包：未开发")
	elif event is InputEventMouseButton and not event.pressed:
		_hide_tooltip()

# 魔力值按钮长按提示
func _on_mana_gui_input(event: InputEvent) -> void:
	_handle_stat_tooltip(event, mana_button, "mana")

# 行动力按钮长按提示
func _on_ap_gui_input(event: InputEvent) -> void:
	_handle_stat_tooltip(event, ap_button, "action_points")

# 卡牌上限按钮长按提示
func _on_limit_gui_input(event: InputEvent) -> void:
	_handle_stat_tooltip(event, limit_button, "card_limit")

# 统计属性按钮的长按提示处理（按下显示、松手消失、按压缩放动画）
func _handle_stat_tooltip(event: InputEvent, node: Control, key: String) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 按压缩放动画
			var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tw.tween_property(node, "scale", Vector2(0.9, 0.9), 0.08)
			tw.tween_property(node, "scale", Vector2.ONE, 0.25)
			_show_tooltip_at(node, _tooltip_text(key))
		elif not event.pressed:
			_hide_tooltip()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_show_tooltip_at(node, _tooltip_text(key))

# 在指定节点附近显示气泡提示
func _show_tooltip_at(node: Control, text: String) -> void:
	# 先移除旧提示
	if _active_tooltip and is_instance_valid(_active_tooltip):
		_active_tooltip.queue_free()
		_active_tooltip = null
	# 实例化新提示
	var tip: PanelContainer = _tooltip_scene.instantiate()
	tip.set_text(text)
	tooltip_anchor.add_child(tip)
	_active_tooltip = tip
	# 计算位置：优先显示在节点上方，空间不够则显示在下方
	var anchor_rect := tooltip_anchor.get_global_rect()
	var node_rect := node.get_global_rect()
	var tip_size := tip.get_rect().size
	var x := clampf(node_rect.position.x + (node_rect.size.x - tip_size.x) * 0.5, anchor_rect.position.x, anchor_rect.end.x - tip_size.x)
	var y := node_rect.position.y - tip_size.y - 8.0
	if y < anchor_rect.position.y:
		y = node_rect.end.y + 8.0
	tip.set_global_position(Vector2(x, y))
	# 淡入 + 弹性放大动画
	tip.modulate.a = 0.0
	tip.scale = Vector2(0.8, 0.8)
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(tip, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(tip, "scale", Vector2.ONE, 0.2)

# 隐藏气泡提示
func _hide_tooltip() -> void:
	if _active_tooltip and is_instance_valid(_active_tooltip):
		_active_tooltip.queue_free()
		_active_tooltip = null
# [DEBUG] 打印排队完成后的3条线路存档数据
func _debug_print_lines() -> void:
	var cm := chapter.chapter_manager
	print("========== [DEBUG] 排队存档数据 ==========")
	for i in range(cm.lines.size()):
		var line: Array = cm.lines[i]
		var names := []
		for j in range(line.size()):
			names.append(cm.node_title_for_line(i, j))
		print("线路%d (%d个节点): %s" % [i, line.size(), " → ".join(names)])
	print("剩余节点总数: %d" % cm.get_pool_size())
	print("==========================================")
