###############################################################
# LIVEdie/GOGOT/scripts/UIStyleManager.gd
# Key Classes      • UIStyleManager – manages global UI scaling
# Key Functions    • set_scale
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • (none)
# Last Major Rev   • 25-07-12 – initial implementation
###############################################################
class_name UIStyleManager
extends Node
signal scale_changed(new_scale: float)

var US_scale_SH := 1.0


func set_scale(v: float) -> void:
    v = clamp(v, 0.5, 2.0)
    if not is_equal_approx(v, US_scale_SH):
        US_scale_SH = v
        scale_changed.emit(US_scale_SH)
