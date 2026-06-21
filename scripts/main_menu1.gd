extends Control

# ============================================================
# 主菜单场景控制器
# 管理开始冒险、继续冒险、设置面板、语言切换
# 支持存档检测、二次确认新冒险
# 按钮果冻动画由 PressEffect 组件统一处理
# ============================================================

var SettingsManager: Node = null  # 全局设置管理器引用

# --- UI节点引用（%唯一名称绑定）---
@onready var settings_panel: Control = %SettingsPanel   # 设置面板
@onready var settings_button: Button = %SettingsButton # 设置按钮
@onready var start_button: Button = %StartButton       # 开始冒险按钮
@onready var quit_button: Button = %QuitButton         # 退出游戏按钮
@onready var version_label: Label = %VersionLabel      # 版本号标签
@onready var master_slider: HSlider = %MasterSlider    # 主音量滑块
@onready var sfx_slider: HSlider = %SFXSlider          # 音效滑块
@onready var bgm_slider: HSlider = %BGMSlider          # 背景音乐滑块
@onready var language_option: OptionButton = %LanguageOption  # 语言选择下拉框
@onready var apply_button: Button = %ApplyButton       # 应用设置按钮
@onready var close_button: Button = %CloseButton       # 关闭设置按钮
@onready var status_label: Label = %StatusLabel        # 设置状态提示标签
@onready var continue_button: Button = %ContinueButton # 继续冒险按钮

func _ready() -> void:
	SettingsManager = get_node("/root/SettingsManager")
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	language_option.item_selected.connect(_on_language_changed)
	SettingsManager.settings_changed.connect(_apply_localization)
	_load_settings_to_ui()
	_check_continue()
	_apply_localization()

func _on_settings_pressed() -> void:
	_load_settings_to_ui()
	settings_panel.visible = true
	_refresh_status()

func _on_close_pressed() -> void:
	settings_panel.visible = false

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
	var left = %StartButton.get_parent()
	var tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(left, "position:x", -400.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/adventure_scene.tscn"))

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
	if lang == "en":
		settings_button.text = "Settings"
		start_button.text = "Start"
		quit_button.text = "Quit"
		version_label.text = "Prototype v0.3.2"
		continue_button.text = "Continue"
	else:
		settings_button.text = "设置"
		start_button.text = "开始冒险"
		quit_button.text = "退出游戏"
		version_label.text = "原型 v0.3.2"
		continue_button.text = "继续冒险"

func _check_continue() -> void:
	continue_button.visible = AdventureState.has_save()

func _on_continue_pressed() -> void:
	var tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	var left = %ContinueButton.get_parent()
	tw.tween_property(left, "position:x", -400.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/adventure_scene.tscn"))

func _confirm_new_run() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "开始新冒险将覆盖当前存档，确定继续？"
	dialog.title = "提示"
	dialog.confirmed.connect(func():
		AdventureState.delete_save()
		_on_start_pressed()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(320, 160))
