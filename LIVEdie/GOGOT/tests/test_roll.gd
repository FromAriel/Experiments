extends SceneTree


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
    bus.roll_requested.emit("1d4")
    assert(exec.RE_last_result_SH.notation == "1d4")

    bus.roll_requested.emit("1d4,2d6")
    assert(exec.RE_last_result_SH.groups.size() == 2)
    assert(exec.RE_last_result_SH.sections.size() == 1)
    print("RollExecutor test passed")
    quit()
