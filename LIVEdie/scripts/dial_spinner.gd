###############################################################
# LIVEdie/scripts/dial_spinner.gd
# Key Classes      • DialSpinner – rotating quantity selector
# Key Functions    • _gui_input() – handle drag and taps
#                   set_ds_value() – clamp and animate value
# Critical Consts  • DS_COLOR_A/B – dial segment colors
# Editor Exports   • ds_max_value: int
#                   ds_accel: float
# Dependencies     • none
# Last Major Rev   • 24-05-XX – spinner dial implementation
###############################################################
class_name DialSpinner
extends Control

const DS_COLOR_A := Color("#3082e8")
const DS_COLOR_B := Color("#7c3aed")
const DS_SEGMENTS := 16

@export var ds_max_value: int = 1000
@export var ds_accel: float = 1.05

var ds_value: int = 1
var ds_dragging: bool = false
var ds_last_angle: float = 0.0
var ds_step: float = 1.0
var ds_flash: bool = false
var ds_scale: float = 1.0
var ds_input_buffer: String = ""
var ds_show_keypad: bool = false


func _ready() -> void:
    set_process(true)


func set_ds_value(v: int) -> void:
    v = clamp(v, 1, ds_max_value)
    if v == ds_value:
        return
    ds_value = v
    ds_flash = not ds_flash
    ds_scale = 1.2
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    if ds_show_keypad:
        _keypad_input(event)
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            ds_dragging = true
            ds_last_angle = _to_angle(event.position)
            ds_step = 1.0
        else:
            ds_dragging = false
    elif event is InputEventMouseMotion and ds_dragging:
        var angle := _to_angle(event.position)
        var diff := angle - ds_last_angle
        if abs(diff) > 0.05:
            var inc: int = int(sign(diff) * max(1, int(abs(diff) / 0.05)) * int(ds_step))
            set_ds_value(ds_value + inc)
            ds_last_angle = angle
            ds_step = min(ds_step * ds_accel, 20.0)
    elif (
        event is InputEventMouseButton
        and not event.pressed
        and event.button_index == MOUSE_BUTTON_LEFT
    ):
        var center := Vector2(size.x / 2.0, size.y / 2.0)
        if (event.position - center).length() < min(size.x, size.y) * 0.25:
            _toggle_keypad()


func _toggle_keypad() -> void:
    ds_show_keypad = not ds_show_keypad
    if ds_show_keypad:
        ds_input_buffer = str(ds_value)
    queue_redraw()


func _keypad_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var area := Rect2(size * 0.1, size * 0.8)
        var btn_size := Vector2(area.size.x / 3.0, area.size.y / 4.0)
        if area.has_point(event.position):
            var col := int((event.position.x - area.position.x) / btn_size.x)
            var row := int((event.position.y - area.position.y) / btn_size.y)
            var idx := row * 3 + col
            var labels := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Del", "0", "OK"]
            var label: String = labels[idx]
            if label == "Del":
                if ds_input_buffer.length() > 0:
                    ds_input_buffer = ds_input_buffer.substr(0, ds_input_buffer.length() - 1)
            elif label == "OK":
                if ds_input_buffer != "":
                    set_ds_value(int(ds_input_buffer))
                ds_show_keypad = false
            else:
                if ds_input_buffer == "0":
                    ds_input_buffer = ""
                ds_input_buffer += label
                if int(ds_input_buffer) > ds_max_value:
                    ds_input_buffer = str(ds_max_value)
            queue_redraw()
            event.accept()


func _process(delta: float) -> void:
    ds_scale = lerp(ds_scale, 1.0, delta * 5.0)


func _to_angle(pos: Vector2) -> float:
    var center := Vector2(size.x / 2.0, size.y / 2.0)
    return atan2(pos.y - center.y, pos.x - center.x)


func _draw() -> void:
    var center := Vector2(size.x / 2.0, size.y / 2.0)
    var radius: float = min(size.x, size.y) / 2.0 - 10.0
    for i in range(DS_SEGMENTS):
        var a1 := TAU * float(i) / DS_SEGMENTS
        var a2 := TAU * float(i + 1) / DS_SEGMENTS
        var col := DS_COLOR_A if i % 2 == 0 else DS_COLOR_B
        if ds_flash and i % 2 == 0:
            col = col.lightened(0.3)
        draw_arc(center, radius, a1, a2 - a1, 20.0, col)
    var disp := ds_input_buffer if ds_show_keypad else str(ds_value)
    var font := get_theme_default_font()
    var str_size := font.get_string_size(disp)
    draw_set_transform(center, 0.0, Vector2.ONE * ds_scale)
    draw_string(font, -str_size / 2, disp, HORIZONTAL_ALIGNMENT_CENTER, -1, -1, Color.WHITE)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if ds_show_keypad:
        _draw_keypad()


func _draw_keypad() -> void:
    var area := Rect2(size * 0.1, size * 0.8)
    var btn_size := Vector2(area.size.x / 3.0, area.size.y / 4.0)
    var labels := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Del", "0", "OK"]
    var font := get_theme_default_font()
    for i in range(labels.size()):
        var col := i % 3
        var row := i / 3
        var pos := area.position + Vector2(col * btn_size.x, row * btn_size.y)
        draw_rect(Rect2(pos, btn_size).grow(-2.0), Color(0.2, 0.2, 0.2, 0.8))
        var txt: String = labels[i]
        var tsize: Vector2 = font.get_string_size(txt)
        draw_string(
            font,
            pos + btn_size / 2 - tsize / 2,
            txt,
            HORIZONTAL_ALIGNMENT_CENTER,
            -1,
            -1,
            Color.WHITE
        )
