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
            return 2
        return seq.pop_front()


func _init() -> void:
    var rng = TestRNGManager.new([2])
    rng.name = "RNGManager"
    var exec: RollExecutor = RollExecutor.new()
    exec.name = "RollExecutor"
    exec.RE_parser_IN = DiceParser.new()
    root.add_child(rng)
    root.add_child(exec)
    await process_frame
    var res = exec._debug_roll("1d6!!")
    assert(res.kept.size() == 1)
    assert(res.kept[0] == 2)
    print("Explode no double count test passed")
    quit()
