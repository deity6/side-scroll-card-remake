extends Control

# ============================================================
# 主菜单场景控制器
# 管理树影版主界面、艺术字菜单、设置弹窗、语言图片切换和彩蛋小游戏
# 父菜单使用图片素材，缺素材时自动退回文字占位
# ============================================================

const ASSET_DIR := "res://assets/ui/main_menu_pet_spring/"  # 主菜单正式素材目录
const LANGUAGE_FADE_TIME := 0.2  # 菜单语言图片渐变切换时长
const MENU_GLOW_TIME := 0.12  # 菜单亮态淡入淡出时长
const EASTER_TAP_REQUIRED := 7  # 解锁小游戏需要连续点击版本号次数
const PROJECTILE_GRAVITY := 360.0  # 小光卡下落重力
const PROJECTILE_MAX_SPEED := 1450.0  # 小光卡最大飞行速度
const PROJECTILE_LIFE_TIME := 4.0  # 小光卡最大存活时间
const CHARGE_MAX_TIME := 1.15  # 小光卡最大蓄力时间
const CHARGE_MIN_IMPULSE := 260.0  # 小光卡最小蓄力冲量
const CHARGE_MAX_IMPULSE := 760.0  # 小光卡最大蓄力冲量
const CHARGE_SPIN_MIN_SPEED := 2.4  # 蓄力时小光卡最小视觉旋转速度
const CHARGE_SPIN_MAX_SPEED := 18.0  # 蓄力时小光卡最大视觉旋转速度
const THROW_DIRECTION_MIN_SPEED := 80.0  # 判定有效切线方向的最小拖动速度
const OBJECT_GRAVITY := 520.0  # 小物体下落重力
const AIR_FRICTION := 0.995  # 空中阻力系数
const COLLISION_RESTITUTION := 0.42  # 目标碰撞弹性
const TARGET_LIFE_TIME := 8.0  # 被击中或落地后目标保留时间
const SURFACE_Y := 620.0  # 目标物体下落的地面位置 (y 超过此值则停止下落)
const SURFACE_FRICTION := 0.82  # 地面摩擦系数 (目标落地后水平速度衰减)
const SLEEP_SPEED := 28.0  # 速度低于此值视为静止
const LEAF_FADE_LINE_Y := 690.0  # 落叶超过该 Y 轴监测线后淡出并停止碰撞
const FRUIT_FADE_LINE_Y := 820.0  # 果子超过该 Y 轴监测线后淡出并停止碰撞
const LINE_FADE_SPEED := 1.35  # 越过监测线后的淡出速度
const LEAF_SPAWN_INTERVAL := 1.25  # 落叶生成间隔
const FRUIT_SPAWN_INTERVAL := 2.6  # 果子生成间隔
const LEAF_REGION := Rect2(Vector2(380, 190), Vector2(230, 90))  # 落叶生成区域
const FRUIT_REGION := Rect2(Vector2(420, 260), Vector2(170, 70))  # 果子生成区域
const TRAIL_SPAWN_INTERVAL := 0.035  # 拖拽轨迹光效生成间隔
const TRAIL_DELAY_OFFSET := Vector2(-16, 10)  # 拖尾相对鼠标位置的延迟偏移

var SettingsManager: Node = null  # 全局设置管理器引用

var _current_language := "zh"  # 当前父菜单图片语言
var _language_tween: Tween = null  # 菜单语言渐变 Tween
var _glow_tweens := {}  # 菜单亮态 Tween 表
var _menu_items := {}  # 父菜单节点配置表
var _easter_tap_count := 0  # 版本号连续点击计数
var _mini_game_enabled := false  # 是否已解锁主菜单小游戏
var _charging_card: Control = null  # 正在拖拽蓄力的小光卡节点
var _charging_start := Vector2.ZERO  # 蓄力起点
var _charging_started_at := 0.0  # 蓄力开始时间
var _last_drag_position := Vector2.ZERO  # 上一次拖拽位置
var _last_drag_time := 0.0  # 上一次拖拽时间
var _drag_velocity := Vector2.ZERO  # 释放时使用的甩动速度
var _has_throw_direction := false  # 是否已经检测到有效发射切线方向
var _trail_spawn_timer := 0.0  # 拖尾生成计时器
var _projectiles: Array = []  # 飞行中的小光卡数据
var _targets: Array = []  # 彩蛋小游戏目标数据
var _leaf_spawn_timer := 0.0  # 落叶生成计时器
var _fruit_spawn_timer := 0.0  # 果子生成计时器
var _eyes_node: Control = null  # 暗处眼睛占位节点

# --- 背景与主界面节点 ---
@onready var background_layers: Control = %BackgroundLayers  # 背景分层父节点
@onready var background_far: TextureRect = %BackgroundFar  # 远景森林入口背景
@onready var tree_body: TextureRect = %TreeBody  # 主树与树影主体
@onready var foreground_leaves: TextureRect = %ForegroundLeaves  # 前景枝叶遮挡
@onready var menu_layer: Control = %MenuLayer  # 父菜单艺术字层
@onready var mini_game_layer: Control = %MiniGameLayer  # 彩蛋小游戏层
@onready var target_layer: Control = %TargetLayer  # 小游戏目标层
@onready var projectile_layer: Control = %ProjectileLayer  # 小光卡飞行层

# --- 父菜单节点 ---
@onready var start_menu_item: Control = %StartMenuItem  # 开始冒险菜单项
@onready var continue_menu_item: Control = %ContinueMenuItem  # 继续冒险菜单项
@onready var settings_menu_item: Control = %SettingsMenuItem  # 设置菜单项
@onready var quit_menu_item: Control = %QuitMenuItem  # 退出游戏菜单项
@onready var start_button: Button = %StartButton  # 开始冒险透明点击区
@onready var continue_button: Button = %ContinueButton  # 继续冒险透明点击区
@onready var settings_button: Button = %SettingsButton  # 设置透明点击区
@onready var quit_button: Button = %QuitButton  # 退出游戏透明点击区

# --- 设置弹窗节点 ---
@onready var settings_overlay: Control = %SettingsOverlay  # 设置弹窗遮罩层
@onready var settings_panel: PanelContainer = %SettingsPanel  # 设置弹窗面板
@onready var settings_title: Label = %SettingsTitle  # 设置标题
@onready var master_label: Label = %MasterLabel  # 主音量标签
@onready var sfx_label: Label = %SFXLabel  # 音效标签
@onready var bgm_label: Label = %BGMLabel  # 背景音乐标签
@onready var language_label: Label = %LanguageLabel  # 语言标签
@onready var master_slider: HSlider = %MasterSlider  # 主音量滑块
@onready var sfx_slider: HSlider = %SFXSlider  # 音效滑块
@onready var bgm_slider: HSlider = %BGMSlider  # 背景音乐滑块
@onready var language_option: OptionButton = %LanguageOption  # 语言选择下拉框
@onready var apply_button: Button = %ApplyButton  # 应用设置按钮
@onready var close_button: Button = %CloseButton  # 关闭设置按钮
@onready var status_label: Label = %StatusLabel  # 设置状态提示标签

# --- 其他节点 ---
@onready var version_label: Label = %VersionLabel  # 版本号标签
@onready var version_hotspot: Button = %VersionHotspot  # 版本号彩蛋点击区


func _ready() -> void:
	SettingsManager = get_node("/root/SettingsManager")
	_build_menu_items()
	_load_background_layers()
	_connect_menu_item("start", start_button, _on_start_pressed)
	_connect_menu_item("continue", continue_button, _on_continue_pressed)
	_connect_menu_item("settings", settings_button, _on_settings_pressed)
	_connect_menu_item("quit", quit_button, _on_quit_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	version_hotspot.pressed.connect(_on_version_hotspot_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	language_option.item_selected.connect(_on_language_changed)
	SettingsManager.settings_changed.connect(_apply_localization)
	_load_settings_to_ui()
	_check_continue()
	_apply_localization()


func _process(delta: float) -> void:
	_update_charging_card(delta)
	_update_spawners(delta)
	_update_projectiles(delta)
	_update_targets(delta)
	_update_eyes_motion()


func _input(event: InputEvent) -> void:
	if not _mini_game_enabled or settings_overlay.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_menu_pointer_position(event.position):
			return
		if event.pressed:
			_begin_card_charge(event.position)
		else:
			_release_card(event.position)
	elif event is InputEventMouseMotion and _charging_card:
		_update_card_charge(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_card_charge(event.position)
		else:
			_release_card(event.position)
	elif event is InputEventScreenDrag and _charging_card:
		_update_card_charge(event.position)


# 初始化父菜单节点配置，统一管理艺术字图片与占位文本
func _build_menu_items() -> void:
	_menu_items = {
		"start": {
			"root": start_menu_item,
			"dark": %StartTextDark,
			"glow": %StartTextGlow,
			"label": %StartFallbackLabel,
			"zh": "开始冒险",
			"en": "Start",
		},
		"continue": {
			"root": continue_menu_item,
			"dark": %ContinueTextDark,
			"glow": %ContinueTextGlow,
			"label": %ContinueFallbackLabel,
			"zh": "继续冒险",
			"en": "Continue",
		},
		"settings": {
			"root": settings_menu_item,
			"dark": %SettingsTextDark,
			"glow": %SettingsTextGlow,
			"label": %SettingsFallbackLabel,
			"zh": "设置",
			"en": "Settings",
		},
		"quit": {
			"root": quit_menu_item,
			"dark": %QuitTextDark,
			"glow": %QuitTextGlow,
			"label": %QuitFallbackLabel,
			"zh": "退出游戏",
			"en": "Quit",
		},
	}


# 连接菜单点击区和亮态反馈
func _connect_menu_item(key: String, button: Button, pressed_callable: Callable) -> void:
	button.pressed.connect(pressed_callable)
	button.mouse_entered.connect(func(): _set_menu_glow(key, true))
	button.mouse_exited.connect(func(): _set_menu_glow(key, false))
	button.button_down.connect(func(): _set_menu_glow(key, true))
	button.button_up.connect(func(): _set_menu_glow(key, false))


# 加载主菜单背景分层素材，缺图时保留场景内颜色占位
func _load_background_layers() -> void:
	background_far.texture = _load_texture_or_null(ASSET_DIR + "main_menu_bg_far.png")
	tree_body.texture = _load_texture_or_null(ASSET_DIR + "main_menu_tree_body.png")
	foreground_leaves.texture = _load_texture_or_null(ASSET_DIR + "main_menu_fg_leaves.png")


# 根据语言加载艺术字图片组，并在缺图时显示文字占位
func _apply_menu_language(lang: String, animated: bool = true) -> void:
	_current_language = "en" if lang == "en" else "zh"
	if _language_tween and _language_tween.is_valid():
		_language_tween.kill()
	_language_tween = create_tween().set_parallel(true) if animated else null
	for key in _menu_items.keys():
		var item: Dictionary = _menu_items[key]
		var dark_rect: TextureRect = item["dark"]
		var glow_rect: TextureRect = item["glow"]
		var label: Label = item["label"]
		var dark_texture := _load_texture_or_null("%smenu_%s_%s_dark.png" % [ASSET_DIR, key, _current_language])
		var glow_texture := _load_texture_or_null("%smenu_%s_%s_glow.png" % [ASSET_DIR, key, _current_language])
		dark_rect.texture = dark_texture
		glow_rect.texture = glow_texture
		label.text = item[_current_language]
		label.visible = dark_texture == null
		if animated and _language_tween:
			dark_rect.modulate.a = 0.0
			label.modulate.a = 0.0
			_language_tween.tween_property(dark_rect, "modulate:a", 1.0, LANGUAGE_FADE_TIME)
			_language_tween.tween_property(label, "modulate:a", 1.0, LANGUAGE_FADE_TIME)
		else:
			dark_rect.modulate.a = 1.0
			label.modulate.a = 1.0
		glow_rect.modulate.a = 0.0


# 菜单暗态和亮态切换
func _set_menu_glow(key: String, enabled: bool) -> void:
	if not _menu_items.has(key):
		return
	var item: Dictionary = _menu_items[key]
	var glow_rect: TextureRect = item["glow"]
	var label: Label = item["label"]
	if _glow_tweens.has(key):
		var old_tween: Tween = _glow_tweens[key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	var tween := create_tween().set_parallel(true)
	_glow_tweens[key] = tween
	tween.tween_property(glow_rect, "modulate:a", 1.0 if enabled else 0.0, MENU_GLOW_TIME)
	tween.tween_property(label, "modulate", Color(1.0, 0.96, 0.62, 1.0) if enabled else Color.WHITE, MENU_GLOW_TIME)


func _on_settings_pressed() -> void:
	_load_settings_to_ui()
	settings_overlay.visible = true
	_refresh_status()


func _on_close_pressed() -> void:
	settings_overlay.visible = false


func _on_apply_pressed() -> void:
	SettingsManager.set_setting("master_volume", int(master_slider.value))
	SettingsManager.set_setting("sfx_volume", int(sfx_slider.value))
	SettingsManager.set_setting("bgm_volume", int(bgm_slider.value))
	var lang_code := "zh" if language_option.selected <= 0 else "en"
	SettingsManager.set_setting("language", lang_code)
	_refresh_status()


func _on_start_pressed() -> void:
	if AdventureState.has_save():
		_confirm_new_run()
		return
	_transition_to_adventure()


func _on_continue_pressed() -> void:
	_transition_to_adventure()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_master_changed(value: float) -> void:
	SettingsManager.set_setting("master_volume", int(value))
	_refresh_status()


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_setting("sfx_volume", int(value))
	_refresh_status()


func _on_bgm_changed(value: float) -> void:
	SettingsManager.set_setting("bgm_volume", int(value))
	_refresh_status()


func _on_language_changed(_index: int) -> void:
	var lang_code := "zh" if language_option.selected <= 0 else "en"
	SettingsManager.set_setting("language", lang_code)


func _load_settings_to_ui() -> void:
	master_slider.value = SettingsManager.get_setting("master_volume", 100)
	sfx_slider.value = SettingsManager.get_setting("sfx_volume", 100)
	bgm_slider.value = SettingsManager.get_setting("bgm_volume", 100)
	var lang := str(SettingsManager.get_setting("language", "zh"))
	language_option.clear()
	language_option.add_item("中文", 0)
	language_option.add_item("English", 1)
	language_option.selected = 1 if lang == "en" else 0


func _refresh_status() -> void:
	var m := int(master_slider.value)
	var s := int(sfx_slider.value)
	var b := int(bgm_slider.value)
	var lang := "en" if language_option.selected > 0 else "zh"
	if lang == "en":
		status_label.text = "Master: %d%%  SFX: %d%%  BGM: %d%%" % [m, s, b]
	else:
		status_label.text = "主音量: %d%%  音效: %d%%  背景音乐: %d%%" % [m, s, b]


func _apply_localization() -> void:
	var lang := str(SettingsManager.get_setting("language", "zh"))
	_apply_menu_language(lang, _current_language != lang)
	if lang == "en":
		version_label.text = "Prototype v0.3.2"
		settings_title.text = "Settings"
		master_label.text = "Master Volume"
		sfx_label.text = "SFX"
		bgm_label.text = "BGM"
		language_label.text = "Language"
		apply_button.text = "Apply"
	else:
		version_label.text = "原型 v0.3.2"
		settings_title.text = "游戏设置"
		master_label.text = "主音量"
		sfx_label.text = "音效"
		bgm_label.text = "背景音乐"
		language_label.text = "语言"
		apply_button.text = "应用设置"
	_refresh_status()


func _check_continue() -> void:
	continue_menu_item.visible = AdventureState.has_save()


func _transition_to_adventure() -> void:
	background_layers.pivot_offset = get_viewport_rect().size * 0.5
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(background_layers, "scale", Vector2(1.12, 1.12), 0.42)
	tw.tween_property(background_layers, "position", Vector2(-36, -76), 0.42)
	tw.tween_property(menu_layer, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(func(): get_tree().change_scene_to_file("res://scenes/adventure_scene.tscn"))


func _confirm_new_run() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "开始新冒险将覆盖当前存档，确定继续？"
	dialog.title = "提示"
	dialog.confirmed.connect(func():
		AdventureState.delete_save()
		_transition_to_adventure()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(320, 160))


func _is_menu_pointer_position(pos: Vector2) -> bool:
	for item in _menu_items.values():
		var root: Control = item["root"]
		if root.visible and root.get_global_rect().has_point(pos):
			return true
	return version_hotspot.get_global_rect().has_point(pos)


func _on_version_hotspot_pressed() -> void:
	_easter_tap_count += 1
	if _easter_tap_count >= EASTER_TAP_REQUIRED and not _mini_game_enabled:
		_enable_mini_game()


func _enable_mini_game() -> void:
	_mini_game_enabled = true
	_spawn_eyes()
	version_label.modulate = Color(1.0, 0.96, 0.58, 1.0)


# 更新落叶和果子的区域生成器
func _update_spawners(delta: float) -> void:
	if not _mini_game_enabled:
		return
	_leaf_spawn_timer -= delta
	_fruit_spawn_timer -= delta
	if _leaf_spawn_timer <= 0.0:
		_leaf_spawn_timer = LEAF_SPAWN_INTERVAL + randf_range(-0.35, 0.35)
		_spawn_falling_target("leaf")
	if _fruit_spawn_timer <= 0.0:
		_fruit_spawn_timer = FRUIT_SPAWN_INTERVAL + randf_range(-0.5, 0.5)
		_spawn_falling_target("fruit")


# 生成会沿曲线下落的轻量物体，正式素材到位后可替换为 Sprite/AnimatedSprite2D
func _spawn_falling_target(kind: String) -> void:
	var region := LEAF_REGION if kind == "leaf" else FRUIT_REGION
	var radius := randf_range(12.0, 17.0) if kind == "leaf" else randf_range(15.0, 20.0)
	var node := _create_target_visual(kind, radius)
	node.position = Vector2(
		randf_range(region.position.x, region.end.x),
		randf_range(region.position.y, region.end.y)
	)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_layer.add_child(node)
	var initial_velocity := Vector2(randf_range(-45.0, 45.0), randf_range(20.0, 60.0))
	_targets.append({
		"node": node,
		"kind": kind,
		"mass": 0.42 if kind == "leaf" else 0.9,
		"radius": radius,
		"velocity": initial_velocity,
		"phase": randf_range(0.0, TAU),
		"alive": true,
		"settled": false,
		"life": TARGET_LIFE_TIME,
	})


func _spawn_eyes() -> void:
	if _eyes_node and is_instance_valid(_eyes_node):
		return
	_eyes_node = _create_target_visual("eyes", 22.0)
	_eyes_node.position = Vector2(610, 650)
	_eyes_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_layer.add_child(_eyes_node)


func _begin_card_charge(pos: Vector2) -> void:
	if _charging_card:
		_charging_card.queue_free()
	_charging_start = pos
	_charging_started_at = Time.get_ticks_msec() / 1000.0
	_last_drag_position = pos
	_last_drag_time = _charging_started_at
	_drag_velocity = Vector2.ZERO
	_has_throw_direction = false
	_trail_spawn_timer = 0.0
	_charging_card = _create_projectile_visual()
	_charging_card.position = pos - _charging_card.size * 0.5
	projectile_layer.add_child(_charging_card)


func _update_charging_card(delta: float) -> void:
	if not _charging_card:
		return
	var hold_time := maxf((Time.get_ticks_msec() / 1000.0) - _charging_started_at, 0.0)
	var charge_ratio := clampf(hold_time / CHARGE_MAX_TIME, 0.0, 1.0)
	var spin_speed := lerpf(CHARGE_SPIN_MIN_SPEED, CHARGE_SPIN_MAX_SPEED, charge_ratio)
	_charging_card.rotation += spin_speed * delta
	_trail_spawn_timer -= delta
	if _trail_spawn_timer <= 0.0:
		_trail_spawn_timer = TRAIL_SPAWN_INTERVAL
		_spawn_drag_trail(_last_drag_position)


func _update_card_charge(pos: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var dt := maxf(now - _last_drag_time, 0.001)
	_drag_velocity = (pos - _last_drag_position) / dt
	if _drag_velocity.length() >= THROW_DIRECTION_MIN_SPEED:
		_has_throw_direction = true
	_last_drag_position = pos
	_last_drag_time = now
	_charging_card.position = pos - _charging_card.size * 0.5
	_spawn_drag_trail(pos)


func _release_card(pos: Vector2) -> void:
	if not _charging_card:
		return
	_update_card_charge(pos)
	var hold_time := maxf((Time.get_ticks_msec() / 1000.0) - _charging_started_at, 0.01)
	if not _has_throw_direction:
		_fade_unthrown_card()
		return
	var charge_ratio := clampf(hold_time / CHARGE_MAX_TIME, 0.0, 1.0)
	var drag_direction := _drag_velocity.normalized()
	var velocity := drag_direction * lerpf(CHARGE_MIN_IMPULSE, CHARGE_MAX_IMPULSE, charge_ratio)
	velocity += _drag_velocity * 0.35
	if velocity.length() > PROJECTILE_MAX_SPEED:
		velocity = velocity.normalized() * PROJECTILE_MAX_SPEED
	_projectiles.append({
		"node": _charging_card,
		"velocity": velocity,
		"radius": 18.0,
		"life": PROJECTILE_LIFE_TIME,
	})
	_charging_card = null


func _fade_unthrown_card() -> void:
	var card := _charging_card
	_charging_card = null
	if not card:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "modulate:a", 0.0, 0.35)
	tw.tween_property(card, "scale", Vector2(0.35, 0.35), 0.35)
	tw.chain().tween_callback(card.queue_free)


func _spawn_drag_trail(pos: Vector2) -> void:
	var trail := ColorRect.new()
	trail.color = Color(1.0, 0.86, 0.26, 0.32)
	trail.position = pos + TRAIL_DELAY_OFFSET
	trail.size = Vector2(22, 14)
	trail.pivot_offset = trail.size * 0.5
	trail.rotation = randf_range(-0.25, 0.25)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile_layer.add_child(trail)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(trail, "modulate:a", 0.0, 0.26)
	tw.tween_property(trail, "scale", Vector2(0.25, 0.25), 0.26)
	tw.chain().tween_callback(trail.queue_free)


func _update_projectiles(delta: float) -> void:
	for i in range(_projectiles.size() - 1, -1, -1):
		var item: Dictionary = _projectiles[i]
		var node: Control = item["node"]
		if not is_instance_valid(node):
			_projectiles.remove_at(i)
			continue
		var velocity: Vector2 = item["velocity"]
		velocity += Vector2(0, PROJECTILE_GRAVITY) * delta
		item["life"] = float(item["life"]) - delta
		node.position += velocity * delta
		node.rotation += delta * 8.0
		item["velocity"] = velocity
		_check_projectile_hits(item)
		var rect := get_viewport_rect().grow(160.0)
		if item["life"] <= 0.0 or not rect.has_point(node.global_position):
			node.queue_free()
			_projectiles.remove_at(i)
		else:
			_projectiles[i] = item


func _check_projectile_hits(projectile_data: Dictionary) -> void:
	var projectile: Control = projectile_data["node"]
	var center := projectile.global_position + projectile.size * 0.5
	var projectile_velocity: Vector2 = projectile_data["velocity"]
	var projectile_radius := float(projectile_data["radius"])
	for target_index in range(_targets.size()):
		var target: Dictionary = _targets[target_index]
		if not target["alive"]:
			continue
		var target_node: Control = target["node"]
		if not is_instance_valid(target_node):
			target["alive"] = false
			_targets[target_index] = target
			continue
		var target_center := target_node.global_position + target_node.size * 0.5
		var delta := target_center - center
		var hit_distance := float(target["radius"]) + projectile_radius
		if delta.length() <= hit_distance:
			var normal := delta.normalized() if delta.length() > 0.001 else Vector2.UP
			var impulse := projectile_velocity.length() / maxf(float(target["mass"]), 0.1)
			var target_velocity := Vector2(target["velocity"]) + normal * impulse * 0.38
			target_velocity.y -= minf(impulse * 0.12, 260.0)
			target["velocity"] = target_velocity
			target_node.rotation += randf_range(-0.45, 0.45)
			_targets[target_index] = target


func _update_targets(delta: float) -> void:
	for i in range(_targets.size() - 1, -1, -1):
		var target: Dictionary = _targets[i]
		var node: Control = target["node"]
		if not is_instance_valid(node):
			_targets.remove_at(i)
			continue
		var velocity: Vector2 = target["velocity"]
		if str(target["kind"]) == "leaf":
			velocity.x += sin(Time.get_ticks_msec() / 350.0 + float(target["phase"])) * 26.0 * delta
		velocity += Vector2(0, OBJECT_GRAVITY) * delta
		velocity *= AIR_FRICTION
		node.position += velocity * delta
		var floor_y := SURFACE_Y - node.size.y
		if node.position.y >= floor_y:
			node.position.y = floor_y
			target["settled"] = true
			if velocity.y > 0.0:
				velocity.y = -velocity.y * COLLISION_RESTITUTION
			velocity.x *= SURFACE_FRICTION
			if absf(velocity.y) < 45.0:
				velocity.y = 0.0
		if node.position.x < 24.0:
			node.position.x = 24.0
			velocity.x = absf(velocity.x) * COLLISION_RESTITUTION
		elif node.position.x > get_viewport_rect().size.x - node.size.x - 24.0:
			node.position.x = get_viewport_rect().size.x - node.size.x - 24.0
			velocity.x = -absf(velocity.x) * COLLISION_RESTITUTION
		node.rotation += velocity.x * delta * 0.01
		target["velocity"] = velocity
		if target["settled"] and velocity.length() < SLEEP_SPEED:
			target["life"] = float(target["life"]) - delta * 2.0
			node.modulate.a = clampf(float(target["life"]) / TARGET_LIFE_TIME, 0.0, 1.0)
		else:
			target["life"] = float(target["life"]) - delta * 0.12
		if float(target["life"]) <= 0.0:
			_play_target_fade(node)
			_targets.remove_at(i)
		else:
			_targets[i] = target


func _update_eyes_motion() -> void:
	if _eyes_node and is_instance_valid(_eyes_node):
		_eyes_node.scale.y = 0.45 + absf(sin(Time.get_ticks_msec() / 700.0)) * 0.35


func _play_target_fade(target_node: Control) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(target_node, "modulate:a", 0.0, 0.2)
	tw.tween_property(target_node, "scale", Vector2(1.6, 1.6), 0.2)
	tw.chain().tween_callback(target_node.queue_free)


func _create_projectile_visual() -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(30, 42)
	root.size = Vector2(30, 42)
	root.pivot_offset = root.size * 0.5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var trail := ColorRect.new()
	trail.color = Color(1.0, 0.9, 0.35, 0.32)
	trail.position = Vector2(-18, 10)
	trail.size = Vector2(26, 22)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(trail)
	var card := ColorRect.new()
	card.color = Color(1.0, 0.96, 0.78, 0.95)
	card.position = Vector2(5, 4)
	card.size = Vector2(20, 30)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)
	return root


func _create_target_visual(kind: String, radius: float) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	root.size = root.custom_minimum_size
	root.pivot_offset = root.size * 0.5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "fruit":
		_add_rect_part(root, Vector2(radius * 0.32, radius * 0.42), Vector2(radius * 1.2, radius * 1.2), Color(0.96, 0.43, 0.25, 0.96))
		_add_rect_part(root, Vector2(radius * 0.75, radius * 0.12), Vector2(radius * 0.28, radius * 0.42), Color(0.34, 0.22, 0.12, 0.95))
	elif kind == "eyes":
		_add_rect_part(root, Vector2(radius * 0.12, radius * 0.62), Vector2(radius * 0.58, radius * 0.3), Color(1.0, 0.9, 0.35, 0.95))
		_add_rect_part(root, Vector2(radius * 1.05, radius * 0.62), Vector2(radius * 0.58, radius * 0.3), Color(1.0, 0.9, 0.35, 0.95))
	else:
		_add_rect_part(root, Vector2(radius * 0.2, radius * 0.72), Vector2(radius * 1.45, radius * 0.52), Color(0.63, 0.84, 0.36, 0.92))
		_add_rect_part(root, Vector2(radius * 0.9, radius * 0.78), Vector2(radius * 0.18, radius * 0.68), Color(0.36, 0.52, 0.2, 0.88))
	return root


func _add_rect_part(parent: Control, pos: Vector2, part_size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = part_size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)


func _load_texture_or_null(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	return resource as Texture2D
