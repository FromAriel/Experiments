extends SceneTree


class TestRNGManager:
    extends RNGManager

    func _ready() -> void:
        RM_rng_IN = RandomNumberGenerator.new()


func _init() -> void:
    var rng = TestRNGManager.new()
    rng.name = "RNGManager"
    var exec: RollExecutor = RollExecutor.new()
    exec.name = "RollExecutor"
    exec.RE_parser_IN = DiceParser.new()
    root.add_child(rng)
    root.add_child(exec)
    await process_frame
    var res = exec._debug_roll("10d6>=5")
    assert(typeof(res.total) == TYPE_INT)
    print("Success count test passed")
    quit()
