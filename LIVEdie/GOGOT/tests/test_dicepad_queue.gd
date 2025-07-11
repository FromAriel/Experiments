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
    var scene = load("res://scenes/MainUI.tscn")
    var main = scene.instantiate()
    root.add_child(main)
    await process_frame
    var dp = main.get_node("DicePad")
    dp._on_Die_pressed(6)
    dp._on_Pipe_pressed()
    dp._on_Die_pressed(8)
    dp._on_Pipe_pressed()
    dp._on_Die_pressed(8)
    assert(dp.DP_queue_label_SH.text == "1×D6 | 1×D8 | 1×D8")
    print("DicePad queue test passed")
    quit()
