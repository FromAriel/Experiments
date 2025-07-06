#
# LIVEdie/scripts/dial_spinner.gd
# Key Classes      • DialSpinner – popup dial for quantity selection
# Key Functions    • popup_centered() – show dial
#                   • ds_value – current value
# Critical Consts  • none
# Dependencies     • none
# Last Major Rev   • 24-06-XX – initial dial spinner
###############################################################
class_name DialSpinner
extends AcceptDialog

@export var ds_max_value: int = 1000
@export var ds_accel_factor: float = 1.05

var ds_value: int = 1
var _dragging: bool = false
var _last_angle: float = 0.0
var _accel: float = 1.0
var _flash: bool = false
var _dial_angle: float = 0.0

@onready var _dial := $DialArea
@onready var _label: Label = $DialArea/ValueLabel
@onready var _input_panel: PopupPanel = $DialArea/InputPanel as PopupPanel


func _ready() -> void:
    _label.text = str(ds_value)
    _dial.gui_input.connect(_on_dial_input)
    $DialArea/ValueLabel.gui_input.connect(_on_label_input)
    _dial.spinner = self
    _dial.queue_redraw()
    _build_keypad()
    _input_panel.hide()
    self.hide()


func _build_keypad() -> void:
    var grid := GridContainer.new()
    grid.columns = 3
    _input_panel.add_child(grid)
    var order := ["7", "8", "9", "4", "5", "6", "1", "2", "3", "DEL", "0", "OK"]
    for key in order:
        var btn := Button.new()
        if key == "DEL":
            btn.text = "\u232b"
        elif key == "OK":
            btn.text = "\u2714"
        else:
            btn.text = key
        btn.custom_minimum_size = Vector2(80, 80)
        btn.add_theme_font_size_override("font_size", 32)
        grid.add_child(btn)
        if key.is_valid_int():
            btn.pressed.connect(_on_key.bind(key))
        elif key == "OK":
            btn.pressed.connect(_on_ok_pressed)
        else:
            btn.pressed.connect(_on_del_pressed)


func _on_label_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        _input_panel.popup_centered()
        event.accept()


func _on_key(ch: String) -> void:
    var s := str(ds_value)
    if s == "0":
        s = ""
    s += ch
    var v: int = clamp(int(s), 0, ds_max_value)
    ds_value = v
    _update_label()


func _on_ok_pressed() -> void:
    _input_panel.hide()


func _on_del_pressed() -> void:
    var s := str(ds_value)
    if s.length() > 1:
        s = s.substr(0, s.length() - 1)
    else:
        s = "0"
    ds_value = int(s)
    _update_label()


func _on_dial_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed:
            _dragging = true
            _last_angle = _pos_angle(event.position)
            _accel = 1.0
        else:
            _dragging = false
    elif event is InputEventMouseMotion and _dragging:
        var angle := _pos_angle(event.position)
        var delta := angle - _last_angle
        delta = wrapf(delta, -PI, PI)
        _last_angle = angle
        var step := int(delta * 30.0 * _accel)
        if step != 0:
            _set_value(ds_value + step)
            _accel *= ds_accel_factor


func _pos_angle(pos: Vector2) -> float:
    var center: Vector2 = _dial.size / 2
    return atan2(pos.y - center.y, pos.x - center.x)


func _set_value(v: int) -> void:
    var new_val: int = clamp(v, 0, ds_max_value)
    if new_val == ds_value:
        return
    var diff: int = new_val - ds_value
    ds_value = new_val
    _flash = not _flash
    _dial_angle += diff * 0.05
    _update_label()
    _pulse()
    _dial.queue_redraw()


func _update_label() -> void:
    _label.text = str(ds_value)


func _pulse() -> void:
    _label.scale = Vector2.ONE
    var tw := create_tween()
    tw.tween_property(_label, "scale", Vector2(1.2, 1.2), 0.1)
    tw.tween_property(_label, "scale", Vector2.ONE, 0.2).set_delay(0.1)


func open_dial(size: Vector2i = Vector2i()) -> void:
    _open_at_position(Vector2.ZERO, size)


func open_over(node: Control, size: Vector2i = Vector2i()) -> void:
    var rect := node.get_global_rect()
    var center := rect.position + rect.size / 2
    _open_at_position(center, size)


func _open_at_position(center: Vector2, size: Vector2i) -> void:
    _update_label()
    _input_panel.hide()
    _flash = false
    _dial.queue_redraw()
    if center == Vector2.ZERO:
        popup_centered(size)
    else:
        self.position = center - Vector2(size) / 2
        popup()
