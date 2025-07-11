###############################################################
# LIVEdie/GOGOT/scripts/RollTab.gd
# Key Classes      • RollTab – handles roll animation placeholder
# Key Functions    • _on_roll_executed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • UIEventBus.gd
# Last Major Rev   • 24-07-11 – initial stub
###############################################################
class_name RollTab
extends Control


func _ready() -> void:
    get_node("/root/RollExecutor").roll_executed.connect(_on_roll_executed)


func _on_roll_executed(result: Dictionary) -> void:
    print("Result:", result)
