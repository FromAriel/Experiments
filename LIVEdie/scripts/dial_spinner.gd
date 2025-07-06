###############################################################
# LIVEdie/scripts/dial_spinner.gd
# Key Classes      • DialSpinner – circular quantity selector
# Key Functions    • set_value() – clamp and animate
#                   _input() – handle drag rotation
# Critical Consts  • none
# Editor Exports   • dsp_max_value: int – Range(1..1000)
#                   dsp_accel_rate: float – acceleration factor
# Dependencies     • none
# Last Major Rev   • 24-04-XX – initial version
###############################################################
class_name DialSpinner
extends Control

@export var dsp_max_value: int = 1000
@export var dsp_accel_rate: float = 0.1
@export var dsp_segments: int = 24

var dsp_value: int = 1
var dsp_dragging: bool = false
var dsp_last_angle: float = 0.0
var dsp_accum_angle: float = 0.0
var dsp_pad_value: String = ""

@onready var dsp_label: Label = Label.new()
@onready var dsp_pad: PanelContainer = PanelContainer.new()


func _ready() -> void:
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    dsp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    dsp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    dsp_label.anchor_left = 0.25
    dsp_label.anchor_right = 0.75
    dsp_label.anchor_top = 0.25
    dsp_label.anchor_bottom = 0.75
    dsp_label.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(dsp_label)
    dsp_label.gui_input.connect(_on_label_input)
    _build_pad()
    set_value(dsp_value)


func _build_pad() -> void:
    dsp_pad.visible = false
    dsp_pad.anchor_left = 0.2
    dsp_pad.anchor_right = 0.8
    dsp_pad.anchor_top = 0.2
    dsp_pad.anchor_bottom = 0.8
    var grid := GridContainer.new()
    grid.columns = 3
    for i in range(1, 10):
        var b := Button.new()
        b.text = str(i)
        b.pressed.connect(_on_pad_digit.bind(i))
        grid.add_child(b)
    var zero := Button.new()
    zero.text = "0"
    zero.pressed.connect(_on_pad_digit.bind(0))
    grid.add_child(zero)
    var ok := Button.new()
    ok.text = "OK"
    ok.pressed.connect(_on_pad_ok)
    grid.add_child(ok)
    var del := Button.new()
    del.text = "<x"
    del.pressed.connect(_on_pad_delete)
    grid.add_child(del)
    dsp_pad.add_child(grid)
    add_child(dsp_pad)


func set_value(val: int) -> void:
    val = clamp(val, 1, dsp_max_value)
    if val == dsp_value:
        return
    dsp_value = val
    dsp_label.text = str(dsp_value)
    var tw = create_tween()
    tw.tween_property(dsp_label, "scale", Vector2.ONE * 1.2, 0.1).set_trans(Tween.TRANS_SINE)
    tw.tween_property(dsp_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)
    queue_redraw()


func _angle_to_point(p: Vector2) -> float:
    return (p - size / 2).angle()


func _input(event: InputEvent) -> void:
    if dsp_pad.visible:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            dsp_dragging = true
            dsp_last_angle = _angle_to_point(event.position)
            dsp_accum_angle = 0.0
            accept_event()
        else:
            dsp_dragging = false
            accept_event()
    elif event is InputEventMouseMotion and dsp_dragging:
        var ang = _angle_to_point(event.position)
        var delta = ang - dsp_last_angle
        if delta > PI:
            delta -= TAU
        elif delta < -PI:
            delta += TAU
        dsp_last_angle = ang
        dsp_accum_angle += delta
        var step = TAU / float(dsp_segments)
        var inc = int(dsp_accum_angle / step)
        if inc != 0:
            var scaled = inc * (1 + abs(inc) * dsp_accel_rate)
            set_value(dsp_value + scaled)
            dsp_accum_angle -= inc * step
            accept_event()


func _draw() -> void:
    var c = size / 2
    var r = min(size.x, size.y) / 2 - 4
    var seg = TAU / float(dsp_segments)
    for i in range(dsp_segments):
        var col = Color(0.2, 0.4, 1.0) if i % 2 == 0 else Color(0.5, 0.3, 1.0)
        draw_arc(c, r, i * seg, seg * 0.9, 12, col)
    var rot = float(dsp_value % dsp_segments) / dsp_segments * TAU
    var p1 = c + Vector2.RIGHT.rotated(rot) * (r * 0.8)
    draw_line(c, p1, Color.WHITE, 2)


func _on_label_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        dsp_pad_value = ""
        dsp_pad.visible = true
        event.accept()


func _on_pad_digit(d: int) -> void:
    dsp_pad_value += str(d)
    dsp_label.text = dsp_pad_value


func _on_pad_delete() -> void:
    if dsp_pad_value.length() > 0:
        dsp_pad_value = dsp_pad_value.left(dsp_pad_value.length() - 1)
    dsp_label.text = dsp_pad_value


func _on_pad_ok() -> void:
    if dsp_pad_value != "":
        set_value(int(dsp_pad_value))
    dsp_pad.visible = false
    dsp_label.text = str(dsp_value)
