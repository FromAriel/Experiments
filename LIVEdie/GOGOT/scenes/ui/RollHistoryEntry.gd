###############################################################
# LIVEdie/GOGOT/scenes/ui/RollHistoryEntry.gd
# Key Classes      • RollHistoryEntry – row in history list
# Key Functions    • _on_Header_gui_input
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • UIScalable.gd
# Last Major Rev   • 24-07-14 – initial version
###############################################################
class_name RollHistoryEntry
extends VBoxContainer

signal toggled(debug_visible: bool)

@onready var RH_expanded_SH: VBoxContainer = $BG/Main/Expanded
@onready var RH_json_label_SH: Label = $BG/Main/Expanded/JSONLabel
@onready var RH_arrow_SH: TextureRect = $BG/Main/Header/ArrowIcon
var RH_stage_SH := 0


func _on_Header_gui_input(ev: InputEvent) -> void:
    if ev is InputEventMouseButton and ev.pressed:
        RH_stage_SH = (RH_stage_SH + 1) % 3
        RH_expanded_SH.visible = RH_stage_SH > 0
        RH_json_label_SH.visible = RH_stage_SH == 2
        RH_arrow_SH.rotation_degrees = 0 if RH_stage_SH == 0 else 90
        emit_signal("toggled", RH_json_label_SH.visible)
