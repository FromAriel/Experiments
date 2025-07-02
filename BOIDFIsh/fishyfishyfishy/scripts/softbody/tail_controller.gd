# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/fishyfishyfishy/scripts/softbody/tail_controller.gd
# Key Classes      • TailController – provides jittery target motion
# Key Functions    • _physics_process() – procedural sine noise
# Critical Consts  • none
# Editor Exports   • amplitude, speed
# Dependencies     • none
# Last Major Rev   • 24-04-2024 – initial creation
###############################################################

extends Node2D
class_name TailController

# ------------------------------------------------------------------ #
#  Inspector                                                         #
# ------------------------------------------------------------------ #
@export var TC_amplitude_IN: float = 1.0
@export var TC_speed_IN: float = 2.0

# ------------------------------------------------------------------ #
#  Runtime data                                                      #
# ------------------------------------------------------------------ #
var TC_phase_UP: float = 0.0


# ------------------------------------------------------------------ #
#  Physics update                                                    #
# ------------------------------------------------------------------ #
func _physics_process(delta: float) -> void:
    TC_phase_UP += delta * TC_speed_IN
    position.y = sin(TC_phase_UP) * TC_amplitude_IN
