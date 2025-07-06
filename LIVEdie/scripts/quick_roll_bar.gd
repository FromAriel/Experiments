###############################################################
# LIVEdie/scripts/quick_roll_bar.gd
# Key Classes      • QuickRollBar – UI for dice selection
# Key Functions    • _on_die_pressed() – queue dice
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

const QRB_LONG_PRESS_TIME := 0.6

var qrb_queue: Array = []
var qrb_last_faces: int = 0
var qrb_prev_queue: Array = []

var qrb_long_timer: Timer
var qrb_long_mode: String = ""
var qrb_long_value: int = 0
var qrb_long_active: bool = false
var qrb_spinner: AcceptDialog


func _ready() -> void:
    _connect_dice_buttons($StandardRow)
    _connect_dice_buttons($AdvancedRow)
    $StandardRow/AdvancedToggle.pressed.connect(_on_toggle_advanced)
    $RepeaterRow/RollButton.pressed.connect(_on_roll_pressed)
    _connect_repeat_buttons()
    qrb_long_timer = Timer.new()
    qrb_long_timer.one_shot = true
    qrb_long_timer.wait_time = QRB_LONG_PRESS_TIME
    add_child(qrb_long_timer)
    qrb_long_timer.timeout.connect(_on_long_timeout)
    qrb_spinner = load("res://scenes/quantity_spinner.tscn").instantiate()
    add_child(qrb_spinner)
    qrb_spinner.hide()
    qrb_spinner.confirmed.connect(_on_spinner_confirmed)


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
            node.pressed.connect(_on_die_pressed.bind(faces))
            node.button_down.connect(_on_die_down.bind(node, faces))
            node.button_up.connect(_on_die_up.bind(node, faces))


func _connect_repeat_buttons() -> void:
    for node in $RepeaterRow.get_children():
        if node is Button:
            var mult := int(node.text.substr(1))
            node.pressed.connect(_on_repeat_pressed.bind(mult))
            node.button_down.connect(_on_repeat_down.bind(node, mult))
            node.button_up.connect(_on_repeat_up.bind(node, mult))


func _on_toggle_advanced() -> void:
    $AdvancedRow.visible = not $AdvancedRow.visible


func _on_die_down(_btn: Button, faces: int) -> void:
    qrb_long_mode = "die"
    qrb_long_value = faces
    qrb_long_timer.start()


func _on_die_up(_btn: Button, faces: int) -> void:
    qrb_long_timer.stop()
    if qrb_long_active:
        return
    _on_die_pressed(faces)


func _on_die_pressed(faces: int) -> void:
    _add_die(faces, 1)


func _on_repeat_pressed(mult: int) -> void:
    if qrb_last_faces == 0:
        return
    _add_die(qrb_last_faces, mult - 1)


func _on_repeat_down(_btn: Button, mult: int) -> void:
    qrb_long_mode = "repeat"
    qrb_long_value = mult
    qrb_long_timer.start()


func _on_repeat_up(_btn: Button, mult: int) -> void:
    qrb_long_timer.stop()
    if qrb_long_active:
        _apply_multiplier(mult)
        qrb_long_active = false
        _clear_preview()
        return
    _on_repeat_pressed(mult)


func _add_die(faces: int, qty: int) -> void:
    if qrb_queue.is_empty() or qrb_queue[-1]["faces"] != faces:
        qrb_queue.append({"faces": faces, "count": qty})
    else:
        qrb_queue[-1]["count"] += qty
    qrb_last_faces = faces
    _update_queue_label()


func _update_queue_label() -> void:
    var parts: Array = []
    for entry in qrb_queue:
        var part := "d" + str(entry["faces"])
        if entry["count"] > 1:
            part += _superscript(entry["count"])
        parts.append(part)
    $QueueLabel.text = " ".join(parts)


func _preview_multiplier(mult: int) -> void:
    var parts: Array = []
    for entry in qrb_queue:
        var part := "d" + str(entry["faces"])
        var count: int = int(entry["count"]) * mult
        if count > 1:
            part += _superscript(count)
        parts.append(part)
    $QueueLabel.modulate = Color(1, 0.4, 0.4)
    $QueueLabel.text = " ".join(parts)


func _clear_preview() -> void:
    $QueueLabel.modulate = Color.WHITE
    _update_queue_label()


func _superscript(val: int) -> String:
    var result := ""
    for c in str(val):
        result += QRB_SUPERSCRIPTS.get(c, c)
    return result


func _apply_multiplier(mult: int) -> void:
    if qrb_queue.is_empty():
        return
    qrb_prev_queue.clear()
    for entry in qrb_queue:
        qrb_prev_queue.append(entry.duplicate())
        entry["count"] *= mult
    _update_queue_label()


func _on_long_timeout() -> void:
    qrb_long_active = true
    if qrb_long_mode == "repeat":
        _preview_multiplier(qrb_long_value)
    elif qrb_long_mode == "die":
        qrb_spinner.get_node("SpinBox").value = 1
        qrb_spinner.popup_centered()


func _on_spinner_confirmed() -> void:
    var qty := int(qrb_spinner.get_node("SpinBox").value)
    _add_die(qrb_long_value, qty)
    qrb_long_active = false


func _build_expression() -> String:
    var parts: Array = []
    for entry in qrb_queue:
        parts.append(str(entry["count"]) + "d" + str(entry["faces"]))
    return " + ".join(parts)


func _on_roll_pressed() -> void:
    if qrb_queue.is_empty():
        return
    var parser := DiceParser.new()
    var expr := _build_expression()
    var res := parser.evaluate(expr)
    print("Rolled: %s -> %s" % [expr, res])
    qrb_queue.clear()
    qrb_last_faces = 0
    _update_queue_label()


func undo_last_action() -> void:
    if qrb_prev_queue.is_empty():
        return
    qrb_queue = []
    for entry in qrb_prev_queue:
        qrb_queue.append(entry.duplicate())
    qrb_prev_queue.clear()
    _update_queue_label()
