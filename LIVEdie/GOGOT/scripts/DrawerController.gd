# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/DrawerController.gd
# Key Classes      • DrawerController – controls LowerPane slide
# Key Functions    • open_half, close_drawer
# Critical Consts  • (none)
# Editor Exports   • DC_drag_speed_IN: float
#                  • DC_half_height_IN: int
#                  • DC_closed_height_IN: int
# Dependencies     • (none)
# Last Major Rev   • 24-07-13 – simplify to half-open drawer
###############################################################
extends Node

@export var DC_drag_speed_IN: float = 350.0
@export var DC_half_height_IN: int = 700
@export var DC_closed_height_IN: int = 48

@onready var DC_main_ui_SH: Control = get_node("/root/MainUI")
@onready var DC_lower_pane_SH: Control = DC_main_ui_SH.get_node("LowerPane")
@onready var DC_handle_SH: Control = DC_lower_pane_SH.get_node("DragHandle")
var DC_state_SH: String = "closed"
var DC_dragging_IN: bool = false
var DC_start_y_IN: float = 0.0
var DC_start_h_IN: float = 0.0


func _log(msg: String) -> void:
    if OS.is_debug_build():
        print_debug(msg)


func _ready() -> void:
    DC_lower_pane_SH.z_index = 1
    DC_handle_SH.gui_input.connect(_on_handle_gui_input)
    DC_lower_pane_SH.gui_input.connect(_on_handle_gui_input)
    DC_lower_pane_SH.offset_top = -DC_closed_height_IN
    DC_state_SH = "closed"
    DC_handle_SH.mouse_default_cursor_shape = Control.CURSOR_DRAG


func _on_handle_gui_input(ev: InputEvent) -> void:
    if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
        if ev.pressed:
            DC_dragging_IN = true
            DC_start_y_IN = ev.position.y
            DC_start_h_IN = -DC_lower_pane_SH.offset_top
        else:
            if DC_dragging_IN:
                _finish_drag()
            DC_dragging_IN = false
    elif ev is InputEventMouseMotion and DC_dragging_IN:
        var new_h = DC_start_h_IN + (DC_start_y_IN - ev.position.y)
        _update_drag(new_h)


func _update_drag(height: float) -> void:
    height = clamp(height, DC_closed_height_IN, DC_half_height_IN)
    DC_lower_pane_SH.offset_top = -height
    if OS.is_debug_build():
        _log("drag height %s" % height)


func _finish_drag() -> void:
    var h: float = -DC_lower_pane_SH.offset_top
    var snap_closed: float = DC_half_height_IN * 0.5

    if h < snap_closed:
        close_drawer()
    else:
        open_half()


func _snap(height: int) -> void:
    var t: Tween = create_tween()
    t.tween_property(DC_lower_pane_SH, "offset_top", -height, DC_drag_speed_IN / 1000.0)
    if OS.is_debug_build():
        _log("snap to %s" % height)
    if OS.has_feature("mobile"):
        Input.vibrate_handheld(30)


func open_half() -> void:
    DC_state_SH = "half"
    _snap(DC_half_height_IN)


func close_drawer() -> void:
    DC_state_SH = "closed"
    _snap(DC_closed_height_IN)
