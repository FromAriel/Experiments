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
# gdlint:enable = class-variable-name
