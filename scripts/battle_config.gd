class_name BattleConfig
extends RefCounted
## 战斗系统共享配置。

## 卡牌宽度（像素）。
const CARD_WIDTH: float = 240.0
## 卡牌高度（像素）。
const CARD_HEIGHT: float = 360.0

## 手牌位置查找表，按 1 到 10 张手牌排列。
const HAND_POSITIONS: Array = [
	[Vector2(0, -120)],
	[Vector2(-105, -100), Vector2(105, -100)],
	[Vector2(-215, -58), Vector2(0, -85), Vector2(215, -58)],
	[Vector2(-252, -52), Vector2(-84, -66), Vector2(84, -66), Vector2(252, -52)],
	[Vector2(-268, -46), Vector2(-134, -62), Vector2(0, -70), Vector2(134, -62), Vector2(268, -46)],
	[Vector2(-286, -38), Vector2(-172, -52), Vector2(-58, -60), Vector2(58, -60), Vector2(172, -52), Vector2(286, -38)],
	[Vector2(-300, -34), Vector2(-200, -46), Vector2(-100, -55), Vector2(0, -60), Vector2(100, -55), Vector2(200, -46), Vector2(300, -34)],
	[Vector2(-308, -32), Vector2(-220, -42), Vector2(-132, -51), Vector2(-44, -58), Vector2(44, -58), Vector2(132, -51), Vector2(220, -42), Vector2(308, -32)],
	[Vector2(-314, -30), Vector2(-236, -40), Vector2(-158, -49), Vector2(-80, -56), Vector2(0, -60), Vector2(80, -56), Vector2(158, -49), Vector2(236, -40), Vector2(314, -30)],
	[Vector2(-320, -28), Vector2(-249, -38), Vector2(-178, -47), Vector2(-107, -54), Vector2(-36, -60), Vector2(36, -60), Vector2(107, -54), Vector2(178, -47), Vector2(249, -38), Vector2(320, -28)],
]

## 手牌角度查找表，按 1 到 10 张手牌排列。
const HAND_ANGLES: Array = [
	[0.0],
	[-2.0, 2.0],
	[-5.0, 0.0, 5.0],
	[-7.0, -2.5, 2.5, 7.0],
	[-8.0, -4.0, 0.0, 4.0, 8.0],
	[-9.0, -5.5, -2.0, 2.0, 5.5, 9.0],
	[-10.0, -6.5, -3.0, 0.0, 3.0, 6.5, 10.0],
	[-11.0, -8.0, -5.0, -2.0, 2.0, 5.0, 8.0, 11.0],
	[-12.0, -9.0, -6.0, -3.0, 0.0, 3.0, 6.0, 9.0, 12.0],
	[-13.0, -10.0, -7.0, -4.0, -1.5, 1.5, 4.0, 7.0, 10.0, 13.0],
]

## 拖拽跟随速度，0 到 1，越大跟随越快。
const DRAG_LERP_SPEED: float = 0.2
## 拖拽时的放大比例。
const DRAG_SCALE: float = 1.05

## 手牌排列动画时长。
const HAND_POSITION_DURATION: float = 0.35
## 拖拽回弹动画时长。
const DRAG_RETURN_DURATION: float = 0.3
## 出牌消失动画时长。
const PLAY_DURATION: float = 0.25

## 入场起点，相对于 HandContainer。
const CARD_ENTRY_ORIGIN: Vector2 = Vector2(400.0, -150.0)
## 每张手牌入场间隔。
const CARD_ENTRY_STAGGER: float = 0.08
## 单张手牌入场时长。
const CARD_ENTRY_DURATION: float = 0.45
## 入场弧线高度。
const CARD_ENTRY_ARC_HEIGHT: float = 120.0

## 气泡提示显示时长。
const TOAST_DURATION: float = 2.0
## 气泡提示淡入时长。
const TOAST_FADE_IN: float = 0.2
## 气泡提示淡出时长。
const TOAST_FADE_OUT: float = 0.4
## 气泡提示最终停留 Y 坐标。
const TOAST_TARGET_Y: float = 200.0

## 卡牌基础透明度。
const CARD_BASE_ALPHA: float = 0.9
## 卡牌圆角半径。
const CARD_CORNER_RADIUS: int = 8
## 卡牌边框宽度。
const CARD_BORDER_WIDTH: int = 2
## 不可用卡牌暗化程度。
const CARD_DISABLED_DIM: float = 0.2
## 不可用卡牌遮罩颜色。
const CARD_DISABLED_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
## 悬浮时卡牌上移像素。
const HOVER_LIFT: float = 40.0
## 悬浮时两侧卡牌推开距离。
const HOVER_PUSH_AWAY: float = 100.0
## 悬浮时卡牌缩放。
const HOVER_SCALE: float = 1.1

## 获取指定手牌数量时第 index 张卡牌的位置偏移。
static func get_hand_position(hand_size: int, index: int) -> Vector2:
	var idx: int = clampi(hand_size - 1, 0, HAND_POSITIONS.size() - 1)
	var positions: Array = HAND_POSITIONS[idx]
	var card_idx: int = clampi(index, 0, positions.size() - 1)
	return positions[card_idx]

## 获取指定手牌数量时第 index 张卡牌的角度。
static func get_hand_angle(hand_size: int, index: int) -> float:
	var idx: int = clampi(hand_size - 1, 0, HAND_ANGLES.size() - 1)
	var angles: Array = HAND_ANGLES[idx]
	var card_idx: int = clampi(index, 0, angles.size() - 1)
	return angles[card_idx]
