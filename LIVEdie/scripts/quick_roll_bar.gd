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
var qrb_input_replace: bool = true
var qrb_input_panel: PopupPanel
var qrb_input_edit: LineEdit

@onready var qrb_chip_box: HBoxContainer = $QueueRow/HScroll/DiceChips
@onready var qrb_history_button: Button = $"../HistoryButton"
@onready var qrb_history_panel: RollHistoryPanel = $"../RollHistoryPanel"


func _ready() -> void:
    _connect_dice_buttons($StandardRow)
    _connect_dice_buttons($AdvancedRow)
    $StandardRow/AdvancedToggle.pressed.connect(_on_toggle_advanced)
    $RepeaterRow/RollButton.pressed.connect(_on_roll_pressed)
    $RepeaterRow/DieX2.pressed.connect(_on_delete_pressed)
    $RepeaterRow/DieX.pressed.connect(_on_diex_pressed)
    _connect_repeat_buttons()
    $LongPressTimer.timeout.connect(_on_long_press_timeout)
    $PreviewDialog.confirmed.connect(_on_preview_confirmed)
    $DialSpinner.confirmed.connect(_on_spinner_confirmed)
    qrb_history_button.pressed.connect(_on_history_pressed)
    _build_input_panel()


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


func _on_delete_pressed() -> void:
    if qrb_queue.is_empty():
        return
    qrb_queue.pop_back()
    if qrb_queue.is_empty():
        qrb_last_faces = 0
    else:
        qrb_last_faces = qrb_queue[-1]["faces"]
    _update_queue_display()


func _on_diex_pressed() -> void:
    _open_input_panel()


func _open_input_panel() -> void:
    var start_val := qrb_last_faces if qrb_last_faces > 0 else 6
    qrb_input_edit.text = str(start_val)
    qrb_input_edit.select_all()
    qrb_input_replace = true
    qrb_input_panel.popup_centered()
    qrb_input_edit.grab_focus()


func _on_input_key(ch: String) -> void:
    if qrb_input_replace:
        qrb_input_edit.text = ch
        qrb_input_replace = false
    else:
        qrb_input_edit.text += ch
    qrb_input_edit.caret_column = qrb_input_edit.text.length()


func _on_input_del_pressed() -> void:
    var txt := qrb_input_edit.text
    if txt == "0":
        qrb_input_panel.hide()
        return
    if txt.length() > 1:
        txt = txt.substr(0, txt.length() - 1)
    else:
        txt = "0"
        qrb_input_replace = true
        qrb_input_edit.select_all()
    qrb_input_edit.text = txt
    qrb_input_edit.caret_column = txt.length()


func _on_input_ok_pressed() -> void:
    var faces := int(qrb_input_edit.text)
    if faces == 0:
        qrb_input_panel.hide()
        return
    _add_die(faces, 1)
    qrb_input_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
    if qrb_input_panel.visible and event is InputEventMouseButton and event.pressed:
        if not qrb_input_panel.get_global_rect().has_point(event.position):
            qrb_input_panel.hide()


func _build_input_panel() -> void:
    qrb_input_panel = PopupPanel.new()
    qrb_input_panel.name = "InputPanel"
    add_child(qrb_input_panel)
    var vb := VBoxContainer.new()
    qrb_input_panel.add_child(vb)
    qrb_input_edit = LineEdit.new()
    qrb_input_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vb.add_child(qrb_input_edit)
    var grid := GridContainer.new()
    grid.columns = 3
    vb.add_child(grid)
    var order := ["7", "8", "9", "4", "5", "6", "1", "2", "3", "DEL", "0", "OK"]
    for key in order:
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(80, 80)
        btn.add_theme_font_size_override("font_size", 32)
        grid.add_child(btn)
        if key.is_valid_int():
            btn.text = key
            btn.pressed.connect(_on_input_key.bind(key))
        elif key == "OK":
            btn.text = "\u2714"
            btn.pressed.connect(_on_input_ok_pressed)
        else:
            btn.text = "\u232b"
            btn.pressed.connect(_on_input_del_pressed)
    qrb_input_panel.hide()
