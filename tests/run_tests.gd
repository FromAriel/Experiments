###############################################################
# tests/run_tests.gd
# Key funcs/classes: \u2022 run_all() – executes SpatialHash2D tests
# Critical consts    \u2022 NONE
###############################################################

extends SceneTree

const SpatialHash2D = preload("res://scripts/boids/SpatialHash2D.gd")


func _initialize() -> void:
    var passed := run_all()
    if passed:
        print("All tests passed.")
        quit(0)
    else:
        print("Tests failed.")
        quit(1)


func run_all() -> bool:
    var ok := true
    ok = ok and test_spatial_hash_basic()
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
    return success
