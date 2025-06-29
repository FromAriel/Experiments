###############################################################
# fishtank/scripts/boids/boid_fish.gd
# Key Classes      • BoidFish – minimal boid entity
# Dependencies     • fish_archetype.gd, tank_environment.gd
# Editor Exports   • BF_behavior_SH: FishBehavior
#                   • BF_wander_phase_UP: float
#                   • BF_target_depth_SH: float
# Last Major Rev   • 24-07-05 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name

class_name BoidFish
extends Node2D

enum FishBehavior {
    SCHOOL,
    DART,
    CURIOUS,
    IDLE,
}

const TankEnvironment = preload("res://scripts/data/tank_environment.gd")

@export var BF_behavior_SH: FishBehavior = FishBehavior.SCHOOL
@export var BF_wander_phase_UP: float = 0.0
@export var BF_target_depth_SH: float = 0.0

var BF_velocity_UP: Vector2 = Vector2.ZERO
var BF_archetype_IN: FishArchetype
var BF_group_id_SH: int = 0
var BF_isolated_timer_UP: float = 0.0
var BF_depth_UP: float = 0.0
var BF_environment_IN: TankEnvironment


func _ready() -> void:
    set_process(true)


func _process(_delta: float) -> void:
    if BF_velocity_UP != Vector2.ZERO:
        rotation = BF_velocity_UP.angle()
    if BF_environment_IN != null:
        _BF_apply_depth_IN()


func _BF_apply_depth_IN() -> void:
    var BF_ratio_UP: float = clamp(
        (BF_environment_IN.TE_size_IN.z - BF_depth_UP) / BF_environment_IN.TE_size_IN.z,
        0.0,
        1.0,
    )
    var BF_scale_UP: float = lerp(0.5, 1.0, BF_ratio_UP)
    scale = Vector2.ONE * BF_scale_UP
    modulate.a = lerp(0.4, 1.0, BF_ratio_UP)
