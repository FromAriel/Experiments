###############################################################
# LIVEdie/scripts/custom_die_panel.gd
# Key Classes      • CustomDiePanel – numeric keypad for custom die faces
# Key Functions    • open_panel_at() – popup keypad near position
#                   _on_ok_pressed() – confirm selection
#                   _on_visibility_changed() – cancel on focus loss
# Editor Exports   • cdp_max_value: int – highest allowed face count
# Last Major Rev   • 24-06-XX – initial implementation
###############################################################
class_name CustomDiePanel
extends PopupPanel

signal faces_chosen(faces: int)

@export var cdp_max_value: int = 999

var cdp_value: int = 6
var _confirmed: bool = false
var _overwrite: bool = false

@onready var _display: Label = $VBox/Display
@onready var _grid: GridContainer = $VBox/Grid


func _ready() -> void:
    _build_keypad()
    hide()
    visibility_changed.connect(_on_visibility_changed)


func _build_keypad() -> void:
    var order := ["7", "8", "9", "4", "5", "6", "1", "2", "3", "DEL", "0", "OK"]
    for key in order:
        var btn := Button.new()
        if key == "DEL":
            btn.text = "\u232b"
            btn.pressed.connect(_on_del_pressed)
        elif key == "OK":
            btn.text = "\u2714"
            btn.pressed.connect(_on_ok_pressed)
        else:
            btn.text = key
            btn.pressed.connect(_on_key.bind(key))
        btn.custom_minimum_size = Vector2(80, 80)
        btn.add_theme_font_size_override("font_size", 32)
        _grid.add_child(btn)


func open_panel_at(center: Vector2, last_value: int) -> void:
    cdp_value = clamp(last_value, 1, cdp_max_value)
    _overwrite = true
    _confirmed = false
    _update_display()
    position = center - Vector2(size) / 2
    popup()


func _update_display() -> void:
    _display.text = str(cdp_value)


func _on_key(ch: String) -> void:
    var s := "" if _overwrite or cdp_value == 0 else str(cdp_value)
    _overwrite = false
    s += ch
    cdp_value = clamp(int(s), 0, cdp_max_value)
    _update_display()


func _on_del_pressed() -> void:
    if _overwrite or cdp_value == 0:
        hide()
    else:
        var s := str(cdp_value)
        if s.length() > 1:
            s = s.substr(0, s.length() - 1)
        else:
            s = "0"
        cdp_value = int(s)
        if cdp_value == 0:
            hide()
        else:
            _update_display()


func _on_ok_pressed() -> void:
    if cdp_value == 0:
        hide()
        return
    _confirmed = true
    hide()
    emit_signal("faces_chosen", cdp_value)


func _on_visibility_changed() -> void:
    if not visible and not _confirmed:
        emit_signal("faces_chosen", 0)
