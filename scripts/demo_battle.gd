extends Control

var SettingsManager: Node = null

@onready var title_label: Label = %TitleLabel
@onready var info_label: Label = %InfoLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	SettingsManager = get_node("/root/SettingsManager")
	back_button.pressed.connect(_on_back_pressed)
	_refresh_text()

func _refresh_text() -> void:
	var lang := str(SettingsManager.get_setting("language", "zh"))
	if lang == "en":
		title_label.text = "Battle Prototype"
		info_label.text = "Minimal interactive prototype. Cards and balance are placeholders."
		back_button.text = "Back"
	else:
		title_label.text = "战斗原型"
		info_label.text = "最小可交互原型。卡牌与数值都是占位。"
		back_button.text = "返回"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
