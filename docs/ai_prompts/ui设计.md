# UI 设计风格指南

## 冒险界面设计风格

- **背景色**：深色储格风格，主色调 `#0f1119`。
- **卡片风格**：圆角 `PanelContainer`，深色卡片背景，不同节点类型用不同色块图标区分。
- **节点色彩编号**：
  - 战斗=深红 `#853320`
  - 精英=深橙 `#b3470a`
  - BOSS=深红 `#a31414`
  - 休息=深绿 `#2e854a`
  - 铁匠=灰色 `#525761`
  - 商店=金黄 `#937e1f`
  - 宝箱=赭金 `#8e6b1e`
  - 下一站=深蓝 `#385c9e`
- **底部 HUD**：条栏型布局，左下卡包，中间 HP/EXP 条，右下魔力/行动力上限图标按钮。
- **字体颜色**：白色文字，浅灰色描述文字。
- **动画**：按下缩放 0.95，松手回弹 1.0，`TRANS_ELASTIC` 果冻回弹。
- **关闭按钮**：只在选中卡片时显示，淡入淡出动画。
- **锁定特效**：功能节点被关闭时缩放+淡出消失。

## 冒险界面 - 卡片节点设计

### 概述
冒险界面中央区域（%Center，HBoxContainer）显示 3 张节点卡片，分别对应 3 条独立线路的当前头部节点。卡片在 .tscn 中预置（CardSlot1/2/3），运行时由 dventure_scene.gd 填充数据，不动态创建/销毁节点。

### 场景结构（adventure_scene.tscn）
`
Center (HBoxContainer, unique_name_in_owner, separation=16, alignment=CENTER)
  ├─ CardSlot1 (PanelContainer, script=adventure_card.gd, mouse_filter=0)
  │    ├─ CloseButton (Button, layout_mode=2, size_flags_horizontal=END, 右上角定位)
  │    ├─ MarginContainer (mouse_filter=2 穿透)
  │    │    └─ VBoxContainer (mouse_filter=2 穿透)
  │    │         ├─ TitleLabel (Label, mouse_filter=2, autowrap, custom_minimum_size=160x20)
  │    │         ├─ IconRect (ColorRect, mouse_filter=2, height=60)
  │    │         ├─ DescLabel (Label, mouse_filter=2, autowrap, custom_minimum_size=160x40)
  │    │         └─ ActionButton (Button, mouse_filter=2, 默认隐藏)
  ├─ CardSlot2 (同结构)
  └─ CardSlot3 (同结构)
`

### 卡片尺寸与布局
- CardSlot：custom_minimum_size = Vector2(180, 260)，可编辑器调整
- Center（HBoxContainer）：宽 640，高 340，水平居中，间距 16
- 卡片间距通过 Center 的 separation 控制
- 卡片尺寸通过各 CardSlot 的 custom_minimum_size 控制

### 选中状态（单选）
- 同一时间只能有 1 张卡片被选中，点击已选中的卡片取消选中
- 场景层（adventure_scene.gd）管理选中逻辑：点击时先取消其他卡片，再选中当前
- 卡片脚本（adventure_card.gd）只负责视觉切换，不管理全局选中状态

### 选中视觉效果
- **未选中**：StyleBoxFlat，背景色 Color(0, 0, 0, 0.3)，圆角 8，内边距 4
- **选中**：在未选中基础上增加：
  - 金色边框：宽度 3，颜色 Color(1.0, 0.9, 0.4, 1.0)
  - 金色辉光：shadow_color = Color(1.0, 0.85, 0.2, 0.6)，shadow_size = 10
- 选中时显示 ActionButton 和 CloseButton

### 关闭按钮（CloseButton）
- 位置：卡片右上角，代码动态定位 position = Vector2(card_size.x - 28, 4)
- 大小：custom_minimum_size = Vector2(24, 24)
- 文字："X"
- 默认隐藏，选中时显示
- 点击触发 card_close_requested(slot_index) 信号
- **mouse_filter**：PanelContainer=0（STOP），MarginContainer/VBox/内容子节点=2（PASS穿透），确保 Button 优先接收点击

### 关闭销毁动画（adventure_scene.gd）
- 缩放：scale 从 Vector2.ONE → Vector2(0.5, 0.5)，0.2 秒，EASE_IN + TRANS_BACK
- 淡出：modulate:a 从 1.0 → 0.0，0.2 秒，与缩放并行
- 动画结束后调用 esolve_skip(line_idx) 跳过节点（无奖励），然后 _sync_cards() 刷新

### 动作按钮（ActionButton）
- 默认隐藏，选中时显示于卡片底部
- 文字由场景根据节点类型设置：战斗/精英战斗/BOSS战斗/休息恢复/升级卡牌/进入商店/打开宝箱/前往下一章
- 点击触发 card_action_requested(slot_index) 信号
- 场景处理：调用 esolve_enter() 进入节点事件 → 应用奖励 → 刷新 UI

### 信号设计（adventure_card.gd）
| 信号 | 参数 | 触发时机 |
|------|------|----------|
| card_selected | slot_index: int | 点击卡片面板任意位置 |
| card_close_requested | slot_index: int | 点击关闭按钮 |
| card_action_requested | slot_index: int | 点击动作按钮 |

### 数据填充（adventure_scene.gd _sync_cards）
- _slot_card_data: Array 记录 3 个槽位当前显示的线路索引（-1=空）
- get_hand() 返回节点类型枚举值，通过 _find_line_for_type() 转换为线路索引
- 每次关闭或进入节点后调用 _sync_cards() 刷新全部卡片

### 节点类型与颜色映射（CARD_COLORS）
| NodeType | 标题 | 色块颜色 |
|----------|------|----------|
| BATTLE | 怪物战斗 | 深红 (0.52, 0.20, 0.20) |
| ELITE | 精英战斗 | 橙红 (0.70, 0.28, 0.10) |
| BOSS | BOSS战斗 | 深红 (0.64, 0.08, 0.08) |
| REST | 休息节点 | 深绿 (0.18, 0.52, 0.28) |
| SMITH | 铁匠节点 | 灰色 (0.32, 0.34, 0.38) |
| SHOP | 商店节点 | 金黄 (0.58, 0.50, 0.12) |
| CHEST | 宝箱节点 | 赭金 (0.56, 0.42, 0.12) |
| NEXT_CHAPTER | 前往下一章 | 深蓝 (0.22, 0.36, 0.62) |

### 交互约束
- BOSS 和 NEXT_CHAPTER 不可关闭跳过（is_close_allowed 返回 false）
- 同一线路节点按顺序消耗，消耗后从共享池抽取下一个节点填补
- 关闭节点消耗但无奖励，进入节点消耗并触发对应奖励逻辑