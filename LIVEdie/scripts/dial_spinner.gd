#
# LIVEdie/scripts/dial_spinner.gd
# Key Classes      • DialSpinner – circular quantity selector widget
# Key Functions    • _unhandled_input() – handle dial rotation
#                   _draw() – render dial segments
# Critical Consts  • DS_BASE_RADIUS – dial size
# Editor Exports   • ds_accel_rate: float – acceleration tuning
#                   ds_max_value: int – maximum quantity
# Dependencies     • none
# Last Major Rev   • 24-04-XX – overhauled spinner visuals
###############################################################
class_name DialSpinner
extends Control

signal quantity_selected(value: int)

const DS_BASE_RADIUS := 64.0

@export var ds_accel_rate: float = 0.2
@export var ds_max_value: int = 1000
@export var ds_segments: int = 12
@export var ds_color_a: Color = Color(0.2, 0.4, 1.0)
@export var ds_color_b: Color = Color(0.6, 0.2, 0.8)

var ds_value: int = 1:
    set = _set_value
var ds_step_internal: float = 1.0
var _ds_dragging: bool = false
var _ds_last_angle: float = 0.0
var _ds_accum_angle: float = 0.0
var _ds_flash_state: bool = false

@onready var ds_label: Label = $ValueLabel
@onready var ds_number_panel: Control = $NumberPanel


func _ready() -> void:
    ds_label.text = str(ds_value)
    ds_number_panel.visible = false


func _set_value(val: int) -> void:
    ds_value = clamp(val, 1, ds_max_value)
    ds_label.text = str(ds_value)
    _animate_label()
    queue_redraw()


func _animate_label() -> void:
    ds_label.scale = Vector2.ONE * 1.2
    var tw := create_tween()
    tw.tween_property(ds_label, "scale", Vector2.ONE, 0.2)


func _draw() -> void:
    var center := get_rect().size / 2.0
    var r := DS_BASE_RADIUS
    var step_angle := TAU / float(ds_segments)
    for i in range(ds_segments):
        var a1 := i * step_angle - PI / 2
        var a2 := (i + 1) * step_angle - PI / 2
        var p := [
            center, center + Vector2(cos(a1), sin(a1)) * r, center + Vector2(cos(a2), sin(a2)) * r
        ]
        var col := ds_color_a if (i + int(_ds_flash_state)) % 2 == 0 else ds_color_b
        draw_colored_polygon(p, col)


func _unhandled_input(event: InputEvent) -> void:
    if ds_number_panel.visible:
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _ds_dragging = true
                _ds_last_angle = _point_angle(event.position)
                _ds_accum_angle = 0.0
                ds_step_internal = 1.0
            else:
                _ds_dragging = false
                quantity_selected.emit(ds_value)
                hide()
    elif event is InputEventMouseMotion and _ds_dragging:
        var ang := _point_angle(event.position)
        var diff := _wrap_angle(ang - _ds_last_angle)
        _ds_last_angle = ang
        _ds_accum_angle += diff
        var steps := int(abs(_ds_accum_angle) / 0.2)
        if steps > 0:
            var dir: float = sign(_ds_accum_angle)
            _ds_accum_angle -= dir * steps * 0.2
            for _i in range(steps):
                _apply_step(dir)


func _point_angle(p: Vector2) -> float:
    var center := get_rect().size / 2.0
    return (p - center).angle()


func _wrap_angle(a: float) -> float:
    if a > PI:
        a -= TAU
    elif a < -PI:
        a += TAU
    return a


func _apply_step(dir: float) -> void:
    _ds_flash_state = not _ds_flash_state
    _set_value(ds_value + int(dir * ds_step_internal))
    ds_step_internal = min(ds_step_internal + ds_accel_rate, ds_max_value)


func _on_ValueLabel_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        ds_number_panel.visible = true
        $NumberPanel/LineEdit.text = str(ds_value)
        $NumberPanel/LineEdit.grab_focus()


func _on_NumberOkButton_pressed() -> void:
    var val := int($NumberPanel/LineEdit.text)
    _set_value(val)
    ds_number_panel.visible = false
    quantity_selected.emit(ds_value)
    hide()


func _on_NumberDelButton_pressed() -> void:
    $NumberPanel/LineEdit.text = ""
