###############################################################
# fishtank/scripts/boids/boid_system.gd
# Key Classes      • BoidSystem – manages fish boids
# Key Functions    • BS_spawn_population_IN() – instantiate fish
#                   • _physics_process() – update boids
# Critical Consts  • BS_neighbor_radius_IN: float
# Dependencies     • boid_system_config.gd, fish_archetype.gd, boid_fish.gd
# Last Major Rev   • 24-07-05 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,loop-variable-name

class_name BoidSystem
extends Node2D

@export var BS_config_IN: BoidSystemConfig
@export var BS_fish_scene_IN: PackedScene
@export var BS_neighbor_radius_IN: float = 80.0
@export var BS_bounds_rect_IN: Rect2 = Rect2(-100, -60, 200, 120)
@export var BS_wall_buffer_IN: float = 16.0

var BS_fish_nodes_SH: Array[BoidFish] = []
var BS_rng_UP := RandomNumberGenerator.new()


func _ready() -> void:
    if BS_config_IN == null:
        BS_config_IN = BoidSystemConfig.new()
    if BS_fish_scene_IN == null:
        BS_fish_scene_IN = preload("res://scenes/BoidFish.tscn")
    BS_rng_UP.randomize()


func BS_spawn_population_IN(archetypes: Array[FishArchetype]) -> void:
    if archetypes.is_empty():
        return
    var BS_count_UP: int = BS_rng_UP.randi_range(
        BS_config_IN.BC_fish_count_min_IN, BS_config_IN.BC_fish_count_max_IN
    )
    for i in range(BS_count_UP):
        var BS_arch_UP: FishArchetype = archetypes[BS_rng_UP.randi_range(0, archetypes.size() - 1)]
        _BS_spawn_fish_IN(BS_arch_UP)


func _BS_spawn_fish_IN(arch: FishArchetype) -> void:
    var BS_fish_UP: BoidFish = BS_fish_scene_IN.instantiate()
    BS_fish_UP.position = Vector2(
        BS_rng_UP.randf_range(
            BS_bounds_rect_IN.position.x, BS_bounds_rect_IN.position.x + BS_bounds_rect_IN.size.x
        ),
        BS_rng_UP.randf_range(
            BS_bounds_rect_IN.position.y, BS_bounds_rect_IN.position.y + BS_bounds_rect_IN.size.y
        )
    )
    BS_fish_UP.BF_velocity_UP = (
        Vector2(BS_rng_UP.randf_range(-1.0, 1.0), BS_rng_UP.randf_range(-1.0, 1.0)).normalized()
        * BS_config_IN.BC_max_speed_IN
        * 0.5
    )
    BS_fish_UP.BF_archetype_IN = arch
    add_child(BS_fish_UP)
    BS_fish_nodes_SH.append(BS_fish_UP)


func _physics_process(delta: float) -> void:
    for BS_fish_UP in BS_fish_nodes_SH:
        _BS_update_fish_IN(BS_fish_UP, delta)


func _BS_update_fish_IN(fish: BoidFish, delta: float) -> void:
    var BS_sep_UP := Vector2.ZERO
    var BS_ali_UP := Vector2.ZERO
    var BS_coh_UP := Vector2.ZERO
    var BS_count_UP := 0
    for BS_other_UP in BS_fish_nodes_SH:
        if BS_other_UP == fish:
            continue
        var BS_diff_UP := fish.position - BS_other_UP.position
        var BS_dist_UP: float = BS_diff_UP.length()
        if BS_dist_UP <= BS_neighbor_radius_IN and BS_dist_UP > 0.0:
            BS_sep_UP += BS_diff_UP.normalized() / BS_dist_UP
            BS_ali_UP += BS_other_UP.BF_velocity_UP
            BS_coh_UP += BS_other_UP.position
            BS_count_UP += 1

    var BS_align_weight_UP := _BS_get_weight_IN(
        fish.BF_archetype_IN, "FA_alignment_weight_IN", BS_config_IN.BC_default_alignment_IN
    )
    var BS_cohes_weight_UP := _BS_get_weight_IN(
        fish.BF_archetype_IN, "FA_cohesion_weight_IN", BS_config_IN.BC_default_cohesion_IN
    )
    var BS_separ_weight_UP := _BS_get_weight_IN(
        fish.BF_archetype_IN, "FA_separation_weight_IN", BS_config_IN.BC_default_separation_IN
    )
    var BS_wander_weight_UP := _BS_get_weight_IN(
        fish.BF_archetype_IN, "FA_wander_weight_IN", BS_config_IN.BC_default_wander_IN
    )

    var BS_steer_UP := Vector2.ZERO
    if BS_count_UP > 0:
        BS_sep_UP /= BS_count_UP
        BS_ali_UP = (BS_ali_UP / BS_count_UP) - fish.BF_velocity_UP
        BS_coh_UP = (BS_coh_UP / BS_count_UP) - fish.position
        if BS_sep_UP != Vector2.ZERO:
            BS_steer_UP += BS_sep_UP.normalized() * BS_separ_weight_UP
        if BS_ali_UP != Vector2.ZERO:
            BS_steer_UP += BS_ali_UP.normalized() * BS_align_weight_UP
        if BS_coh_UP != Vector2.ZERO:
            BS_steer_UP += BS_coh_UP.normalized() * BS_cohes_weight_UP

    var BS_wander_UP := (
        Vector2(BS_rng_UP.randf_range(-1.0, 1.0), BS_rng_UP.randf_range(-1.0, 1.0))
        * BS_wander_weight_UP
    )
    BS_steer_UP += BS_wander_UP

    BS_steer_UP += _BS_wall_avoidance_IN(fish)

    var BS_vel_UP := fish.BF_velocity_UP + BS_steer_UP
    BS_vel_UP = BS_vel_UP.limit_length(BS_config_IN.BC_max_speed_IN)
    fish.position += BS_vel_UP * delta
    fish.BF_velocity_UP = BS_vel_UP
    fish.rotation = BS_vel_UP.angle()


func _BS_wall_avoidance_IN(fish: BoidFish) -> Vector2:
    var BS_force_UP := Vector2.ZERO
    var BS_left_UP: float = BS_bounds_rect_IN.position.x + BS_wall_buffer_IN
    var BS_right_UP: float = (
        BS_bounds_rect_IN.position.x + BS_bounds_rect_IN.size.x - BS_wall_buffer_IN
    )
    var BS_top_UP: float = BS_bounds_rect_IN.position.y + BS_wall_buffer_IN
    var BS_bottom_UP: float = (
        BS_bounds_rect_IN.position.y + BS_bounds_rect_IN.size.y - BS_wall_buffer_IN
    )

    if fish.position.x < BS_left_UP:
        BS_force_UP.x += 1.0
    elif fish.position.x > BS_right_UP:
        BS_force_UP.x -= 1.0

    if fish.position.y < BS_top_UP:
        BS_force_UP.y += 1.0
    elif fish.position.y > BS_bottom_UP:
        BS_force_UP.y -= 1.0

    return BS_force_UP


func _BS_get_weight_IN(arch: FishArchetype, field: String, default_val: float) -> float:
    if arch != null:
        var val = arch.get(field)
        if typeof(val) == TYPE_FLOAT:
            return val
    return default_val
