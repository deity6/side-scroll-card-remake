# 卡牌复刻

> Godot 4.4.1 / GDScript / 竖版卡牌 Roguelike 原型 / v0.3.3

一个以竖版战斗、冒险节点和手牌操作为核心的卡牌 Roguelike 原型。
当前版本建立了完整的音效系统，并完成了主菜单重构和彩蛋代码分离。

## 当前版本 v0.3.3

- 新增 SoundManager 全局音效管理器（Autoload 单例），支持 SFX 播放（随机 pitch）、BGM 淡入淡出预留、播放器池管理。
- 下载并接入 28 个免费音效素材（来源 mixkit.co），覆盖 UI/冒险/战斗/奖励四类场景共 31 处调用点。
- 音效映射配置 Data/sfx_mapping.json，新增音效只需添加映射和素材文件，无需改代码。
- 主菜单背景从绿色占位恢复黑色，按钮和游戏名居中对齐。
- 彩蛋小游戏代码从 menu_controller.gd 分离到独立脚本 easter_egg_minigame.gd。
- 修复战斗场景未使用参数警告，清理 58 个临时文件。

## 核心功能

- 主菜单、设置、冒险和战斗基础流程。
- 冒险节点选择与存档流程。
- 战斗中的抽牌堆、手牌、弃牌堆循环。
- 行动力、血量、护甲、装备和回合流程。
- 手牌入场、悬浮、选中、拖拽出牌和回弹动画。
- 全局音效系统：按钮点击、卡牌操作、伤害/治疗/护甲、胜负结算、升级等音效。
- Debug 按钮复用正式逻辑，用于加牌、改血、洗牌、改行动力。

## 目录结构

`	ext
卡牌复刻/
├─ scenes/                         # Godot 场景文件
│  ├─ main_menu.tscn               # 主菜单场景
│  ├─ adventure_scene.tscn         # 冒险节点选择场景
│  ├─ battle_scene.tscn            # 战斗主场景
│  └─ battle_card.tscn             # 单张战斗卡牌 UI 场景
├─ scripts/                        # GDScript 逻辑脚本
│  ├─ sound_manager.gd             # SoundManager 全局音效管理器
│  ├─ menu_controller.gd           # 主菜单控制器
│  ├─ easter_egg_minigame.gd       # 彩蛋小游戏控制器
│  ├─ battle_scene.gd              # 战斗流程与 HUD 控制
│  ├─ battle_card.gd               # 卡牌显示与交互
│  ├─ battle_state.gd              # 战斗运行时状态
│  ├─ card_pool.gd                 # 卡牌池与数据查询
│  └─ adventure_*.gd               # 冒险流程与玩家状态
├─ Data/                           # 数据与配置
│  ├─ cards/                       # 卡牌 JSON 数据
│  └─ sfx_mapping.json             # 音效映射配置
├─ assets/                         # 美术与音频资源
│  ├─ audio/sfx/                   # 音效素材（28 个，按场景分类）
│  ├─ cards/battle_card_pet/       # 萌宠风格卡牌素材
│  └─ ui/battle_scene_pet_spring/  # 春日森林战斗 UI 素材
├─ docs/ai_prompts/                # 设计文档与规范
├─ default_bus_layout.tres         # AudioBus 配置（Master/SFX/BGM）
└─ project.godot                   # Godot 项目配置
`

## 运行方式

1. 使用 Godot 4.4.1 打开 project.godot。
2. 运行主场景 res://scenes/main_menu.tscn。
3. 从主菜单进入冒险或战斗流程，音效自动播放。

## 音效系统

- 调用：SoundManager.play_sfx("key") 或 SoundManager.play_sfx_varied("key")（随机 pitch）。
- 映射：Data/sfx_mapping.json，新增音效只需添加映射和素材文件。
- BGM：SoundManager.play_bgm("key") / stop_bgm() 已预留，素材待后续添加。
- AudioBus：Master -> SFX / BGM，配置在 default_bus_layout.tres。

## 资源规范

- 战斗 UI 素材：assets/ui/battle_scene_pet_spring/
- 卡牌素材：assets/cards/battle_card_pet/
- 音效素材：assets/audio/sfx/，按场景分类存放。
- .import 文件不提交。

## 版本历史

| 版本 | 说明 |
| --- | --- |
| v0.3.3 | 音效系统（SoundManager + 28 个素材）；主菜单重构；彩蛋代码分离。 |
| v0.3.2 | 春日森林 battle scene 与萌宠 battle card 视觉替换；重构卡牌分层与 z-index。 |
| v0.3 | 冒险节点、随机池、三路线节点选择、基础存档流程。 |
| v0.2 | 主菜单、设置与基础战斗原型。 |

## 后续计划

- 添加 BGM 背景音乐（主菜单 + 战斗场景各一首）。
- 接入真实怪物立绘或 Spine/GIF 动画方案。
- 完善敌人 buff/debuff、玩家装备和技能图标的运行时刷新。
- 补充战斗特效、受击反馈、出牌提示与更完整的动画节奏。
- 持续扩展卡牌池、装备池、事件与章节内容。
