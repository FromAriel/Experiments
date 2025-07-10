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
    if DP_queue_label_SH.text == "(no dice)" or DP_queue_label_SH.text == "":
        DP_queue_label_SH.text = prefix
    else:
        DP_queue_label_SH.text += ", " + prefix
    DP_current_quantity_SH = 1


func _on_CustomDie_pressed() -> void:
    if DP_queue_label_SH.text == "(no dice)" or DP_queue_label_SH.text == "":
        DP_queue_label_SH.text = "DX?"
    else:
        DP_queue_label_SH.text += ", DX?"


func _on_Pipe_pressed() -> void:
    DP_queue_label_SH.text += " | "


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


func _on_Backspace_pressed() -> void:
    if DP_backspace_long_SH:
        DP_backspace_long_SH = false
        return
    if DP_queue_label_SH.text.length() > 0:
        DP_queue_label_SH.text = DP_queue_label_SH.text.substr(
            0, DP_queue_label_SH.text.length() - 1
        )


func _on_Roll_pressed() -> void:
    print(DP_queue_label_SH.text)
