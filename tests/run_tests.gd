###############################################################
# tests/run_tests.gd
# Key funcs/classes: \u2022 run_all() – executes SpatialHash2D tests
# Critical consts    \u2022 NONE
###############################################################

extends SceneTree

const SpatialHash2D = preload("res://scripts/boids/SpatialHash2D.gd")
const FishBody = preload("res://scripts/entities/fish_body.gd")
const FishBodyScene = preload("res://scenes/FishBody.tscn")
const FishAgent = preload("res://scripts/fish/fish_agent.gd")


func _initialize() -> void:
    var passed := await run_all()
    if passed:
        print("All tests passed.")
        quit(0)
    else:
        print("Tests failed.")
        quit(1)


func run_all() -> bool:
    var ok := true
    ok = ok and test_spatial_hash_basic()
    ok = ok and await test_fish_movement()
    ok = ok and await test_energy_dissipation()
    return ok


func test_spatial_hash_basic() -> bool:
    var grid := SpatialHash2D.new(10.0)
    grid.update("a", Vector2.ZERO)
    grid.update("b", Vector2(5, 0))
    grid.update("c", Vector2(20, 0))
    var res := grid.query_range(Vector2.ZERO, 8.0)
    var success := res.has("a") and res.has("b") and not res.has("c")
    if not success:
        push_error("SpatialHash2D basic query failed: %s" % [res])
    grid.queue_free()
    return success


func test_fish_movement() -> bool:
    var scene: PackedScene = FishBodyScene
    var fish: FishBody = scene.instantiate()
    get_root().add_child(fish)
    await physics_frame
    var seg := fish.get_node("segment_0") as RigidBody2D
    var start := seg.global_position
    fish.set_head_velocity(Vector2(50, 0))
    await physics_frame
    await physics_frame
    var moved := seg.global_position.distance_to(start) >= 1.0
    if not moved:
        push_error("segment_0 did not move: %s -> %s" % [start, seg.global_position])
    fish.queue_free()
    return moved


func test_energy_dissipation() -> bool:
    var scene: PackedScene = FishBodyScene
    var fish: FishBody = scene.instantiate()
    get_root().add_child(fish)
    var agent := FishAgent.new()
    fish.add_child(agent)
    agent.velocity = Vector2(20, 0)
    agent.setup(SpatialHash2D.new(10.0), agent.params)
    var last_speed := 0.0
    for i in range(120):
        await physics_frame
        last_speed = fish.get_head_velocity().length()
    fish.queue_free()
    if last_speed > fish.max_safe_speed:
        push_error("speed exceeded: %.2f" % last_speed)
        return false
    return true
