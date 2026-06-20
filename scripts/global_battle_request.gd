extends Node
## 全局战斗请求数据 - 用于冒险场景与战斗场景之间传递数据
## 作为 Autoload 注册，场景切换时数据不会丢失

# --- 战斗请求数据 ---
var node_type: int = -1          # 触发战斗的节点类型（BATTLE/ELITE/BOSS）
var player_hp: int = 52          # 进入战斗时的玩家HP
var player_max_hp: int = 52      # 玩家最大HP
var player_armor: int = 0        # 进入战斗时的护甲
var ap: int = 3                  # 进入战斗时的行动力
var deck: Array = []             # 玩家的牌组（深拷贝）
var equipment: Array = []        # 已装备的装备牌列表
var reward_exp: int = 0          # 战斗胜利奖励经验值
var reward_gold: int = 0         # 战斗胜利奖励金币
var is_retry: bool = false       # 是否为重试模式（保留上次战斗参数）
var result_player_hp: int = 0    # 战斗结束时玩家实际HP（用于回写存档）
var result_ap: int = -1           # 战斗结束时玩家剩余AP（-1表示未设置）
var result_level: int = 0          # 战斗结束时等级（胜利面板计算后回写）
var result_exp_value: int = 0      # 战斗结束时剩余经验值
var result_exp_to_next: int = 0    # 战斗结束时升级所需经验
var result_max_hp: int = 0         # 战斗结束时最大HP（0=未设置）
var result_max_mana: int = 0       # 战斗结束时最大魔力（0=未设置）
var hand_limit: int = 10          # 手牌上限（从冒险存档传入）
var player_exp: int = 0            # 进入战斗时经验值
var player_level: int = 1           # 进入战斗时等级
var player_exp_to_next: int = 20    # 当前升级所需经验

# --- 标记数据是否有效 ---
var has_request: bool = false

# --- 战斗结果 ---
var result: String = ""          # "win" / "lose" / ""（未结算）
var result_exp: int = 0          # 实际获得的经验
var result_gold: int = 0         # 实际获得的金币

# 设置战斗请求数据
func set_request(p_node_type: int, p_player_hp: int, p_max_hp: int,
		p_ap: int, p_deck: Array, p_equipment: Array = []) -> void:
	node_type = p_node_type
	player_hp = p_player_hp
	player_max_hp = p_max_hp
	ap = p_ap
	deck.clear()
	for card in p_deck:
		deck.append(card.duplicate())
	equipment.clear()
	for eq in p_equipment:
		equipment.append(eq.duplicate())
	result = ""
	result_exp = 0
	result_gold = 0
	has_request = true
	is_retry = false

# 设置重试请求（保留相同参数，不重置数据）
func set_retry() -> void:
	is_retry = true
	result = ""
	result_exp = 0
	result_gold = 0
	has_request = true

# 获取战斗奖励经验值
func get_reward_exp() -> int:
	match node_type:
		0: return 10   # BATTLE
		1: return 20   # ELITE
		2: return 40   # BOSS
	return 10

# 获取战斗奖励金币
func get_reward_gold() -> int:
	match node_type:
		0: return 5    # BATTLE
		1: return 12   # ELITE
		2: return 30   # BOSS
	return 5

# 获取怪物最大HP（根据节点类型）
func get_enemy_max_hp() -> int:
	match node_type:
		0: return 25   # BATTLE 普通怪
		1: return 45   # ELITE 精英怪
		2: return 80   # BOSS
	return 25

# 清除战斗请求数据
func clear_request() -> void:
	node_type = -1
	player_hp = 52
	player_max_hp = 52
	player_armor = 0
	ap = 3
	# 注意：deck 不在此清除，由冒险场景管理其生命周期
	equipment.clear()
	reward_exp = 0
	reward_gold = 0
	result = ""
	result_exp = 0
	result_gold = 0
	result_player_hp = 0
	result_ap = -1
	result_level = 0
	result_exp_value = 0
	result_exp_to_next = 0
	result_max_hp = 0
	result_max_mana = 0
	# hand_limit 由 adventure_player_state 权威定义，此处不做默认值覆盖
	player_exp = 0
	player_level = 1
	player_exp_to_next = 20
	has_request = false
	is_retry = false

# 重置战斗结果（用于重试）
func reset_result() -> void:
	result = ""
	result_exp = 0
	result_gold = 0
	result_player_hp = 0
	result_ap = -1
	result_level = 0
	result_exp_value = 0
	result_exp_to_next = 0
	result_max_hp = 0
	result_max_mana = 0
	# hand_limit 由 adventure_player_state 权威定义，此处不做默认值覆盖
	player_exp = 0
	player_level = 1
	player_exp_to_next = 20
