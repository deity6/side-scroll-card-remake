class_name AdventureState
extends RefCounted

# ============================================================
# 冒险模式 - 冒险状态管理器
# 管理整个冒险流程：章节推进、玩家状态、存档读档
# 作为AdventureScene的数据核心
# ============================================================

# --- 信号 ---
signal chapter_changed  # 章节切换时触发
signal run_finished     # 所有章节通关时触发

# --- 章节数据 ---
var total_chapters: int = 2        # 总章节数
var current_chapter: int = 0       # 当前章节索引（从0开始）

# --- 子管理器 ---
var chapter_manager := ChapterNodeManager.new()  # 当前章节的节点树管理
var player := AdventurePlayerState.new()         # 玩家状态

# 开始新一轮冒险
func start_run(p_total_chapters: int = 2, seed_value: int = -1) -> void:
	total_chapters = maxi(p_total_chapters, 1)
	current_chapter = 0
	player.initialize()  # 初始化玩家属性
	chapter_manager.setup(current_chapter, total_chapters, seed_value)
	chapter_changed.emit()

# 推进到下一章节
func advance_chapter() -> void:
	current_chapter += 1
	if current_chapter >= total_chapters:
		run_finished.emit()  # 所有章节通关
		return
	chapter_manager.setup(current_chapter, total_chapters)
	chapter_changed.emit()

# 返回当前章节显示标签（如"第1章"）
func chapter_label() -> String:
	return "第" + str(current_chapter + 1) + "章"

# 返回剩余节点数显示文本
func remaining_label() -> String:
	return "剩余战斗节点: " + str(chapter_manager.battle_remaining)

# --- 存档序列化 ---

# 将整个冒险状态序列化为字典
func serialize() -> Dictionary:
	return {
		"total_chapters": total_chapters,
		"current_chapter": current_chapter,
		"chapter_manager": chapter_manager.serialize(),
		"player": player.serialize(),
	}

# 从字典反序列化恢复冒险状态
func deserialize(data: Dictionary) -> void:
	total_chapters = data.get("total_chapters", 2)
	current_chapter = data.get("current_chapter", 0)
	chapter_manager.deserialize(data.get("chapter_manager", {}))
	player.deserialize(data.get("player", {}))
	chapter_changed.emit()

# --- 静态存档方法 ---

# 保存冒险进度到文件
static func save_run(data: Dictionary) -> void:
	var cfg = ConfigFile.new()
	for key in data.keys():
		cfg.set_value("save", key, data[key])
	cfg.save("user://savegame.cfg")

# 从文件加载冒险进度（失败返回空字典）
static func load_run() -> Dictionary:
	var cfg = ConfigFile.new()
	if cfg.load("user://savegame.cfg") != OK:
		return {}
	var result := {}
	for key in cfg.get_section_keys("save"):
		result[key] = cfg.get_value("save", key)
	return result

# 检查是否存在存档
static func has_save() -> bool:
	return FileAccess.file_exists("user://savegame.cfg")

# 删除存档文件
static func delete_save() -> void:
	if FileAccess.file_exists("user://savegame.cfg"):
		DirAccess.remove_absolute("user://savegame.cfg")
