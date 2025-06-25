###############################################################
# scripts/boids/boid.gd
# Key funcs/classes: \u2022 Boid – agent placeholder
# Critical consts    \u2022 NONE
###############################################################

class_name Boid
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var params: FlockParameters


func _physics_process(delta: float) -> void:
    velocity += acceleration * delta
    # TODO: implement boid steering using params
