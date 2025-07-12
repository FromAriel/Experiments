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
@export var DC_closed_height_IN: int = 0

@onready var DC_main_ui_SH: Control = get_node("/root/MainUI")
@onready var DC_lower_pane_SH: Control = DC_main_ui_SH.get_node("LowerPane")
@onready var DC_handle_SH: Control = DC_lower_pane_SH.get_node("DragHandle")
var DC_dimmer_SH: ColorRect
var DC_state_SH: String = "closed"
var DC_start_y_IN: float = 0.0
var DC_start_height_IN: float = 0.0


func _log(msg: String) -> void:
    if OS.is_debug_build():
        print_debug(msg)


func _ready() -> void:
    DC_dimmer_SH = ColorRect.new()
    DC_dimmer_SH.color = Color.BLACK
    DC_dimmer_SH.modulate.a = 0.5
    DC_dimmer_SH.anchor_right = 1.0
    DC_dimmer_SH.anchor_bottom = 1.0
    DC_dimmer_SH.visible = false
    DC_main_ui_SH.add_child(DC_dimmer_SH)
    DC_lower_pane_SH.z_index = 2
    DC_dimmer_SH.z_index = 1
    DC_handle_SH.gui_input.connect(_on_handle_gui_input)
    DC_lower_pane_SH.offset_top = -DC_full_height_IN


func _on_handle_gui_input(ev: InputEvent) -> void:
    if ev is InputEventMouseButton:
        if ev.pressed:
            DC_start_y_IN = ev.position.y
            DC_start_height_IN = -DC_lower_pane_SH.offset_top
        else:
            _end_drag(DC_start_height_IN + DC_start_y_IN - ev.position.y)
    elif ev is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _update_drag(DC_start_height_IN + DC_start_y_IN - ev.position.y)


func _update_drag(height: float) -> void:
    height = clamp(height, 0, DC_full_height_IN)
    DC_lower_pane_SH.offset_top = -height
    if OS.is_debug_build():
        _log("drag height %s" % height)


func _end_drag(height: float) -> void:
    height = clamp(height, 0, DC_full_height_IN)
    if height < DC_preview_height_IN / 2:
        close_drawer()
    elif height < (DC_preview_height_IN + DC_full_height_IN) / 2:
        open_preview()
    else:
        open_full()


func _snap(height: int, show_dimmer: bool) -> void:
    DC_dimmer_SH.visible = show_dimmer
    create_tween().tween_property(
        DC_lower_pane_SH, "offset_top", -height, DC_drag_speed_IN / 1000.0
    )
    if OS.is_debug_build():
        _log("snap to %s" % height)


func open_preview() -> void:
    DC_state_SH = "preview"
    _snap(DC_preview_height_IN, true)


func open_full() -> void:
    DC_state_SH = "full"
    _snap(DC_full_height_IN, false)


func close_drawer() -> void:
    DC_state_SH = "closed"
    _snap(DC_closed_height_IN, false)
