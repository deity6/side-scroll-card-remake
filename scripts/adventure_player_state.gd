class_name AdventurePlayerState
extends RefCounted

# ============================================================
# 冒险模式 - 玩家状态
# 管理玩家在冒险中的生命值、金币、经验、魔法等属性
# 支持序列化/反序列化用于存档系统
# ============================================================

# --- 状态变化信号 ---
signal hp_changed       # 生命值变化
signal gold_changed     # 金币变化
signal exp_changed      # 经验值变化
signal stats_changed    # 属性变化（升级等）

# --- 基础属性 ---
var hp: int = 52              # 当前生命值
var max_hp: int = 52          # 最大生命值
var gold: int = 0             # 金币数量
var level: int = 1            # 等级
var experience: int = 0       # 当前经验值（避免使用exp命名以免与内置函数冲突）
var exp_to_next: int = 20     # 升级所需经验值

# --- 战斗属性 ---
var mana: int = 2             # 当前魔力值
var max_mana: int = 2         # 最大魔力值
var action_points: int = 3    # 当前行动力
var max_action_points: int = 3 # 最大行动力
var card_limit: int = 10       # 手牌上限
var cards_drawn_per_turn: int = 5  # 每回合抽卡数

# --- 卡组 ---
var deck: Array = []          # 玩家拥有的卡牌列表
# 卡牌定义已迁移到 CardPool（card_pool.gd + Data/cards/*.json）
# 初始牌组通过 CardPool.get_default_player_deck() 获取


# 初始化所有属性为默认值
func initialize() -> void:
	hp = 52
	max_hp = 52
	gold = 0
	level = 1
	experience = 0
	exp_to_next = 20
	mana = 2
	max_mana = 2
	action_points = 3
	max_action_points = 3
	card_limit = 10
	cards_drawn_per_turn = 5
	deck.clear()
	# 从卡池构建初始牌组（CardPool 从 JSON 加载卡牌定义）
	var pool = CardPool.new()
	deck = pool.get_default_player_deck()
	stats_changed.emit()

# --- 生命值相关 ---

# 恢复生命值（不超过上限）
func heal(amount: int) -> void:
	var old_hp := hp
	hp = mini(hp + amount, max_hp)
	if hp != old_hp:
		hp_changed.emit()

# 受到伤害（不低于0）
func take_damage(amount: int) -> void:
	var old_hp := hp
	hp = maxi(hp - amount, 0)
	if hp != old_hp:
		hp_changed.emit()

# --- 金币相关 ---

# 增加金币
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit()

# 消耗金币（余额不足返回false）
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit()
	return true

# --- 经验与升级 ---

# 增加经验值，自动处理升级
func add_experience(amount: int) -> void:
	experience += amount
	while experience >= exp_to_next:
		experience -= exp_to_next
		_level_up()
	exp_changed.emit()

# 升级处理：提升等级、增加属性
func _level_up() -> void:
	level += 1
	exp_to_next = int(exp_to_next * 1.5)  # 升级所需经验递增50%
	max_hp += 5        # 每级增加5点最大生命
	hp = mini(hp + 5, max_hp)  # 同时恢复5点生命
	max_mana += 1      # 每级增加1点魔力上限
	mana = max_mana    # 魔力回满
	stats_changed.emit()

# --- 回合结束恢复 ---
# 不恢复魔力和行动值，已删除
# --- 状态查询 ---

# 玩家是否存活
func is_alive() -> bool:
	return hp > 0

# 生命值比例（0.0~1.0）
func hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)

# 经验值比例（0.0~1.0）
func exp_ratio() -> float:
	if exp_to_next <= 0:
		return 0.0
	return float(experience) / float(exp_to_next)

# --- 存档序列化 ---

# 将所有属性序列化为字典
# --- 序列化辅助方法 ---
## 将卡组序列化为数组（GDScript 不支持 list comprehension）
func _serialize_deck() -> Array:
	var deck_data: Array = []
	for card in deck:
		deck_data.append(card.duplicate())
	return deck_data

func serialize() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp, "gold": gold,
		"level": level, "experience": experience, "exp_to_next": exp_to_next,
		"mana": mana, "max_mana": max_mana,
		"action_points": action_points, "max_action_points": max_action_points,
		"card_limit": card_limit, "cards_drawn_per_turn": cards_drawn_per_turn,
		"deck": _serialize_deck(),
	}

# 从字典反序列化恢复属性
func deserialize(data: Dictionary) -> void:
	hp = data.get("hp", 52)
	max_hp = data.get("max_hp", 52)
	gold = data.get("gold", 0)
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	exp_to_next = data.get("exp_to_next", 20)
	mana = data.get("mana", 2)
	max_mana = data.get("max_mana", 2)
	action_points = data.get("action_points", 3)
	max_action_points = data.get("max_action_points", 3)
	card_limit = data.get("card_limit", 10)
	cards_drawn_per_turn = data.get("cards_drawn_per_turn", 5)
	# 恢复卡组（如果存档中有 deck 数据，否则使用默认牌组）
	var saved_deck = data.get("deck", [])
	if saved_deck is Array and saved_deck.size() > 0:
		deck.clear()
		for card in saved_deck:
			deck.append(card.duplicate())
	stats_changed.emit()
