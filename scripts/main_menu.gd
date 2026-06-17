extends Control

var SettingsManager: Node = null

@onready var settings_panel: Control = %SettingsPanel

@onready var settings_button: Button = %SettingsButton

@onready var start_button: Button = %StartButton

@onready var quit_button: Button = %QuitButton

@onready var version_label: Label = %VersionLabel

@onready var master_slider: HSlider = %MasterSlider

@onready var sfx_slider: HSlider = %SFXSlider

@onready var bgm_slider: HSlider = %BGMSlider

@onready var language_option: OptionButton = %LanguageOption

@onready var apply_button: Button = %ApplyButton

@onready var close_button: Button = %CloseButton

@onready var status_label: Label = %StatusLabel

var _button_tween: Tween = null


func _ready() -> void:
	SettingsManager = get_node("/root/SettingsManager")
	_setup_button_press_effect(settings_button)
	_setup_button_press_effect(start_button)
	_setup_button_press_effect(quit_button)
	_setup_button_press_effect(apply_button)
	_setup_button_press_effect(close_button)
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
	_apply_localization()

func _setup_button_press_effect(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2
	btn.gui_input.connect(_on_button_input.bind(btn))

func _on_button_input(event: InputEvent, btn: Button) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_tween_button_down(btn)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_tween_button_up(btn)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_tween_button_down(btn)
		elif not event.pressed:
			_tween_button_up(btn)

func _tween_button_down(btn: Button) -> void:
	if _button_tween:
		_button_tween.kill()
	_button_tween = create_tween()
	_button_tween.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_button_tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _tween_button_up(btn: Button) -> void:
	if _button_tween:
		_button_tween.kill()
	_button_tween = create_tween()
	_button_tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_button_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

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
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")

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
		version_label.text = "Prototype v0.2"
	else:
		settings_button.text = "设置"
		start_button.text = "开始冒险"
		quit_button.text = "退出游戏"
		version_label.text = "原型 v0.2"
