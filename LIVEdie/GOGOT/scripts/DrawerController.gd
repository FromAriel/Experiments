# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/DrawerController.gd
# Key Classes      • DrawerController – controls LowerPane slide
# Key Functions    • open_preview, open_full, close_drawer
# Critical Consts  • (none)
# Editor Exports   • DC_drag_speed_IN: float
#                  • DC_full_height_IN: int
#                  • DC_preview_height_IN: int
#                  • DC_closed_height_IN: int
# Dependencies     • (none)
# Last Major Rev   • 24-07-13 – implement drag logic
###############################################################
extends Node

@export var DC_drag_speed_IN: float = 300.0
@export var DC_full_height_IN: int = 960
@export var DC_preview_height_IN: int = 600
@export var DC_closed_height_IN: int = 48

@onready var DC_main_ui_SH: Control = get_node("/root/MainUI")
@onready var DC_lower_pane_SH: Control = DC_main_ui_SH.get_node("LowerPane")
@onready var DC_handle_SH: Control = DC_lower_pane_SH.get_node("DragHandle")
var DC_dimmer_SH: ColorRect
var DC_state_SH: String = "closed"
var DC_dragging_IN: bool = false
var DC_start_y_IN: float = 0.0
var DC_start_h_IN: float = 0.0


func _log(msg: String) -> void:
    if OS.is_debug_build():
        print_debug(msg)


func _ready() -> void:
    DC_dimmer_SH = ColorRect.new()
    DC_dimmer_SH.color = Color.BLACK
    DC_dimmer_SH.modulate.a = 0.0
    DC_dimmer_SH.anchor_right = 1.0
    DC_dimmer_SH.anchor_bottom = 1.0
    DC_dimmer_SH.visible = false
    DC_main_ui_SH.add_child(DC_dimmer_SH)
    DC_lower_pane_SH.z_index = 2
    DC_dimmer_SH.z_index = 1
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
    height = clamp(height, DC_closed_height_IN, DC_full_height_IN)
    DC_lower_pane_SH.offset_top = -height
    _update_dimmer(height)
    if OS.is_debug_build():
        _log("drag height %s" % height)


func _update_dimmer(height: float) -> void:
    if height < DC_preview_height_IN:
        DC_dimmer_SH.visible = false
        DC_dimmer_SH.modulate.a = 0.0
        return

    var alpha := (height - DC_preview_height_IN) / (DC_full_height_IN - DC_preview_height_IN) * 0.5
    DC_dimmer_SH.modulate.a = alpha
    DC_dimmer_SH.visible = alpha > 0.0


func _finish_drag() -> void:
    var h: float = -DC_lower_pane_SH.offset_top
    var snap_closed: float = DC_closed_height_IN * 1.5
    var snap_preview: float = (DC_preview_height_IN + DC_full_height_IN) * 0.5

    if h < snap_closed:
        close_drawer()
    elif h < snap_preview:
        open_preview()
    else:
        open_full()


func _snap(height: int, show_dimmer: bool) -> void:
    var alpha: float = 0.5 if show_dimmer else 0.0
    DC_dimmer_SH.visible = true
    var t: Tween = create_tween()
    t.tween_property(DC_lower_pane_SH, "offset_top", -height, DC_drag_speed_IN / 1000.0)
    t.tween_property(DC_dimmer_SH, "modulate:a", alpha, DC_drag_speed_IN / 1000.0)
    t.finished.connect(func(): DC_dimmer_SH.visible = alpha > 0.0)
    if OS.is_debug_build():
        _log("snap to %s" % height)
    if OS.has_feature("mobile"):
        Input.vibrate_handheld(30)


func open_preview() -> void:
    DC_state_SH = "preview"
    _snap(DC_preview_height_IN, true)


func open_full() -> void:
    DC_state_SH = "full"
    _snap(DC_full_height_IN, false)


func close_drawer() -> void:
    DC_state_SH = "closed"
    _snap(DC_closed_height_IN, false)
