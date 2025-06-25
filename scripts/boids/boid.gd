###############################################################
# scripts/boids/boid.gd
# Key funcs/classes: \u2022 Boid – agent placeholder
# Critical consts    \u2022 NONE
###############################################################

class_name Boid
extends Node2D

@export var max_speed: float = 150.0
@export var max_force: float = 30.0
@export var neighbor_radius: float = 40.0
@export var wander_strength: float = 0.3

var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var params: FlockParameters
var spatial_hash: SpatialHash2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    if params == null:
        params = FlockParameters.new()


func setup(hash: SpatialHash2D, p_params: FlockParameters) -> void:
    spatial_hash = hash
    params = p_params


func _physics_process(delta: float) -> void:
    if spatial_hash:
        spatial_hash.update(self, global_position)
        var neighbors := spatial_hash.query_range(global_position, neighbor_radius)
        _apply_boid_rules(neighbors)
    _apply_wander()
    velocity += acceleration * delta
    if velocity.length() > max_speed:
        velocity = velocity.normalized() * max_speed
    global_position += velocity * delta
    acceleration = Vector2.ZERO


func _apply_boid_rules(neighbors: Array) -> void:
    var sep := Vector2.ZERO
    var ali := Vector2.ZERO
    var coh := Vector2.ZERO
    var count := 0
    for boid in neighbors:
        if boid == self:
            continue
        var other: Boid = boid
        var diff := global_position - other.global_position
        var dist := diff.length()
        if dist > 0.0:
            sep += diff.normalized() / dist
        ali += other.velocity
        coh += other.global_position
        count += 1
    if count > 0:
        sep /= count
        ali = (ali / count) - velocity
        coh = (coh / count) - global_position
    var steer := Vector2.ZERO
    if sep != Vector2.ZERO:
        steer += sep.normalized() * params.separation
    if ali != Vector2.ZERO:
        steer += ali.normalized() * params.alignment
    if coh != Vector2.ZERO:
        steer += coh.normalized() * params.cohesion
    if steer.length() > max_force:
        steer = steer.normalized() * max_force
    acceleration += steer


func _apply_wander() -> void:
    var jitter := (
        Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * wander_strength
    )
    acceleration += jitter
