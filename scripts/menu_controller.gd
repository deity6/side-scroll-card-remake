extends Control

# ============================================================
# 主菜单场景控制器
# 管理树影版主界面、艺术字菜单、设置弹窗、语言图片切换
# 彩蛋小游戏逻辑已分离到 easter_egg_minigame.gd
# ============================================================

const ASSET_DIR := "res://assets/ui/main_menu_pet_spring/"
const LANGUAGE_FADE_TIME := 0.2
const MENU_GLOW_TIME := 0.12
const EASTER_TAP_REQUIRED := 7
const MINI_GAME_FADE_DURATION := 0.3

var SettingsManager: Node = null

var _current_language := "zh"
var _language_tween: Tween = null
var _glow_tweens := {}
var _menu_items := {}
var _easter_tap_count := 0
var _mini_game_enabled := false
var _mini_game_visible := false
var _menu_hide_tween: Tween = null

# 彩蛋小游戏控制器引用
var _minigame: Node = null  # EasterEggMiniGame 实例

# --- 背景与主界面节点 ---
@onready var background_layers: Control = %BackgroundLayers
@onready var background_far: TextureRect = %BackgroundFar
@onready var tree_body: TextureRect = %TreeBody
@onready var foreground_leaves: TextureRect = %ForegroundLeaves
@onready var menu_layer: Control = %MenuLayer

# --- 彩蛋图层节点 ---
@onready var mini_game_layer: Control = %MiniGameLayer
@onready var projectile_layer: Control = %ProjectileLayer
@onready var target_layer: Control = %TargetLayer

# --- 父菜单节点 ---
@onready var start_menu_item: Control = %StartMenuItem
@onready var continue_menu_item: Control = %ContinueMenuItem
@onready var settings_menu_item: Control = %SettingsMenuItem
@onready var quit_menu_item: Control = %QuitMenuItem
@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

# --- 设置弹窗节点 ---
@onready var settings_overlay: Control = %SettingsOverlay
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var settings_title: Label = %SettingsTitle
@onready var master_label: Label = %MasterLabel
@onready var sfx_label: Label = %SFXLabel
@onready var bgm_label: Label = %BGMLabel
@onready var language_label: Label = %LanguageLabel
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var bgm_slider: HSlider = %BGMSlider
@onready var language_option: OptionButton = %LanguageOption
@onready var apply_button: Button = %ApplyButton
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel

# --- 彩蛋区域节点 ---
@onready var fruit_zone: ColorRect = %FruitZone
@onready var leaf_zone: ColorRect = %LeafZone
@onready var leaf_fade_line: ColorRect = %LeafFadeLine
@onready var fruit_fade_line: ColorRect = %FruitFadeLine

# --- 其他节点 ---
@onready var version_label: Label = %VersionLabel
@onready var version_hotspot: Button = %VersionHotspot


func _ready() -> void:
	SettingsManager = get_node("/root/SettingsManager")
	# 初始化彩蛋小游戏控制器
	_minigame = preload("res://scripts/easter_egg_minigame.gd").new()
	add_child(_minigame)
	_minigame.setup(projectile_layer, target_layer, mini_game_layer, fruit_zone, leaf_zone, leaf_fade_line, fruit_fade_line, get_viewport_rect().size)
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
	if _mini_game_enabled and _mini_game_visible:
		_set_menu_buttons_enabled(false)
	elif not _mini_game_visible:
		_set_menu_buttons_enabled(true)
	if _minigame and _mini_game_enabled and _mini_game_visible:
		_minigame.process_update(delta)


func _input(event: InputEvent) -> void:
	if not _mini_game_enabled or not _mini_game_visible or settings_overlay.visible:
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var pos: Vector2
		if event is InputEventMouseButton:
			pos = event.position
		else:
			pos = event.position
		if _is_menu_pointer_position(pos):
			return
	if _minigame:
		_minigame.handle_input(event)


func _build_menu_items() -> void:
	_menu_items = {
		"start": {"root": start_menu_item, "dark": %StartTextDark, "glow": %StartTextGlow, "label": %StartFallbackLabel, "zh": "开始冒险", "en": "Start"},
		"continue": {"root": continue_menu_item, "dark": %ContinueTextDark, "glow": %ContinueTextGlow, "label": %ContinueFallbackLabel, "zh": "继续冒险", "en": "Continue"},
		"settings": {"root": settings_menu_item, "dark": %SettingsTextDark, "glow": %SettingsTextGlow, "label": %SettingsFallbackLabel, "zh": "设置", "en": "Settings"},
		"quit": {"root": quit_menu_item, "dark": %QuitTextDark, "glow": %QuitTextGlow, "label": %QuitFallbackLabel, "zh": "退出游戏", "en": "Quit"},
	}


func _connect_menu_item(key: String, button: Button, pressed_callable: Callable) -> void:
	button.pressed.connect(pressed_callable)
	button.mouse_entered.connect(func(): _set_menu_glow(key, true); SoundManager.play_sfx("ui_hover"))
	button.mouse_exited.connect(func(): _set_menu_glow(key, false))
	button.button_down.connect(func(): _set_menu_glow(key, true))
	button.button_up.connect(func(): _set_menu_glow(key, false))


func _load_background_layers() -> void:
	background_far.texture = _load_texture_or_null(ASSET_DIR + "main_menu_bg_far.png")
	tree_body.texture = _load_texture_or_null(ASSET_DIR + "main_menu_tree_body.png")
	foreground_leaves.texture = _load_texture_or_null(ASSET_DIR + "main_menu_fg_leaves.png")


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
	SoundManager.play_sfx_varied("ui_click_default")
	_load_settings_to_ui()
	settings_overlay.visible = true
	_refresh_status()


func _on_close_pressed() -> void:
	SoundManager.play_sfx_varied("ui_click_default")
	settings_overlay.visible = false


func _on_apply_pressed() -> void:
	SoundManager.play_sfx_varied("ui_click_default")
	SettingsManager.set_setting("master_volume", int(master_slider.value))
	SettingsManager.set_setting("sfx_volume", int(sfx_slider.value))
	SettingsManager.set_setting("bgm_volume", int(bgm_slider.value))
	var lang_code := "zh" if language_option.selected <= 0 else "en"
	SettingsManager.set_setting("language", lang_code)
	_refresh_status()


func _on_start_pressed() -> void:
	if AdventureState.has_save():
		SoundManager.play_sfx("ui_click_start_continue")
		_confirm_new_run()
		return
	SoundManager.play_sfx("ui_click_start_new")
	_transition_to_adventure()


func _on_continue_pressed() -> void:
	SoundManager.play_sfx_varied("ui_click_default")
	_transition_to_adventure()


func _on_quit_pressed() -> void:
	SoundManager.play_sfx_varied("ui_click_default")
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
	SoundManager.play_sfx("ui_back")
	background_layers.pivot_offset = get_viewport_rect().size * 0.5
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(background_layers, "scale", Vector2(1.12, 1.12), 0.42)
	tw.tween_property(background_layers, "position", Vector2(-36, -76), 0.42)
	tw.tween_property(menu_layer, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(func(): get_tree().change_scene_to_file("res://scenes/adventure_scene.tscn"))


func _confirm_new_run() -> void:
	SoundManager.play_sfx("ui_dialog_popup")
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
		if root.visible and root.modulate.a > 0.05 and root.get_global_rect().has_point(pos):
			return true
	return version_hotspot.get_global_rect().has_point(pos)


func _on_version_hotspot_pressed() -> void:
	_easter_tap_count += 1
	if _easter_tap_count >= EASTER_TAP_REQUIRED and not _mini_game_enabled:
		_enable_mini_game()
	elif _easter_tap_count >= EASTER_TAP_REQUIRED and _mini_game_enabled:
		_disable_mini_game()


func _enable_mini_game() -> void:
	if _mini_game_enabled and _mini_game_visible:
		return
	_mini_game_enabled = true
	_mini_game_visible = true
	version_label.modulate = Color(1.0, 0.96, 0.58, 1.0)
	_minigame.show_zones()
	# 渐隐按钮并禁用点击
	if _menu_hide_tween and _menu_hide_tween.is_valid():
		_menu_hide_tween.kill()
	_menu_hide_tween = create_tween().set_parallel(true)
	_menu_hide_tween.tween_property(start_menu_item, "modulate:a", 0.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_property(continue_menu_item, "modulate:a", 0.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_property(settings_menu_item, "modulate:a", 0.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_property(quit_menu_item, "modulate:a", 0.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_callback(_set_menu_buttons_disabled)


func _disable_mini_game() -> void:
	if not _mini_game_enabled or not _mini_game_visible:
		return
	_mini_game_visible = false
	_mini_game_enabled = false
	version_label.modulate = Color.WHITE
	_minigame.hide_zones()
	# 渐显按钮并恢复点击
	if _menu_hide_tween and _menu_hide_tween.is_valid():
		_menu_hide_tween.kill()
	_menu_hide_tween = create_tween().set_parallel(true)
	_menu_hide_tween.tween_property(start_menu_item, "modulate:a", 1.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_property(continue_menu_item, "modulate:a", 1.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_property(settings_menu_item, "modulate:a", 1.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_property(quit_menu_item, "modulate:a", 1.0, MINI_GAME_FADE_DURATION)
	_menu_hide_tween.tween_callback(_set_menu_buttons_enabled.bind(true))
	_minigame.clear_all()


func _set_menu_buttons_disabled() -> void:
	start_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_menu_buttons_enabled(enabled: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	start_button.mouse_filter = filter
	continue_button.mouse_filter = filter
	settings_button.mouse_filter = filter
	quit_button.mouse_filter = filter


func _load_texture_or_null(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	return resource as Texture2D
