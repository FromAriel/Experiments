###############################################################
# fishtank/scripts/data/fish_instance.gd
# Key Classes      • FishInstance – runtime fish data
# Key Functions    • N/A
# Critical Consts  • None
# Editor Exports   • FI_unique_id_IN: int
# Dependencies     • FishArchetype
# Last Major Rev   • 24-06-28 – initial creation
###############################################################

class_name FishInstance
extends Resource

# gdlint:disable = class-variable-name

"""
Data container for a single fish in the tank at runtime.
"""

@export var FI_unique_id_IN: int = 0
@export var FI_position_UP: Vector3 = Vector3.ZERO
@export var FI_velocity_UP: Vector3 = Vector3.ZERO
@export var FI_state_SH: String = ""
@export var FI_archetype_ref_SH: FishArchetype
@export var FI_assigned_species_IN: String = ""
@export var FI_age_UP: float = 0.0
@export var FI_animation_state_UP: String = ""
@export var FI_selected_SH: bool = false
# gdlint:enable = class-variable-name
