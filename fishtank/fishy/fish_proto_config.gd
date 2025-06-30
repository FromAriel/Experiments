###############################################################
# fishtank/fishy/fish_proto_config.gd
# Key Classes      • FishProtoConfig – presets for prototype fish
# Editor Exports   • FPC_head_mass_IN: float
#                   • FPC_body_mass_IN: float
#                   • FPC_tail_mass_IN: float
#                   • FPC_head_stiffness_IN: float
#                   • FPC_tail_stiffness_IN: float
#                   • FPC_damping_IN: float
#                   • FPC_body_segments_IN: int
#                   • FPC_tail_segments_IN: int
# Dependencies     • None
# Last Major Rev   • 24-07-06 – initial creation
###############################################################

class_name FishProtoConfig
extends Resource

# gdlint:disable = class-variable-name

@export var FPC_head_mass_IN: float = 2.0
@export var FPC_body_mass_IN: float = 1.0
@export var FPC_tail_mass_IN: float = 0.5

@export var FPC_head_stiffness_IN: float = 200.0
@export var FPC_tail_stiffness_IN: float = 25.0
@export var FPC_damping_IN: float = 5.0

@export var FPC_body_segments_IN: int = 4
@export var FPC_tail_segments_IN: int = 6
@export var FPC_segment_spacing_IN: float = 16.0
# gdlint:enable = class-variable-name
