###############################################################
# scripts/fish_flock.gd
# Key Classes      • FishFlock – spawns and manages a school of fish
# Key Functions    • _ready – populate scene with FishBody instances
# Dependencies     • FishBody.tscn, fish_agent.gd, SpatialHash2D.gd
###############################################################

extends Node2D
const SpatialHash2D = preload("res://scripts/boids/SpatialHash2D.gd")
const FlockParameters = preload("res://scripts/boids/flock_parameters.gd")
const FishBody = preload("res://scripts/entities/fish_body.gd")

@export var fish_scene: PackedScene = preload("res://scenes/FishBody.tscn")
@export var fish_count: int = 50
@export var area_size: Vector2 = Vector2(1280, 720)

var _hash := SpatialHash2D.new(50.0)
var _params := FlockParameters.new()
var _rng := RandomNumberGenerator.new()
var _tracked_agent: Node = null
var _agents: Array = []


func _ready() -> void:
    _rng.randomize()
    for i in range(fish_count):
        var fish = fish_scene.instantiate()
        fish.global_position = Vector2(
            _rng.randf_range(0.0, area_size.x), _rng.randf_range(0.0, area_size.y)
        )
        fish.tank_size = Vector3(area_size.x, area_size.y, fish.tank_size.z)
        add_child(fish)
        var agent = load("res://scripts/fish/fish_agent.gd").new()
        fish.add_child(agent)
        agent.velocity = (
            Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * agent.max_speed
        )
        agent.setup(_hash, _params)
        _agents.append(agent)

    if _agents.size() > 0:
        _tracked_agent = _agents[_rng.randi_range(0, _agents.size() - 1)]
        _tracked_agent.enable_tracing(true)
        print("Tracking agent: %s" % [_tracked_agent.get_path()])


func _physics_process(_delta: float) -> void:
    if _tracked_agent:
        var pos: Vector2 = _tracked_agent.fish.global_position
        print("flock trace frame %d pos=(%.2f,%.2f)" % [Engine.get_physics_frames(), pos.x, pos.y])
