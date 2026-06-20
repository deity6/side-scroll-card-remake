class_name BattleState
extends RefCounted
## 战斗状态管理器
## 管理牌库/手牌/弃牌堆、AP、HP、护甲、伤害计算、装备效果
## 注意：draw_cards/play_card/discard_hand 不发 hand_changed 信号，由 UI 层控制动画节奏

# --- 信号 ---
signal state_changed      # 整体状态变化（HP/AP/护甲等）
signal battle_won         # 战斗胜利
signal battle_lost        # 战斗失败
signal card_played        # 打出一张卡牌（card: Dictionary）
signal equip_triggered    # 装备效果触发（equip_name: String, value: int）

# --- 玩家属性 ---
var player_hp: int = 52
var player_max_hp: int = 52
var player_armor: int = 0
var ap: int = 3            # 行动力
var max_action_points: int = 3  # 行动力上限
var hand_limit: int = 10      # 手牌上限（从冒险存档传入）

# --- 怪物属性 ---
var enemy_hp: int = 25
var enemy_max_hp: int = 25
var enemy_armor: int = 0

# --- 牌组管理 ---
var draw_pile: Array = []     # 抽牌堆
var hand: Array = []          # 手牌
var discard_pile: Array = []  # 弃牌堆

# --- 装备系统 ---
var equipment: Array = []     # 已装备列表 [{name, effect_type, value}]

# --- 回合 ---
var turn: int = 1
var phase: String = "player"  # "player" / "enemy"

# --- 初始化战斗 ---
func setup(p_player_hp: int, p_max_hp: int, p_ap: int,
		p_deck: Array, p_enemy_hp: int, p_equipment: Array = [],
		p_hand_limit: int = 10) -> void:  # 语法默认值，实际值由 adventure_player_state 权威定义并传入
	player_hp = p_player_hp
	player_max_hp = p_max_hp
	player_armor = 0
	ap = p_ap
	max_action_points = p_ap
	hand_limit = p_hand_limit
	enemy_hp = p_enemy_hp
	enemy_max_hp = p_enemy_hp
	enemy_armor = 0
	turn = 1
	phase = "player"
	# 初始化牌组
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	for card in p_deck:
		draw_pile.append(card.duplicate())
	draw_pile.shuffle()
	# 初始化装备
	equipment.clear()
	for eq in p_equipment:
		equipment.append(eq.duplicate())
	# 触发首次装备效果
	_trigger_equipment_on_battle_start()
	# 抽初始手牌（纯数据，不发信号）
	draw_cards(5)
	state_changed.emit()

# --- 牌库操作 ---

## 抽n张牌到手牌（纯数据操作，不发 hand_changed 信号）
## 返回实际抽取的卡牌数量，由 UI 层根据返回值决定是否播放入栈动画
func draw_cards(count: int) -> int:
	var drawn: int = 0
	for _i in range(count):
		if hand.size() >= hand_limit:
			break
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())
		drawn += 1
	# 不再 hand_changed.emit()，由 UI 层控制动画
	return drawn

## 打出一张牌（纯数据操作，不发 hand_changed 信号）
func play_card(index: int) -> bool:
	if index < 0 or index >= hand.size():
		return false
	var card: Dictionary = hand[index]
	var ap_cost: int = int(card.get("ap_cost", 0))
	# 检查AP是否足够
	if ap_cost > ap:
		return false
	# 扣除AP
	ap -= ap_cost
	# 应用卡牌效果
	_apply_card_effect(card)
	# 移到弃牌堆
	discard_pile.append(card)
	hand.remove_at(index)
	# 不再 hand_changed.emit()，由 UI 层控制
	state_changed.emit()
	card_played.emit(card)
	# 检查胜负
	_check_battle_end()
	return true

## 弃掉所有手牌（纯数据操作，不发 hand_changed 信号）
func discard_hand() -> void:
	while hand.size() > 0:
		discard_pile.append(hand.pop_back())

## 将弃牌堆洗入抽牌堆（不发信号，由 UI 层控制刷新）
## 返回实际洗入的卡牌数量
func shuffle_discard_to_draw() -> int:
	var count: int = discard_pile.size()
	if count == 0:
		return 0
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile.clear()
	draw_pile.shuffle()
	return count

## 开始新回合（纯数据抽牌，不发 hand_changed 信号）
func start_new_turn() -> int:
	turn += 1
	# 触发装备效果
	_trigger_equipment_on_turn_start()
	# 抽牌，返回实际抽牌数
	var drawn: int = draw_cards(5)
	state_changed.emit()
	return drawn

# --- 效果处理 ---

func _apply_card_effect(card: Dictionary) -> void:
	var etype: String = str(card.get("effect_type", ""))
	var evalue: int = int(card.get("effect_value", 0))
	match etype:
		"damage":
			_deal_damage_to_enemy(evalue)
		"armor":
			player_armor += evalue
		"heal":
			player_hp = mini(player_hp + evalue, player_max_hp)
		"restore_ap":
			ap += evalue
		"armor_and_draw":
			player_armor += evalue
			draw_cards(1)
		"armor_per_turn":
			# 装备牌打出时：获得即时护甲
			var on_play: int = int(card.get("on_play_armor", 0))
			if on_play > 0:
				player_armor += on_play
			# 添加到装备区
			equipment.append({
				"name": card.get("name", ""),
				"effect_type": "armor_per_turn",
				"value": evalue,
			})
		"draw":
			draw_cards(evalue)

## 对敌人造成伤害（先扣护甲再扣HP）
func _deal_damage_to_enemy(damage: int) -> void:
	var actual := maxi(damage - enemy_armor, 0)
	enemy_armor = maxi(enemy_armor - damage, 0)
	enemy_hp -= actual

# --- 装备效果 ---

## 战斗开始时触发装备效果
func _trigger_equipment_on_battle_start() -> void:
	pass

## 每回合开始时触发装备效果
func _trigger_equipment_on_turn_start() -> void:
	for eq in equipment:
		var etype: String = str(eq.get("effect_type", ""))
		var evalue: int = int(eq.get("value", 0))
		if etype == "armor_per_turn":
			player_armor += evalue
			equip_triggered.emit(str(eq.get("name", "")), evalue)

# --- 胜负判定 ---

func _check_battle_end() -> void:
	if enemy_hp <= 0:
		enemy_hp = 0
		battle_won.emit()
	elif player_hp <= 0:
		player_hp = 0
		battle_lost.emit()

# --- 工具方法 ---

## 检查一张牌是否可以打出（AP是否足够）
func can_play_card(index: int) -> bool:
	if index < 0 or index >= hand.size():
		return false
	var card: Dictionary = hand[index]
	return ap >= int(card.get("ap_cost", 0))

## 获取抽牌堆中所有卡牌 ID（调试用）
func get_draw_pile_ids() -> Array:
	var ids: Array = []
	for card in draw_pile:
		ids.append(str(card.get("id", "?")))
	return ids

## 获取手牌中所有卡牌 ID（调试用）
func get_hand_ids() -> Array:
	var ids: Array = []
	for card in hand:
		ids.append(str(card.get("id", "?")))
	return ids

## 获取弃牌堆中所有卡牌 ID（调试用）
func get_discard_pile_ids() -> Array:
	var ids: Array = []
	for card in discard_pile:
		ids.append(str(card.get("id", "?")))
	return ids

## 获取牌库剩余数量
func get_draw_pile_size() -> int:
	return draw_pile.size()

## 获取弃牌堆数量
func get_discard_pile_size() -> int:
	return discard_pile.size()
