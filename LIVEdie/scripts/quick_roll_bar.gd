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
var qrb_long_press_button: Control

@onready var qrb_chip_box: HBoxContainer = $QueueRow/HScroll/DiceChips
@onready var qrb_history_button: Button = $"../HistoryButton"
@onready var qrb_history_panel: RollHistoryPanel = $"../RollHistoryPanel"
@onready var qrb_die_x_button: Button = $RepeaterRow/DieX
@onready var qrb_del_button: Button = $RepeaterRow/DelButton
@onready var qrb_spinner: DialSpinner = $DialSpinner


func _ready() -> void:
    _connect_dice_buttons($StandardRow)
    _connect_dice_buttons($AdvancedRow)
    $StandardRow/AdvancedToggle.pressed.connect(_on_toggle_advanced)
    $RepeaterRow/RollButton.pressed.connect(_on_roll_pressed)
    _connect_repeat_buttons()
    $LongPressTimer.timeout.connect(_on_long_press_timeout)
    $PreviewDialog.confirmed.connect(_on_preview_confirmed)
    $DialSpinner.confirmed.connect(_on_spinner_confirmed)
    qrb_spinner.keypad_confirmed.connect(_on_keypad_confirmed)
    qrb_spinner.keypad_canceled.connect(_on_keypad_canceled)
    qrb_history_button.pressed.connect(_on_history_pressed)
    qrb_die_x_button.pressed.connect(_on_die_x_pressed)
    qrb_del_button.pressed.connect(_on_del_pressed)


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
            node.button_down.connect(_on_die_down.bind(faces, node))
            node.button_up.connect(_on_die_up.bind(faces, node))


func _connect_repeat_buttons() -> void:
    for node in $RepeaterRow.get_children():
        if node is Button and node.name.begins_with("X"):
            var mult := int(node.text.substr(1))
            node.button_down.connect(_on_repeat_down.bind(mult, node))
            node.button_up.connect(_on_repeat_up.bind(mult, node))


func _on_toggle_advanced() -> void:
    $AdvancedRow.visible = not $AdvancedRow.visible


func _on_die_pressed(faces: int) -> void:
    _add_die(faces, 1)


func _on_repeat_pressed(mult: int) -> void:
    if qrb_last_faces == 0:
        return
    var entry = null
    if not qrb_queue.is_empty():
        entry = qrb_queue[-1]
    if entry != null and entry["faces"] == qrb_last_faces and entry["count"] == 1:
        entry["count"] = mult
        _update_queue_display()
    else:
        _add_die(qrb_last_faces, mult)


func _on_die_down(faces: int, btn: Button) -> void:
    qrb_long_press_type = "die"
    qrb_long_press_param = faces
    qrb_long_press_triggered = false
    qrb_long_press_button = btn
    if not Engine.is_editor_hint() and $LongPressTimer.is_inside_tree():
        $LongPressTimer.start()


func _on_die_up(faces: int, _btn: Button) -> void:
    if $LongPressTimer.time_left > 0.0:
        $LongPressTimer.stop()
        _on_die_pressed(faces)
    elif qrb_long_press_triggered:
        pass
    else:
        _on_die_pressed(faces)


func _on_repeat_down(mult: int, btn: Button) -> void:
    qrb_long_press_type = "repeat"
    qrb_long_press_param = mult
    qrb_long_press_triggered = false
    qrb_long_press_button = btn
    if not Engine.is_editor_hint() and $LongPressTimer.is_inside_tree():
        $LongPressTimer.start()


func _on_repeat_up(mult: int, _btn: Button) -> void:
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
    for child in qrb_chip_box.get_children():
        child.queue_free()
    if qrb_queue.is_empty():
        $QueueRow.hide()
        return
    $QueueRow.show()
    for entry in qrb_queue:
        var chip := Label.new()
        chip.text = "D%d × %d" % [entry["faces"], entry["count"]]
        chip.custom_minimum_size = Vector2(90, 40)
        chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        qrb_chip_box.add_child(chip)


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
    var center := qrb_long_press_button.get_global_rect().get_center()
    $DialSpinner.open_dial_at(center)


func _on_spinner_confirmed() -> void:
    var qty := int($DialSpinner.ds_value)
    _add_die(qrb_long_press_param, qty)


func _on_history_pressed() -> void:
    if qrb_history_panel.visible:
        qrb_history_panel.hide_panel()
    else:
        qrb_history_panel.show_panel()


func _on_roll_pressed() -> void:
    if qrb_queue.is_empty():
        return
    var parser := DiceParser.new()
    var expr := _build_expression()
    var res := parser.evaluate(expr)
    var total = res.get("total", res)
    var msg = "%s -> %s" % [expr, total]
    print("Rolled: %s" % msg)
    qrb_history_panel.add_entry(msg)
    qrb_queue.clear()
    qrb_last_faces = 0
    _update_queue_display()


func _on_del_pressed() -> void:
    if qrb_queue.is_empty():
        return
    qrb_queue.pop_back()
    if qrb_queue.is_empty():
        qrb_last_faces = 0
    else:
        qrb_last_faces = qrb_queue[-1]["faces"]
    _update_queue_display()


func _on_die_x_pressed() -> void:
    var center := qrb_die_x_button.get_global_rect().get_center()
    var initial := qrb_last_faces if qrb_last_faces > 0 else 6
    qrb_spinner.open_keypad_at(center, initial)


func _on_keypad_confirmed(val: int) -> void:
    if val > 0:
        _add_die(val, 1)


func _on_keypad_canceled() -> void:
    pass
