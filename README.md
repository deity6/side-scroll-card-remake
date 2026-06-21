# 卡牌复刻

> Godot 4.4.1 / GDScript / 竖版卡牌 Roguelike 原型 / v0.3.2

一个以竖版战斗、冒险节点和手牌操作为核心的卡牌 Roguelike 原型。当前版本重点完成了“手绘简约萌宠 + 森林冒险 + 春机盎然”方向的战斗场景与 battle card 素材替换。

## 当前版本 v0.3.2

- 接入春日森林版战斗场景素材：背景、敌人占位、状态框、玩家底部栏、牌库图标、结束回合按钮、退出战斗按钮。
- 接入萌宠风格 battle card 分层素材：卡牌底板、边框、名称框、描述区、类型标签、费用图标、选中/禁用层。
- 重构 `battle_card.tscn` 为固定 `240x360` 的分层卡牌节点。
- 重构 `battle_card.gd`，支持按 `attack/action/equip` 切换卡牌底板与边框。
- 修复手牌堆叠遮挡：卡牌内部不再用高 z-index，整张卡作为独立渲染单元参与堆叠。
- 重规划战斗场景 z-index，总层数控制在 `0..14`。
- 保留并强化抽牌飞入动画：飞入时位于前景层，结束后回到正常手牌堆叠层。

## 核心功能

- 主菜单、设置、冒险和战斗基础流程。
- 冒险节点选择与存档流程。
- 战斗中的抽牌堆、手牌、弃牌堆循环。
- 行动力、血量、护甲、装备和回合流程。
- 手牌入场、悬浮、选中、拖拽出牌和回弹动画。
- Debug 按钮复用正式逻辑，用于加牌、改血、洗牌、改行动力。

## 目录结构

```text
卡牌复刻/
├─ scenes/
│  ├─ main_menu.tscn
│  ├─ adventure_scene.tscn
│  ├─ battle_scene.tscn
│  └─ battle_card.tscn
├─ scripts/
│  ├─ battle_scene.gd
│  ├─ battle_card.gd
│  ├─ battle_config.gd
│  ├─ battle_state.gd
│  ├─ card_pool.gd
│  └─ adventure_*.gd
├─ Data/cards/
│  ├─ attack.json
│  ├─ action.json
│  └─ equip.json
├─ assets/
│  ├─ cards/battle_card_pet/
│  ├─ ui/battle_scene_pet_spring/
│  └─ card_template/
├─ docs/ai_prompts/
└─ project.godot
```

## 运行方式

1. 使用 Godot 4.4.1 打开 `project.godot`。
2. 运行主场景 `res://scenes/main_menu.tscn`。
3. 从主菜单进入冒险或战斗流程。

## 资源规范

- 正式战斗 UI 素材位于 `assets/ui/battle_scene_pet_spring/`。
- 正式卡牌素材位于 `assets/cards/battle_card_pet/`。
- AI 制作过程文件可放在 `assets/ai制作/`，正式场景引用优先使用 `assets/cards/` 和 `assets/ui/` 下的稳定命名资源。
- Godot 自动生成的 `.import` 不提交。

## 版本历史

| 版本 | 说明 |
| --- | --- |
| v0.3.2 | 春日森林 battle scene 与萌宠 battle card 视觉替换；重构卡牌分层、手牌堆叠和 z-index 规划。 |
| v0.3 | 冒险节点、随机池、三路线节点选择、基础存档流程。 |
| v0.2 | 主菜单、设置与基础战斗原型。 |

## 后续计划

- 接入真实怪物立绘或 Spine/GIF 动画方案。
- 完善敌人 buff/debuff、玩家装备和技能图标的运行时刷新。
- 补充战斗特效、受击反馈、出牌提示与更完整的动画节奏。
- 持续扩展卡牌池、装备池、事件与章节内容。
