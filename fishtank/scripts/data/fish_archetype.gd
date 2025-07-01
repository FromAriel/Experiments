###############################################################
# fishtank/scripts/data/fish_archetype.gd
# Key Classes      • FishArchetype – archetype configuration
# Key Functions    • N/A
# Critical Consts  • None
# Editor Exports   • FA_name_IN: String
#                   • FA_behavior_IN: int
# Dependencies     • None
# Last Major Rev   • 24-06-28 – initial creation
###############################################################

class_name FishArchetype
extends Resource

# gdlint:disable = class-variable-name

"""
Holds configuration data defining behaviors and visuals for a fish archetype.

The `FA_behavior_IN` field specifies the default `FishBehavior` for fish using
this archetype. Values correspond to the enum defined in `BoidFish`.
"""

enum MovementMode { NORMAL, FLIP_TURN_ENABLED }

@export var FA_name_IN: String = ""
@export var FA_species_list_IN: Array[String] = []
@export var FA_placeholder_texture_IN: Texture2D
@export var FA_base_color_IN: Color = Color.WHITE
@export var FA_size_IN: float = 1.0
@export var FA_group_tendency_IN: float = 0.5
@export var FA_preferred_zone_IN: Vector3 = Vector3.ZERO
@export var FA_activity_pattern_IN: String = ""
@export var FA_aggression_level_IN: float = 0.0
@export var FA_alignment_weight_IN: float = 1.0
@export var FA_cohesion_weight_IN: float = 1.0
@export var FA_separation_weight_IN: float = 1.5
@export var FA_wander_weight_IN: float = 0.5
@export var FA_obstacle_bias_IN: float = 1.0
@export var FA_display_chance_IN: float = 0.0
@export var FA_burst_chance_IN: float = 0.0
@export var FA_chase_chance_IN: float = 0.0
@export var FA_jump_chance_IN: float = 0.0
@export var FA_rest_chance_IN: float = 0.0
@export var FA_behavior_IN: int = 0
@export var FA_turn_speed_IN: float = 5.0
@export var FA_burst_speed_IN: float = 200.0
@export var FA_idle_jitter_IN: float = 1.0
@export var FA_depth_variance_IN: float = 1.0
@export var FA_wander_speed_IN: float = 1.0
@export var FA_special_notes_IN: String = ""
@export var FA_movement_mode_IN: int = MovementMode.NORMAL
@export var FA_flip_turn_threshold_IN: float = deg_to_rad(160.0)
@export var FA_flip_duration_IN: float = 0.4
@export var FA_flip_speed_reduction_IN: float = 0.3
@export var FA_z_steer_weight_IN: float = 5.0
@export var FA_z_deform_min_x_IN: float = 0.6
@export var FA_z_deform_max_y_IN: float = 1.4
@export var FA_z_flip_threshold_IN: float = 0.9
# gdlint:enable = class-variable-name
