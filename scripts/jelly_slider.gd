extends HSlider

@export var fill_color: Color = Color(0.3, 0.7, 1.0, 0.8)
@export var bg_color: Color = Color(0.2, 0.2, 0.25, 0.6)
@export var jelly_amount: float = 0.15

var _fill_rect: ColorRect
var _bg_rect: ColorRect
var _jelly_tween: Tween = null
var _is_dragging: bool = false
var _original_size: Vector2


func _ready() -> void:
    _original_size = custom_minimum_size if custom_minimum_size != Vector2.ZERO else Vector2(200, 8)
    custom_minimum_size = _original_size

    _bg_rect = ColorRect.new()
    _bg_rect.color = bg_color
    _bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_bg_rect)

    _fill_rect = ColorRect.new()
    _fill_rect.color = fill_color
    _fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_fill_rect)

    value_changed.connect(_on_value_changed)
    _update_fill()


func _process(_delta: float) -> void:
    _update_fill()
    _update_jelly()


func _update_fill() -> void:
    if not _bg_rect or not _fill_rect:
        return
    var bar_size := Vector2(size.x, _original_size.y)
    _bg_rect.position = Vector2.ZERO
    _bg_rect.size = bar_size
    var ratio := 0.0
    if max_value > min_value:
        ratio = clampf((value - min_value) / (max_value - min_value), 0.0, 1.0)
    _fill_rect.position = Vector2.ZERO
    _fill_rect.size = Vector2(bar_size.x * ratio, bar_size.y)


func _update_jelly() -> void:
    if _jelly_tween and _jelly_tween.is_running():
        return
    var target_scale_y := 1.0 if not _is_dragging else (1.0 + jelly_amount)
    if abs(scale.y - target_scale_y) > 0.01:
        scale.y = lerpf(scale.y, target_scale_y, 0.2)


func _on_value_changed(_value: float) -> void:
    if _jelly_tween:
        _jelly_tween.kill()
    _jelly_tween = create_tween()
    _jelly_tween.tween_property(self, "scale", Vector2(1.0 + jelly_amount * 0.5, 1.0 + jelly_amount), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _jelly_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _is_dragging = event.pressed
            if not event.pressed:
                _spring_back()
    elif event is InputEventScreenDrag:
        _is_dragging = true


func _spring_back() -> void:
    if _jelly_tween:
        _jelly_tween.kill()
    _jelly_tween = create_tween()
    _jelly_tween.tween_property(self, "scale", Vector2(1.0 - jelly_amount * 0.3, 1.0 + jelly_amount * 0.8), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _jelly_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    _is_dragging = false
