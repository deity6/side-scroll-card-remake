class_name CardPool
extends RefCounted
## 卡牌池管理器（唯一卡牌定义中心）
## 所有卡牌定义从 Data/cards/*.json 加载，其他模块只引用不定义
##
## 使用方式：
##   var pool = CardPool.new()                  # 创建卡池（自动加载 JSON）
##   var card = pool.get_card_by_id("slash_1")  # 按 ID 查找
##   var deck = pool.get_default_player_deck()   # 获取初始牌组
##   pool.register_card({...})                   # 运行时注册新卡

# ============================================================
# 初始牌组配方（只存 ID 列表，按需查卡池构建完整卡牌）
# 后续用户个人牌组也用同样的 ID 列表模式
# ============================================================
const DEFAULT_DECK_IDS: Array = [
	"slash_1", "slash_2", "slash_3", "heavy_strike",
	"defend_1", "defend_2",
	"heal_potion", "tactical_roll", "adrenaline",
	"iron_charm",
]

# --- 卡牌类型常量 ---
const TYPE_ATTACK: String = "attack"
const TYPE_ACTION: String = "action"
const TYPE_EQUIP: String = "equip"

# --- 效果类型常量 ---
const EFFECT_DAMAGE: String = "damage"
const EFFECT_ARMOR: String = "armor"
const EFFECT_HEAL: String = "heal"
const EFFECT_RESTORE_AP: String = "restore_ap"
const EFFECT_ARMOR_AND_DRAW: String = "armor_and_draw"
const EFFECT_ARMOR_PER_TURN: String = "armor_per_turn"
const EFFECT_DRAW: String = "draw"

# --- 卡牌存储：id -> card_data 字典 ---
var _all_cards: Dictionary = {}

# --- JSON 文件目录路径 ---
const CARDS_DIR: String = "res://Data/cards/"

# ============================================================
# 初始化
# ============================================================

func _init() -> void:
	_load_builtin_cards()

## 扫描 Data/cards/ 目录下所有 JSON 文件，加载卡牌到字典
func _load_builtin_cards() -> void:
	var dir := DirAccess.open(CARDS_DIR)
	if dir == null:
		printerr("CardPool: 无法打开目录 ", CARDS_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			_load_json_file(CARDS_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

## 加载单个 JSON 文件中的卡牌数组
func _load_json_file(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		printerr("CardPool: 文件不存在 ", file_path)
		return
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("CardPool: 无法打开 ", file_path)
		return
	var json_text: String = file.get_as_text()
	var json := JSON.new()
	var error: int = json.parse(json_text)
	if error != OK:
		printerr("CardPool: JSON 解析失败 ", file_path, " - ", json.get_error_message())
		return
	var data = json.data
	if not data is Array:
		printerr("CardPool: JSON 根节点必须是数组 ", file_path)
		return
	for card in data:
		if card is Dictionary:
			var card_id: String = str(card.get("id", ""))
			if not card_id.is_empty():
				_all_cards[card_id] = card

# ============================================================
# 查询方法
# ============================================================

## 根据 ID 获取卡牌定义（O(1) 字典查找），找不到返回空字典
func get_card_by_id(card_id: String) -> Dictionary:
	return _all_cards.get(card_id, {})

## 获取所有卡牌列表
func get_all_cards() -> Array:
	return _all_cards.values()

## 按类型筛选卡牌
func get_cards_by_type(card_type: String) -> Array:
	var result: Array = []
	for card_id in _all_cards:
		var card: Dictionary = _all_cards[card_id]
		if str(card.get("type", "")) == card_type:
			result.append(card)
	return result

## 随机获取一张卡牌（返回深拷贝）
func get_random_card() -> Dictionary:
	var all: Array = get_all_cards()
	if all.is_empty():
		return {}
	var idx: int = randi() % all.size()
	return all[idx].duplicate(true)

## 随机获取 N 张不重复卡牌
func get_random_cards(count: int) -> Array:
	var available: Array = get_all_cards()
	var result: Array = []
	var n: int = mini(count, available.size())
	for _i in range(n):
		var idx: int = randi() % available.size()
		result.append(available[idx].duplicate(true))
		available.remove_at(idx)
	return result

# ============================================================
# 牌组构建（核心方法）
# ============================================================

## 根据 ID 列表从卡池构建牌组（返回深拷贝数组）
## ids: 卡牌 ID 列表，如 DEFAULT_DECK_IDS
func build_deck_from_ids(ids: Array) -> Array:
	var deck: Array = []
	for card_id in ids:
		var card: Dictionary = get_card_by_id(str(card_id))
		if card.size() > 0:
			deck.append(card.duplicate(true))
		else:
			printerr("CardPool: 未知卡牌 ID ", card_id)
	return deck

## 获取初始玩家牌组（基于 DEFAULT_DECK_IDS）
func get_default_player_deck() -> Array:
	return build_deck_from_ids(DEFAULT_DECK_IDS)

# ============================================================
# 注册方法（运行时扩展卡池）
# ============================================================

## 注册一张自定义卡牌，返回是否成功
func register_card(card_data: Dictionary) -> bool:
	var card_id: String = str(card_data.get("id", ""))
	if card_id.is_empty():
		printerr("CardPool: 卡牌 id 不能为空")
		return false
	if _all_cards.has(card_id):
		printerr("CardPool: 卡牌 id 已存在 ", card_id)
		return false
	_all_cards[card_id] = card_data.duplicate(true)
	return true

## 批量注册卡牌
func register_cards(cards: Array) -> int:
	var count: int = 0
	for card in cards:
		if register_card(card):
			count += 1
	return count

## 移除自定义卡牌
func unregister_card(card_id: String) -> bool:
	if _all_cards.has(card_id):
		_all_cards.erase(card_id)
		return true
	return false

# ============================================================
# 工具方法
# ============================================================

## 获取卡池统计信息
func get_pool_stats() -> Dictionary:
	var attack: int = 0
	var action: int = 0
	var equip: int = 0
	for card_id in _all_cards:
		var card: Dictionary = _all_cards[card_id]
		match str(card.get("type", "")):
			"attack": attack += 1
			"action": action += 1
			"equip": equip += 1
	return {
		"total": _all_cards.size(),
		"attack": attack,
		"action": action,
		"equip": equip,
	}
