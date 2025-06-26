###############################################################
# scripts/fish/fish_agent.gd
# Key Classes      • FishAgent – boid-style controller for FishBody
# Key Functions    • _physics_process – applies steering forces
# Dependencies     • fish_body.gd, flock_parameters.gd, SpatialHash2D.gd
###############################################################

class_name FishAgent
extends Node

const FishBody = preload("res://scripts/entities/fish_body.gd")
const SpatialHash2D = preload("res://scripts/boids/SpatialHash2D.gd")
const FlockParameters = preload("res://scripts/boids/flock_parameters.gd")

@export var max_speed: float = 150.0
@export var max_force: float = 30.0
@export var neighbor_radius: float = 40.0
@export var wander_strength: float = 0.3
@export var force_scale: float = 100.0

var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var fish: FishBody
var spatial_hash: SpatialHash2D
var params: FlockParameters = FlockParameters.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    if fish == null:
        fish = get_parent() as FishBody
    _rng.randomize()


func setup(hash: SpatialHash2D, p_params: FlockParameters) -> void:
    spatial_hash = hash
    params = p_params


func _physics_process(delta: float) -> void:
    if fish == null:
        return
    if spatial_hash:
        spatial_hash.update(self, fish.global_position)
        var neighbors := spatial_hash.query_range(fish.global_position, neighbor_radius)
        _apply_boid_rules(neighbors)
    _apply_wander()
    velocity += acceleration * delta
    if velocity.length() > max_speed:
        velocity = velocity.normalized() * max_speed
    fish.apply_steering_force(velocity * force_scale)
    acceleration = Vector2.ZERO


func _apply_boid_rules(neighbors: Array) -> void:
    var sep := Vector2.ZERO
    var ali := Vector2.ZERO
    var coh := Vector2.ZERO
    var count := 0
    for boid in neighbors:
        if boid == self:
            continue
        var other := boid as FishAgent
        if other == null:
            continue
        var diff := fish.global_position - other.fish.global_position
        var dist := diff.length()
        if dist > 0.0:
            sep += diff.normalized() / dist
        ali += other.velocity
        coh += other.fish.global_position
        count += 1
    if count > 0:
        sep /= count
        ali = (ali / count) - velocity
        coh = (coh / count) - fish.global_position
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
