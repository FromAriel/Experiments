###############################################################
# fishtank/scripts/data/boid_system_config.gd
# Key Classes      • BoidSystemConfig – default boid parameters
# Key Functions    • N/A
# Critical Consts  • None
# Editor Exports   • BC_default_alignment_IN: float
# Dependencies     • None
# Last Major Rev   • 24-06-28 – initial creation
###############################################################

class_name BoidSystemConfig
extends Resource

# gdlint:disable = class-variable-name

"""
Configurable constants controlling the default boid behavior parameters.
"""

@export var BC_default_alignment_IN: float = 1.0
@export var BC_default_cohesion_IN: float = 1.0
@export var BC_default_separation_IN: float = 1.5
@export var BC_default_wander_IN: float = 0.5
@export var BC_max_speed_IN: float = 200.0
@export var BC_max_force_IN: float = 50.0
@export var BC_fish_count_min_IN: int = 50
@export var BC_fish_count_max_IN: int = 60
@export var BC_archetype_count_min_IN: int = 3
@export var BC_archetype_count_max_IN: int = 5
@export var BC_misc_params_SH: Dictionary = {}
@export var BC_soft_contain_k: float = 2.0
@export var BC_reflect_damping: float = 0.8
@export var BC_noise_freq_base: float = 1.0
@export var BC_thread_threshold: int = 500
@export var BC_depth_speed_front: float = 200.0
@export var BC_depth_speed_back: float = 80.0
@export var BS_boundary_mode_IN: int = 1
# gdlint:enable = class-variable-name
