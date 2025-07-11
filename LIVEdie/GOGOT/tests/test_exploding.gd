extends SceneTree


class TestRNGManager:
    extends RNGManager
    var seq := []

    func _init(s := []):
        seq = s

    func _ready() -> void:
        RM_rng_IN = RandomNumberGenerator.new()

    func RM_generate_roll_SH(_num_sides: int) -> int:
        if seq.is_empty():
            return 1
        return seq.pop_front()


func _init() -> void:
    var rng = TestRNGManager.new([6, 1, 2, 3, 4, 5, 6])
    rng.name = "RNGManager"
    var exec: RollExecutor = RollExecutor.new()
    exec.name = "RollExecutor"
    exec.RE_parser_IN = DiceParser.new()
    root.add_child(rng)
    root.add_child(exec)
    await process_frame
    var res = exec._debug_roll("6d6!")
    assert(res.total >= 7)
    print("Exploding test passed")
    quit()
