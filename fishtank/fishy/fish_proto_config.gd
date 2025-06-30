###############################################################
# fishtank/fishy/fish_proto_config.gd
# Key Classes      • FishProtoConfig – mass and spring presets
# Key Functions    • None
# Critical Consts  • None
# Editor Exports   • FC_head_mass_IN: float
#                   • FC_body_mass_IN: float
#                   • FC_tail_mass_IN: float
# Dependencies     • None
# Last Major Rev   • 24-07-05 – initial creation
###############################################################

class_name FishProtoConfig
extends Resource

# gdlint:disable = class-variable-name

@export var FC_head_mass_IN: float = 2.0
@export var FC_body_mass_IN: float = 1.0
@export var FC_tail_mass_IN: float = 0.5

@export var FC_head_stiffness_IN: float = 200.0
@export var FC_tail_stiffness_IN: float = 25.0
@export var FC_head_damping_IN: float = 30.0
@export var FC_tail_damping_IN: float = 5.0
# gdlint:enable = class-variable-name
