extends Node

# ============================================================
# SoundManager - 全局音效管理器 (Autoload 单例)
# 管理所有 SFX 和 BGM 的加载、播放、音量控制
# 所有场景通过 SoundManager.play_sfx("key") 调用音效
# ============================================================

## 音效播放信号（调试用）
signal sfx_played(key: String)
## BGM 切换信号
signal bgm_changed(key: String)

# --- 音效映射表：key -> AudioStream ---
var _sfx_map: Dictionary = {}
## BGM 映射表：key -> AudioStream
var _bgm_map: Dictionary = {}

# --- 活跃的 SFX 播放器池 ---
## 每个 key 最多同时播放 MAX_SFX_INSTANCES 个实例
const MAX_SFX_INSTANCES := 4
## SFX 播放器池：key -> Array[AudioStreamPlayer]
var _sfx_pool: Dictionary = {}
## SFX 播放器队列（用于淘汰最旧的）：key -> Array[float]（时间戳）
var _sfx_timestamps: Dictionary = {}

# --- BGM 播放器 ---
var _bgm_player: AudioStreamPlayer = null
## 当前播放的 BGM key
var _current_bgm: String = ""
## BGM 淡入淡出 Tween
var _bgm_tween: Tween = null

# --- 音效映射配置路径 ---
const MAPPING_PATH := "res://Data/sfx_mapping.json"


func _ready() -> void:
	# 设置 process 在 pausable 模式下仍然运行
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_mapping()
	_setup_bgm_player()
	# 预加载所有音效到内存
	preload_all()


## 从 JSON 加载音效映射配置
func _load_mapping() -> void:
	var file := FileAccess.open(MAPPING_PATH, FileAccess.READ)
	if not file:
		push_warning("SoundManager: 无法加载映射文件 " + MAPPING_PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("SoundManager: JSON 解析失败 - " + json.get_error_message())
		return
	var data: Dictionary = json.data
	# 加载 SFX 映射
	var sfx_data: Dictionary = data.get("sfx", {})
	for key in sfx_data:
		var path: String = sfx_data[key]
		if ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream:
				_sfx_map[key] = stream
			else:
				push_warning("SoundManager: 无法加载音效 " + key + " -> " + path)
		else:
			push_warning("SoundManager: 音效文件不存在 " + key + " -> " + path)
	# BGM 映射暂不加载（素材待后续版本添加，v0.3.4+）
	# var bgm_data: Dictionary = data.get("bgm", {})
	# for key in bgm_data:
	# 	var path: String = bgm_data[key]
	# 	if ResourceLoader.exists(path):
	# 		var stream = load(path) as AudioStream
	# 		if stream:
	# 			_bgm_map[key] = stream
	print("SoundManager: 已加载 %d 个 SFX, %d 个 BGM（BGM 暂未添加）" % [_sfx_map.size(), _bgm_map.size()])


## 创建 BGM 播放器并挂载到播放树
func _setup_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	_bgm_player.name = "BGMPlayer"
	add_child(_bgm_player)


## 预加载所有已映射的音效到内存
func preload_all() -> void:
	for key in _sfx_map:
		_ensure_pool(key)


## 确保某个 key 的播放器池已初始化
func _ensure_pool(key: String) -> void:
	if not _sfx_pool.has(key):
		_sfx_pool[key] = []
		_sfx_timestamps[key] = []


## 获取指定 key 的一个可用播放器，超出上限时淘汰最旧的
func _get_player(key: String) -> AudioStreamPlayer:
	_ensure_pool(key)
	var pool: Array = _sfx_pool[key]
	var timestamps: Array = _sfx_timestamps[key]
	# 先找空闲的（未播放的）
	for i in range(pool.size()):
		var player: AudioStreamPlayer = pool[i]
		if not player.playing:
			timestamps[i] = Time.get_ticks_msec() / 1000.0
			return player
	# 超过上限，淘汰最旧的
	if pool.size() >= MAX_SFX_INSTANCES:
		var oldest_idx := 0
		var oldest_time: float = timestamps[0]
		for i in range(1, timestamps.size()):
			if timestamps[i] < oldest_time:
				oldest_time = timestamps[i]
				oldest_idx = i
		var old_player: AudioStreamPlayer = pool[oldest_idx]
		old_player.stop()
		timestamps[oldest_idx] = Time.get_ticks_msec() / 1000.0
		return old_player
	# 还有空间，创建新播放器
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)
	pool.append(player)
	timestamps.append(Time.get_ticks_msec() / 1000.0)
	return player


## 播放一次性音效
func play_sfx(key: String) -> void:
	if not _sfx_map.has(key):
		return
	var stream: AudioStream = _sfx_map[key]
	var player := _get_player(key)
	player.stream = stream
	player.pitch_scale = 1.0
	player.play()
	sfx_played.emit(key)


## 播放带随机 pitch 变化的音效（+-5%），避免重复播放的机械感
func play_sfx_varied(key: String) -> void:
	if not _sfx_map.has(key):
		return
	var stream: AudioStream = _sfx_map[key]
	var player := _get_player(key)
	player.stream = stream
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()
	sfx_played.emit(key)


## 播放 BGM，支持淡入
func play_bgm(key: String, fade_time: float = 0.8) -> void:
	if key == _current_bgm and _bgm_player.playing:
		return
	if not _bgm_map.has(key):
		push_warning("SoundManager: BGM 不存在 - " + key)
		return
	_current_bgm = key
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	if _bgm_player.playing and fade_time > 0.0:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, fade_time * 0.5)
		_bgm_tween.tween_callback(func():
			_bgm_player.stream = _bgm_map[key]
			_bgm_player.volume_db = -40.0
			_bgm_player.play()
			_bgm_tween = create_tween()
			_bgm_tween.tween_property(_bgm_player, "volume_db", 0.0, fade_time * 0.5)
		)
	else:
		_bgm_player.stream = _bgm_map[key]
		_bgm_player.volume_db = -40.0 if fade_time > 0.0 else 0.0
		_bgm_player.play()
		if fade_time > 0.0:
			_bgm_tween = create_tween()
			_bgm_tween.tween_property(_bgm_player, "volume_db", 0.0, fade_time)
	bgm_changed.emit(key)


## 停止 BGM 播放，支持淡出
func stop_bgm(fade_time: float = 0.8) -> void:
	if not _bgm_player.playing:
		return
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	if fade_time > 0.0:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, fade_time)
		_bgm_tween.tween_callback(func():
			_bgm_player.stop()
			_current_bgm = ""
		)
	else:
		_bgm_player.stop()
		_current_bgm = ""


## 检查某个音效键是否存在
func has_sfx(key: String) -> bool:
	return _sfx_map.has(key)


## 检查某个 BGM 键是否存在
func has_bgm(key: String) -> bool:
	return _bgm_map.has(key)


## 获取当前播放的 BGM key
func get_current_bgm() -> String:
	return _current_bgm

