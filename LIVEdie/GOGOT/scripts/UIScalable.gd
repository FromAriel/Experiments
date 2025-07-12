###############################################################
# LIVEdie/GOGOT/scripts/UIScalable.gd
# Key Classes      • UIScalable – adjusts node size based on UI scale
# Key Functions    • update_ui_scale
# Critical Consts  • (none)
# Editor Exports   • US_base_size_IN: Vector2
#                  • US_base_font_IN: int
# Dependencies     • UIStyleManager.gd
# Last Major Rev   • 25-07-12 – initial implementation
###############################################################
class_name UIScalable
extends Control

@export var US_base_size_IN: Vector2 = Vector2(80, 80)
@export var US_base_font_IN: int = 24


func _ready() -> void:
    var manager := get_node("/root/UIStyleManager")
    manager.scale_changed.connect(update_ui_scale)
    update_ui_scale(manager.US_scale_SH)


func update_ui_scale(scale: float) -> void:
    custom_minimum_size = US_base_size_IN * scale
    add_theme_font_size_override("font_size", int(US_base_font_IN * scale))
