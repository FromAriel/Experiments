extends SceneTree


func _init() -> void:
    var ctrl = preload("res://scripts/DrawerController.gd").new()
    ctrl.name = "DrawerController"
    var scene = load("res://scenes/MainUI.tscn").instantiate()
    root.add_child(ctrl)
    root.add_child(scene)
    await process_frame

    ctrl.open_preview()
    await process_frame
    assert(scene.get_node("LowerPane").offset_top == -ctrl.DC_preview_height_IN)

    ctrl.open_full()
    await process_frame
    assert(scene.get_node("LowerPane").offset_top == -ctrl.DC_full_height_IN)

    ctrl.close_drawer()
    await process_frame
    assert(scene.get_node("LowerPane").offset_top == -ctrl.DC_closed_height_IN)

    print("DrawerController basic test passed")
    quit()
