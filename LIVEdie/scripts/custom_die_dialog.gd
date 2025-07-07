###############################################################
# LIVEdie/scripts/custom_die_dialog.gd
# Key Classes      • CustomDieDialog – keypad popup for die sides
# Key Functions    • popup_with_value() – open dialog with default
# Dependencies     • none
# Last Major Rev   • 24-06-XX – initial implementation
###############################################################
class_name CustomDieDialog
extends AcceptDialog

signal sides_entered(sides: int)

var cd_value: int = 6
var _replace: bool = true
var _ok_selected: bool = false
var _label: Label
var _grid: GridContainer


func _ready() -> void:
    title = "Custom Die"
    _label = Label.new()
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.custom_minimum_size = Vector2(200, 60)
    add_child(_label)
    _grid = GridContainer.new()
    _grid.columns = 3
    add_child(_grid)
    _build_buttons()
    get_ok_button().hide()
    connect("visibility_changed", _on_visibility_changed)


func _build_buttons() -> void:
    var order := ["7", "8", "9", "4", "5", "6", "1", "2", "3", "DEL", "0", "OK"]
    for key in order:
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(80, 80)
        btn.add_theme_font_size_override("font_size", 32)
        if key == "DEL":
            btn.text = "\u232b"
            btn.pressed.connect(_on_del_pressed)
        elif key == "OK":
            btn.text = "\u2714"
            btn.pressed.connect(_on_ok_pressed)
        else:
            btn.text = key
            btn.pressed.connect(_on_digit_pressed.bind(key))
        _grid.add_child(btn)


func popup_with_value(value: int) -> void:
    cd_value = value
    _label.text = str(value)
    _replace = true
    _ok_selected = false
    popup_centered()


func _on_digit_pressed(digit: String) -> void:
    if _replace:
        _label.text = digit
        _replace = false
    else:
        var s := _label.text
        if s == "0":
            s = ""
        _label.text = s + digit
    cd_value = int(_label.text)


func _on_del_pressed() -> void:
    if _label.text == "0":
        _ok_selected = true
        hide()
        emit_signal("sides_entered", 0)
        return
    var s := _label.text
    if s.length() > 1:
        s = s.substr(0, s.length() - 1)
    else:
        s = "0"
    _label.text = s
    cd_value = int(s)


func _on_ok_pressed() -> void:
    _ok_selected = true
    hide()
    emit_signal("sides_entered", cd_value)


func _on_visibility_changed() -> void:
    if not _ok_selected:
        emit_signal("sides_entered", 0)
