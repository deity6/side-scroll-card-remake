extends Node

# ============================================================
# 彩蛋小游戏控制器
# 从主菜单分离出来的独立彩蛋系统
# 管理小卡蓄力发射、叶子果子下落、碰撞物理、眼睛动画
# ============================================================

# 小卡参数
const CARD_CHARGE_MAX_TIME := 1.15
const CARD_MIN_IMPULSE := 260.0
const CARD_MAX_IMPULSE := 760.0
const CARD_SPIN_MIN_SPEED := 2.4
const CARD_SPIN_MAX_SPEED := 18.0
const CARD_LIFE_TIME := 4.0
const CARD_GRAVITY := 320.0
const CARD_MAX_SPEED := 1450.0
const CARD_MASS := 2.1

# 物理参数
const OBJECT_GRAVITY := 520.0
const AIR_FRICTION := 0.992
const COLLISION_RESTITUTION := 0.36
const TARGET_LIFE_TIME := 8.0
const SURFACE_Y := 620.0
const SURFACE_FRICTION := 0.78
const SLEEP_SPEED := 24.0

# 叶子参数
const LEAF_SPAWN_INTERVAL := 1.25
const LEAF_SPAWN_REGION := Rect2(Vector2(360, -20), Vector2(300, 30))
const LEAF_FADE_LINE_Y := 680.0
const LEAF_LATERAL_AMPLITUDE := 110.0
const LEAF_LATERAL_FREQUENCY := 1.8
const LEAF_FALL_SPEED_MIN := 34.0
const LEAF_FALL_SPEED_MAX := 72.0
const LEAF_MASS := 0.8

# 果子参数
const FRUIT_SPAWN_INTERVAL := 2.6
const FRUIT_SPAWN_REGION := Rect2(Vector2(480, -20), Vector2(320, 30))
const FRUIT_FADE_LINE_Y := 800.0
const FRUIT_MASS := 1.4
const FRUIT_DENSITY_ZONE := Rect2(Vector2(500, 0), Vector2(300, 80))
const FRUIT_DENSITY_SLOW_FACTOR := 0.48
const FRUIT_DENSITY_ABSORB_FACTOR := 0.78

# 监测线参数
const LINE_FADE_SPEED := 1.25

# 拖尾参数
const TRAIL_SPAWN_INTERVAL := 0.035
const TRAIL_DELAY_OFFSET := Vector2(-16, 10)
const TRAIL_LIFE_TIME := 0.5

# 发射方向判定
const THROW_DIRECTION_MIN_SPEED := 80.0

# 运行时状态
var _charging_card: Control = null
var _charging_start := Vector2.ZERO
var _charging_started_at := 0.0
var _last_drag_position := Vector2.ZERO
var _last_drag_time := 0.0
var _drag_velocity := Vector2.ZERO
var _has_throw_direction := false
var _trail_spawn_timer := 0.0
var _projectiles: Array = []
var _targets: Array = []
var _leaf_spawn_timer := 0.0
var _fruit_spawn_timer := 0.0
var _eyes_node: Control = null
var _eyes_blink_seed := randf_range(0.0, TAU)

# 节点引用（由主菜单注入）
var projectile_layer: Control
var target_layer: Control
var mini_game_layer: Control
var fruit_zone: ColorRect
var leaf_zone: ColorRect
var leaf_fade_line: ColorRect
var fruit_fade_line: ColorRect
var viewport_size: Vector2


func setup(p_projectile_layer: Control, p_target_layer: Control, p_mini_game_layer: Control, p_fruit_zone: ColorRect, p_leaf_zone: ColorRect, p_leaf_fade_line: ColorRect, p_fruit_fade_line: ColorRect, p_viewport_size: Vector2) -> void:
	projectile_layer = p_projectile_layer
	target_layer = p_target_layer
	mini_game_layer = p_mini_game_layer
	fruit_zone = p_fruit_zone
	leaf_zone = p_leaf_zone
	leaf_fade_line = p_leaf_fade_line
	fruit_fade_line = p_fruit_fade_line
	viewport_size = p_viewport_size
	_setup_zones()


func _setup_zones() -> void:
	if fruit_zone:
		fruit_zone.set_deferred("color", Color(0.8, 0.2, 0.2, 0.15))
		fruit_zone.set_deferred("position", FRUIT_DENSITY_ZONE.position)
		fruit_zone.set_deferred("size", FRUIT_DENSITY_ZONE.size)
		fruit_zone.set_deferred("mouse_filter", Control.MOUSE_FILTER_IGNORE)
	if leaf_zone:
		leaf_zone.set_deferred("color", Color(0.2, 0.8, 0.2, 0.15))
		leaf_zone.set_deferred("position", LEAF_SPAWN_REGION.position)
		leaf_zone.set_deferred("size", LEAF_SPAWN_REGION.size)
		leaf_zone.set_deferred("mouse_filter", Control.MOUSE_FILTER_IGNORE)
	if leaf_fade_line:
		leaf_fade_line.set_deferred("color", Color(0.0, 0.8, 0.0, 0.3))
		leaf_fade_line.set_deferred("position", Vector2(0, LEAF_FADE_LINE_Y))
		leaf_fade_line.set_deferred("size", Vector2(viewport_size.x, 2))
		leaf_fade_line.set_deferred("mouse_filter", Control.MOUSE_FILTER_IGNORE)
	if fruit_fade_line:
		fruit_fade_line.set_deferred("color", Color(0.8, 0.0, 0.0, 0.3))
		fruit_fade_line.set_deferred("position", Vector2(0, FRUIT_FADE_LINE_Y))
		fruit_fade_line.set_deferred("size", Vector2(viewport_size.x, 2))
		fruit_fade_line.set_deferred("mouse_filter", Control.MOUSE_FILTER_IGNORE)


func show_zones() -> void:
	if fruit_zone: fruit_zone.visible = true
	if leaf_zone: leaf_zone.visible = true
	if leaf_fade_line: leaf_fade_line.visible = true
	if fruit_fade_line: fruit_fade_line.visible = true
	mini_game_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_spawn_eyes()


func hide_zones() -> void:
	if fruit_zone: fruit_zone.visible = false
	if leaf_zone: leaf_zone.visible = false
	if leaf_fade_line: leaf_fade_line.visible = false
	if fruit_fade_line: fruit_fade_line.visible = false
	mini_game_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_active() -> bool:
	return _projectiles.size() > 0 or _targets.size() > 0 or _charging_card != null


func process_update(delta: float) -> void:
	_update_charging_card(delta)
	_update_spawners(delta)
	_update_projectiles(delta)
	_update_targets(delta)
	_update_eyes_motion()


func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_card_charge(event.position)
		else:
			_release_card(event.position)
		return true
	elif event is InputEventMouseMotion and _charging_card:
		_update_card_charge(event.position)
		return true
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_card_charge(event.position)
		else:
			_release_card(event.position)
		return true
	elif event is InputEventScreenDrag and _charging_card:
		_update_card_charge(event.position)
		return true
	return false


func clear_all() -> void:
	for projectile in _projectiles:
		if is_instance_valid(projectile["node"]):
			projectile["node"].queue_free()
	_projectiles.clear()
	for target in _targets:
		if is_instance_valid(target["node"]):
			target["node"].queue_free()
	_targets.clear()
	if _charging_card:
		_charging_card.queue_free()
		_charging_card = null
	if _eyes_node and is_instance_valid(_eyes_node):
		_eyes_node.queue_free()
		_eyes_node = null


func _update_spawners(delta: float) -> void:
	_leaf_spawn_timer -= delta
	_fruit_spawn_timer -= delta
	if _leaf_spawn_timer <= 0.0:
		_leaf_spawn_timer = LEAF_SPAWN_INTERVAL + randf_range(-0.35, 0.35)
		_spawn_falling_target("leaf")
	if _fruit_spawn_timer <= 0.0:
		_fruit_spawn_timer = FRUIT_SPAWN_INTERVAL + randf_range(-0.5, 0.5)
		_spawn_falling_target("fruit")


func _spawn_falling_target(kind: String) -> void:
	var region := LEAF_SPAWN_REGION if kind == "leaf" else FRUIT_SPAWN_REGION
	var radius := randf_range(12.0, 17.0) if kind == "leaf" else randf_range(15.0, 20.0)
	var node := _create_target_visual(kind, radius)
	node.position = Vector2(randf_range(region.position.x, region.end.x), randf_range(region.position.y, region.end.y))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_layer.add_child(node)
	var initial_velocity := Vector2(randf_range(-45.0, 45.0), randf_range(20.0, 60.0))
	_targets.append({"node": node, "kind": kind, "mass": LEAF_MASS if kind == "leaf" else FRUIT_MASS, "radius": radius, "velocity": initial_velocity, "phase": randf_range(0.0, TAU), "alive": true, "settled": false, "life": TARGET_LIFE_TIME, "fade_line_y": LEAF_FADE_LINE_Y if kind == "leaf" else FRUIT_FADE_LINE_Y, "lateral_amplitude": LEAF_LATERAL_AMPLITUDE if kind == "leaf" else 0.0, "lateral_frequency": LEAF_LATERAL_FREQUENCY if kind == "leaf" else 0.0})


func _spawn_eyes() -> void:
	if _eyes_node and is_instance_valid(_eyes_node):
		return
	_eyes_node = _create_target_visual("eyes", 22.0)
	_eyes_node.position = Vector2(610, 650)
	_eyes_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_layer.add_child(_eyes_node)


func _update_targets(delta: float) -> void:
	for i in range(_targets.size() - 1, -1, -1):
		var target: Dictionary = _targets[i]
		var node: Control = target["node"]
		if not is_instance_valid(node):
			_targets.remove_at(i)
			continue
		var velocity: Vector2 = target["velocity"]
		var kind: String = target["kind"]
		if kind == "leaf":
			var phase: float = target["phase"]
			var lateral_amplitude: float = target["lateral_amplitude"]
			var lateral_frequency: float = target["lateral_frequency"]
			var time := Time.get_ticks_msec() / 1000.0
			var lateral_force := sin(time * lateral_frequency + phase) * lateral_amplitude * delta
			velocity.x += lateral_force
			velocity.y *= 0.98
		elif kind == "fruit":
			if FRUIT_DENSITY_ZONE.has_point(node.global_position):
				velocity *= FRUIT_DENSITY_SLOW_FACTOR
		velocity += Vector2(0, OBJECT_GRAVITY) * delta
		velocity *= AIR_FRICTION
		node.position += velocity * delta
		var floor_y := SURFACE_Y - node.size.y
		if node.position.y >= floor_y:
			node.position.y = floor_y
			target["settled"] = true
			if velocity.y > 0.0:
				velocity.y = -velocity.y * COLLISION_RESTITUTION
			velocity.x *= SURFACE_FRICTION
			if absf(velocity.y) < 45.0:
				velocity.y = 0.0
		if node.position.x < 24.0:
			node.position.x = 24.0
			velocity.x = absf(velocity.x) * COLLISION_RESTITUTION
		elif node.position.x > viewport_size.x - node.size.x - 24.0:
			node.position.x = viewport_size.x - node.size.x - 24.0
			velocity.x = -absf(velocity.x) * COLLISION_RESTITUTION
		node.rotation += velocity.x * delta * 0.01
		target["velocity"] = velocity
		var fade_line_y: float = target["fade_line_y"]
		if node.global_position.y > fade_line_y:
			velocity *= 0.95
			target["velocity"] = velocity
			if velocity.length() < SLEEP_SPEED:
				target["life"] = float(target["life"]) - delta * 2.0
				node.modulate.a = clampf(float(target["life"]) / TARGET_LIFE_TIME, 0.0, 1.0)
			else:
				target["life"] = float(target["life"]) - delta * 0.12
		else:
			target["life"] = float(target["life"]) - delta * 0.12
		if float(target["life"]) <= 0.0:
			_play_target_fade(node)
			_targets.remove_at(i)
		else:
			_targets[i] = target


func _begin_card_charge(pos: Vector2) -> void:
	if _charging_card:
		_charging_card.queue_free()
	_charging_start = pos
	_charging_started_at = Time.get_ticks_msec() / 1000.0
	_last_drag_position = pos
	_last_drag_time = _charging_started_at
	_drag_velocity = Vector2.ZERO
	_has_throw_direction = false
	_trail_spawn_timer = 0.0
	_charging_card = _create_projectile_visual()
	_charging_card.position = pos - _charging_card.size * 0.5
	_charging_card.modulate.a = 1.0
	projectile_layer.add_child(_charging_card)


func _update_charging_card(delta: float) -> void:
	if not _charging_card:
		return
	var hold_time := maxf((Time.get_ticks_msec() / 1000.0) - _charging_started_at, 0.0)
	var charge_ratio := clampf(hold_time / CARD_CHARGE_MAX_TIME, 0.0, 1.0)
	var spin_speed := lerpf(CARD_SPIN_MIN_SPEED, CARD_SPIN_MAX_SPEED, charge_ratio)
	_charging_card.rotation += spin_speed * delta
	_trail_spawn_timer -= delta
	if _trail_spawn_timer <= 0.0:
		_trail_spawn_timer = TRAIL_SPAWN_INTERVAL
		_spawn_drag_trail(_last_drag_position)


func _update_card_charge(pos: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var dt := maxf(now - _last_drag_time, 0.001)
	_drag_velocity = (pos - _last_drag_position) / dt
	if _drag_velocity.length() >= THROW_DIRECTION_MIN_SPEED:
		_has_throw_direction = true
	_last_drag_position = pos
	_last_drag_time = now
	var target_pos := pos - _charging_card.size * 0.5
	_charging_card.position = _charging_card.position.lerp(target_pos, 0.82)
	_charging_card.rotation += _drag_velocity.length() * dt * 0.0012
	_charging_card.modulate.a = 1.0
	_spawn_drag_trail(pos)


func _release_card(pos: Vector2) -> void:
	if not _charging_card:
		return
	_update_card_charge(pos)
	var hold_time := maxf((Time.get_ticks_msec() / 1000.0) - _charging_started_at, 0.01)
	var throw_direction := Vector2.ZERO
	if _has_throw_direction and _drag_velocity.length() > 10.0:
		throw_direction = _drag_velocity.normalized()
	else:
		var from_start := pos - _charging_start
		if from_start.length() > 8.0:
			throw_direction = from_start.normalized()
		else:
			throw_direction = Vector2(randf_range(-0.6, 0.6), -0.8).normalized()
	var charge_ratio := clampf(hold_time / CARD_CHARGE_MAX_TIME, 0.0, 1.0)
	var speed := lerpf(CARD_MIN_IMPULSE, CARD_MAX_IMPULSE, charge_ratio)
	var velocity := throw_direction * speed
	if _has_throw_direction:
		velocity += _drag_velocity * 0.4
	if velocity.length() > CARD_MAX_SPEED:
		velocity = velocity.normalized() * CARD_MAX_SPEED
	elif velocity.length() < 80.0:
		velocity = throw_direction * 120.0
	_projectiles.append({"node": _charging_card, "velocity": velocity, "radius": 18.0, "life": CARD_LIFE_TIME, "mass": CARD_MASS})
	_charging_card = null


func _spawn_drag_trail(_pos: Vector2) -> void:
	var trail := ColorRect.new()
	trail.color = Color(1.0, 0.86, 0.26, 0.36)
	trail.position = _last_drag_position + TRAIL_DELAY_OFFSET
	trail.size = Vector2(22, 14)
	trail.pivot_offset = trail.size * 0.5
	trail.rotation = randf_range(-0.25, 0.25)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile_layer.add_child(trail)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(trail, "modulate:a", 0.0, 0.26)
	tw.tween_property(trail, "scale", Vector2(0.25, 0.25), 0.26)
	tw.chain().tween_callback(trail.queue_free)


func _update_projectiles(delta: float) -> void:
	for i in range(_projectiles.size() - 1, -1, -1):
		var item: Dictionary = _projectiles[i]
		var node: Control = item["node"]
		if not is_instance_valid(node):
			_projectiles.remove_at(i)
			continue
		var velocity: Vector2 = item["velocity"]
		var old_speed := velocity.length()
		velocity += Vector2(0, CARD_GRAVITY) * delta
		velocity *= pow(AIR_FRICTION, delta * 60.0)
		var new_speed := velocity.length()
		if new_speed > 0.001:
			velocity = velocity * minf(new_speed, old_speed * 1.04 + 80.0) / new_speed
		item["life"] = float(item["life"]) - delta
		node.position += velocity * delta
		node.rotation += delta * clampf(velocity.length() * 0.004, 1.8, 9.0)
		node.modulate.a = clampf(float(item["life"]) / maxf(CARD_LIFE_TIME * 0.35, 0.05), 0.0, 1.0)
		item["velocity"] = velocity
		_check_projectile_hits(item)


func _check_projectile_hits(projectile_data: Dictionary) -> void:
	var projectile: Control = projectile_data["node"]
	var center := projectile.global_position + projectile.size * 0.5
	var projectile_velocity: Vector2 = projectile_data["velocity"]
	var projectile_radius := float(projectile_data["radius"])
	var projectile_mass: float = projectile_data["mass"]
	for target_index in range(_targets.size()):
		var target: Dictionary = _targets[target_index]
		if not target["alive"]:
			continue
		var target_node: Control = target["node"]
		if not is_instance_valid(target_node):
			target["alive"] = false
			_targets[target_index] = target
			continue
		var target_center := target_node.global_position + target_node.size * 0.5
		var delta_vec := target_center - center
		var hit_distance := float(target["radius"]) + projectile_radius
		var separation := delta_vec.length() - hit_distance
		if separation > 0.0:
			continue
		var normal := delta_vec.normalized() if delta_vec.length() > 0.001 else Vector2.UP
		var target_mass: float = target["mass"]
		var total_mass := projectile_mass + target_mass
		var closing_speed := maxf(-separation, 0.0) + projectile_velocity.dot(normal) - Vector2(target["velocity"]).dot(normal)
		var impulse_strength := clampf(closing_speed / maxf(total_mass, 0.1) * total_mass, 0.0, 260.0)
		var impulse_vec := normal * impulse_strength
		var new_target_velocity: Vector2 = Vector2(target["velocity"]) + impulse_vec * (projectile_mass / total_mass) * 1.1
		new_target_velocity.y = minf(new_target_velocity.y, 380.0)
		target["velocity"] = new_target_velocity
		var new_projectile_velocity: Vector2 = projectile_velocity - impulse_vec * (target_mass / total_mass)
		new_projectile_velocity *= 0.86
		if target["kind"] == "fruit" and FRUIT_DENSITY_ZONE.has_point(projectile.global_position):
			new_projectile_velocity *= FRUIT_DENSITY_ABSORB_FACTOR
			new_target_velocity *= FRUIT_DENSITY_SLOW_FACTOR
			target["velocity"] = new_target_velocity
		projectile_data["velocity"] = new_projectile_velocity
		target_node.rotation += randf_range(-0.5, 0.5)
		_targets[target_index] = target


func _update_eyes_motion() -> void:
	if _eyes_node and is_instance_valid(_eyes_node):
		var t := Time.get_ticks_msec() / 1000.0 + _eyes_blink_seed
		var blink := 0.45 + absf(sin(t * 1.1)) * 0.28 + (0.18 if fmod(t, 3.2) < 0.08 else 0.0)
		_eyes_node.scale.y = clampf(blink, 0.25, 0.92)


func _play_target_fade(target_node: Control) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(target_node, "modulate:a", 0.0, 0.2)
	tw.tween_property(target_node, "scale", Vector2(1.6, 1.6), 0.2)
	tw.chain().tween_callback(target_node.queue_free)


func _create_projectile_visual() -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(30, 42)
	root.size = Vector2(30, 42)
	root.pivot_offset = root.size * 0.5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var trail := ColorRect.new()
	trail.color = Color(1.0, 0.9, 0.35, 0.32)
	trail.position = Vector2(-18, 10)
	trail.size = Vector2(26, 22)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(trail)
	var card := ColorRect.new()
	card.color = Color(1.0, 0.96, 0.78, 0.95)
	card.position = Vector2(5, 4)
	card.size = Vector2(20, 30)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)
	return root


func _create_target_visual(kind: String, radius: float) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	root.size = root.custom_minimum_size
	root.pivot_offset = root.size * 0.5
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "fruit":
		_add_rect_part(root, Vector2(radius * 0.32, radius * 0.42), Vector2(radius * 1.2, radius * 1.2), Color(0.96, 0.43, 0.25, 0.96))
		_add_rect_part(root, Vector2(radius * 0.75, radius * 0.12), Vector2(radius * 0.28, radius * 0.42), Color(0.34, 0.22, 0.12, 0.95))
	elif kind == "eyes":
		_add_rect_part(root, Vector2(radius * 0.12, radius * 0.62), Vector2(radius * 0.58, radius * 0.3), Color(1.0, 0.9, 0.35, 0.95))
		_add_rect_part(root, Vector2(radius * 1.05, radius * 0.62), Vector2(radius * 0.58, radius * 0.3), Color(1.0, 0.9, 0.35, 0.95))
	else:
		_add_rect_part(root, Vector2(radius * 0.2, radius * 0.72), Vector2(radius * 1.45, radius * 0.52), Color(0.63, 0.84, 0.36, 0.92))
		_add_rect_part(root, Vector2(radius * 0.9, radius * 0.78), Vector2(radius * 0.18, radius * 0.68), Color(0.36, 0.52, 0.2, 0.88))
	return root


func _add_rect_part(parent: Control, pos: Vector2, part_size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = part_size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
