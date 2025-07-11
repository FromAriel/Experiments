extends SceneTree

var cases = [
    {"src": "3d6 | 2d6", "sections": 2},
    {"src": "1 | 1d8, 2", "groups": 3, "sections": 2},
    {"src": "| 2d6", "err": "Empty roll"},
    {"src": "2d6 || 1d4", "err": "Empty roll"},
    {"src": "1d6 |", "err": "Empty roll"}
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
        await process_frame
        if case.has("err"):
            assert(got.size() > 0)
            var msg = got.pop_back()
            assert(msg.find(case.err) != -1)
        else:
            assert(exec.RE_last_result_SH.sections.size() == case.sections)
            if case.has("groups"):
                assert(exec.RE_last_result_SH.groups.size() == case.groups)
        exec.RE_last_result_SH = {}

    print("Pipe notation tests passed")
    quit()
