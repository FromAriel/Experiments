###############################################################
# scripts/benchmark/headless_benchmark.gd
# Key Classes      • HeadlessBenchmark – small headless run for velocity debug
# Key Functions    • _initialize() – spawn one fish and simulate
# Dependencies     • FishBody.tscn, fish_agent.gd, SpatialHash2D.gd
###############################################################

extends SceneTree

const FishScene = preload("res://scenes/FishBody.tscn")
const FishAgent = preload("res://scripts/fish/fish_agent.gd")
const SpatialHash2D = preload("res://scripts/boids/SpatialHash2D.gd")

@export var steps: int = 120


func _initialize() -> void:
    var fish: Node2D = FishScene.instantiate()
    get_root().add_child(fish)
    var agent := FishAgent.new()
    fish.add_child(agent)
    agent.velocity = Vector2(10, 0)
    agent.debug_log = true
    agent.setup(SpatialHash2D.new(10.0), agent.params)
    await run_simulation()
    quit()


func run_simulation() -> void:
    for i in range(steps):
        await physics_frame
    print("benchmark complete")
