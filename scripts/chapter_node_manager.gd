class_name ChapterNodeManager
extends RefCounted

# ============================================================
# 章节节点管理器
#   - 点击"开始冒险"时一次性从随机池抽取所有节点排入3条线路
#   - 池清空后存档，用户操作只删不补
#   - 排队用两个战斗累加器控制精英/BOSS出现时机
#   - 同线路内同类功能节点不可连续
# ============================================================

# --- 信号 ---
signal nodes_changed
signal next_chapter_requested

# --- 节点类型枚举 ---
enum NodeType { BATTLE, ELITE, BOSS, REST, SMITH, SHOP, CHEST, NEXT_CHAPTER }

# =====================================================
# 随机池参数（数值常量，方便调试修改）
# =====================================================
const POOL_NORMAL_COUNT  := 7   # A - 普通怪数量
const POOL_ELITE_COUNT   := 4   # B - 精英怪数量
const POOL_BOSS_COUNT    := 1   # BOSS数量（固定1）
const POOL_REST_COUNT    := 3   # E - 休息节点数量
const POOL_SMITH_COUNT   := 2   # F - 铁匠节点数量
const POOL_SHOP_COUNT    := 3   # G - 商店节点数量
const POOL_CHEST_COUNT   := 3   # H - 宝箱节点数量

const ELITE_THRESHOLD    := 2   # C - 初阶战斗累加值阈值（≥此值时精英可被抽取）
const BOSS_THRESHOLD     := 6   # D - 中阶战斗累加值阈值（≥此值时BOSS可被抽取）

const LINE_COUNT         := 3   # 固定3条线路（左/中/右）

# --- 可抽取类型集合（战斗类/功能类） ---
const BATTLE_TYPES := [NodeType.BATTLE, NodeType.ELITE, NodeType.BOSS]
const FUNCTION_TYPES := [NodeType.REST, NodeType.SMITH, NodeType.SHOP, NodeType.CHEST]
# 可重复节点类型（同类在同线路内不可连续）
const REPEATABLE_TYPES := [NodeType.REST, NodeType.SMITH, NodeType.SHOP, NodeType.CHEST]
# 不可首次抽取的类型
const NO_FIRST_DRAW_TYPES := [NodeType.ELITE, NodeType.BOSS]

# --- 节点描述映射 ---
const NODE_DESCRIPTIONS := {
	NodeType.BATTLE: "与普通敌人战斗，胜利可获得奖励。",
	NodeType.ELITE: "与精英敌人战斗，奖励更丰厚。",
	NodeType.BOSS: "与BOSS战斗，击败后可前往下一章。",
	NodeType.REST: "在营火旁恢复部分生命。",
	NodeType.SMITH: "在铁匠铺升级一张卡牌。",
	NodeType.SHOP: "在商店购买卡牌或道具。",
	NodeType.CHEST: "打开宝箱获得随机卡牌或金币。",
	NodeType.NEXT_CHAPTER: "结束本章冒险，前往下一章。",
}

# --- 章节状态 ---
var chapter_index: int = 0
var total_chapters: int = 2
var battle_remaining: int = 0
var elite_remaining: int = 0
var boss_defeated: bool = false
var boss_appeared: bool = false

# --- 线路数据 ---
# 每条线路是节点数组，每个节点是 Dictionary { "type": int, "index": int }
# 不可重复节点 index = 1~N（普通怪1、精英怪2...）
# 可重复节点 index = 0
# NEXT_CHAPTER 节点 index = 0
var lines: Array = []
var shared_pool := []
var rng := RandomNumberGenerator.new()

# --- 功能节点使用统计 ---
var function_used := {}

# =====================================================
# 初始化
# =====================================================
func setup(p_chapter_index: int, p_total_chapters: int, seed_value: int = -1) -> void:
	chapter_index = clampi(p_chapter_index, 0, maxi(p_total_chapters - 1, 0))
	total_chapters = maxi(p_total_chapters, 1)
	boss_defeated = false
	boss_appeared = false
	shared_pool.clear()
	lines.clear()
	function_used.clear()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	_init_function_used()
	_build_pool()
	for i in range(LINE_COUNT):
		lines.append([])
	_distribute_pool()
	nodes_changed.emit()

func _init_function_used() -> void:
	for t in FUNCTION_TYPES:
		function_used[t] = 0

# =====================================================
# 构建随机池：创建所有编号节点并 shuffle
# =====================================================
func _build_pool() -> void:
	shared_pool.clear()
	battle_remaining = POOL_NORMAL_COUNT + POOL_ELITE_COUNT
	elite_remaining = POOL_ELITE_COUNT
	# 普通怪 1~A
	for i in range(1, POOL_NORMAL_COUNT + 1):
		shared_pool.append({"type": NodeType.BATTLE, "index": i})
	# 精英怪 1~B
	for i in range(1, POOL_ELITE_COUNT + 1):
		shared_pool.append({"type": NodeType.ELITE, "index": i})
	# BOSS 1
	for i in range(1, POOL_BOSS_COUNT + 1):
		shared_pool.append({"type": NodeType.BOSS, "index": i})
	# 功能节点（可重复，index=0）
	for _i in range(POOL_REST_COUNT):
		shared_pool.append({"type": NodeType.REST, "index": 0})
	for _i in range(POOL_SMITH_COUNT):
		shared_pool.append({"type": NodeType.SMITH, "index": 0})
	for _i in range(POOL_SHOP_COUNT):
		shared_pool.append({"type": NodeType.SHOP, "index": 0})
	for _i in range(POOL_CHEST_COUNT):
		shared_pool.append({"type": NodeType.CHEST, "index": 0})
	shared_pool.shuffle()

# =====================================================
# 一次性分配：轮询3条线路，逐个按规则抽取
# =====================================================
func _distribute_pool() -> void:
	var slot := 0
	var elite_accum := 0   # 初阶战斗累加值
	var boss_accum := 0    # 中阶战斗累加值
	while not shared_pool.is_empty():
		var line_idx := slot % LINE_COUNT
		var is_first := (slot < LINE_COUNT)  # 前3个槽位是头节点
		var chosen: Variant = _pick_node(line_idx, is_first, elite_accum, boss_accum)
		if chosen == null:
			# 没有满足条件的节点了，跳过该槽位
			slot += 1
			continue
		lines[line_idx].append(chosen)
		# 从池中移除
		shared_pool.erase(chosen)
		# 更新累加器
		var ct: int = chosen["type"]
		if ct == NodeType.BATTLE or ct == NodeType.ELITE:
			elite_accum += 1
			boss_accum += 1
		if ct == NodeType.ELITE:
			elite_accum = 0
		if ct == NodeType.BOSS:
			boss_accum = 0
		slot += 1

# 从池中按规则挑一个节点
func _pick_node(line_idx: int, is_first: bool, elite_accum: int, boss_accum: int) -> Variant:
	# 确定当前可抽取的类型集合
	var allowed_types := []
	# 普通怪：始终可抽
	allowed_types.append(NodeType.BATTLE)
	# 精英怪：初阶累加≥阈值，或普通怪已抽完
	if elite_accum >= ELITE_THRESHOLD or _count_in_pool(NodeType.BATTLE) == 0:
		allowed_types.append(NodeType.ELITE)
	# BOSS：中阶累加≥阈值，或精英+普通已抽完
	if boss_accum >= BOSS_THRESHOLD or (_count_in_pool(NodeType.BATTLE) == 0 and _count_in_pool(NodeType.ELITE) == 0):
		allowed_types.append(NodeType.BOSS)
	# 功能节点：始终可抽（但受连续限制）
	for ft in FUNCTION_TYPES:
		allowed_types.append(ft)
	# 头节点排除不可首次抽取的类型
	if is_first:
		var filtered := []
		for t in allowed_types:
			if t not in NO_FIRST_DRAW_TYPES:
				filtered.append(t)
		allowed_types = filtered
	# 同线路连续限制：排除当前线路末尾的可重复节点类型
	var last_type := _last_type_in_line(line_idx)
	if last_type != -1 and last_type in REPEATABLE_TYPES:
		var filtered := []
		for t in allowed_types:
			if t != last_type:
				filtered.append(t)
		allowed_types = filtered
	# 从池中筛选满足条件的节点
	var candidates := []
	for node in shared_pool:
		if node["type"] in allowed_types:
			candidates.append(node)
	if candidates.is_empty():
		return null
	# 随机挑一个
	return candidates[rng.randi() % candidates.size()]

# 池中某类型的节点数量
func _count_in_pool(type_val: int) -> int:
	var count := 0
	for node in shared_pool:
		if node["type"] == type_val:
			count += 1
	return count

# 获取指定线路最后一个节点的类型（用于连续限制）
func _last_type_in_line(line_idx: int) -> int:
	if line_idx < 0 or line_idx >= lines.size():
		return -1
	var line: Array = lines[line_idx]
	if line.is_empty():
		return -1
	return int(line[line.size() - 1]["type"])

# =====================================================
# 公共查询接口
# =====================================================
func get_hand() -> Array:
	var hand := []
	for i in range(LINE_COUNT):
		if i < lines.size() and lines[i].size() > 0:
			hand.append(lines[i][0])
		else:
			hand.append(null)
	return hand

func get_pool_size() -> int:
	var total := 0
	for line in lines:
		total += line.size()
	return total

func can_enter(line_idx: int) -> bool:
	return line_idx >= 0 and line_idx < lines.size() and lines[line_idx].size() > 0

func is_close_allowed(line_idx: int) -> bool:
	if not can_enter(line_idx): return false
	var t: int = lines[line_idx][0]["type"]
	return t != NodeType.BOSS

func node_type(line_idx: int) -> int:
	if not can_enter(line_idx): return -1
	return int(lines[line_idx][0]["type"])

func node_index(line_idx: int) -> int:
	if not can_enter(line_idx): return -1
	return int(lines[line_idx][0]["index"])

func node_title(line_idx: int) -> String:
	var t := node_type(line_idx)
	var idx := node_index(line_idx)
	match t:
		NodeType.BATTLE: return "普通怪%d" % idx
		NodeType.ELITE: return "精英怪%d" % idx
		NodeType.BOSS: return "BOSS%d" % idx
		NodeType.REST: return "休息"
		NodeType.SMITH: return "铁匠"
		NodeType.SHOP: return "商店"
		NodeType.CHEST: return "宝箱"
		NodeType.NEXT_CHAPTER: return "前往下一章"
	return "未知节点"

func node_description(line_idx: int) -> String:
	var t := node_type(line_idx)
	return NODE_DESCRIPTIONS.get(t, "")

# 获取指定线路中指定位置节点的标题（用于debug）
func node_title_for_line(line_idx: int, pos: int) -> String:
	if line_idx < 0 or line_idx >= lines.size(): return "?"
	var line: Array = lines[line_idx]
	pos = clampi(pos, 0, maxi(line.size() - 1, 0))
	if line.is_empty(): return "?"
	var node: Dictionary = line[pos]
	var t: int = node["type"]
	var idx: int = node["index"]
	match t:
		NodeType.BATTLE: return "普通怪%d" % idx
		NodeType.ELITE: return "精英怪%d" % idx
		NodeType.BOSS: return "BOSS%d" % idx
		NodeType.REST: return "休息"
		NodeType.SMITH: return "铁匠"
		NodeType.SHOP: return "商店"
		NodeType.CHEST: return "宝箱"
		NodeType.NEXT_CHAPTER: return "前往下一章"
	return "未知节点"

# =====================================================
# 节点操作（用户行为，只删不补）
# =====================================================
func resolve_enter(line_idx: int) -> int:
	if not can_enter(line_idx): return -1
	var node: Dictionary = lines[line_idx][0]
	var t: int = node["type"]
	lines[line_idx].remove_at(0)
	match t:
		NodeType.BATTLE:
			battle_remaining = maxi(battle_remaining - 1, 0)
		NodeType.ELITE:
			elite_remaining = maxi(elite_remaining - 1, 0)
			battle_remaining = maxi(battle_remaining - 1, 0)
		NodeType.BOSS:
			boss_defeated = true
			boss_appeared = false
		NodeType.REST, NodeType.SMITH, NodeType.SHOP, NodeType.CHEST:
			if function_used.has(t):
				function_used[t] = int(function_used[t]) + 1
		NodeType.NEXT_CHAPTER:
			next_chapter_requested.emit()
			return t
	# BOSS击败后：将其他线路头部替换为NEXT_CHAPTER
	if t == NodeType.BOSS and boss_defeated:
		for i in range(LINE_COUNT):
			if i == line_idx: continue
			if lines[i].size() > 0 and int(lines[i][0]["type"]) != NodeType.NEXT_CHAPTER:
				lines[i][0] = {"type": NodeType.NEXT_CHAPTER, "index": 0}
	nodes_changed.emit()
	return t

func resolve_skip(line_idx: int) -> void:
	if not can_enter(line_idx): return
	var node: Dictionary = lines[line_idx][0]
	var t: int = node["type"]
	if t == NodeType.BOSS or t == NodeType.NEXT_CHAPTER: return
	lines[line_idx].remove_at(0)
	match t:
		NodeType.BATTLE:
			battle_remaining = maxi(battle_remaining - 1, 0)
		NodeType.ELITE:
			elite_remaining = maxi(elite_remaining - 1, 0)
			battle_remaining = maxi(battle_remaining - 1, 0)
		NodeType.REST, NodeType.SMITH, NodeType.SHOP, NodeType.CHEST:
			if function_used.has(t):
				function_used[t] = int(function_used[t]) + 1
	nodes_changed.emit()

func is_chapter_clear_available() -> bool:
	if boss_defeated: return true
	for line in lines:
		for node in line:
			if int(node["type"]) == NodeType.BOSS: return false
	return true

# =====================================================
# 存档序列化
# =====================================================
func serialize() -> Dictionary:
	var lines_data := []
	for line in lines:
		var arr := []
		for item in line:
			arr.append({"type": int(item["type"]), "index": int(item["index"])})
		lines_data.append(arr)
	return {
		"chapter_index": chapter_index,
		"total_chapters": total_chapters,
		"battle_remaining": battle_remaining,
		"elite_remaining": elite_remaining,
		"boss_defeated": boss_defeated,
		"boss_appeared": boss_appeared,
		"lines": lines_data,
		"shared_pool": [],
		"function_used": function_used.duplicate(true),
	}

func deserialize(data: Dictionary) -> void:
	chapter_index = data.get("chapter_index", 0)
	total_chapters = data.get("total_chapters", 2)
	battle_remaining = data.get("battle_remaining", POOL_NORMAL_COUNT + POOL_ELITE_COUNT)
	elite_remaining = data.get("elite_remaining", POOL_ELITE_COUNT)
	boss_defeated = data.get("boss_defeated", false)
	boss_appeared = data.get("boss_appeared", false)
	shared_pool = []
	lines.clear()
	var saved_lines = data.get("lines", [])
	for arr in saved_lines:
		var line := []
		for item in arr:
			if item is Dictionary:
				line.append({"type": int(item["type"]), "index": int(item["index"])})
			else:
				# 兼容旧版存档（纯int）
				line.append({"type": int(item), "index": 0})
		lines.append(line)
	function_used = data.get("function_used", {})
	nodes_changed.emit()
