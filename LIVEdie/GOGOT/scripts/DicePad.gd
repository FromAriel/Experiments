# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/DicePad.gd
# Key Classes      • DicePad – manages dice input state and queue
# Key Functions    • _on_Quantity_pressed, _on_Die_pressed
# Critical Consts  • DP_LONG_PRESS_TIME
# Editor Exports   • (none)
# Dependencies     • UIEventBus.gd
# Last Major Rev   • 24-07-10 – initial implementation
###############################################################
class_name DicePad
extends VBoxContainer

const DP_LONG_PRESS_TIME: float = 0.5

@onready var DP_queue_label_SH: Label = $QueueLabel
@onready var DP_roll_btn_SH: Button = $AdvancedRow/RollBtn
var DP_custom_dialog_IN: AcceptDialog
var DP_current_quantity_SH: int = 1
var DP_backspace_timer_IN: Timer
var DP_backspace_long_SH: bool = false


func _ready() -> void:
    DP_backspace_timer_IN = Timer.new()
    DP_backspace_timer_IN.one_shot = true
    DP_backspace_timer_IN.wait_time = DP_LONG_PRESS_TIME
    DP_backspace_timer_IN.timeout.connect(_on_Backspace_long)
    add_child(DP_backspace_timer_IN)

    _connect_quantity_buttons()
    _connect_die_buttons()
    $AdvancedRow/DXPromptBtn.pressed.connect(_on_CustomDie_pressed)
    $AdvancedRow/PipeBtn.pressed.connect(_on_Pipe_pressed)
    $AdvancedRow/BackspaceBtn.pressed.connect(_on_Backspace_pressed)
    $AdvancedRow/BackspaceBtn.gui_input.connect(_on_Backspace_gui_input)
    $AdvancedRow/RollBtn.pressed.connect(_on_Roll_pressed)
    get_node("/root/RollExecutor").roll_failed.connect(_on_roll_failed)
    DP_custom_dialog_IN = AcceptDialog.new()
    add_child(DP_custom_dialog_IN)
    DP_custom_dialog_IN.canceled.connect(
        func():
            DP_queue_label_SH.text = DP_queue_label_SH.text.replace(", DX?", "").replace("DX?", "")
            _collapse_spaces()
    )
    _update_roll_button_state()


func _connect_quantity_buttons() -> void:
    var map := {
        $QtyRow/Qty1: 1,
        $QtyRow/Qty2: 2,
        $QtyRow/Qty3: 3,
        $QtyRow/Qty4: 4,
        $QtyRow/Qty5: 5,
        $QtyRow/Qty10: 10
    }
    for btn in map.keys():
        btn.pressed.connect(_on_Quantity_pressed.bind(map[btn]))


func _connect_die_buttons() -> void:
    var die_map := {
        $CommonDiceRow/D4: 4,
        $CommonDiceRow/D6: 6,
        $CommonDiceRow/D8: 8,
        $CommonDiceRow/D10: 10,
        $CommonDiceRow/D12: 12,
        $CommonDiceRow/D20: 20,
        $AdvancedRow/D2Btn: 2,
        $AdvancedRow/D100Btn: 100
    }
    for btn in die_map.keys():
        btn.pressed.connect(_on_Die_pressed.bind(die_map[btn]))


func _on_Quantity_pressed(value: int) -> void:
    DP_current_quantity_SH = value


func _on_Die_pressed(faces: int) -> void:
    var prefix := str(DP_current_quantity_SH) + "×D" + str(faces)
    var base := DP_queue_label_SH.text
    while base.ends_with(" ") or base.ends_with(","):
        base = base.substr(0, base.length() - 1)
    if base == "(no dice)" or base == "":
        DP_queue_label_SH.text = prefix
    elif base.ends_with("|"):
        DP_queue_label_SH.text = base + " " + prefix
    else:
        DP_queue_label_SH.text = base + ", " + prefix
    DP_current_quantity_SH = 1
    _update_roll_button_state()


func _on_CustomDie_pressed() -> void:
    if DP_queue_label_SH.text == "(no dice)" or DP_queue_label_SH.text == "":
        DP_queue_label_SH.text = "DX?"
    else:
        DP_queue_label_SH.text += ", DX?"
    _update_roll_button_state()


func _on_Pipe_pressed() -> void:
    var t := DP_queue_label_SH.text.rstrip(" ,").strip_edges(false, true)

    if t == "" or t.ends_with("|"):
        return

    DP_queue_label_SH.text = t + " | "
    _collapse_spaces()
    _update_roll_button_state()


func _on_Backspace_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        DP_backspace_timer_IN.start()
    elif event is InputEventMouseButton and not event.pressed:
        if DP_backspace_timer_IN.is_stopped():
            return
        DP_backspace_timer_IN.stop()
        if DP_backspace_long_SH:
            DP_backspace_long_SH = false


func _on_Backspace_long() -> void:
    DP_backspace_long_SH = true
    DP_queue_label_SH.text = ""
    _update_roll_button_state()


func _on_Backspace_pressed() -> void:
    if DP_backspace_long_SH:
        DP_backspace_long_SH = false
        return
    if DP_queue_label_SH.text.length() > 0:
        DP_queue_label_SH.text = DP_queue_label_SH.text.substr(
            0, DP_queue_label_SH.text.length() - 1
        )
        while (
            DP_queue_label_SH.text.ends_with(" ")
            or DP_queue_label_SH.text.ends_with(",")
            or DP_queue_label_SH.text.ends_with("|")
        ):
            DP_queue_label_SH.text = DP_queue_label_SH.text.substr(
                0, DP_queue_label_SH.text.length() - 1
            )
    _update_roll_button_state()


func _on_Roll_pressed() -> void:
    var clean := DP_queue_label_SH.text.replace("×", "").replace("D", "d")
    get_node("/root/UIEventBus").emit_signal("roll_requested", clean)


func _on_roll_failed(msg: String) -> void:
    DP_queue_label_SH.modulate = Color(1, 0.2, 0.2)
    push_warning(msg)
    create_tween().tween_property(DP_queue_label_SH, "modulate", Color(1, 1, 1), 0.4)


func _collapse_spaces() -> void:
    var re := RegEx.new()
    re.compile("\\s+")
    DP_queue_label_SH.text = re.sub(DP_queue_label_SH.text, " ")


func _update_roll_button_state() -> void:
    DP_roll_btn_SH.disabled = DP_queue_label_SH.text.rstrip(" ").ends_with("|")
