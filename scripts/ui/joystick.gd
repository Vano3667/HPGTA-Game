extends Control
## One-thumb floating movement stick. It tracks a single touch and never needs a second finger.
## The stick appears wherever the thumb lands in the lower part of the screen; Harry is free to
## move across the whole arena.

var vector := Vector2.ZERO
var enabled := true
var right_handed := true
var stick_size := 56.0
var stick_opacity := 0.5
var sensitivity := 1.0

var _index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func reset() -> void:
    _index = -1
    vector = Vector2.ZERO
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            # The thumb zone is the lower 60% of the screen.
            if enabled and _index == -1 and touch.position.y >= get_viewport_rect().size.y * 0.4:
                _index = touch.index
                _origin = touch.position
                _knob = touch.position
                vector = Vector2.ZERO
                queue_redraw()
        elif touch.index == _index:
            reset()
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        if drag.index != _index:
            return
        _knob = drag.position
        var d: Vector2 = _knob - _origin
        var l: float = d.length()
        # Floating stick: the base follows when the thumb travels past the rim.
        if l > stick_size * 1.3:
            _origin = _knob - d / l * stick_size * 1.3
            d = _knob - _origin
            l = d.length()
        var reach: float = stick_size / maxf(0.3, sensitivity)
        if l < stick_size * 0.12:
            vector = Vector2.ZERO
        else:
            vector = d / l * minf(1.0, l / reach)
        queue_redraw()


func _draw() -> void:
    if not enabled:
        return
    var vs: Vector2 = get_viewport_rect().size
    var col := Color(0.85, 0.82, 0.7, stick_opacity)
    if _index == -1:
        # Resting hint on the chosen hand side.
        var side: float = 0.66 if right_handed else 0.26
        var rest := Vector2(vs.x * side, vs.y - stick_size * 2.4)
        draw_arc(rest, stick_size, 0.0, TAU, 32, Color(col, stick_opacity * 0.5), 2.0)
        draw_circle(rest, stick_size * 0.3, Color(col, stick_opacity * 0.3))
        return
    draw_arc(_origin, stick_size, 0.0, TAU, 32, col, 2.0)
    draw_circle(_origin + vector * stick_size, stick_size * 0.38, Color(0.4, 0.86, 0.95, stick_opacity))
