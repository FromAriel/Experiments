###############################################################
# fishtank/scripts/data/tank_environment.gd
# Key Classes      • TankEnvironment – tank parameters and population
# Key Functions    • N/A
# Critical Consts  • None
# Editor Exports   • TE_size_IN: Vector3
# Dependencies     • FishInstance
# Last Major Rev   • 24-06-28 – initial creation
###############################################################

class_name TankEnvironment
extends Resource

# gdlint:disable = class-variable-name

"""
Encapsulates the environment settings and fish population of the aquarium.
"""

@export var TE_size_IN: Vector3 = Vector3(16.0, 9.0, 5.5)
@export var TE_boundaries_SH: AABB = AABB()
@export var TE_decor_objects_SH: Array[PackedScene] = []
@export var TE_lighting_params_IN: Dictionary = {}
@export var TE_water_params_IN: Dictionary = {}
@export var TE_population_SH: Array[FishInstance] = []
# gdlint:enable = class-variable-name
