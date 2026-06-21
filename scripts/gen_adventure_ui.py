from pathlib import Path
base = Path(".")
def write(path, text):
    p = base / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8", newline="\n")

# adventure_card.gd
write("scripts/adventure_card.gd", '''extends PanelContainer

signal card_selected(index: int)

var index: int = 0
var selected: bool = false

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var icon: ColorRect = %Icon
@onready var close_button: Button = %CloseButton
@onready var action_button: Button = %ActionButton

func set_index(value: int) -> void:
    index = value

func set_title(text: String) -> void:
    title_label.text = text

func set_desc(text: String) -> void:
    desc_label.text = text

func set_icon_color(color: Color) -> void:
    icon.color = color

func set_selected(value: bool) -> void:
    selected = value
    action_button.visible = value

func set_close_visible(value: bool) -> void:
    close_button.visible = value

func set_close_enabled(value: bool) -> void:
    close_button.disabled = not value
    close_button.modulate = Color(1, 1, 1, 1) if value else Color(0.6, 0.6, 0.6, 0.8)

func set_action_text(text: String) -> void:
    action_button.text = text

func _ready() -> void:
    gui_input.connect(_on_gui_input)
    close_button.pressed.connect(_on_close_pressed)
    action_button.pressed.connect(_on_action_pressed)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        card_selected.emit(index)

func _on_close_pressed() -> void:
    get_viewport().set_input_as_handled()
    card_selected.emit(-1)

func _on_action_pressed() -> void:
    get_viewport().set_input_as_handled()
    card_selected.emit(index + 1000)
''')

# adventure_tooltip.gd
write("scripts/adventure_tooltip.gd", '''extends PanelContainer

@onready var label: Label = %Label

func set_text(value: String) -> void:
    label.text = value
    size = Vector2.ZERO
    reset_size()
''')

# adventure_card.tscn
write("scenes/adventure_card.tscn", '''[gd_scene load_steps=2 format=3 uid="uid://b4a0u000001"]

[ext_resource type="Script" uid="uid://a1b2c3d4e5f60001" path="res://scripts/adventure_card.gd" id="1"]

[node name="AdventureCard" type="PanelContainer"]
custom_minimum_size = Vector2(190, 260)
tooltip_text = ""
mouse_filter = 0
script = ExtResource("1")

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 12
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 12
theme_override_constants/margin_bottom = 12

[node name="VBox" type="VBoxContainer" parent="Margin"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name="Header" type="HBoxContainer" parent="Margin/VBox"]
layout_mode = 2

[node name="TitleLabel" type="Label" parent="Margin/VBox/Header"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.0
horizontal_alignment = 1
autowrap_mode = 2

[node name="CloseButton" type="Button" parent="Margin/VBox/Header"]
unique_name_in_owner = true
custom_minimum_size = Vector2(26, 26)
layout_mode = 2
size_flags_horizontal = 10
text = "\\u00d7"

[node name="Icon" type="ColorRect" parent="Margin/VBox"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
size_flags_stretch_ratio = 2.0
color = Color(0.15, 0.15, 0.18, 1)

[node name="DescLabel" type="Label" parent="Margin/VBox"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
horizontal_alignment = 1
autowrap_mode = 2

[node name="ActionButton" type="Button" parent="Margin/VBox"]
unique_name_in_owner = true
visible = false
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
size_flags_horizontal = 3
''')

# adventure_tooltip.tscn
write("scenes/adventure_tooltip.tscn", '''[gd_scene load_steps=2 format=3 uid="uid://b4a0u000002"]

[ext_resource type="Script" uid="uid://a1b2c3d4e5f60002" path="res://scripts/adventure_tooltip.gd" id="1"]

[node name="AdventureTooltip" type="PanelContainer"]
visible = false
mouse_filter = 2
script = ExtResource("1")

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name="Label" type="Label" parent="Margin"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
autowrap_mode = 2
''')

# adventure_scene.gd
scene_lines = [
    "extends Control",
    "",
    "const CARD_SCENE_PATH := \"res://scenes/adventure_card.tscn\"",
    "const TOOLTIP_SCENE_PATH := \"res://scenes/adventure_tooltip.tscn\"",
    "",
    "const CARD_COLORS := {",
    "    ChapterNodeManager.NodeType.BATTLE: Color(0.52, 0.20, 0.20, 1),",
    "    ChapterNodeManager.NodeType.ELITE: Color(0.70, 0.28, 0.10, 1),",
    "    ChapterNodeManager.NodeType.BOSS: Color(0.64, 0.08, 0.08, 1),",
    "    ChapterNodeManager.NodeType.REST: Color(0.18, 0.52, 0.28, 1),",
    "    ChapterNodeManager.NodeType.SMITH: Color(0.32, 0.34, 0.38, 1),",
    "    ChapterNodeManager.NodeType.SHOP: Color(0.58, 0.50, 0.12, 1),",
    "    ChapterNodeManager.NodeType.CHEST: Color(0.56, 0.42, 0.12, 1),",
    "    ChapterNodeManager.NodeType.NEXT_CHAPTER: Color(0.22, 0.36, 0.62, 1),",
    "}",
    "",
    "var player: AdventurePlayerState = AdventurePlayerState.new()",
    "var selected_card_index: int = -1",
    "var _tooltip_scene: PackedScene = preload(TOOLTIP_SCENE_PATH)",
    "var _active_tooltip: Node = null",
    "",
    "@onready var chapter_label: Label = %ChapterLabel",
    "@onready var gold_label: Label = %GoldLabel",
    "@onready var remaining_label: Label = %RemainingLabel",
    "@onready var card_slots_container: HBoxContainer = %CardSlots",
    "@onready var card_pack_button: Button = %CardPackButton",
    "@onready var hp_bar: ProgressBar = %HpBar",
    "@onready var hp_label: Label = %HpLabel",
    "@onready var exp_bar: ProgressBar = %ExpBar",
    "@onready var exp_label: Label = %ExpLabel",
    "@onready var mana_button: Button = %ManaButton",
    "@onready var ap_button: Button = %ApButton",
    "@onready var limit_button: Button = %LimitButton",
    "@onready var tooltip_anchor: Control = %TooltipAnchor",
    "@onready var back_button: Button = %BackButton",
    "",
    "func _node_action_text(node_type: int) -> String:",
    "    var t := node_type",
    "    if t == ChapterNodeManager.NodeType.BATTLE:",
    '        return "??"',
    "    if t == ChapterNodeManager.NodeType.ELITE:",
    '        return "????"',
    "    if t == ChapterNodeManager.NodeType.BOSS:",
    '        return "BOSS??"',
    "    if t == ChapterNodeManager.NodeType.REST:",
    '        return "????"',
    "    if t == ChapterNodeManager.NodeType.SMITH:",
    '        return "????"',
    "    if t == ChapterNodeManager.NodeType.SHOP:",
    '        return "????"',
    "    if t == ChapterNodeManager.NodeType.CHEST:",
    '        return "????"',
    "    if t == ChapterNodeManager.NodeType.NEXT_CHAPTER:",
    '        return "?????"',
    '    return "????"',
    "",
    "func _tooltip_text(key: String) -> String:",
    '    if key == "hp":',
    '        return "HP??????????0????????"',
    '    if key == "gold":',
    '        return "???????????????"',
    '    if key == "mana":',
    '        return "??????????????????????"',
    '    if key == "action_points":',
    '        return "?????????????????"',
    '    if key == "card_limit":',
    '        return "?????????????????"',
    '    return ""',
    "",
    "func _ready() -> void:",
    "    back_button.pressed.connect(_on_back_button_pressed)",
    "    card_pack_button.gui_input.connect(_on_card_pack_gui_input)",
    "    mana_button.gui_input.connect(_on_mana_gui_input)",
    "    ap_button.gui_input.connect(_on_ap_gui_input)",
    "    limit_button.gui_input.connect(_on_limit_gui_input)",
    "    player.initialize()",
    "    _refresh_hud()",
    "    adventure.start_run(2)",
    "    _sync_ui()",
    "",
    "func _refresh_hud() -> void:",
    '    gold_label.text = "?? %d" % player.gold',
    "    hp_bar.max_value = player.max_hp",
    "    hp_bar.value = player.hp",
    '    hp_label.text = "%d/%d" % [player.hp, player.max_hp]',
    "    exp_bar.max_value = player.exp_to_next",
    "    exp_bar.value = player.exp",
    '    exp_label.text = "%d/%d" % [player.exp, player.exp_to_next]',
    '    mana_button.text = "%d" % player.mana',
    '    ap_button.text = "%d" % player.action_points',
    '    limit_button.text = "%d" % player.card_limit',
    "",
    "func _sync_ui() -> void:",
    "    chapter_label.text = adventure.chapter_label()",
    "    remaining_label.text = adventure.remaining_label()",
    "    _sync_cards()",
    "    if selected_card_index == -1:",
    "        _hide_tooltip()",
    "",
    "func _sync_cards() -> void:",
    "    for child in card_slots_container.get_children():",
    "        child.queue_free()",
    "    var hand := adventure.chapter_manager.get_hand()",
    "    for i in range(hand.size()):",
    "        var node_type := adventure.chapter_manager.node_type(i)",
    "        var card: Control = preload(CARD_SCENE_PATH).instantiate()",
    "        card.set_index(i)",
    "        card.set_title(adventure.chapter_manager.node_title(i))",
    "        card.set_desc(adventure.chapter_manager.node_description(i))",
    "        card.set_icon_color(CARD_COLORS.get(node_type, Color(0.2, 0.2, 0.2, 1)))",
    "        card.set_selected(selected_card_index == i)",
    "        card.set_close_visible(true)",
    "        card.set_close_enabled(adventure.chapter_manager.is_close_allowed(i))",
    "        card.set_action_text(_node_action_text(node_type))",
    "        card.card_selected.connect(_on_card_selected)",
    "        card_slots_container.add_child(card)",
    "",
    "func _on_card_selected(raw_index: int) -> void:",
    "    if raw_index == -1:",
    "        _handle_close()",
    "        return",
    "    if raw_index >= 1000:",
    "        _handle_action(raw_index - 1000)",
    "        return",
    "    var index := raw_index",
    "    if not adventure.chapter_manager.can_enter(index):",
    "        return",
    "    if selected_card_index == index:",
    "        selected_card_index = -1",
    "    else:",
    "        selected_card_index = index",
    "    _sync_cards()",
    "",
    "func _handle_close() -> void:",
    "    if selected_card_index == -1:",
    "        return",
    "    if not adventure.chapter_manager.is_close_allowed(selected_card_index):",
    "        return",
    "    adventure.chapter_manager.resolve_skip(selected_card_index)",
    "    selected_card_index = -1",
    "    _sync_ui()",
    "",
    "func _handle_action(index: int) -> void:",
    "    if not adventure.chapter_manager.can_enter(index):",
    "        return",
    "    var node_type := adventure.chapter_manager.resolve_enter(index)",
    "    _apply_node_reward(node_type)",
    "    selected_card_index = -1",
    "    _sync_ui()",
    "",
    "func _apply_node_reward(node_type: int) -> void:",
    "    if node_type == ChapterNodeManager.NodeType.BATTLE:",
    "        player.add_gold(5)",
    "        player.add_exp(10)",
    "    elif node_type == ChapterNodeManager.NodeType.ELITE:",
    "        player.add_gold(12)",
    "        player.add_exp(20)",
    "    elif node_type == ChapterNodeManager.NodeType.BOSS:",
    "        player.add_gold(30)",
    "        player.add_exp(40)",
    "    elif node_type == ChapterNodeManager.NodeType.REST:",
    "        player.heal(int(player.max_hp * 0.25))",
    "    elif node_type == ChapterNodeManager.NodeType.CHEST:",
    "        player.add_gold(8)",
    "        player.add_exp(6)",
    "    elif node_type == ChapterNodeManager.NodeType.SMITH:",
    "        player.add_exp(5)",
    "    _refresh_hud()",
    "",
    "func _on_card_pack_gui_input(event: InputEvent) -> void:",
    "    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:",
    '        _show_tooltip_at(card_pack_button, "??????????")',
    "    elif event is InputEventMouseButton and not event.pressed:",
    "        _hide_tooltip()",
    "",
    "func _on_mana_gui_input(event: InputEvent) -> void:",
    '    _handle_stat_tooltip(event, mana_button, "mana")',
    "",
    "func _on_ap_gui_input(event: InputEvent) -> void:",
    '    _handle_stat_tooltip(event, ap_button, "action_points")',
    "",
    "func _on_limit_gui_input(event: InputEvent) -> void:",
    '    _handle_stat_tooltip(event, limit_button, "card_limit")',
    "",
    "func _handle_stat_tooltip(event: InputEvent, node: Control, key: String) -> void:",
    "    if event is InputEventMouseButton:",
    "        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:",
    "            _show_tooltip_at(node, _tooltip_text(key))",
    "        elif not event.pressed:",
    "            _hide_tooltip()",
    "    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):",
    "        _show_tooltip_at(node, _tooltip_text(key))",
    "",
    "func _show_tooltip_at(node: Control, text: String) -> void:",
    "    if _active_tooltip and is_instance_valid(_active_tooltip):",
    "        _active_tooltip.queue_free()",
    "        _active_tooltip = null",
    "    var tip: Control = _tooltip_scene.instantiate()",
    "    tip.set_text(text)",
    "    tooltip_anchor.add_child(tip)",
    "    _active_tooltip = tip",
    "    var anchor_rect := tooltip_anchor.get_global_rect()",
    "    var node_rect := node.get_global_rect()",
    "    var tip_size := tip.get_rect().size",
    "    var x := clampf(node_rect.position.x + (node_rect.size.x - tip_size.x) * 0.5, anchor_rect.position.x, anchor_rect.end.x - tip_size.x)",
    "    var y := node_rect.position.y - tip_size.y - 8.0",
    "    if y < anchor_rect.position.y:",
    "        y = node_rect.end.y + 8.0",
    "    tip.set_global_position(Vector2(x, y))",
    "",
    "func _hide_tooltip() -> void:",
    "    if _active_tooltip and is_instance_valid(_active_tooltip):",
    "        _active_tooltip.queue_free()",
    "        _active_tooltip = null",
    "",
    "func _on_back_button_pressed() -> void:",
    '    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")',
]
write("scripts/adventure_scene.gd", "\n".join(scene_lines) + "\n")

# adventure_scene.tscn
write("scenes/adventure_scene.tscn", '''[gd_scene load_steps=4 format=3 uid="uid://b4a0u000003"]

[ext_resource type="Script" uid="uid://a1b2c3d4e5f60003" path="res://scripts/adventure_scene.gd" id="1"]
[ext_resource type="PackedScene" uid="uid://b4a0u000001" path="res://scenes/adventure_card.tscn" id="2"]
[ext_resource type="PackedScene" uid="uid://b4a0u000002" path="res://scenes/adventure_tooltip.tscn" id="3"]

[node name="AdventureScene" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="BgColor" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.06, 0.07, 0.1, 1)

[node name="TopBar" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 24.0
offset_top = 16.0
offset_right = -24.0
offset_bottom = 68.0
grow_horizontal = 2

[node name="ChapterLabel" type="Label" parent="TopBar"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
horizontal_alignment = 1

[node name="GoldLabel" type="Label" parent="TopBar"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 10
horizontal_alignment = 2

[node name="Center" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = 84.0
offset_right = -24.0
offset_bottom = -248.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_top = 8
theme_override_constants/margin_bottom = 8

[node name="CenterV" type="VBoxContainer" parent="Center"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 16

[node name="RemainingLabel" type="Label" parent="Center/CenterV"]
unique_name_in_owner = true
layout_mode = 2
horizontal_alignment = 1

[node name="CardSlots" type="HBoxContainer" parent="Center/CenterV"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
alignment = 1
theme_override_constants/separation = 24

[node name="BottomHud" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = -220.0
offset_right = -24.0
offset_bottom = -24.0
grow_horizontal = 2
grow_vertical = 0

[node name="LeftArea" type="VBoxContainer" parent="BottomHud"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name="CardPackButton" type="Button" parent="BottomHud/LeftArea"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 56)
layout_mode = 2

[node name="BackButton" type="Button" parent="BottomHud/LeftArea"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 44)
layout_mode = 2

[node name="CenterArea" type="VBoxContainer" parent="BottomHud"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 6

[node name="HpBar" type="ProgressBar" parent="BottomHud/CenterArea"]
unique_name_in_owner = true
custom_minimum_size = Vector2(220, 18)
layout_mode = 2
max_value = 100.0
value = 52.0
show_percentage = false

[node name="HpLabel" type="Label" parent="BottomHud/CenterArea"]
unique_name_in_owner = true
layout_mode = 2
horizontal_alignment = 1

[node name="ExpBar" type="ProgressBar" parent="BottomHud/CenterArea"]
unique_name_in_owner = true
custom_minimum_size = Vector2(220, 14)
layout_mode = 2
max_value = 20.0
value = 0.0
show_percentage = false

[node name="ExpLabel" type="Label" parent="BottomHud/CenterArea"]
unique_name_in_owner = true
layout_mode = 2
horizontal_alignment = 1

[node name="RightArea" type="HBoxContainer" parent="BottomHud"]
layout_mode = 2
size_flags_horizontal = 10
theme_override_constants/separation = 14

[node name="ManaButton" type="Button" parent="BottomHud/RightArea"]
unique_name_in_owner = true
custom_minimum_size = Vector2(58, 58)
layout_mode = 2

[node name="ApButton" type="Button" parent="BottomHud/RightArea"]
unique_name_in_owner = true
custom_minimum_size = Vector2(58, 58)
layout_mode = 2

[node name="LimitButton" type="Button" parent="BottomHud/RightArea"]
unique_name_in_owner = true
custom_minimum_size = Vector2(58, 58)
layout_mode = 2

[node name="TooltipAnchor" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
''')

print("written")
