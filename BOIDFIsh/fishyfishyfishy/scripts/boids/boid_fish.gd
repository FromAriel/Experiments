extends RefCounted
class_name BoidFish
## Pure-logic fish; no nodes, no rendering – holds state and behaviour.

# --------------------------------------------------------------------- #
#  Runtime state                                                        #
# --------------------------------------------------------------------- #
var BF_head_pos_UP: Vector3 = Vector3.ZERO
var BF_tail_pos_UP: Vector3 = Vector3.ZERO
var BF_velocity_UP: Vector3 = Vector3.ZERO
var BF_accel_UP: Vector3 = Vector3.ZERO

# --------------------------------------------------------------------- #
#  Constants / Inspector                                                #
# --------------------------------------------------------------------- #
var BF_archetype_IN: FishArchetype
var BF_species_id_SH: int = 0
const BF_SEGMENT_RATIO_SH: float = 0.25

# Steering radii (in pixels, 3-D space).
const BF_SEPARATION_RADIUS_SH: float = 120.0
const BF_ALIGNMENT_RADIUS_SH: float = 180.0
const BF_COHESION_RADIUS_SH: float = 180.0

# Steering weights.
const BF_SEPARATION_WEIGHT_SH: float = 1.6
const BF_ALIGNMENT_WEIGHT_SH: float = 1.0
const BF_COHESION_WEIGHT_SH: float = 0.9
const BF_DEPTH_PREF_WEIGHT_SH: float = 0.35
const BF_WALL_AVOID_WEIGHT_SH: float = 2.0

# Wall avoid margin (distance from tank wall that triggers soft push).
const BF_WALL_MARGIN_SH: float = 60.0

# Clamp for the resulting acceleration (prevents “teleport” jumps).
const BF_MAX_FORCE_SH: float = 250.0

# --------------------------------------------------------------------- #
#  Construction                                                         #
# --------------------------------------------------------------------- #
func _init(
        archetype: FishArchetype,
        head_pos: Vector3,
        initial_velocity: Vector3,
        species_id: int
) -> void:
    BP_validate_inputs(archetype)

    BF_archetype_IN = archetype
    BF_head_pos_UP = head_pos
    BF_velocity_UP = initial_velocity
    BF_species_id_SH = species_id

    var segment_length: float = BF_archetype_IN.FA_size_vec3_IN.z * BF_SEGMENT_RATIO_SH
    if initial_velocity.length() > 0.0:
        BF_tail_pos_UP = BF_head_pos_UP - initial_velocity.normalized() * segment_length
    else:
        BF_tail_pos_UP = BF_head_pos_UP - Vector3.FORWARD * segment_length


# --------------------------------------------------------------------- #
#  Public API                                                           #
# --------------------------------------------------------------------- #
func update_behavior(delta: float, boid_system: BoidSystem) -> void:
    # ---------------------------------------------------------------- #
    #  1. Query neighbours via spatial hash                            #
    # ---------------------------------------------------------------- #
    var neighbours: Array[BoidFish] = boid_system.get_neighbors(self, BF_ALIGNMENT_RADIUS_SH)

    # Vectors accumulating the various steering components.
    var sep: Vector3 = Vector3.ZERO
    var ali: Vector3 = Vector3.ZERO
    var coh: Vector3 = Vector3.ZERO

    # Counters for averaging.
    var count_sep: int = 0
    var count_ali: int = 0
    var count_coh: int = 0

    for other: BoidFish in neighbours:
        var offset: Vector3 = BF_head_pos_UP - other.BF_head_pos_UP
        var dist: float = offset.length()

        if dist <= 0.0:
            continue
        else:
            pass

        # Separation.
        if dist < BF_SEPARATION_RADIUS_SH:
            sep += offset.normalized() / dist
            count_sep += 1
        else:
            pass

        # Alignment.
        if dist < BF_ALIGNMENT_RADIUS_SH:
            ali += other.BF_velocity_UP
            count_ali += 1
        else:
            pass

        # Cohesion.
        if dist < BF_COHESION_RADIUS_SH:
            coh += other.BF_head_pos_UP
            count_coh += 1
        else:
            pass

    # Average and convert into steering vectors (desired − current vel).
    var steer_sep: Vector3 = Vector3.ZERO
    if count_sep > 0:
        sep /= float(count_sep)
        steer_sep = sep.normalized() * BF_archetype_IN.FA_max_speed_IN - BF_velocity_UP
    else:
        pass

    var steer_ali: Vector3 = Vector3.ZERO
    if count_ali > 0:
        ali /= float(count_ali)
        steer_ali = ali.normalized() * BF_archetype_IN.FA_max_speed_IN - BF_velocity_UP
    else:
        pass

    var steer_coh: Vector3 = Vector3.ZERO
    if count_coh > 0:
        coh /= float(count_coh)
        var to_center: Vector3 = coh - BF_head_pos_UP
        steer_coh = to_center.normalized() * BF_archetype_IN.FA_max_speed_IN - BF_velocity_UP
    else:
        pass

    # ---------------------------------------------------------------- #
    #  2. Depth preference (Z-axis)                                     #
    # ---------------------------------------------------------------- #
    var preferred_z: float = boid_system.FB_tank_size_IN.z * BF_archetype_IN.FA_depth_pref_IN
    var depth_error: float = preferred_z - BF_head_pos_UP.z
    var steer_depth: Vector3 = Vector3(0.0, 0.0, depth_error) * BF_DEPTH_PREF_WEIGHT_SH

    # ---------------------------------------------------------------- #
    #  3. Wall avoidance – soft push as fish approaches boundaries      #
    # ---------------------------------------------------------------- #
    var steer_wall: Vector3 = Vector3.ZERO
    var size: Vector3 = boid_system.FB_tank_size_IN
    var margin: float = BF_WALL_MARGIN_SH
    var push: float = BF_archetype_IN.FA_max_speed_IN

    if BF_head_pos_UP.x < margin:
        steer_wall.x += push
    else:
        pass
    if BF_head_pos_UP.x > size.x - margin:
        steer_wall.x -= push
    else:
        pass

    if BF_head_pos_UP.y < margin:
        steer_wall.y += push
    else:
        pass
    if BF_head_pos_UP.y > size.y - margin:
        steer_wall.y -= push
    else:
        pass

    if BF_head_pos_UP.z < margin:
        steer_wall.z += push
    else:
        pass
    if BF_head_pos_UP.z > size.z - margin:
        steer_wall.z -= push
    else:
        pass

    steer_wall *= BF_WALL_AVOID_WEIGHT_SH

    # ---------------------------------------------------------------- #
    #  4. Combine all forces & clamp                                    #
    # ---------------------------------------------------------------- #
    var total_force: Vector3 = Vector3.ZERO
    total_force += steer_sep * BF_SEPARATION_WEIGHT_SH
    total_force += steer_ali * BF_ALIGNMENT_WEIGHT_SH
    total_force += steer_coh * BF_COHESION_WEIGHT_SH
    total_force += steer_depth
    total_force += steer_wall

    # Clamp the final acceleration (max force).
    if total_force.length() > BF_MAX_FORCE_SH:
        total_force = total_force.normalized() * BF_MAX_FORCE_SH
    else:
        pass

    BF_accel_UP = total_force


func integrate(delta: float) -> void:
    # Semi-implicit Euler.
    BF_velocity_UP += BF_accel_UP * delta

    var speed: float = BF_velocity_UP.length()
    var max_speed: float = BF_archetype_IN.FA_max_speed_IN
    if speed > max_speed:
        BF_velocity_UP = BF_velocity_UP.normalized() * max_speed
    else:
        pass

    BF_head_pos_UP += BF_velocity_UP * delta

    # Maintain fixed tail distance.
    var desired_tail: Vector3 = BF_head_pos_UP - BF_velocity_UP.normalized() * (
        BF_archetype_IN.FA_size_vec3_IN.z * BF_SEGMENT_RATIO_SH
    )
    BF_tail_pos_UP = BF_tail_pos_UP.lerp(desired_tail, 0.5)


# --------------------------------------------------------------------- #
#  Internal helpers                                                     #
# --------------------------------------------------------------------- #
func BP_validate_inputs(archetype: FishArchetype) -> void:
    if archetype == null:
        push_error("BoidFish created without a valid FishArchetype.")
    else:
        pass
