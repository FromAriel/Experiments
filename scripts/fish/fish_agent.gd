################################################################
# scripts/fish/fish_agent.gd
# Direct‐velocity version with wander tamed & smoothing
################################################################
class_name FishAgent
extends Node

const FishBody        = preload("res://scripts/entities/fish_body.gd")
const SpatialHash2D   = preload("res://scripts/boids/SpatialHash2D.gd")
const FlockParameters = preload("res://scripts/boids/flock_parameters.gd")

@export var max_speed:       float = 0    # px/sec
@export var max_force:       float = 0    # max steering force
@export var neighbor_radius: float = 0
@export var wander_strength: float = 0.001   # much lower jitter
@export var smoothing:       float = 50   # lerp factor [0,1]
@export var debug_log:      bool  = true

var velocity:      Vector2 = Vector2.ZERO
var acceleration:  Vector2 = Vector2.ZERO
var fish:          FishBody
var spatial_hash:  SpatialHash2D
var params:        FlockParameters = FlockParameters.new()
var _rng := RandomNumberGenerator.new()
var _boid_accel:   Vector2 = Vector2.ZERO
var _wander_accel: Vector2 = Vector2.ZERO

func _ready() -> void:
    fish = get_parent() as FishBody
    _rng.randomize()

func setup(hash: SpatialHash2D, p_params: FlockParameters) -> void:
    spatial_hash = hash
    params = p_params

func _physics_process(delta: float) -> void:
    if fish == null:
        return

    # --- BOID STEERING ---
    if spatial_hash:
        spatial_hash.update(self, fish.global_position)
        var neighbors = spatial_hash.query_range(fish.global_position, neighbor_radius)
        _apply_boid_rules(neighbors)

    # --- RANDOM WANDER ---
    _apply_wander()

    # --- CLAMP TOTAL ACCELERATION ---
    acceleration = acceleration.limit_length(max_force)

    # --- COMPUTE NEW VELOCITY & SMOOTH IT ---
    var target_vel = velocity + acceleration * delta
    if target_vel.length() > max_speed:
        target_vel = target_vel.normalized() * max_speed
    velocity = velocity.lerp(target_vel, smoothing)

    # --- CLAMP AGAIN TO AVOID OVERSHOOT ---
    if velocity.length() > max_speed:
        velocity = velocity.normalized() * max_speed

    # --- APPLY TO FISH HEAD ---
    fish.set_head_velocity(velocity)

    # --- DEBUG LOGGING ---
    if debug_log:
        var speed = velocity.length()
        var dir   = velocity.normalized()
        print("frame %d | speed=%.2f | dir=(%.2f,%.2f) | boid=%.2f | wander=%.2f" %
            [
                Engine.get_physics_frames(),
                speed,
                dir.x, dir.y,
                _boid_accel.length(),
                _wander_accel.length()
            ]
        )

    # --- RESET FOR NEXT FRAME ---
    acceleration = Vector2.ZERO


# ----------------------- BOID RULES ----------------------------------------
func _apply_boid_rules(neighbors: Array) -> void:
    var sep   = Vector2.ZERO
    var ali   = Vector2.ZERO
    var coh   = Vector2.ZERO
    var count = 0

    for boid in neighbors:
        if boid == self:
            continue
        var other = boid as FishAgent
        if other == null:
            continue
        var diff = fish.global_position - other.fish.global_position
        var dist = diff.length()
        if dist > 0:
            sep += diff.normalized() / dist
        ali += other.velocity
        coh += other.fish.global_position
        count += 1

    var steer = Vector2.ZERO
    if count > 0:
        sep /= count
        ali = (ali / count) - velocity
        coh = (coh / count) - fish.global_position
        if sep != Vector2.ZERO:
            steer += sep.normalized() * params.separation
        if ali != Vector2.ZERO:
            steer += ali.normalized() * params.alignment
        if coh != Vector2.ZERO:
            steer += coh.normalized() * params.cohesion

    if steer.length() > max_force:
        steer = steer.normalized() * max_force

    acceleration += steer
    _boid_accel = steer


# ----------------------- RANDOM WANDER -------------------------------------
func _apply_wander() -> void:
    var jitter = Vector2(
        _rng.randf_range(-1.0, 1.0),
        _rng.randf_range(-1.0, 1.0)
    ) * wander_strength
    acceleration += jitter
    _wander_accel = jitter
