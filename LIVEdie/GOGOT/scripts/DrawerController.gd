# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/DrawerController.gd
# Key Classes      • DrawerController – controls LowerPane slide
# Key Functions    • DC_open_drawer_IN, DC_close_drawer_IN
# Critical Consts  • (none)
# Editor Exports   • DC_drawer_speed_IN: float
#                  • DC_open_height_IN: int
#                  • DC_preview_height_IN: int
#                  • DC_closed_height_IN: int
# Dependencies     • (none)
# Last Major Rev   • 24-07-09 – initial placeholder
###############################################################
extends Node

@export var DC_drawer_speed_IN: float = 300.0
@export var DC_open_height_IN: int = 960
@export var DC_preview_height_IN: int = 600
@export var DC_closed_height_IN: int = 0

@onready var DC_main_ui_SH: Control = get_node("/root/MainUI")
@onready var DC_lower_pane_SH: Control = DC_main_ui_SH.get_node("LowerPane")
var DC_dimmer_SH: ColorRect
var DC_locked_IN: bool = true
var DC_state_SH: String = "closed"
var DC_dragging_IN: bool = false
var DC_start_y_IN: float = 0.0
var DC_last_unlock_time_IN: float = 0.0


func _ready() -> void:
    DC_dimmer_SH = ColorRect.new()
    DC_dimmer_SH.color = Color(0, 0, 0, 0.5)
    DC_dimmer_SH.anchor_right = 1.0
    DC_dimmer_SH.anchor_bottom = 1.0
    DC_dimmer_SH.visible = false
    DC_main_ui_SH.add_child(DC_dimmer_SH)
    DC_dimmer_SH.z_index = DC_lower_pane_SH.z_index - 1
    DC_lower_pane_SH.offset_top = -DC_closed_height_IN


func open_drawer() -> void:
    if DC_state_SH == "closed":
        DC_open_preview_IN()
    elif DC_state_SH == "preview":
        DC_open_full_IN()


func close_drawer() -> void:
    DC_state_SH = "closed"
    DC_dimmer_SH.visible = false
    create_tween().tween_property(
        DC_lower_pane_SH, "offset_top", -DC_closed_height_IN, DC_drawer_speed_IN / 1000.0
    )


func DC_open_preview_IN() -> void:
    DC_state_SH = "preview"
    DC_dimmer_SH.visible = true
    create_tween().tween_property(
        DC_lower_pane_SH, "offset_top", -DC_preview_height_IN, DC_drawer_speed_IN / 1000.0
    )


func DC_open_full_IN() -> void:
    DC_state_SH = "full"
    DC_dimmer_SH.visible = false
    create_tween().tween_property(
        DC_lower_pane_SH, "offset_top", -DC_open_height_IN, DC_drawer_speed_IN / 1000.0
    )


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton or event is InputEventScreenTouch:
        if event.pressed:
            DC_start_y_IN = event.position.y
            DC_dragging_IN = true
        elif DC_dragging_IN:
            var dy: float = DC_start_y_IN - event.position.y
            if dy > 50:
                _handle_swipe_up()
            elif dy < -50:
                _handle_swipe_down()
            DC_dragging_IN = false
    elif event is InputEventMouseMotion and DC_dragging_IN and not DC_locked_IN:
        var dy: float = DC_start_y_IN - event.position.y
        var new_h: float = clamp(dy, 0, DC_open_height_IN)
        DC_lower_pane_SH.offset_top = -new_h


func _handle_swipe_up() -> void:
    if DC_locked_IN:
        var now := Time.get_ticks_msec()
        if now - DC_last_unlock_time_IN < 1000:
            DC_locked_IN = false
            DC_last_unlock_time_IN = 0.0
            DC_open_full_IN()
        else:
            DC_last_unlock_time_IN = now
    else:
        if DC_state_SH == "closed":
            DC_open_preview_IN()
        elif DC_state_SH == "preview":
            DC_open_full_IN()


func _handle_swipe_down() -> void:
    if DC_state_SH != "closed":
        close_drawer()
