###############################################################
# LIVEdie/scripts/custom_die_input.gd
# Key Classes      • CustomDieInput – keypad for die face input
# Key Functions    • open_input() – open keypad with initial value
# Dependencies     • none
# Last Major Rev   • 24-06-XX – initial version
###############################################################
class_name CustomDieInput
extends PopupPanel

signal confirmed(value: int)
signal cancelled

@export var cdi_max_value: int = 999

var cdi_value: int = 0
var _replace: bool = true

@onready var _label: Label = $VBox/ValueLabel
@onready var _grid: GridContainer = $VBox/Grid


func _ready() -> void:
    _build_keypad()
    hide()


func _build_keypad() -> void:
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
        _grid.add_child(btn)
        if key.is_valid_int():
            btn.pressed.connect(_on_digit.bind(int(key)))
        elif key == "OK":
            btn.pressed.connect(_on_ok)
        else:
            btn.pressed.connect(_on_del)


func open_input(initial: int) -> void:
    cdi_value = clamp(initial, 0, cdi_max_value)
    _replace = true
    _update_label()
    popup_centered()


func _on_digit(d: int) -> void:
    if _replace:
        cdi_value = d
        _replace = false
    else:
        var new_val: int = clamp(cdi_value * 10 + d, 0, cdi_max_value)
        cdi_value = new_val
    _update_label()


func _on_ok() -> void:
    hide()
    if cdi_value == 0:
        emit_signal("cancelled")
    else:
        emit_signal("confirmed", cdi_value)


func _on_del() -> void:
    if _replace or cdi_value == 0:
        hide()
        emit_signal("cancelled")
        return
    var s := str(cdi_value)
    s = s.substr(0, s.length() - 1)
    if s == "":
        cdi_value = 0
        _replace = true
    else:
        cdi_value = int(s)
    _update_label()


func _update_label() -> void:
    _label.text = str(cdi_value)


func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventMouseButton or event is InputEventScreenTouch:
        if not event.pressed:
            hide()
            emit_signal("cancelled")
