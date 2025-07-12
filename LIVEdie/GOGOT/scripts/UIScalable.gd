###############################################################
# LIVEdie/GOGOT/scripts/UIScalable.gd
# Key Classes      • UIScalable – helper for resizable UI controls
# Key Functions    • update_ui_scale
# Critical Consts  • (none)
# Editor Exports   • SC_base_size_IN: Vector2 – Range base size
#                  • SC_base_font_IN: int – Base font size
# Dependencies     • UIStyleManager.gd
# Last Major Rev   • 24-07-13 – initial version
###############################################################
class_name UIScalable
extends Control

@export var SC_base_size_IN: Vector2 = Vector2(80, 80)
@export var SC_base_font_IN: int = 24


func _ready() -> void:
    var mgr := get_node("/root/UIStyleManager") as UIStyleManager
    mgr.scale_changed.connect(update_ui_scale)
    update_ui_scale(mgr.US_scale_SH)


func update_ui_scale(scale: float) -> void:
    custom_minimum_size = SC_base_size_IN * scale
    add_theme_font_size_override("font_size", int(SC_base_font_IN * scale))
    update_minimum_size()
