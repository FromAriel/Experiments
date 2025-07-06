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


func _ready() -> void:
    _connect_dice_buttons($StandardRow)
    _connect_dice_buttons($AdvancedRow)
    $StandardRow/AdvancedToggle.pressed.connect(_on_toggle_advanced)
    $RepeaterRow/RollButton.pressed.connect(_on_roll_pressed)
    _connect_repeat_buttons()
    $LongPressTimer.timeout.connect(_on_long_press_timeout)
    $PreviewDialog.confirmed.connect(_on_preview_confirmed)
    $DialSpinner.confirmed.connect(_on_spinner_confirmed)
    $QueueRow.visible = false


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


func _add_die(faces: int, qty: int) -> void:
    if qrb_queue.is_empty() or qrb_queue[-1]["faces"] != faces:
        qrb_queue.append({"faces": faces, "count": qty})
    else:
        qrb_queue[-1]["count"] += qty
    qrb_last_faces = faces
    _update_queue_display()


func _update_queue_display() -> void:
    var box := $QueueRow/Scroll/DiceBox
    for child in box.get_children():
        child.queue_free()
    for entry in qrb_queue:
        var chip := _make_chip(entry["faces"], entry["count"])
        box.add_child(chip)
    $QueueRow.visible = not qrb_queue.is_empty()


func _make_chip(faces: int, qty: int) -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(80, 48)
    panel.theme_type_variation = "Panel"
    var label := Label.new()
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.text = "D%s" % faces
    if qty > 1:
        label.text += _superscript(qty)
    panel.add_child(label)
    return panel


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


func _show_spinner(faces: int) -> void:
    qrb_long_press_param = faces
    $DialSpinner.ds_value = 1
    $DialSpinner.open_dial()


func _on_spinner_confirmed() -> void:
    var qty := int($DialSpinner.ds_value)
    _add_die(qrb_long_press_param, qty)


func _on_roll_pressed() -> void:
    if qrb_queue.is_empty():
        return
    var parser := DiceParser.new()
    var expr := _build_expression()
    var res := parser.evaluate(expr)
    print("Rolled: %s -> %s" % [expr, res])
    if owner.has_node("RollHistory"):
        var rh := owner.get_node("RollHistory") as RollHistoryPanel
        rh.add_entry(expr, str(res))
    qrb_queue.clear()
    qrb_last_faces = 0
    _update_queue_display()
