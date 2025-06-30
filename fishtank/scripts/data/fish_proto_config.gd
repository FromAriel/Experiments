###############################################################
# fishtank/scripts/data/fish_proto_config.gd
# Key Classes      • FishProtoConfig – soft-body fish test parameters
# Key Functions    • N/A
# Critical Consts  • None
# Editor Exports   • FP_segment_masses_IN: Array
#                   • FP_stiffness_IN: Array
#                   • FP_damping_IN: Array
# Dependencies     • None
# Last Major Rev   • 24-07-05 – initial creation
###############################################################

class_name FishProtoConfig
extends Resource

# gdlint:disable = class-variable-name

"""
Configuration resource describing mass and spring presets for the
`FishProto` scene. Arrays are ordered from head to tail.
"""

@export var FP_segment_masses_IN: Array[float] = []
@export var FP_stiffness_IN: Array[float] = []
@export var FP_damping_IN: Array[float] = []

# gdlint:enable = class-variable-name
