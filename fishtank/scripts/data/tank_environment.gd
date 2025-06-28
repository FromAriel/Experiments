###############################################################
# fishtank/scripts/data/tank_environment.gd
# Key Classes      • TankEnvironment – tank parameters and population
# Key Functions    • TE_update_bounds_IN() – calculate tank AABB
# Critical Consts  • None
# Editor Exports   • TE_size_IN: Vector3
# Dependencies     • FishInstance
# Last Major Rev   • 24-06-30 – compute tank bounds
###############################################################

class_name TankEnvironment
extends Resource

# gdlint:disable = class-variable-name,function-name

"""
Encapsulates the environment settings and fish population of the aquarium.
"""

@export var TE_size_IN: Vector3 = Vector3(16.0, 9.0, 5.5)
@export var TE_boundaries_SH: AABB = AABB()
@export var TE_decor_objects_SH: Array[PackedScene] = []
@export var TE_lighting_params_IN: Dictionary = {}
@export var TE_water_params_IN: Dictionary = {}
@export var TE_population_SH: Array[FishInstance] = []


func _init() -> void:
    TE_update_bounds_IN()


func TE_update_bounds_IN() -> void:
    TE_boundaries_SH = AABB(
        Vector3(-TE_size_IN.x / 2.0, -TE_size_IN.y / 2.0, -TE_size_IN.z / 2.0), TE_size_IN
    )
# gdlint:enable = class-variable-name,function-name
