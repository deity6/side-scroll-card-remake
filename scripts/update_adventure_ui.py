from pathlib import Path
base = Path(r"D:\\Got\\GodotSharp\\Program\\??????")
# helper to create file with UTF-8 and LF
def write_file(rel, content):
    p = base / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8", newline="\n")

card_tscn = '''[gd_scene load_steps=2 format=3 uid=\"uid://b4a0u000001\"]

[ext_resource type=\"Script\" uid=\"uid://a1b2c3d4e5f60001\" path=\"res://scripts/adventure_card.gd\" id=\"1\"]

[node name=\"AdventureCard\" type=\"PanelContainer\"]
custom_minimum_size = Vector2(190, 260)
tooltip_text = \"\"
mouse_filter = 0
script = ExtResource(\"1\")

[node name=\"Margin\" type=\"MarginContainer\" parent=\".\"]
layout_mode = 2
theme_override_constants/margin_left = 12
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 12
theme_override_constants/margin_bottom = 12

[node name=\"VBox\" type=\"VBoxContainer\" parent=\"Margin\"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

[node name=\"Header\" type=\"HBoxContainer\" parent=\"Margin/VBox\"]
layout_mode = 2

[node name=\"TitleLabel\" type=\"Label\" parent=\"Margin/VBox/Header\"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.0
horizontal_alignment = 1
autowrap_mode = 2

[node name=\"CloseButton\" type=\"Button\" parent=\"Margin/VBox/Header\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(26, 26)
layout_mode = 2
size_flags_horizontal = 10
text = \"\\u00d7\"

[node name=\"Icon\" type=\"ColorRect\" parent=\"Margin/VBox\"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
size_flags_stretch_ratio = 2.0
color = Color(0.15, 0.15, 0.18, 1)

[node name=\"DescLabel\" type=\"Label\" parent=\"Margin/VBox\"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
horizontal_alignment = 1
autowrap_mode = 2

[node name=\"ActionButton\" type=\"Button\" parent=\"Margin/VBox\"]
unique_name_in_owner = true
visible = false
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
size_flags_horizontal = 3
'''
tooltip_tscn = '''[gd_scene load_steps=2 format=3 uid=\"uid://b4a0u000002\"]

[ext_resource type=\"Script\" uid=\"uid://a1b2c3d4e5f60002\" path=\"res://scripts/adventure_tooltip.gd\" id=\"1\"]

[node name=\"AdventureTooltip\" type=\"PanelContainer\"]
visible = false
mouse_filter = 2
script = ExtResource(\"1\")

[node name=\"Margin\" type=\"MarginContainer\" parent=\".\"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 8

[node name=\"Label\" type=\"Label\" parent=\"Margin\"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
autowrap_mode = 2
'''
scene_tscn = '''[gd_scene load_steps=4 format=3 uid=\"uid://b4a0u000003\"]

[ext_resource type=\"Script\" uid=\"uid://a1b2c3d4e5f60003\" path=\"res://scripts/adventure_scene.gd\" id=\"1\"]
[ext_resource type=\"PackedScene\" uid=\"uid://b4a0u000001\" path=\"res://scenes/adventure_card.tscn\" id=\"2\"]
[ext_resource type=\"PackedScene\" uid=\"uid://b4a0u000002\" path=\"res://scenes/adventure_tooltip.tscn\" id=\"3\"]

[node name=\"AdventureScene\" type=\"Control\"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource(\"1\")

[node name=\"BgColor\" type=\"ColorRect\" parent=\".\"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.06, 0.07, 0.1, 1)

[node name=\"TopBar\" type=\"HBoxContainer\" parent=\".\"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 24.0
offset_top = 16.0
offset_right = -24.0
offset_bottom = 68.0
grow_horizontal = 2

[node name=\"ChapterLabel\" type=\"Label\" parent=\"TopBar\"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
horizontal_alignment = 1

[node name=\"GoldLabel\" type=\"Label\" parent=\"TopBar\"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 10
horizontal_alignment = 2

[node name=\"Center\" type=\"MarginContainer\" parent=\".\"]
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

[node name=\"CenterV\" type=\"VBoxContainer\" parent=\"Center\"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 16

[node name=\"RemainingLabel\" type=\"Label\" parent=\"Center/CenterV\"]
unique_name_in_owner = true
layout_mode = 2
horizontal_alignment = 1

[node name=\"CardSlots\" type=\"HBoxContainer\" parent=\"Center/CenterV\"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
alignment = 1
theme_override_constants/separation = 24

[node name=\"BottomHud\" type=\"HBoxContainer\" parent=\".\"]
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

[node name=\"LeftArea\" type=\"VBoxContainer\" parent=\"BottomHud\"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8

[node name=\"CardPackButton\" type=\"Button\" parent=\"BottomHud/LeftArea\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 56)
layout_mode = 2

[node name=\"BackButton\" type=\"Button\" parent=\"BottomHud/LeftArea\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 44)
layout_mode = 2

[node name=\"CenterArea\" type=\"VBoxContainer\" parent=\"BottomHud\"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 6

[node name=\"HpBar\" type=\"ProgressBar\" parent=\"BottomHud/CenterArea\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(220, 18)
layout_mode = 2
max_value = 100.0
value = 52.0
show_percentage = false

[node name=\"HpLabel\" type=\"Label\" parent=\"BottomHud/CenterArea\"]
unique_name_in_owner = true
layout_mode = 2
horizontal_alignment = 1

[node name=\"ExpBar\" type=\"ProgressBar\" parent=\"BottomHud/CenterArea\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(220, 14)
layout_mode = 2
max_value = 20.0
value = 0.0
show_percentage = false

[node name=\"ExpLabel\" type=\"Label\" parent=\"BottomHud/CenterArea\"]
unique_name_in_owner = true
layout_mode = 2
horizontal_alignment = 1

[node name=\"RightArea\" type=\"HBoxContainer\" parent=\"BottomHud\"]
layout_mode = 2
size_flags_horizontal = 10
theme_override_constants/separation = 14

[node name=\"ManaButton\" type=\"Button\" parent=\"BottomHud/RightArea\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(58, 58)
layout_mode = 2

[node name=\"ApButton\" type=\"Button\" parent=\"BottomHud/RightArea\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(58, 58)
layout_mode = 2

[node name=\"LimitButton\" type=\"Button\" parent=\"BottomHud/RightArea\"]
unique_name_in_owner = true
custom_minimum_size = Vector2(58, 58)
layout_mode = 2

[node name=\"TooltipAnchor\" type=\"Control\" parent=\".\"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
'''
# GDScript for adventure scene (ASCII-only, CJK via runtime strings)
gd = '''extends Control\n\nconst CARD_SCENE_PATH := \"res://scenes/adventure_card.tscn\"\nconst TOOLTIP_SCENE_PATH := \"res://scenes/adventure_tooltip.tscn\"\n\nconst CARD_COLORS := {\n    ChapterNodeManager.NodeType.BATTLE: Color(0.52, 0.20, 0.20, 1),\n    ChapterNodeManager.NodeType.ELITE: Color(0.70, 0.28, 0.10, 1),\n    ChapterNodeManager.NodeType.BOSS: Color(0.64, 0.08, 0.08, 1),\n    ChapterNodeManager.NodeType.REST: Color(0.18, 0.52, 0.28, 1),\n    ChapterNodeManager.NodeType.SMITH: Color(0.32, 0.34, 0.38, 1),\n    ChapterNodeManager.NodeType.SHOP: Color(0.58, 0.50, 0.12, 1),\n    ChapterNodeManager.NodeType.CHEST: Color(0.56, 0.42, 0.12, 1),\n    ChapterNodeManager.NodeType.NEXT_CHAPTER: Color(0.22, 0.36, 0.62, 1),\n}\n\nfunc _node_action_text(node_type: int) -> String:\n    var t := node_type\n    if t == ChapterNodeManager.NodeType.BATTLE:\n        return \"??\"\n    if t == ChapterNodeManager.NodeType.ELITE:\n        return \"????\"\n    if t == ChapterNodeManager.NodeType.BOSS:\n        return \"BOSS??\"\n    if t == ChapterNodeManager.NodeType.REST:\n        return \"????\"\n    if t == ChapterNodeManager.NodeType.SMITH:\n        return \"????\"\n    if t == ChapterNodeManager.NodeType.SHOP:\n        return \"????\"\n    if t == ChapterNodeManager.NodeType.CHEST:\n        return \"????\"\n    if t == ChapterNodeManager.NodeType.NEXT_CHAPTER:\n        return \"?????\"\n    return \"????\"\n\nfunc _tooltip_text(key: String) -> String:\n    if key == \"hp\":\n        return \"HP??????????0????????\"\n    if key == \"gold\":\n        return \"???????????????\"\n    if key == \"mana\":\n        return \"??????????????????????\"\n    if key == \"action_points\":\n        return \"?????????????????\"\n    if key == \"card_limit\":\n        return \"?????????????????\"\n    return \"\"\n\nvar player: AdventurePlayerState = AdventurePlayerState.new()\nvar selected_card_index: int = -1\nvar _tooltip_scene: PackedScene = preload(TOOLTIP_SCENE_PATH)\nvar _active_tooltip: Node = null\n\n@onready var chapter_label: Label = %ChapterLabel\n@onready var gold_label: Label = %GoldLabel\n@onready var remaining_label: Label = %RemainingLabel\n@onready var card_slots_container: HBoxContainer = %CardSlots\n@onready var card_pack_button: Button = %CardPackButton\n@onready var hp_bar: ProgressBar = %HpBar\n@onready var hp_label: Label = %HpLabel\n@onready var exp_bar: ProgressBar = %ExpBar\n@onready var exp_label: Label = %ExpLabel\n@onready var mana_button: Button = %ManaButton\n@onready var ap_button: Button = %ApButton\n@onready var limit_button: Button = %LimitButton\n@onready var tooltip_anchor: Control = %TooltipAnchor\n@onready var back_button: Button = %BackButton\n\nfunc _ready() -> void:\n    back_button.pressed.connect(_on_back_button_pressed)\n    card_pack_button.gui_input.connect(_on_card_pack_gui_input)\n    mana_button.gui_input.connect(_on_mana_gui_input)\n    ap_button.gui_input.connect(_on_ap_gui_input)\n    limit_button.gui_input.connect(_on_limit_gui_input)\n    player.initialize()\n    _refresh_hud()\n    adventure.start_run(2)\n    _sync_ui()\n\nfunc _refresh_hud() -> void:\n    gold_label.text = \"?? %d\" % player.gold\n    hp_bar.max_value = player.max_hp\n    hp_bar.value = player.hp\n    hp_label.text = \"%d/%d\" % [player.hp, player.max_hp]\n    exp_bar.max_value = player.exp_to_next\n    exp_bar.value = player.exp\n    exp_label.text = \"%d/%d\" % [player.exp, player.exp_to_next]\n    mana_button.text = \"%d\" % player.mana\n    ap_button.text = \"%d\" % player.action_points\n    limit_button.text = \"%d\" % player.card_limit\n\nfunc _sync_ui() -> void:\n    chapter_label.text = adventure.chapter_label()\n    remaining_label.text = adventure.remaining_label()\n    _sync_cards()\n    if selected_card_index == -1:\n        _hide_tooltip()\n\nfunc _sync_cards() -> void:\n    for child in card_slots_container.get_children():\n        child.queue_free()\n    var hand := adventure.chapter_manager.get_hand()\n    for i in range(hand.size()):\n        var node_type := adventure.chapter_manager.node_type(i)\n        var card: Control = preload(CARD_SCENE_PATH).instantiate()\n        card.set_index(i)\n        card.set_title(adventure.chapter_manager.node_title(i))\n        card.set_desc(adventure.chapter_manager.node_description(i))\n        card.set_icon_color(CARD_COLORS.get(node_type, Color(0.2, 0.2, 0.2, 1)))\n        card.set_selected(selected_card_index == i)\n        card.set_close_visible(true)\n        card.set_close_enabled(adventure.chapter_manager.is_close_allowed(i))\n        card.set_action_text(_node_action_text(node_type))\n        card.card_selected.connect(_on_card_selected)\n        card_slots_container.add_child(card)\n\nfunc _on_card_selected(raw_index: int) -> void:\n    if raw_index == -1:\n        _handle_close()\n        return\n    if raw_index >= 1000:\n        _handle_action(raw_index - 1000)\n        return\n    var index := raw_index\n    if not adventure.chapter_manager.can_enter(index):\n        return\n    if selected_card_index == index:\n        selected_card_index = -1\n    else:\n        selected_card_index = index\n    _sync_cards()\n\nfunc _handle_close() -> void:\n    if selected_card_index == -1:\n        return\n    if not adventure.chapter_manager.is_close_allowed(selected_card_index):\n        return\n    adventure.chapter_manager.resolve_skip(selected_card_index)\n    selected_card_index = -1\n    _sync_ui()\n\nfunc _handle_action(index: int) -> void:\n    if not adventure.chapter_manager.can_enter(index):\n        return\n    var node_type := adventure.chapter_manager.resolve_enter(index)\n    _apply_node_reward(node_type)\n    selected_card_index = -1\n    _sync_ui()\n\nfunc _apply_node_reward(node_type: int) -> void:\n    if node_type == ChapterNodeManager.NodeType.BATTLE:\n        player.add_gold(5)\n        player.add_exp(10)\n    elif node_type == ChapterNodeManager.NodeType.ELITE:\n        player.add_gold(12)\n        player.add_exp(20)\n    elif node_type == ChapterNodeManager.NodeType.BOSS:\n        player.add_gold(30)\n        player.add_exp(40)\n    elif node_type == ChapterNodeManager.NodeType.REST:\n        player.heal(int(player.max_hp * 0.25))\n    elif node_type == ChapterNodeManager.NodeType.CHEST:\n        player.add_gold(8)\n        player.add_exp(6)\n    elif node_type == ChapterNodeManager.NodeType.SMITH:\n        player.add_exp(5)\n    _refresh_hud()\n\nfunc _on_card_pack_gui_input(event: InputEvent) -> void:\n    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:\n        _show_tooltip_at(card_pack_button, \"??????????\")\n    elif event is InputEventMouseButton and not event.pressed:\n        _hide_tooltip()\n\nfunc _on_mana_gui_input(event: InputEvent) -> void:\n    _handle_stat_tooltip(event, mana_button, \"mana\")\n\nfunc _on_ap_gui_input(event: InputEvent) -> void:\n    _handle_stat_tooltip(event, ap_button, \"action_points\")\n\nfunc _on_limit_gui_input(event: InputEvent) -> void:\n    _handle_stat_tooltip(event, limit_button, \"card_limit\")\n\nfunc _handle_stat_tooltip(event: InputEvent, node: Control, key: String) -> void:\n    if event is InputEventMouseButton:\n        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:\n            _show_tooltip_at(node, _tooltip_text(key))\n        elif not event.pressed:\n            _hide_tooltip()\n    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):\n        _show_tooltip_at(node, _tooltip_text(key))\n\nfunc _show_tooltip_at(node: Control, text: String) -> void:\n    if _active_tooltip and is_instance_valid(_active_tooltip):\n        _active_tooltip.queue_free()\n        _active_tooltip = null\n    var tip: Control = _tooltip_scene.instantiate()\n    tip.set_text(text)\n    tooltip_anchor.add_child(tip)\n    _active_tooltip = tip\n    var anchor_rect := tooltip_anchor.get_global_rect()\n    var node_rect := node.get_global_rect()\n    var tip_size := tip.get_rect().size\n    var x := clampf(node_rect.position.x + (node_rect.size.x - tip_size.x) * 0.5, anchor_rect.position.x, anchor_rect.end.x - tip_size.x)\n    var y := node_rect.position.y - tip_size.y - 8.0\n    if y < anchor_rect.position.y:\n        y = node_rect.end.y + 8.0\n    tip.set_global_position(Vector2(x, y))\n\nfunc _hide_tooltip() -> void:\n    if _active_tooltip and is_instance_valid(_active_tooltip):\n        _active_tooltip.queue_free()\n        _active_tooltip = null\n\nfunc _on_back_button_pressed() -> void:\n    get_tree().change_scene_to_file(\"res://scenes/main_menu.tscn\")\n'''
write_file("scenes/adventure_card.tscn", card_tscn)
write_file("scenes/adventure_tooltip.tscn", tooltip_tscn)
write_file("scenes/adventure_scene.tscn", scene_tscn)
write_file("scripts/adventure_scene.gd", gd)
print("written")
