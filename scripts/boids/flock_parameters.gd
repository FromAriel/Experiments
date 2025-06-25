###############################################################
# scripts/boids/flock_parameters.gd
# Key funcs/classes: \u2022 FlockParameters – container for boid weights
# Critical consts    \u2022 NONE
###############################################################

class_name FlockParameters
extends Resource

@export var separation: float = 1.0
@export var alignment: float = 1.0
@export var cohesion: float = 1.0
