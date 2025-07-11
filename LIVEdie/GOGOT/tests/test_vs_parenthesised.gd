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
    var res = exec._debug_roll("(1d4 vs 1d4) + 1")
    assert(res.sections[0].winner in ["lhs", "rhs", "tie"])
    print("VS parenthesised test passed")
    quit()
