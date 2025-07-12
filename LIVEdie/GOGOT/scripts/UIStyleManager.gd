###############################################################
# LIVEdie/GOGOT/scripts/UIStyleManager.gd
# Key Classes      • UIStyleManager – global UI scaling manager
# Key Functions    • set_scale
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • (none)
# Last Major Rev   • 24-07-13 – add dynamic UI scaling
###############################################################
class_name UIStyleManager
extends Node
signal scale_changed(new_scale: float)

var US_scale_SH: float = 1.0:
    set = set_scale


func set_scale(v: float) -> void:
    v = clamp(v, 0.5, 2.0)
    if !is_equal_approx(v, US_scale_SH):
        US_scale_SH = v
        emit_signal("scale_changed", US_scale_SH)
