###############################################################
# LIVEdie/scripts/quick_roll_bar.gd
# Key Classes      • QuickRollBar – UI for dice selection
# Key Functions    • _on_die_pressed() – queue dice
#                   _on_long_press_timeout() – handle long press
# Critical Consts  • QRB_SUPERSCRIPTS – digits for display
# Dependencies     • DiceParser
# Last Major Rev   • 24-04-XX – initial implementation
###############################################################
class_name QuickRollBar
extends VBoxContainer

const QRB_SUPERSCRIPTS := {
    "0": "\u2070",
    "1": "\u00B9",
    "2": "\u00B2",
    "3": "\u00B3",
    "4": "\u2074",
    "5": "\u2075",
    "6": "\u2076",
    "7": "\u2077",
    "8": "\u2078",
    "9": "\u2079"
}

var qrb_queue: Array = []
var qrb_last_faces: int = 0
var qrb_prev_queue: Array = []
var qrb_long_press_type: String = ""
var qrb_long_press_param: int = 0
var qrb_long_press_triggered: bool = false
var qrb_edit_index: int = -1


func _ready() -> void:
    _connect_dice_buttons($StandardRow)
    _connect_dice_buttons($AdvancedRow)
    $StandardRow/AdvancedToggle.pressed.connect(_on_toggle_advanced)
    $RepeaterRow/RollButton.pressed.connect(_on_roll_pressed)
    _connect_repeat_buttons()
    $LongPressTimer.timeout.connect(_on_long_press_timeout)
    $PreviewDialog.confirmed.connect(_on_preview_confirmed)
    $DialSpinner.confirmed.connect(_on_spinner_confirmed)


func _connect_dice_buttons(row: HBoxContainer) -> void:
    for node in row.get_children():
        if (
            node is Button
            and node.text.begins_with("D")
            and node.text != "DX?"
            and node.text != "ROLL"
            and node != $StandardRow/AdvancedToggle
        ):
            var faces := int(node.text.substr(1).replace("%", "100"))
            node.button_down.connect(_on_die_down.bind(faces))
            node.button_up.connect(_on_die_up.bind(faces))


func _connect_repeat_buttons() -> void:
    for node in $RepeaterRow.get_children():
        if node is Button and node.name.begins_with("X"):
            var mult := int(node.text.substr(1))
            node.button_down.connect(_on_repeat_down.bind(mult))
            node.button_up.connect(_on_repeat_up.bind(mult))


func _on_toggle_advanced() -> void:
    $AdvancedRow.visible = not $AdvancedRow.visible


func _on_die_pressed(faces: int) -> void:
    _add_die(faces, 1)


func _on_repeat_pressed(mult: int) -> void:
    if qrb_last_faces == 0:
        return
    _add_die(qrb_last_faces, mult - 1)


func _on_die_down(faces: int) -> void:
    qrb_long_press_type = "die"
    qrb_long_press_param = faces
    qrb_long_press_triggered = false
    $LongPressTimer.start()


func _on_die_up(faces: int) -> void:
    if $LongPressTimer.time_left > 0.0:
        $LongPressTimer.stop()
        _on_die_pressed(faces)
    elif qrb_long_press_triggered:
        pass
    else:
        _on_die_pressed(faces)


func _on_repeat_down(mult: int) -> void:
    qrb_long_press_type = "repeat"
    qrb_long_press_param = mult
    qrb_long_press_triggered = false
    $LongPressTimer.start()


func _on_repeat_up(mult: int) -> void:
    if $LongPressTimer.time_left > 0.0:
        $LongPressTimer.stop()
        _on_repeat_pressed(mult)
    elif qrb_long_press_triggered:
        pass
    else:
        _on_repeat_pressed(mult)


func _on_chip_down(index: int) -> void:
    qrb_long_press_type = "chip"
    qrb_long_press_param = index
    qrb_long_press_triggered = false
    $LongPressTimer.start()


func _on_chip_up(index: int) -> void:
    if $LongPressTimer.time_left > 0.0:
        $LongPressTimer.stop()
        _edit_chip(index)
    elif qrb_long_press_triggered:
        pass
    else:
        _edit_chip(index)


func _edit_chip(index: int) -> void:
    if index < 0 or index >= qrb_queue.size():
        return
    var entry: Dictionary = qrb_queue[index]
    qrb_edit_index = index
    _show_spinner(entry["faces"], entry["count"])


func _add_die(faces: int, qty: int) -> void:
    if qrb_queue.is_empty() or qrb_queue[-1]["faces"] != faces:
        qrb_queue.append({"faces": faces, "count": qty})
    else:
        qrb_queue[-1]["count"] += qty
    qrb_last_faces = faces
    _update_queue_display()


func _update_queue_display() -> void:
    var box: HBoxContainer = $QueueRow/ScrollContainer/DiceChips
    for child in box.get_children():
        child.queue_free()
    var i := 0
    for entry in qrb_queue:
        var chip := Button.new()
        chip.text = "D%s × %s" % [entry["faces"], entry["count"]]
        chip.flat = true
        chip.custom_minimum_size = Vector2(90, 48)
        box.add_child(chip)
        chip.button_down.connect(_on_chip_down.bind(i))
        chip.button_up.connect(_on_chip_up.bind(i))
        i += 1
    $QueueRow.visible = not qrb_queue.is_empty()


func _superscript(val: int) -> String:
    var result := ""
    for c in str(val):
        result += QRB_SUPERSCRIPTS.get(c, c)
    return result


func _build_expression() -> String:
    var parts: Array = []
    for entry in qrb_queue:
        parts.append(str(entry["count"]) + "d" + str(entry["faces"]))
    return " + ".join(parts)


func _on_long_press_timeout() -> void:
    qrb_long_press_triggered = true
    if qrb_long_press_type == "repeat":
        _show_multiplier_preview(qrb_long_press_param)
    elif qrb_long_press_type == "die":
        _show_spinner(qrb_long_press_param)
    elif qrb_long_press_type == "chip":
        if qrb_long_press_param >= 0 and qrb_long_press_param < qrb_queue.size():
            qrb_queue.remove_at(qrb_long_press_param)
            _update_queue_display()


func _show_multiplier_preview(mult: int) -> void:
    var preview: Array = []
    for entry in qrb_queue:
        preview.append({"faces": entry["faces"], "count": entry["count"] * mult})
    var parts: Array = []
    for entry in preview:
        var p := "d" + str(entry["faces"])
        if entry["count"] > 1:
            p += _superscript(entry["count"])
        parts.append(p)
    $PreviewDialog.dialog_text = " -> ".join(parts)
    $PreviewDialog.popup_centered()


func _on_preview_confirmed() -> void:
    _apply_multiplier(qrb_long_press_param)


func _apply_multiplier(mult: int) -> void:
    qrb_prev_queue = qrb_queue.duplicate(true)
    for entry in qrb_queue:
        entry["count"] *= mult
    _update_queue_display()


func _show_spinner(faces: int, start_val: int = 1) -> void:
    qrb_long_press_param = faces
    $DialSpinner.ds_value = start_val
    $DialSpinner.open_dial()


func _on_spinner_confirmed() -> void:
    var qty := int($DialSpinner.ds_value)
    if qrb_edit_index >= 0:
        if qty > 0:
            qrb_queue[qrb_edit_index]["count"] = qty
        else:
            qrb_queue.remove_at(qrb_edit_index)
        qrb_edit_index = -1
        _update_queue_display()
    else:
        _add_die(qrb_long_press_param, qty)


func _on_roll_pressed() -> void:
    if qrb_queue.is_empty():
        return
    var parser := DiceParser.new()
    var expr := _build_expression()
    var res := parser.evaluate(expr)
    print("Rolled: %s -> %s" % [expr, res])
    qrb_queue.clear()
    qrb_last_faces = 0
    _update_queue_display()
