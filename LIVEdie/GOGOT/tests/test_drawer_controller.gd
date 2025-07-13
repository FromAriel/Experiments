extends SceneTree


func _init() -> void:
    var ctrl = preload("res://scripts/DrawerController.gd").new()
    ctrl.name = "DrawerController"
    var scene = load("res://scenes/MainUI.tscn").instantiate()
    root.add_child(ctrl)
    root.add_child(scene)
    await process_frame

    var lower = scene.get_node("LowerPane")
    assert(lower.offset_top == -ctrl.DC_closed_height_IN)

    ctrl.open_half()
    await create_timer(0.35).timeout
    assert(lower.offset_top == -ctrl.DC_half_height_IN)

    ctrl.close_drawer()
    await create_timer(0.35).timeout
    assert(lower.offset_top == -ctrl.DC_closed_height_IN)

    print("DrawerController basic test passed")
    quit()
