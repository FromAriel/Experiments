# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/DrawerController.gd
# Key Classes      • DrawerController – controls LowerPane slide
# Key Functions    • open_preview, open_full
# Critical Consts  • (none)
# Editor Exports   • DC_drawer_speed_IN: float
#                  • DC_full_height_IN: int
#                  • DC_preview_height_IN: int
#                  • DC_closed_height_IN: int
# Dependencies     • (none)
# Last Major Rev   • 24-07-09 – initial placeholder
###############################################################
extends Node

@export var DC_drawer_speed_IN: float = 300.0
@export var DC_full_height_IN: int = 960
@export var DC_preview_height_IN: int = 600
@export var DC_closed_height_IN: int = 0

@onready var DC_main_ui_SH: Control = get_node("/root/MainUI")
@onready var DC_lower_pane_SH: Control = DC_main_ui_SH.get_node("LowerPane")
@onready var DC_drag_handle_SH: Control = DC_lower_pane_SH.get_node("DragHandle")
var DC_dimmer_SH: ColorRect
var DC_state_SH: String = "closed"
var DC_dragging_IN: bool = false
var DC_start_y_IN: float = 0.0
var DC_start_height_IN: float = 0.0


func _ready() -> void:
    DC_lower_pane_SH.z_index = 2
    DC_lower_pane_SH.offset_top = -DC_full_height_IN
    DC_dimmer_SH = ColorRect.new()
    DC_dimmer_SH.color = Color(0, 0, 0, 0.5)
    DC_dimmer_SH.anchor_right = 1.0
    DC_dimmer_SH.anchor_bottom = 1.0
    DC_dimmer_SH.z_index = 1
    DC_dimmer_SH.visible = false
    DC_main_ui_SH.add_child(DC_dimmer_SH)
    DC_drag_handle_SH.gui_input.connect(_on_handle_gui_input)


func DC_log_IN(msg: String) -> void:
    if OS.is_debug_build():
        print_debug(msg)


func open_drawer() -> void:
    if DC_state_SH == "closed":
        open_preview()
    elif DC_state_SH == "preview":
        open_full()


func close_drawer() -> void:
    DC_state_SH = "closed"
    DC_snap_IN(DC_closed_height_IN, false)


func DC_open_preview_IN() -> void:
    DC_state_SH = "preview"
    DC_snap_IN(DC_preview_height_IN, true)


func DC_open_full_IN() -> void:
    DC_state_SH = "full"
    DC_snap_IN(DC_full_height_IN, false)


func DC_snap_IN(height: int, show_dimmer: bool) -> void:
    DC_dimmer_SH.visible = show_dimmer
    var tw: Tween = create_tween()
    tw.tween_property(DC_lower_pane_SH, "offset_top", -height, DC_drawer_speed_IN / 1000.0)
    DC_log_IN("snap" + str(height))


func open_preview() -> void:
    DC_open_preview_IN()


func open_full() -> void:
    DC_open_full_IN()


func _on_handle_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton or event is InputEventScreenTouch:
        if event.pressed:
            DC_dragging_IN = true
            DC_start_y_IN = event.position.y
            DC_start_height_IN = -DC_lower_pane_SH.offset_top
            DC_log_IN("start drag" + str(DC_start_height_IN))
        elif DC_dragging_IN:
            _end_drag(event.position.y)
            DC_dragging_IN = false
    elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and DC_dragging_IN:
        _update_drag(event.position.y)


func _update_drag(y: float) -> void:
    var dy: float = DC_start_y_IN - y
    var height: float = clamp(DC_start_height_IN + dy, DC_closed_height_IN, DC_full_height_IN)
    DC_lower_pane_SH.offset_top = -height
    DC_log_IN("drag" + str(height))


func _end_drag(y: float) -> void:
    var dy: float = DC_start_y_IN - y
    var height: float = clamp(DC_start_height_IN + dy, DC_closed_height_IN, DC_full_height_IN)
    if height < DC_preview_height_IN / 2:
        close_drawer()
    elif height < (DC_preview_height_IN + DC_full_height_IN) / 2:
        open_preview()
    else:
        open_full()
