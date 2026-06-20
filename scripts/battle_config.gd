class_name BattleConfig
extends RefCounted
## 战斗系统共享配置
## 修改此文件中的常量即可同步所有战斗相关脚本的参数

# ============================================================
# 卡牌尺寸（像素）
# 所有卡牌统一使用此尺寸，_lock_size() 会在运行时强制覆盖
# ============================================================
## 卡牌宽度（像素）
const CARD_WIDTH: float = 240.0
## 卡牌高度（像素）
const CARD_HEIGHT: float = 360.0

# ============================================================
# 手牌位置查找表（适配 720x1280 竖屏）
# 每个子数组对应 1~10 张手牌时，每张卡的 (x, y) 偏移
#   x: 水平偏移，0=屏幕正中，负=左，正=右
#   y: 垂直偏移，负=向上（屏幕内），正=向下（屏幕外）
# 所有偏移相对于 HandContainer 底部中心点
# ============================================================
const HAND_POSITIONS: Array = [
	[Vector2(0, -50)],
	[Vector2(-100, -50), Vector2(100, -50)],
	[Vector2(-180, -50), Vector2(0, -59), Vector2(180, -50)],
	[Vector2(-240, -25), Vector2(-80, -50), Vector2(80, -50), Vector2(240, -25)],
	[Vector2(-240, -20), Vector2(-170, -40), Vector2(0, -50), Vector2(170, -40), Vector2(240, -20)],
	[Vector2(-460, 13), Vector2(-273, -25), Vector2(-90, -50), Vector2(90, -50), Vector2(273, -25), Vector2(460, 13)],
	[Vector2(-534, 18), Vector2(-365, -14), Vector2(-189, -39), Vector2(0, -50), Vector2(189, -39), Vector2(365, -14), Vector2(534, 18)],
	[Vector2(-565, 28), Vector2(-400, -14), Vector2(-231, -39), Vector2(-80, -50), Vector2(80, -50), Vector2(231, -39), Vector2(400, -14), Vector2(565, 28)],
	[Vector2(-600, 37), Vector2(-445, -2), Vector2(-300, -29), Vector2(-150, -45), Vector2(0, -50), Vector2(150, -45), Vector2(300, -29), Vector2(445, -2), Vector2(600, 37)],
	[Vector2(-610, 38), Vector2(-472, 5), Vector2(-340, -21), Vector2(-200, -41), Vector2(-64, -50), Vector2(64, -50), Vector2(200, -41), Vector2(340, -21), Vector2(472, 5), Vector2(610, 38)],
]

# ============================================================
# 手牌角度查找表（度）
# 与 HAND_POSITIONS 一一对应，实现弧形展开效果
# 负值=逆时针（向左倾斜），正值=顺时针（向右倾斜）
# ============================================================
const HAND_ANGLES: Array = [
	[0.0],
	[-2.0, 2.0],
	[-3.0, 0.0, 3.0],
	[-8.0, -4.0, 4.0, 8.0],
	[-8.0, -4.0, 0.0, 4.0, 8.0],
	[-9.0, -6.0, -3.0, 3.0, 6.0, 9.0],
	[-9.0, -6.0, -3.0, 0.0, 3.0, 6.0, 9.0],
	[-12.0, -9.0, -6.0, -3.0, 3.0, 6.0, 9.0, 12.0],
	[-12.0, -9.0, -6.0, -3.0, 0.0, 3.0, 6.0, 9.0, 12.0],
	[-15.0, -12.0, -9.0, -6.0, -3.0, 3.0, 6.0, 9.0, 12.0, 15.0],
]



# ============================================================
# 拖拽参数
# ============================================================
## 拖拽跟随速度（0~1，越大跟随越快，1=无延迟弹感）
const DRAG_LERP_SPEED: float = 0.2
## 拖拽时的放大比例（视觉提示正在拖拽）
const DRAG_SCALE: float = 1.05

# ============================================================
# 动画参数（秒）
# ============================================================
## 手牌排列动画时长（卡牌移动到目标位置的过渡时间）
const HAND_POSITION_DURATION: float = 0.35
## 拖拽回弹动画时长（卡牌返回原位的弹性时间）
const DRAG_RETURN_DURATION: float = 0.3
## 出牌消失动画时长（打出卡牌缩小+淡出的时间）
const PLAY_DURATION: float = 0.25

# ============================================================
# 入场动画参数
# 控制战斗开始时手牌从屏幕外飞入的动画效果
# ============================================================
## 入场起点：屏幕外右侧中点（相对于 HandContainer 的偏移）
## x=400 表示在屏幕右侧外约 400px，y=-150 表示在 HandContainer 上方
const CARD_ENTRY_ORIGIN: Vector2 = Vector2(400.0, -150.0) ##第一发牌点
## 每张卡牌入场的间隔延迟（秒），逐张错开形成"发牌"节奏感
const CARD_ENTRY_STAGGER: float = 0.08
## 单张卡牌入场弧线动画时长（秒）
const CARD_ENTRY_DURATION: float = 0.45
## 入场弧线向上凸起的高度（像素），控制弧线弯曲程度
const CARD_ENTRY_ARC_HEIGHT: float = 120.0

# ============================================================
# 气泡提示框参数（手牌上限提示等非交互式提示）
# ============================================================
## 气泡提示框显示时长（秒）
const TOAST_DURATION: float = 2.0
## 气泡提示框淡入时长（秒）
const TOAST_FADE_IN: float = 0.2
## 气泡提示框淡出时长（秒）
const TOAST_FADE_OUT: float = 0.4
## 气泡提示框最终停留位置 Y（相对于屏幕顶部，像素）
const TOAST_TARGET_Y: float = 200.0

# ============================================================
# 卡牌视觉样式参数
# 修改此处即可同步所有卡牌的外观（battle_card.gd 引用）
# ============================================================
## 卡牌基础透明度（0~1，越高越不透明；重叠时调低避免文字穿透）
const CARD_BASE_ALPHA: float = 0.9
## 卡牌圆角半径（像素）
const CARD_CORNER_RADIUS: int = 8
## 卡牌边框宽度（像素）
const CARD_BORDER_WIDTH: int = 2
## 不可用卡牌（行动力不足）的灰暗程度（0~1，越低越暗）
const CARD_DISABLED_DIM: float = 0.2
## 不可用卡牌的阴影颜色（RGBA）
const CARD_DISABLED_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
## 悬浮时卡牌上移像素
const HOVER_LIFT: float = 40.0
## 悬浮时两侧卡牌推开距离（像素）
const HOVER_PUSH_AWAY: float = 100.0
## 悬浮时卡牌缩放
const HOVER_SCALE: float = 1.1

# ============================================================
# 工具方法
# ============================================================

## 获取指定手牌数时第 index 张卡的位置偏移
## hand_size: 当前手牌总数，index: 卡牌在手牌中的索引（从0开始）
static func get_hand_position(hand_size: int, index: int) -> Vector2:
	var idx: int = clampi(hand_size - 1, 0, HAND_POSITIONS.size() - 1)
	var positions: Array = HAND_POSITIONS[idx]
	var card_idx: int = clampi(index, 0, positions.size() - 1)
	return positions[card_idx]

## 获取指定手牌数时第 index 张卡的角度（度）
static func get_hand_angle(hand_size: int, index: int) -> float:
	var idx: int = clampi(hand_size - 1, 0, HAND_ANGLES.size() - 1)
	var angles: Array = HAND_ANGLES[idx]
	var card_idx: int = clampi(index, 0, angles.size() - 1)
	return angles[card_idx]
