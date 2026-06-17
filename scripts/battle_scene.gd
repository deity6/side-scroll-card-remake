extends Control

var SettingsManager: Node = null

@onready var title_label: Label = %TitleLabel
@onready var player_label: Label = %PlayerLabel
@onready var enemy_label: Label = %EnemyLabel
@onready var deck_label: Label = %DeckLabel
@onready var discard_label: Label = %DiscardLabel
@onready var hand_container: BoxContainer = %HandContainer
@onready var end_turn_button: Button = %EndTurnButton
@onready var restart_button: Button = %RestartButton
@onready var back_button: Button = %BackButton
@onready var result_label: Label = %ResultLabel

var battle := BattleDemoState.new()

func _ready() -> void:
	SettingsManager = get_node("/root/SettingsManager")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	back_button.pressed.connect(_on_back_pressed)
	battle.hand_changed.connect(_refresh_hand)
	battle.state_changed.connect(_refresh_stats)
	_apply_localization()
	battle.start_battle()

func _apply_localization() -> void:
	var lang := str(SettingsManager.get_setting("language", "zh"))
	if lang == "en":
		title_label.text = "Battle Prototype"
		end_turn_button.text = "End Turn"
		restart_button.text = "Restart"
		back_button.text = "Back"
	else:
		title_label.text = "战斗原型"
		end_turn_button.text = "结束回合"
		restart_button.text = "重新开始"
		back_button.text = "返回"

func _refresh_stats() -> void:
	var lang := str(SettingsManager.get_setting("language", "zh"))
	if lang == "en":
		player_label.text = "Player HP:%d  Block:%d  Energy:%d  Turn:%d" % [battle.player_hp, battle.player_block, battle.energy, battle.turn]
		enemy_label.text = "Enemy HP:%d  Block:%d" % [battle.enemy_hp, battle.enemy_block]
		deck_label.text = "Draw:%d" % battle.draw_pile.size()
		discard_label.text = "Discard:%d" % battle.discard_pile.size()
		result_label.text = _result_text_en()
	else:
		player_label.text = "玩家 生命:%d  护甲:%d  能量:%d  回合:%d" % [battle.player_hp, battle.player_block, battle.energy, battle.turn]
		enemy_label.text = "敌人 生命:%d  护甲:%d" % [battle.enemy_hp, battle.enemy_block]
		deck_label.text = "牌库:%d" % battle.draw_pile.size()
		discard_label.text = "弃牌堆:%d" % battle.discard_pile.size()
		result_label.text = _result_text_zh()

func _refresh_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for i in range(battle.hand.size()):
		var card: Dictionary = battle.hand[i]
		var btn := Button.new()
		btn.text = "%s %d" % [card.get("name","?"), card.get("cost",0)]
		btn.custom_minimum_size = Vector2(120, 80)
		btn.disabled = not battle.can_play(i)
		btn.pressed.connect(_on_card_pressed.bind(i))
		hand_container.add_child(btn)
	_refresh_stats()

func _on_card_pressed(index: int) -> void:
	battle.play_card(index)

func _on_end_turn_pressed() -> void:
	battle.end_player_turn()

func _on_restart_pressed() -> void:
	battle.start_battle()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _result_text_en() -> String:
	if battle.enemy_hp <= 0:
		return "You won!"
	if battle.player_hp <= 0:
		return "You lost..."
	return ""

func _result_text_zh() -> String:
	if battle.enemy_hp <= 0:
		return "你赢了！"
	if battle.player_hp <= 0:
		return "你输了……"
	return ""
