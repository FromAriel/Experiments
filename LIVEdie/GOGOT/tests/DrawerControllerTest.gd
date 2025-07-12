extends SceneTree


func _init() -> void:
    var main := preload("res://scenes/MainUI.tscn").instantiate()
    root.add_child(main)
    var ctrl := preload("res://scripts/DrawerController.gd").new()
    ctrl.name = "DrawerController"
    root.add_child(ctrl)
    await process_frame
    ctrl.open_preview()
    await create_timer(0.5).timeout
    assert(main.get_node("LowerPane").offset_top == -ctrl.DC_preview_height_IN)
    ctrl.open_full()
    await create_timer(0.5).timeout
    assert(main.get_node("LowerPane").offset_top == -ctrl.DC_full_height_IN)
    ctrl.close_drawer()
    await create_timer(0.5).timeout
    assert(main.get_node("LowerPane").offset_top == -ctrl.DC_closed_height_IN)
    print("DrawerController smoke test passed")
    quit()
