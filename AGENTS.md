# AGENTS.md
Read this md using UTF-8 (without BOM)
> Please use Chinese to communicate in the conversation context.
> 本文件作为仓库入口，放 **入口规则、开发流程、强制约束速查**。
> 具体设计、数值、UI 规范不写在这里，统一指向文档索引。(细则在## 3. 文档与提示词索引）


## 1. Project Overview（项目基础信息）
- 项目类型：Godot 4.4.x / GDScript（当前开发环境 Godot 4.4.1）
- 项目目标：先建立一个**可运行、可验证、可逐步增强**的竖版卡牌 Roguelike 原型。
- 当前状态：主菜单、设置、战斗、冒险基础流程已存在；仓库内暂无 ssets/、暂无 	ests/；Data/ 目录存在，当前主要为空。
- 主场景：es://scenes/main_menu.tscn
- Autoload：
  - SettingsManager：es://scenes/settings_manager.tscn
  - MCPGameBridge：es://addons/godot_mcp/game_bridge/mcp_game_bridge.gd（当前为兼容占位，非运行必需）
  - SoundManager：es://scripts/sound_manager.gd（全局音效管理器，SFX 播放 + BGM 预留）

## 2. Setup & Development（环境搭建与开发流程）
### 2.1 依赖安装
- 当前无包管理器依赖，不需要额外安装步骤。
- 核心依赖是本地安装的 **Godot 4.4.1**。
- ddons/godot_mcp 为辅助开发插件，不是运行必要前提；该插件声明 godot_version_min="4.5"，与当前 4.4.1 不完全兼容。

### 2.2 开发运行
### 2.3 开发环境说明
- Godot 编辑器运行时可同时修改文件（Godot 会弹出"重新加载"提示，点击确认即可同步）。
- 但 **修改文件前必须做 git 备份**（见第4节约束）。

### 2.3 提交前检查
- .gd/.tscn 统一使用 UTF-8（无 BOM）。
- 统一使用 LF 换行：* text=auto eol=lf。
- 单个.gd不能混用空格和tab缩进，代码统一Tab缩进。
- .gd等代码部分写明新属性或者新方法的中文注释
- 修改 @onready、节点名、初始值时，必须同步检查 .tscn 是否一致。
- 场景 connection 与脚本 .connect() 不要重复连接同一信号。

## 3. 文档与提示词索引
- 索引入口：docs/ai_prompts/AI_PROMPTS_INDEX.md
- 工程约束速查：docs/ai_prompts/注意事项.md
- 项目总纲与阶段：docs/ai_prompts/00_总控提示词.md
- 规则：
  - 想了解"做成什么样"，先读索引文档。
  - 想了解"怎么做 / 不能做什么"，先读本文件与注意事项。
  - 新增或改名 docs/ai_prompts/ 下的文档时，及时更新索引

## 4. 强制约束速查（提炼自仓库规范，不展开细节）
- **重要改动前必须备份**：删除或大规模修改关键文件前，先 git stash 或 git commit 做本地备份，防止误操作无法回退。
- Godot 4.4 / 4.4.1 兼容，禁止使用 4.5+ 新增 API。
- GDScript 统一 4 空格缩进；.gd/.tscn 统一 LF；统一 UTF-8 无 BOM。
- 含中文内容时，避免 PowerShell Set-Content 管道写入，优先用 Python / apply_patch。
- Autoload 用 get_node 获取实例，不把实例脚本当作静态类 preload 调用。
- 同一信号不要在场景文件和脚本文件中重复连接。
- @onready 对象在 _ready() 前可能为空，setter 需做空值保护。
- 数值优先放在 Data/*.json，不在脚本中硬编码。
- 禁止一次性重写整个项目，或无差别批量重构。
- 禁止把密码、密钥、API Key、.env 写进代码或提交到仓库。
- 音效文件统一使用 MP3 格式（ssets/audio/sfx/），映射配置在 Data/sfx_mapping.json。

## 5.脚本代码规范（方便定义同步）
- 每个数据只在一个脚本中定义默认值，其他脚本只引用和透传。
- 修改数据前先确认：这个属性的权威来源是哪个文件？我改的是不是那个文件？
- 当前划分：玩家属性→adventure_player_state / 战斗传递→global_battle_request（只透传）/ 战斗运行→battle_state（只接收）/ 卡牌→card_pool+JSON
- 禁止在多个脚本中对同一属性各自定义默认值，因为这完全可以通过修改原脚本参数实现，若实在因无默认值导致问题复现需要在代码中注释写明，然后进行默认值假定义。

## 6. 测试与验证（当前现状）
- 当前没有自动化测试目录，也没有自动化测试用例。
- 每次改动以最小可用流程验证：主菜单进入、战斗可跑、设置可改、无明显运行时报错。
- 后续如果引入自动化测试，再补充 	ests/ 与执行命令说明。

## 7. 维护约定
- AGENTS.md 只放入口规则和工程约定，不放完整设计、数值、UI 规范。
- 如果后续需要"完整规范正文"，建议新建 docs/AGENTS_EXPANDED.md，本文件继续承担入口索引角色。
- 当仓库同时存在 gent.md、design.md 与正式索引文档时，建议后续单独做一次去重收敛，避免同一问题出现多个权威来源。
