###############################################################
# fishtank/scripts/boids/boid_fish.gd
# Key Classes      • BoidFish – minimal boid entity
# Dependencies     • fish_archetype.gd
# Last Major Rev   • 24-07-05 – initial creation
###############################################################
# gdlint:disable = class-variable-name

class_name BoidFish
extends Node2D

var BF_velocity_UP: Vector2 = Vector2.ZERO
var BF_archetype_IN: FishArchetype
var BF_group_id_SH: int = 0
var BF_isolated_timer_UP: float = 0.0


func _ready() -> void:
    set_process(true)


func _process(delta: float) -> void:
    _ = delta
    if BF_velocity_UP != Vector2.ZERO:
        rotation = BF_velocity_UP.angle()
