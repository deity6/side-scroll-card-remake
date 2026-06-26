# 卡牌复刻

> Godot 4.4.1 / GDScript / 竖版卡牌 Roguelike 原型 / v0.3.4

一个以竖版战斗、冒险节点和手牌操作为核心的卡牌 Roguelike 原型。当前版本重点完成了音效系统的构建，包含 28 个免费音效素材和完整的 SoundManager 管理器。

## 当前版本 v0.3.4

- 新增 **SoundManager** 全局音效管理器（Autoload 单例），支持 SFX 播放（随机 pitch）、BGM 淡入淡出预留、播放器池管理。
- 下载并接入 **28 个免费音效素材**（来源 mixkit.co），覆盖 UI/冒险/战斗/奖励四类场景共 31 处调用点。
- 音效映射配置文件 Data/sfx_mapping.json，新增音效只需添加映射和素材文件，无需改代码。
- 主菜单重构：背景从绿色占位恢复黑色，按钮和游戏名居中对齐。
- 彩蛋小游戏代码从 menu_controller.gd 分离到独立脚本 easter_egg_minigame.gd，通过 setup() 注入节点引用。
- 修复 attle_scene.gd 中 _on_card_played 未使用参数警告。
- 清理 58 个临时文件和调试脚本，更新 .gitignore。
- 移除 BGM 素材引用（暂未添加），SoundManager BGM 接口保留但不加载。

## 核心功能

- 主菜单、设置、冒险和战斗基础流程。
- 冒险节点选择与存档流程。
- 战斗中的抽牌堆、手牌、弃牌堆循环。
- 行动力、血量、护甲、装备和回合流程。
- 手牌入场、悬浮、选中、拖拽出牌和回弹动画。
- **全局音效系统**：SFX 播放、随机 pitch、播放器池管理、BGM 预留。

## 目录结构

`	ext
卡牌复刻/
├─ scenes/                         # Godot 场景文件
│  ├─ main_menu.tscn               # 主菜单场景（黑色背景 + 居中布局）
│  ├─ adventure_scene.tscn         # 冒险节点选择场景
│  ├─ battle_scene.tscn            # 战斗主场景
│  └─ battle_card.tscn             # 单张战斗卡牌 UI 场景
├─ scripts/                        # GDScript 逻辑脚本
│  ├─ sound_manager.gd             # SoundManager Autoload 单例
│  ├─ easter_egg_minigame.gd       # 彩蛋小游戏控制器
│  ├─ menu_controller.gd           # 主菜单控制器（含音效接入）
│  ├─ adventure_scene.gd           # 冒险场景（含音效接入）
│  ├─ battle_scene.gd              # 战斗场景（含音效接入）
│  ├─ battle_card.gd               # 单张卡牌显示与交互逻辑
│  ├─ battle_config.gd             # 战斗布局、手牌位置与显示配置
│  ├─ battle_state.gd              # 战斗运行时状态数据
│  ├─ card_pool.gd                 # 卡牌池加载与卡牌数据查询
│  └─ adventure_*.gd               # 冒险流程、节点与玩家状态脚本
├─ Data/cards/                     # 卡牌 JSON 数据
│  ├─ attack.json                  # 攻击牌定义
│  ├─ action.json                  # 行动牌定义
│  └─ equip.json                   # 装备牌定义
├─ Data/sfx_mapping.json           # 音效键→文件路径映射配置
├─ assets/                         # 美术与 UI 资源
│  ├─ audio/sfx/                   # 音效素材（MP3 格式）
│  │  ├─ ui/                       # UI 音效（6 个）
│  │  ├─ adventure/                # 冒险音效（8 个）
│  │  ├─ battle/                   # 战斗音效（11 个）
│  │  └─ reward/                   # 奖励音效（3 个）
│  ├─ cards/battle_card_pet/       # 萌宠风格战斗卡牌分层素材
│  ├─ ui/battle_scene_pet_spring/  # 春日森林战斗场景 UI 素材
│  └─ card_template/               # 早期卡牌模板与缩放参考素材
├─ docs/ai_prompts/                # 项目设计、提示词与规范文档
└─ project.godot                   # Godot 项目配置入口
`

## 运行方式

1. 使用 Godot 4.4.1 打开 project.godot。
2. 运行主场景 es://scenes/main_menu.tscn。
3. 从主菜单进入冒险或战斗流程。

## 音效系统

### 架构

- **SoundManager**：全局 Autoload 单例，管理所有 SFX 和 BGM 的加载、播放、音量控制。
- **音效映射**：Data/sfx_mapping.json 定义音效键到文件路径的映射，新增音效只需添加映射和素材文件。
- **播放器池**：每个音效键最多同时播放 4 个实例，超出时淘汰最旧的，避免爆音。
- **随机 pitch**：play_sfx_varied() 随机调整 ±5% 音高，避免重复播放的机械感。

### 使用方式

`gdscript
# 播放一次性音效
SoundManager.play_sfx("battle_damage_deal")

# 播放带随机 pitch 变化的音效
SoundManager.play_sfx_varied("ui_click_default")

# BGM 淡入播放（素材待后续添加）
SoundManager.play_bgm("bgm_battle", 0.8)

# BGM 淡出停止
SoundManager.stop_bgm(0.8)
`

### 音效清单

| 类别 | 数量 | 说明 |
|------|------|------|
| UI 类 | 6 | 按钮点击、悬停、弹窗等 |
| 冒险类 | 8 | 节点选择、关闭、进入等 |
| 战斗类 | 11 | 卡牌操作、伤害/治疗/护甲、胜负等 |
| 奖励类 | 3 | 升级、金币、卡牌获得等 |

## 资源规范

- 正式战斗 UI 素材位于 ssets/ui/battle_scene_pet_spring/。
- 正式卡牌素材位于 ssets/cards/battle_card_pet/。
- 音效文件统一使用 MP3 格式（ssets/audio/sfx/），映射配置在 Data/sfx_mapping.json。
- AI 制作过程文件可放在 ssets/ai制作/，正式场景引用优先使用 ssets/cards/ 和 ssets/ui/ 下的稳定命名资源。
- Godot 自动生成的 .import 不提交。

## 版本历史

完整更新记录见 CHANGELOG.md。

| 版本 | 说明 |
| --- | --- |
| v0.3.4 | 音效系统构建：SoundManager 管理器、28 个音效素材、sfx_mapping.json 映射配置、31 处调用点集成。 |
| v0.3.2 | 春日森林 battle scene 与萌宠 battle card 视觉替换；重构卡牌分层、手牌堆叠和 z-index 规划。 |
| v0.3 | 冒险节点、随机池、三路线节点选择、基础存档流程。 |
| v0.2 | 主菜单、设置与基础战斗原型。 |

## 后续计划

- 接入真实怪物立绘或 Spine/GIF 动画方案。
- 完善敌人 buff/debuff、玩家装备和技能图标的运行时刷新。
- 补充战斗特效、受击反馈、出牌提示与更完整的动画节奏。
- **添加 BGM 素材**（v0.3.5+ 版本）。
- 持续扩展卡牌池、装备池、事件与章节内容。
