extends SceneTree


func _init() -> void:
    var ctrl = preload("res://scripts/DrawerController.gd").new()
    ctrl.name = "DrawerController"
    var scene = load("res://scenes/MainUI.tscn").instantiate()
    root.add_child(ctrl)
    root.add_child(scene)
    await process_frame

    var lower = scene.get_node("LowerPane")
    var dimmer = ctrl.DC_dimmer_SH
    assert(lower.offset_top == -ctrl.DC_closed_height_IN)

    ctrl.open_preview()
    await create_timer(0.35).timeout
    assert(lower.offset_top == -ctrl.DC_preview_height_IN)
    assert(is_equal_approx(dimmer.modulate.a, 0.5))

    ctrl.open_full()
    await create_timer(0.35).timeout
    assert(lower.offset_top == -ctrl.DC_full_height_IN)
    assert(is_equal_approx(dimmer.modulate.a, 0.0))

    ctrl.close_drawer()
    await create_timer(0.35).timeout
    assert(lower.offset_top == -ctrl.DC_closed_height_IN)
    assert(is_equal_approx(dimmer.modulate.a, 0.0))

    print("DrawerController basic test passed")
    quit()
