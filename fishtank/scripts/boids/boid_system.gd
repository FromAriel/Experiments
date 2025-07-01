###############################################################
# fishtank/scripts/boids/boid_system.gd
# Key Classes      • BoidSystem – manages fish boids
# Key Functions    • BS_spawn_population_IN() – instantiate fish
#                   • _physics_process() – update boids
#                   • _BS_update_fish_IN() – group‐preferred flocking, soft & hard walls
# Critical Consts  • BS_neighbor_radius_IN: float
# Dependencies     • boid_system_config.gd, fish_archetype.gd, boid_fish.gd
# Last Major Rev   • 25-07-06 – adds reveal animation and spawn fix
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,loop-variable-name

class_name BoidSystem
extends Node2D

@export var BS_config_IN: BoidSystemConfig
@export var BS_fish_scene_IN: PackedScene
@export var BS_neighbor_radius_IN: float = 80.0
@export var BS_separation_distance_IN: float = 40.0
@export var BS_environment_IN: TankEnvironment
@export var BS_group_count_IN: int = 5  # at least 5 groups
@export var BS_group_preference_weight_IN: float = 2.0

# Soft‐repulsion parameters
@export var BS_boundary_margin_IN: float = 50.0
@export var BS_boundary_force_IN: float = 100.0

# Hard‐wall parameters
@export var BS_hard_margin_IN: float = 20.0
@export var BS_hard_decel_IN: float = 200.0

# Soft deceleration when nearing walls
@export var BS_soft_decel_IN: float = 80.0
# Additional steering back toward the tank center
@export var BS_wall_nudge_IN: float = 50.0

@export var BS_grid_cell_size_IN: float = 100.0
@export var BS_collider_IN: TankCollider
@export var BS_reveal_batch_IN: int = 3
@export var BS_reveal_interval_IN: float = 0.2
var BS_fish_nodes_SH: Array[BoidFish] = []
# gdlint:ignore-start

var BS_group_colors := [
    # gdlint:ignore = max-line-length
    Color(1, 0, 0),
    Color(0, 1, 0),
    Color(0, 0, 1),
    Color(1, 1, 0),
    Color(1, 0, 1),
    Color(0, 1, 1)  # red  # green  # blue  # yellow  # magenta  # cyan
]
var BS_rng_UP := RandomNumberGenerator.new()
var BS_grid_SH: Dictionary = {}
var BS_reveal_timer_UP: Timer
var BS_reveal_index_UP: int = 0
var BS_steer_UP: Vector3 = Vector3.ZERO

# Wander noise generator
var BS_noise_UP := FastNoiseLite.new()
var BS_wander_weight_UP: float = 1.0
var BS_group_centers: Array[Vector2] = []

# gdlint:ignore-end


func _ready() -> void:
    if BS_config_IN == null:
        BS_config_IN = BoidSystemConfig.new()
    _BS_ensure_fish_scene_exists_IN()
    if BS_environment_IN == null:
        var parent = get_parent()
        if parent is FishTank:
            BS_environment_IN = (parent as FishTank).FT_environment_IN
        else:
            BS_environment_IN = TankEnvironment.new()
    if BS_collider_IN == null:
        var tc_node = get_parent().get_node_or_null("Tank")
        if tc_node is TankCollider:
            BS_collider_IN = tc_node
    BS_rng_UP.randomize()
    BS_noise_UP.seed = BS_rng_UP.randi()
    BS_noise_UP.frequency = BS_config_IN.BC_noise_freq_base
    BS_group_centers.resize(BS_group_count_IN)
    for i in range(BS_group_centers.size()):
        BS_group_centers[i] = Vector2.ZERO


func _BS_ensure_fish_scene_exists_IN() -> void:
    if BS_fish_scene_IN != null and is_instance_valid(BS_fish_scene_IN):
        return  # user-provided scene is fine
    # Try to load the default scene path first
    var default_path := "res://scenes/BoidFish.tscn"
    if ResourceLoader.exists(default_path):
        BS_fish_scene_IN = load(default_path)
        if BS_fish_scene_IN != null:
            return
    # Fallback: build an in-memory PackedScene so the simulation never crashes
    var root := load("res://scripts/boids/boid_fish.gd").new() as Node2D
    var sprite := Sprite2D.new()
    sprite.centered = true
    var tex_path := "res://art/ellipse_placeholder.png"
    if ResourceLoader.exists(tex_path):
        sprite.texture = load(tex_path)
    root.add_child(sprite)
    var ps := PackedScene.new()
    var err := ps.pack(root)
    if err == OK:
        BS_fish_scene_IN = ps
    else:
        push_error("BoidSystem: Failed to build fallback fish scene! (err %d)" % err)


func BS_spawn_population_IN(archetypes: Array[FishArchetype]) -> void:
    if archetypes.is_empty():
        return
    var count: int = BS_rng_UP.randi_range(
        BS_config_IN.BC_fish_count_min_IN, BS_config_IN.BC_fish_count_max_IN
    )
    for i in range(count):
        var arch: FishArchetype = archetypes[BS_rng_UP.randi_range(0, archetypes.size() - 1)]
        var fish = _BS_spawn_fish_IN(arch)
        fish.scale = Vector2.ONE * 0.1
        var c: Color = fish.modulate
        c.a = 0.0
        fish.modulate = c
    BS_reveal_index_UP = 0
    if BS_reveal_timer_UP == null:
        BS_reveal_timer_UP = Timer.new()
        BS_reveal_timer_UP.autostart = false
        BS_reveal_timer_UP.one_shot = false
        add_child(BS_reveal_timer_UP)
        BS_reveal_timer_UP.connect("timeout", Callable(self, "_BS_on_reveal_timeout_IN"))
    BS_reveal_timer_UP.wait_time = BS_reveal_interval_IN
    BS_reveal_timer_UP.start()


func _BS_spawn_fish_IN(arch: FishArchetype) -> BoidFish:
    var fish: BoidFish
    if BS_fish_scene_IN != null and is_instance_valid(BS_fish_scene_IN):
        fish = BS_fish_scene_IN.instantiate() as BoidFish
    else:
# gdlint:ignore = duplicated-load
        fish = load("res://scripts/boids/boid_fish.gd").new()
    # Position & depth
    if BS_environment_IN != null:
        var b: AABB = BS_environment_IN.TE_boundaries_SH
        var center: Vector3 = b.position + b.size * 0.5
        fish.BF_position_UP = Vector3(
            center.x,
            center.y,
            BS_rng_UP.randf_range(0.0, BS_environment_IN.TE_size_IN.z),
        )
        fish.position = Vector2(fish.BF_position_UP.x, fish.BF_position_UP.y)
        fish.BF_environment_IN = BS_environment_IN
    else:
        fish.BF_position_UP = Vector3(
            BS_rng_UP.randf_range(-50, 50),
            BS_rng_UP.randf_range(-30, 30),
            0.0,
        )
        fish.position = Vector2(fish.BF_position_UP.x, fish.BF_position_UP.y)
    # assign group and tint
    fish.BF_head_pos_UP = fish.BF_position_UP
    fish.BF_tail_pos_UP = fish.BF_position_UP
    fish.BF_group_id_SH = BS_rng_UP.randi_range(0, BS_group_count_IN - 1)
    var ci = fish.BF_group_id_SH % BS_group_colors.size()
    fish.modulate = BS_group_colors[ci]
    fish.BF_archetype_IN = arch
    add_child(fish)
    BS_fish_nodes_SH.append(fish)
    return fish


func _BS_on_reveal_timeout_IN() -> void:
    for _i in range(BS_reveal_batch_IN):
        if BS_reveal_index_UP >= BS_fish_nodes_SH.size():
            BS_reveal_timer_UP.stop()
            return
        var fish: BoidFish = BS_fish_nodes_SH[BS_reveal_index_UP]
        var tw := create_tween()
        tw.tween_property(fish, "scale", Vector2.ONE, 0.5)
        tw.tween_property(fish, "modulate:a", 1.0, 0.5)
        BS_reveal_index_UP += 1


func _physics_process(delta: float) -> void:
    _BS_update_grid_IN()
    for fish in BS_fish_nodes_SH:
        _BS_update_fish_IN(fish, delta)
        _BS_apply_boundary_IN(fish, delta)
        if BS_collider_IN != null:
            BS_collider_IN.TC_confine_IN(fish, delta, BS_hard_decel_IN)
        _BS_apply_sanity_check_IN(fish, delta)


func _BS_update_grid_IN() -> void:
    BS_grid_SH.clear()
    var group_sum := []
    var group_count := []
    for i in range(BS_group_count_IN):
        group_sum.append(Vector2.ZERO)
        group_count.append(0)
    for fish in BS_fish_nodes_SH:
        var cell = Vector2i(
            floor(fish.BF_position_UP.x / BS_grid_cell_size_IN),
            floor(fish.BF_position_UP.y / BS_grid_cell_size_IN)
        )
        if not BS_grid_SH.has(cell):
            BS_grid_SH[cell] = []
        BS_grid_SH[cell].append(fish)
        var g := fish.BF_group_id_SH
        group_sum[g] += Vector2(fish.BF_position_UP.x, fish.BF_position_UP.y)
        group_count[g] += 1
    for i in range(BS_group_count_IN):
        if group_count[i] > 0:
            BS_group_centers[i] = lerp(BS_group_centers[i], group_sum[i] / group_count[i], 0.05)


func _BS_update_fish_IN(fish: BoidFish, delta: float) -> void:
    BS_steer_UP = Vector3.ZERO
    # gather neighbor sums
    var same_sep = Vector3.ZERO
    var same_ali = Vector3.ZERO
    var same_coh = Vector3.ZERO
    var same_count = 0
    var all_sep = Vector3.ZERO
    var all_ali = Vector3.ZERO
    var all_coh = Vector3.ZERO
    var all_count = 0

    var cell = Vector2i(
        floor(fish.BF_position_UP.x / BS_grid_cell_size_IN),
        floor(fish.BF_position_UP.y / BS_grid_cell_size_IN),
    )
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            var key = Vector2i(cell.x + dx, cell.y + dy)
            if not BS_grid_SH.has(key):
                continue
            for other in BS_grid_SH[key]:
                if other == fish:
                    continue
                var diff: Vector3 = other.BF_position_UP - fish.BF_position_UP
                var dist: float = diff.length()
                if dist < BS_neighbor_radius_IN:
                    all_ali += other.BF_velocity_UP
                    all_coh += other.BF_position_UP
                    all_count += 1
                    if dist < BS_separation_distance_IN and dist > 0.0:
                        all_sep -= diff / dist
                    if other.BF_group_id_SH == fish.BF_group_id_SH:
                        same_ali += other.BF_velocity_UP
                        same_coh += other.BF_position_UP
                        same_count += 1
                        if dist < BS_separation_distance_IN and dist > 0.0:
                            same_sep -= diff / dist

    # decide which to use (group preference)
    var use_ali: Vector3
    var use_coh: Vector3
    var use_sep: Vector3
    var use_count: int
    var weight_mult: float
    if same_count > 0:
        use_ali = same_ali
        use_coh = same_coh
        use_sep = same_sep
        use_count = same_count
        weight_mult = BS_group_preference_weight_IN
    else:
        use_ali = all_ali
        use_coh = all_coh
        use_sep = all_sep
        use_count = all_count
        weight_mult = 1.0

    var steer = Vector3.ZERO
    if use_count > 0:
        # alignment
        var ali_vec = (
            (use_ali / use_count).normalized() * BS_config_IN.BC_max_speed_IN - fish.BF_velocity_UP
        )
        ali_vec = ali_vec.limit_length(BS_config_IN.BC_max_force_IN)
        # cohesion
        var coh_vec = (use_coh / use_count) - fish.BF_position_UP
        if coh_vec != Vector3.ZERO:
            coh_vec = coh_vec.normalized() * BS_config_IN.BC_max_speed_IN - fish.BF_velocity_UP
            coh_vec = coh_vec.limit_length(BS_config_IN.BC_max_force_IN)
        # separation
        var sep_vec = use_sep / use_count
        if sep_vec != Vector3.ZERO:
            sep_vec = sep_vec.normalized() * BS_config_IN.BC_max_speed_IN - fish.BF_velocity_UP
            sep_vec = sep_vec.limit_length(BS_config_IN.BC_max_force_IN)

        steer += ali_vec * BS_config_IN.BC_default_alignment_IN * weight_mult
        steer += coh_vec * BS_config_IN.BC_default_cohesion_IN * weight_mult
        steer += sep_vec * BS_config_IN.BC_default_separation_IN * weight_mult
        fish.BF_isolated_timer_UP = 0.0
    else:
        fish.BF_isolated_timer_UP += delta

    BS_steer_UP += steer
    _BS_apply_behavior_IN(fish, delta)

    fish.BF_wander_phase_UP += fish.BF_archetype_IN.FA_wander_speed_IN * delta
    var wander_vec := (
        (
            Vector3(
                BS_noise_UP.get_noise_3d(fish.BF_wander_phase_UP, 0.0, 0.0),
                BS_noise_UP.get_noise_3d(0.0, fish.BF_wander_phase_UP, 0.0),
                BS_noise_UP.get_noise_3d(0.0, 0.0, fish.BF_wander_phase_UP),
            )
            . normalized()
        )
        * BS_wander_weight_UP
    )
    BS_steer_UP += wander_vec

    # soft‐wall repulsion with slowdown and center bias
    var wall_factor = 0.0
    if BS_environment_IN != null:
        var b = BS_environment_IN.TE_boundaries_SH
        var eff_min_x = b.position.x + BS_hard_margin_IN
        var eff_max_x = b.position.x + b.size.x - BS_hard_margin_IN
        var eff_min_y = b.position.y + BS_hard_margin_IN
        var eff_max_y = b.position.y + b.size.y - BS_hard_margin_IN

        var soft_min_x = eff_min_x + BS_boundary_margin_IN
        var soft_max_x = eff_max_x - BS_boundary_margin_IN
        var soft_min_y = eff_min_y + BS_boundary_margin_IN
        var soft_max_y = eff_max_y - BS_boundary_margin_IN

        var push = Vector3.ZERO

        if fish.BF_position_UP.x < soft_min_x:
            var d = (soft_min_x - fish.BF_position_UP.x) / BS_boundary_margin_IN
            push.x += d
            wall_factor = max(wall_factor, d)
        elif fish.BF_position_UP.x > soft_max_x:
            var d = (fish.BF_position_UP.x - soft_max_x) / BS_boundary_margin_IN
            push.x -= d
            wall_factor = max(wall_factor, d)

        if fish.BF_position_UP.y < soft_min_y:
            var dY = (soft_min_y - fish.BF_position_UP.y) / BS_boundary_margin_IN
            push.y += dY
            wall_factor = max(wall_factor, dY)
        elif fish.BF_position_UP.y > soft_max_y:
            var dY = (fish.BF_position_UP.y - soft_max_y) / BS_boundary_margin_IN
            push.y -= dY
            wall_factor = max(wall_factor, dY)

        if push != Vector3.ZERO:
            BS_steer_UP += push * BS_boundary_force_IN
            var center := Vector3(
                b.position.x + b.size.x * 0.5,
                b.position.y + b.size.y * 0.5,
                fish.BF_position_UP.z,
            )
            var to_center := (center - fish.BF_position_UP).normalized()
            BS_steer_UP += to_center * BS_wall_nudge_IN * wall_factor

    var depth_ratio := 0.0
    if BS_environment_IN != null:
        depth_ratio = fish.BF_position_UP.z / BS_environment_IN.TE_size_IN.z
    var max_speed: float = lerp(
        BS_config_IN.BC_depth_speed_front,
        BS_config_IN.BC_depth_speed_back,
        depth_ratio,
    )
    var desired_vel: Vector3 = (fish.BF_velocity_UP + BS_steer_UP).limit_length(max_speed)

    if (
        fish.BF_archetype_IN != null
        and fish.BF_archetype_IN.FA_movement_mode_IN == FishArchetype.MovementMode.FLIP_TURN_ENABLED
    ):
        var angle_diff: float = abs(
            Vector2(fish.BF_velocity_UP.x, fish.BF_velocity_UP.y).angle_to(
                Vector2(desired_vel.x, desired_vel.y)
            )
        )
        if (
            angle_diff > fish.BF_archetype_IN.FA_flip_turn_threshold_IN
            and fish.BF_flip_timer_UP <= 0.0
        ):
            fish._BF_start_flip_turn_IN(fish.BF_archetype_IN.FA_flip_duration_IN)
        if fish.BF_flip_timer_UP > 0.0:
            max_speed *= fish.BF_archetype_IN.FA_flip_speed_reduction_IN
            desired_vel = desired_vel.limit_length(max_speed)
    fish.BF_velocity_UP = (
        fish
        . BF_velocity_UP
        . move_toward(
            desired_vel,
            BS_config_IN.BC_max_force_IN * delta,
        )
    )
    fish.BF_position_UP += fish.BF_velocity_UP * delta
    fish.position = Vector2(fish.BF_position_UP.x, fish.BF_position_UP.y)
    fish.BF_head_pos_UP = fish.BF_position_UP
    var tail_target := fish.BF_position_UP - fish.BF_velocity_UP.normalized() * 10.0
    fish.BF_tail_pos_UP = (
        fish
        . BF_tail_pos_UP
        . move_toward(
            tail_target,
            50.0 * delta,
        )
    )
    var horiz_len := (
        Vector2(
            fish.BF_head_pos_UP.x - fish.BF_tail_pos_UP.x,
            fish.BF_head_pos_UP.y - fish.BF_tail_pos_UP.y,
        )
        . length()
    )
    var pitch_target := atan2(
        fish.BF_head_pos_UP.z - fish.BF_tail_pos_UP.z,
        horiz_len,
    )
    fish.BF_pitch_UP = lerp_angle(
        fish.BF_pitch_UP,
        pitch_target,
        5.0 * delta,
    )
    if fish.BF_velocity_UP != Vector3.ZERO:
        fish.BF_z_steer_target_UP = (
            Vector2(
                fish.BF_velocity_UP.x,
                fish.BF_velocity_UP.y,
            )
            . angle()
        )
        fish.BF_rot_target_UP = fish.BF_z_steer_target_UP
        if fish.BF_archetype_IN != null:
            fish.BF_z_angle_UP = lerp_angle(
                fish.BF_z_angle_UP,
                fish.BF_z_steer_target_UP,
                fish.BF_archetype_IN.FA_z_steer_weight_IN * delta,
            )
        else:
            fish.BF_z_angle_UP = lerp_angle(
                fish.BF_z_angle_UP,
                fish.BF_z_steer_target_UP,
                delta,
            )

    # hard‐wall deceleration
    if BS_environment_IN != null:
        var b2 = BS_environment_IN.TE_boundaries_SH
        var eff_min_x2 = b2.position.x + BS_hard_margin_IN
        var eff_max_x2 = b2.position.x + b2.size.x - BS_hard_margin_IN
        var eff_min_y2 = b2.position.y + BS_hard_margin_IN
        var eff_max_y2 = b2.position.y + b2.size.y - BS_hard_margin_IN
        var eff_min_z2 = b2.position.z
        var eff_max_z2 = b2.position.z + b2.size.z

        if fish.BF_position_UP.x < eff_min_x2:
            fish.BF_position_UP.x = eff_min_x2
            if fish.BF_velocity_UP.x < 0:
                fish.BF_velocity_UP.x = min(fish.BF_velocity_UP.x + BS_hard_decel_IN * delta, 0)
        elif fish.BF_position_UP.x > eff_max_x2:
            fish.BF_position_UP.x = eff_max_x2
            if fish.BF_velocity_UP.x > 0:
                fish.BF_velocity_UP.x = max(fish.BF_velocity_UP.x - BS_hard_decel_IN * delta, 0)

        if fish.BF_position_UP.y < eff_min_y2:
            fish.BF_position_UP.y = eff_min_y2
            if fish.BF_velocity_UP.y < 0:
                fish.BF_velocity_UP.y = min(fish.BF_velocity_UP.y + BS_hard_decel_IN * delta, 0)
        elif fish.BF_position_UP.y > eff_max_y2:
            fish.BF_position_UP.y = eff_max_y2
            if fish.BF_velocity_UP.y > 0:
                fish.BF_velocity_UP.y = max(fish.BF_velocity_UP.y - BS_hard_decel_IN * delta, 0)

        if fish.BF_position_UP.z < eff_min_z2:
            fish.BF_position_UP.z = eff_min_z2
            fish.BF_velocity_UP.z = abs(fish.BF_velocity_UP.z) * BS_config_IN.BC_reflect_damping
        elif fish.BF_position_UP.z > eff_max_z2:
            fish.BF_position_UP.z = eff_max_z2
            fish.BF_velocity_UP.z = -abs(fish.BF_velocity_UP.z) * BS_config_IN.BC_reflect_damping

    if BS_environment_IN != null:
        if abs(fish.BF_position_UP.z - fish.BF_target_depth_SH) < 0.1:
            fish.BF_target_depth_SH = BS_rng_UP.randf_range(0.0, BS_environment_IN.TE_size_IN.z)
        fish.BF_position_UP.z = lerp(
            fish.BF_position_UP.z,
            fish.BF_target_depth_SH,
            fish.BF_depth_lerp_speed_IN * delta,
        )
        var ratio := fish.BF_position_UP.z / BS_environment_IN.TE_size_IN.z
        fish.modulate = Color(
            1.0 - ratio * 0.5,
            1.0 - ratio * 0.5,
            1.0 - ratio * 0.5,
            lerp(1.0, 0.4, ratio),
        )


func _BS_get_weight_IN(arch: FishArchetype, field: String, default_val: float) -> float:
    if arch != null:
        var val = arch.get(field)
        if typeof(val) == TYPE_FLOAT:
            return val
    return default_val


func _BS_apply_behavior_IN(fish: BoidFish, _delta: float) -> void:
    match fish.BF_behavior_SH:
        BoidFish.FishBehavior.DART:
            if BS_rng_UP.randf() < 0.05:
                BS_steer_UP += (
                    Vector3(
                        BS_rng_UP.randf_range(-1, 1),
                        BS_rng_UP.randf_range(-1, 1),
                        0.0,
                    )
                    * fish.BF_archetype_IN.FA_burst_speed_IN
                )
        BoidFish.FishBehavior.IDLE:
            BS_steer_UP *= fish.BF_archetype_IN.FA_idle_jitter_IN
        BoidFish.FishBehavior.CHASE:
            var target := fish.BF_position_UP
            if BS_fish_nodes_SH.size() > 0:
                target = BS_fish_nodes_SH[0].BF_position_UP
            var chase_vec := (target - fish.BF_position_UP).normalized()
            BS_steer_UP += chase_vec * fish.BF_archetype_IN.FA_burst_speed_IN


func _BS_apply_boundary_IN(fish: BoidFish, _delta: float) -> void:
    if BS_environment_IN == null:
        return
    var b := BS_environment_IN.TE_boundaries_SH
    var min_x := b.position.x
    var max_x := b.position.x + b.size.x
    var min_y := b.position.y
    var max_y := b.position.y + b.size.y
    var max_push := 20.0
    match BS_config_IN.BS_boundary_mode_IN:
        1:
            var edge_force := Vector3.ZERO
            edge_force.x += (
                clamp(min_x - fish.BF_position_UP.x, -max_push, 0.0)
                * BS_config_IN.BC_soft_contain_k
            )
            edge_force.x += (
                clamp(max_x - fish.BF_position_UP.x, 0.0, max_push) * BS_config_IN.BC_soft_contain_k
            )
            edge_force.y += (
                clamp(min_y - fish.BF_position_UP.y, -max_push, 0.0)
                * BS_config_IN.BC_soft_contain_k
            )
            edge_force.y += (
                clamp(max_y - fish.BF_position_UP.y, 0.0, max_push) * BS_config_IN.BC_soft_contain_k
            )
            BS_steer_UP += edge_force
        2:
            if fish.BF_position_UP.x < min_x or fish.BF_position_UP.x > max_x:
                fish.BF_velocity_UP.x *= -BS_config_IN.BC_reflect_damping
            if fish.BF_position_UP.y < min_y or fish.BF_position_UP.y > max_y:
                fish.BF_velocity_UP.y *= -BS_config_IN.BC_reflect_damping
        3:
            if fish.BF_position_UP.x < min_x:
                fish.BF_position_UP.x = max_x
            elif fish.BF_position_UP.x > max_x:
                fish.BF_position_UP.x = min_x
            if fish.BF_position_UP.y < min_y:
                fish.BF_position_UP.y = max_y
            elif fish.BF_position_UP.y > max_y:
                fish.BF_position_UP.y = min_y


func _BS_apply_sanity_check_IN(fish: BoidFish, delta: float) -> void:
    if BS_environment_IN == null:
        return
    var b = BS_environment_IN.TE_boundaries_SH
    var min_x = b.position.x
    var max_x = b.position.x + b.size.x
    var min_y = b.position.y
    var max_y = b.position.y + b.size.y
    var margin = BS_boundary_margin_IN * 0.5
    var near_edge = (
        fish.BF_position_UP.x < min_x + margin
        or fish.BF_position_UP.x > max_x - margin
        or fish.BF_position_UP.y < min_y + margin
        or fish.BF_position_UP.y > max_y - margin
    )
    var outside = (
        fish.BF_position_UP.x < min_x
        or fish.BF_position_UP.x > max_x
        or fish.BF_position_UP.y < min_y
        or fish.BF_position_UP.y > max_y
    )
    if outside:
        var center3: Vector3 = b.position + b.size * 0.5
        var push3: Vector3 = (center3 - fish.BF_position_UP).normalized()
        fish.BF_velocity_UP = (
            fish
            . BF_velocity_UP
            . move_toward(
                push3 * BS_config_IN.BC_max_speed_IN,
                delta * 2.0,
            )
        )
# gdlint:enable = class-variable-name,function-name,function-variable-name,loop-variable-name
