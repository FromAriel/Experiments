###############################################################
# LIVEdie/GOGOT/scripts/DrawerController.gd
# Robust 2-state snap logic: closed if dragged to/below handle,
# open if above threshold; never bounces open when pulled down.
###############################################################
extends Node

@export var DC_drag_speed_IN: float = 150.0
@export var DC_half_height_IN: int = 810
@export var DC_closed_height_IN: int = 48
@export var DC_snap_fraction_IN: float = 0.1  # Where to snap (0.3=30%)

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
                _finish_drag(ev)
            DC_dragging_IN = false
    elif ev is InputEventMouseMotion and DC_dragging_IN:
        var new_h = DC_start_h_IN + (DC_start_y_IN - ev.position.y)
        _update_drag(new_h)

func _update_drag(height: float) -> void:
    height = clamp(height, DC_closed_height_IN, DC_half_height_IN)
    DC_lower_pane_SH.offset_top = -height
    if OS.is_debug_build():
        _log("drag height %s" % height)

func _finish_drag(ev: InputEvent = null) -> void:
    var h: float = -DC_lower_pane_SH.offset_top
    var snap_point: float = DC_closed_height_IN + (DC_half_height_IN - DC_closed_height_IN) * DC_snap_fraction_IN

    # Special: If mouse released at/below handle (dragging down to or below), ALWAYS close.
    var released_y = 0.0
    if ev != null and ev is InputEventMouseButton:
        released_y = ev.position.y

    # If mouse is back at (or below) where drag started, treat as closed (very forgiving).
    if released_y >= DC_start_y_IN - 5.0:
        close_drawer()
        return

    # Standard: snap logic based on drag height
    if h < snap_point:
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
