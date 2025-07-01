# =====================================================================
#  File: res://scripts/boids/boid_system.gd
#  Description: Pure-logic boid simulation (Godot 4.4.1-ready)
#               * Adds safe fallback when no FishArchetype resources
#                 are assigned in the Inspector.
#               * Retains existing behaviour; no 3.x remnants.
# =====================================================================

extends Node
class_name BoidSystem
## Fixed-timestep simulation of all fish (pure logic).

# --------------------------------------------------------------------- #
#  Constants / Inspector                                                #
# --------------------------------------------------------------------- #
const FB_FIXED_DT_SH: float  = 1.0 / 120.0          # Simulation step (s).
const FB_CELL_SIZE_SH: float = 100.0                # Spatial-hash cell size.

@export_category("Tank")
@export var FB_tank_size_IN: Vector3 = Vector3(1920.0, 1080.0, 1080.0)

@export_category("Archetypes")
@export var FB_archetypes_IN: Array[FishArchetype] = []   # Filled in Editor.

# --------------------------------------------------------------------- #
#  Runtime data                                                         #
# --------------------------------------------------------------------- #
var FB_fish_array_UP: Array[BoidFish]          = []        # All fish.
var FB_spatial_hash_UP: Dictionary             = {}        # Vector3i → PackedInt32Array
var FB_rand_SH: RandomNumberGenerator          = RandomNumberGenerator.new()
var FB_accumulated_time_UP: float              = 0.0
var FB_last_snapshot_UP: Array                 = []        # Immutable frame snapshot.

# --------------------------------------------------------------------- #
#  Lifecycle                                                            #
# --------------------------------------------------------------------- #
func _ready() -> void:
    FB_rand_SH.randomize()
    _ensure_archetypes()                                  # Provide fallback.


func _physics_process(delta: float) -> void:
    FB_accumulated_time_UP += delta

    while FB_accumulated_time_UP >= FB_FIXED_DT_SH:
        _step_sim(FB_FIXED_DT_SH)
        FB_accumulated_time_UP -= FB_FIXED_DT_SH


# --------------------------------------------------------------------- #
#  Public API                                                           #
# --------------------------------------------------------------------- #
func set_fish_count(count: int) -> void:
    var target: int  = max(count, 0)
    var current: int = FB_fish_array_UP.size()

    if target > current:
        _add_fish(target - current)
    else:
        _remove_fish(current - target)


func get_snapshot() -> Array:
    return FB_last_snapshot_UP.duplicate()


func get_neighbors(fish: BoidFish, radius: float) -> Array[BoidFish]:
    ## Returns neighbouring fish within *radius* of *fish*.
    var results: Array[BoidFish] = []

    var center_cell: Vector3i = _position_to_hash(fish.BF_head_pos_UP)
    var cells_offset: int     = int(ceil(radius / FB_CELL_SIZE_SH))

    for dz: int in range(-cells_offset, cells_offset + 1):
        for dy: int in range(-cells_offset, cells_offset + 1):
            for dx: int in range(-cells_offset, cells_offset + 1):
                var cell: Vector3i = center_cell + Vector3i(dx, dy, dz)

                if FB_spatial_hash_UP.has(cell):
                    var indices: PackedInt32Array = FB_spatial_hash_UP[cell]
                    for idx: int in indices:
                        var other: BoidFish = FB_fish_array_UP[idx]

                        if other == fish:
                            continue
                        else:
                            pass

                        if fish.BF_head_pos_UP.distance_to(other.BF_head_pos_UP) <= radius:
                            results.append(other)
                        else:
                            pass
                else:
                    pass

    return results


# --------------------------------------------------------------------- #
#  Internal simulation helpers                                          #
# --------------------------------------------------------------------- #
func _ensure_archetypes() -> void:
    ## Guarantees at least one archetype exists to avoid runtime errors.
    if FB_archetypes_IN.is_empty():
        push_warning("BoidSystem: No FishArchetype resources assigned – generating default archetype.")
        var default_arch: FishArchetype = FishArchetype.new()   # Uses class defaults.
        FB_archetypes_IN.append(default_arch)
    else:
        pass


func _add_fish(amount: int) -> void:
    if amount <= 0:
        return
    else:
        pass

    _ensure_archetypes()

    for _i in range(amount):
        # -------------------------------------------------------------- #
        #  Randomly choose an archetype                                  #
        # -------------------------------------------------------------- #
        var arch_index: int         = FB_rand_SH.randi_range(0, FB_archetypes_IN.size() - 1)
        var archetype: FishArchetype = FB_archetypes_IN[arch_index]

        # -------------------------------------------------------------- #
        #  Random starting position & velocity                           #
        # -------------------------------------------------------------- #
        var head_pos: Vector3 = Vector3(
            FB_rand_SH.randf_range(0.0, FB_tank_size_IN.x),
            FB_rand_SH.randf_range(0.0, FB_tank_size_IN.y),
            FB_rand_SH.randf_range(0.0, FB_tank_size_IN.z)
        )

        var velocity: Vector3 = Vector3(
            FB_rand_SH.randf_range(-1.0, 1.0),
            FB_rand_SH.randf_range(-1.0, 1.0),
            FB_rand_SH.randf_range(-1.0, 1.0)
        ).normalized() * archetype.FA_max_speed_IN * 0.5

        var fish: BoidFish = BoidFish.new(archetype, head_pos, velocity, arch_index)
        FB_fish_array_UP.append(fish)


func _remove_fish(amount: int) -> void:
    if amount <= 0:
        return
    else:
        pass

    var new_size: int = max(FB_fish_array_UP.size() - amount, 0)
    FB_fish_array_UP.resize(new_size)


func _step_sim(dt: float) -> void:
    _update_spatial_hash()

    for fish: BoidFish in FB_fish_array_UP:
        fish.update_behavior(dt, self)

    for fish: BoidFish in FB_fish_array_UP:
        fish.integrate(dt)

    _take_snapshot()


func _update_spatial_hash() -> void:
    FB_spatial_hash_UP.clear()

    for index: int in range(FB_fish_array_UP.size()):
        var fish: BoidFish    = FB_fish_array_UP[index]
        var cell: Vector3i    = _position_to_hash(fish.BF_head_pos_UP)

        if FB_spatial_hash_UP.has(cell) == false:
            FB_spatial_hash_UP[cell] = PackedInt32Array()
        else:
            pass

        var arr: PackedInt32Array = FB_spatial_hash_UP[cell]
        arr.push_back(index)
        FB_spatial_hash_UP[cell] = arr


func _position_to_hash(pos: Vector3) -> Vector3i:
    var xi: int = int(floor(pos.x / FB_CELL_SIZE_SH))
    var yi: int = int(floor(pos.y / FB_CELL_SIZE_SH))
    var zi: int = int(floor(pos.z / FB_CELL_SIZE_SH))
    return Vector3i(xi, yi, zi)


func _take_snapshot() -> void:
    FB_last_snapshot_UP.clear()

    for fish: BoidFish in FB_fish_array_UP:
        FB_last_snapshot_UP.append({
            "head":       fish.BF_head_pos_UP,
            "tail":       fish.BF_tail_pos_UP,
            "species_id": fish.BF_species_id_SH
        })
