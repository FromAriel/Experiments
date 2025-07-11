extends SceneTree

var cases = [
    {"src": "3d", "expect_msg": "missing sides"},
    {"src": "5d10,", "expect_msg": "Unexpected input"},
    {"src": ",2d6", "expect_msg": "Unexpected input"},
    {"src": "2d6 |", "expect_msg": "Empty roll"},
    {"src": "1d8, 1d8 , 4d1 , 1d", "expect_msg": "missing sides"}
]


func _init() -> void:
    var bus = preload("res://scripts/UIEventBus.gd").new()
    bus.name = "UIEventBus"
    var rng = RNGManager.new()
    rng.name = "RNGManager"
    var exec: RollExecutor = RollExecutor.new()
    exec.name = "RollExecutor"
    exec.RE_parser_IN = DiceParser.new()
    root.add_child(bus)
    root.add_child(rng)
    root.add_child(exec)
    await process_frame

    var got: Array = []
    exec.roll_failed.connect(func(msg): got.append(msg))

    for case in cases:
        bus.roll_requested.emit(case.src)
        assert(exec.RE_last_result_SH.is_empty())
        var msg = got.pop_back()
        assert(msg.find(case.expect_msg) != -1)

    print("Invalid notation tests passed")
    quit()
