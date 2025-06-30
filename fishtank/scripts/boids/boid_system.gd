###############################################################
# fishtank/scripts/boids/boid_system.gd
# Key Classes      • BoidSystem – manages fish boids
# Key Functions    • BS_spawn_population_IN() – instantiate fish
#                   • _physics_process() – update boids
#                   • _BS_update_fish_IN() – group‐preferred flocking, soft & hard walls
# Critical Consts  • BS_neighbor_radius_IN: float
# Dependencies     • boid_system_config.gd, fish_archetype.gd, boid_fish.gd
# Last Major Rev   • 25-07-05 – combines fallback scene, color groups, z-depth, robust spawn
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
@export var BS_reveal_batch_IN: int = 4
@export var BS_reveal_speed_IN: float = 3.0
var BS_fish_nodes_SH: Array[BoidFish] = []
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
var BS_hidden_fish_SH: Array[BoidFish] = []

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
        _BS_spawn_fish_IN(arch)


func _BS_spawn_fish_IN(arch: FishArchetype) -> void:
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
        fish.position = Vector2(center.x, center.y)
        fish.BF_depth_UP = BS_rng_UP.randf_range(0.0, BS_environment_IN.TE_size_IN.z)
        fish.BF_environment_IN = BS_environment_IN
    else:
        fish.position = Vector2(BS_rng_UP.randf_range(-50, 50), BS_rng_UP.randf_range(-30, 30))
        fish.BF_depth_UP = 0.0
    # assign group and tint
    fish.BF_group_id_SH = BS_rng_UP.randi_range(0, BS_group_count_IN - 1)
    var ci = fish.BF_group_id_SH % BS_group_colors.size()
    fish.modulate = BS_group_colors[ci]
    fish.BF_archetype_IN = arch
    fish.scale = Vector2.ONE * 0.2
    var col := fish.modulate
    col.a = 0.0
    fish.modulate = col
    add_child(fish)
    BS_fish_nodes_SH.append(fish)
    BS_hidden_fish_SH.append(fish)


func _physics_process(delta: float) -> void:
    _BS_update_grid_IN()
    _BS_update_fish_reveal_IN(delta)
    for fish in BS_fish_nodes_SH:
        _BS_update_fish_IN(fish, delta)
        if BS_collider_IN != null:
            BS_collider_IN.TC_confine_IN(fish, delta, BS_hard_decel_IN)
        _BS_apply_sanity_check_IN(fish, delta)


func _BS_update_grid_IN() -> void:
    BS_grid_SH.clear()
    for fish in BS_fish_nodes_SH:
        var cell = Vector2i(
            floor(fish.position.x / BS_grid_cell_size_IN),
            floor(fish.position.y / BS_grid_cell_size_IN)
        )
        if not BS_grid_SH.has(cell):
            BS_grid_SH[cell] = []
        BS_grid_SH[cell].append(fish)


func _BS_update_fish_reveal_IN(delta: float) -> void:
    if BS_hidden_fish_SH.is_empty():
        return
    var show_count = min(BS_reveal_batch_IN, BS_hidden_fish_SH.size())
    var remove_indices: Array[int] = []
    for i in range(show_count):
        var f: BoidFish = BS_hidden_fish_SH[i]
        f.scale = f.scale.move_toward(Vector2.ONE, BS_reveal_speed_IN * delta)
        var col := f.modulate
        col.a = move_toward(col.a, 1.0, BS_reveal_speed_IN * delta)
        f.modulate = col
        if f.scale == Vector2.ONE and is_equal_approx(col.a, 1.0):
            remove_indices.append(i)
    for idx in range(remove_indices.size() - 1, -1, -1):
        BS_hidden_fish_SH.remove_at(remove_indices[idx])


func _BS_update_fish_IN(fish: BoidFish, delta: float) -> void:
    # gather neighbor sums
    var same_sep = Vector2.ZERO
    var same_ali = Vector2.ZERO
    var same_coh = Vector2.ZERO
    var same_count = 0
    var all_sep = Vector2.ZERO
    var all_ali = Vector2.ZERO
    var all_coh = Vector2.ZERO
    var all_count = 0

    var cell = Vector2i(
        floor(fish.position.x / BS_grid_cell_size_IN), floor(fish.position.y / BS_grid_cell_size_IN)
    )
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            var key = Vector2i(cell.x + dx, cell.y + dy)
            if not BS_grid_SH.has(key):
                continue
            for other in BS_grid_SH[key]:
                if other == fish:
                    continue
                var diff: Vector2 = other.position - fish.position
                var dist: float = diff.length()
                if dist < BS_neighbor_radius_IN:
                    all_ali += other.BF_velocity_UP
                    all_coh += other.position
                    all_count += 1
                    if dist < BS_separation_distance_IN and dist > 0.0:
                        all_sep -= diff / dist
                    if other.BF_group_id_SH == fish.BF_group_id_SH:
                        same_ali += other.BF_velocity_UP
                        same_coh += other.position
                        same_count += 1
                        if dist < BS_separation_distance_IN and dist > 0.0:
                            same_sep -= diff / dist

    # decide which to use (group preference)
    var use_ali: Vector2
    var use_coh: Vector2
    var use_sep: Vector2
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

    var steer = Vector2.ZERO
    if use_count > 0:
        # alignment
        var ali_vec = (
            (use_ali / use_count).normalized() * BS_config_IN.BC_max_speed_IN - fish.BF_velocity_UP
        )
        ali_vec = ali_vec.limit_length(BS_config_IN.BC_max_force_IN)
        # cohesion
        var coh_vec = (use_coh / use_count) - fish.position
        if coh_vec != Vector2.ZERO:
            coh_vec = coh_vec.normalized() * BS_config_IN.BC_max_speed_IN - fish.BF_velocity_UP
            coh_vec = coh_vec.limit_length(BS_config_IN.BC_max_force_IN)
        # separation
        var sep_vec = use_sep / use_count
        if sep_vec != Vector2.ZERO:
            sep_vec = sep_vec.normalized() * BS_config_IN.BC_max_speed_IN - fish.BF_velocity_UP
            sep_vec = sep_vec.limit_length(BS_config_IN.BC_max_force_IN)

        steer += ali_vec * BS_config_IN.BC_default_alignment_IN * weight_mult
        steer += coh_vec * BS_config_IN.BC_default_cohesion_IN * weight_mult
        steer += sep_vec * BS_config_IN.BC_default_separation_IN * weight_mult
        fish.BF_isolated_timer_UP = 0.0
    else:
        fish.BF_isolated_timer_UP += delta

    # wander
    var wander_vec = (
        Vector2(BS_rng_UP.randf_range(-1.0, 1.0), BS_rng_UP.randf_range(-1.0, 1.0)).normalized()
        * BS_config_IN.BC_default_wander_IN
        * BS_config_IN.BC_max_force_IN
    )
    steer += wander_vec

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

        var push = Vector2.ZERO

        if fish.position.x < soft_min_x:
            var d = (soft_min_x - fish.position.x) / BS_boundary_margin_IN
            push.x += d
            wall_factor = max(wall_factor, d)
        elif fish.position.x > soft_max_x:
            var d = (fish.position.x - soft_max_x) / BS_boundary_margin_IN
            push.x -= d
            wall_factor = max(wall_factor, d)

        if fish.position.y < soft_min_y:
            var dY = (soft_min_y - fish.position.y) / BS_boundary_margin_IN
            push.y += dY
            wall_factor = max(wall_factor, dY)
        elif fish.position.y > soft_max_y:
            var dY = (fish.position.y - soft_max_y) / BS_boundary_margin_IN
            push.y -= dY
            wall_factor = max(wall_factor, dY)

        if push != Vector2.ZERO:
            steer += push * BS_boundary_force_IN
            var center := Vector2(
                b.position.x + b.size.x * 0.5,
                b.position.y + b.size.y * 0.5,
            )
            steer += (center - fish.position).normalized() * BS_wall_nudge_IN * wall_factor

    # apply movement with smoothing and slowdown near walls
    var target_vel = (fish.BF_velocity_UP + steer * delta).limit_length(
        BS_config_IN.BC_max_speed_IN
    )
    target_vel = target_vel.move_toward(Vector2.ZERO, BS_soft_decel_IN * wall_factor * delta)
    var velocity = fish.BF_velocity_UP.lerp(target_vel, clamp(delta * 4.0, 0.0, 1.0))
    fish.position += velocity * delta
    fish.BF_velocity_UP = velocity

    # hard‐wall deceleration
    if BS_environment_IN != null:
        var b2 = BS_environment_IN.TE_boundaries_SH
        var eff_min_x2 = b2.position.x + BS_hard_margin_IN
        var eff_max_x2 = b2.position.x + b2.size.x - BS_hard_margin_IN
        var eff_min_y2 = b2.position.y + BS_hard_margin_IN
        var eff_max_y2 = b2.position.y + b2.size.y - BS_hard_margin_IN

        if fish.position.x < eff_min_x2:
            fish.position.x = eff_min_x2
            if fish.BF_velocity_UP.x < 0:
                fish.BF_velocity_UP.x = min(fish.BF_velocity_UP.x + BS_hard_decel_IN * delta, 0)
        elif fish.position.x > eff_max_x2:
            fish.position.x = eff_max_x2
            if fish.BF_velocity_UP.x > 0:
                fish.BF_velocity_UP.x = max(fish.BF_velocity_UP.x - BS_hard_decel_IN * delta, 0)

        if fish.position.y < eff_min_y2:
            fish.position.y = eff_min_y2
            if fish.BF_velocity_UP.y < 0:
                fish.BF_velocity_UP.y = min(fish.BF_velocity_UP.y + BS_hard_decel_IN * delta, 0)
        elif fish.position.y > eff_max_y2:
            fish.position.y = eff_max_y2
            if fish.BF_velocity_UP.y > 0:
                fish.BF_velocity_UP.y = max(fish.BF_velocity_UP.y - BS_hard_decel_IN * delta, 0)

    # depth jitter (fakey z)
    var max_z = 0.0
    if BS_environment_IN != null:
        max_z = BS_environment_IN.TE_size_IN.z
    fish.BF_depth_UP = clamp(
        fish.BF_depth_UP + BS_rng_UP.randf_range(-20.0, 20.0) * delta, 0.0, max_z
    )


func _BS_get_weight_IN(arch: FishArchetype, field: String, default_val: float) -> float:
    if arch != null:
        var val = arch.get(field)
        if typeof(val) == TYPE_FLOAT:
            return val
    return default_val


func _BS_apply_sanity_check_IN(fish: BoidFish, delta: float) -> void:
    if BS_environment_IN == null:
        return
    var b = BS_environment_IN.TE_boundaries_SH
    var center = b.position + b.size * 0.5
    var min_x = b.position.x
    var max_x = b.position.x + b.size.x
    var min_y = b.position.y
    var max_y = b.position.y + b.size.y
    var margin = BS_boundary_margin_IN * 0.5
    var near_edge = (
        fish.position.x < min_x + margin
        or fish.position.x > max_x - margin
        or fish.position.y < min_y + margin
        or fish.position.y > max_y - margin
    )
    var outside = (
        fish.position.x < min_x
        or fish.position.x > max_x
        or fish.position.y < min_y
        or fish.position.y > max_y
    )
    if near_edge or outside:
        var push_dir = (Vector2(center.x, center.y) - fish.position).normalized()
        fish.BF_velocity_UP = fish.BF_velocity_UP.move_toward(
            push_dir * BS_config_IN.BC_max_speed_IN, delta * 2.0
        )
# gdlint:enable = class-variable-name,function-name,function-variable-name,loop-variable-name
