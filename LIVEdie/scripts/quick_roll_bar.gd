###############################################################
# LIVEdie/scripts/quick_roll_bar.gd
# Key Classes      • QuickRollBar – UI for standard/advanced dice
# Key Functions    • _on_die_pressed() – queue dice
#                   • _on_repeat_pressed() – update last die count
# Critical Consts  • QR_SUPERSCRIPTS – superscript digits
# Dependencies     • dice_parser.gd
# Last Major Rev   • 24-04-XX – initial version
###############################################################
class_name QuickRollBar
extends Control

const QR_SUPERSCRIPTS := {
    0: "\u2070",
    1: "\u00b9",
    2: "\u00b2",
    3: "\u00b3",
    4: "\u2074",
    5: "\u2075",
    6: "\u2076",
    7: "\u2077",
    8: "\u2078",
    9: "\u2079"
}

var qr_queue: Array = []
var qr_last_index := -1
var qr_parser := DiceParser.new()

@onready var qr_label_queue: Label = $VBox/QueueLabel
@onready var qr_label_result: Label = $VBox/ResultLabel
@onready var qr_advanced_row: Control = $VBox/AdvancedRow


func _ready() -> void:
    for b in $VBox/StandardRow.get_children():
        if b is Button:
            b.pressed.connect(_on_die_pressed.bind(b.text))
    for b in $VBox/AdvancedRow.get_children():
        if b is Button:
            b.pressed.connect(_on_die_pressed.bind(b.text))
    for b in $VBox/RepeatRow.get_children():
        if b is Button:
            b.pressed.connect(_on_repeat_pressed.bind(b.text))


func _on_die_pressed(label: String) -> void:
    if label == "ROLL":
        _roll_dice()
        return
    if label == "\u25BC":
        qr_advanced_row.visible = not qr_advanced_row.visible
        return
    var faces := 0
    if label == "D%":
        faces = 100
    elif label.begins_with("DX"):
        faces = 6
    else:
        faces = int(label.substr(1))
    qr_queue.append({"faces": faces, "count": 1})
    qr_last_index = qr_queue.size() - 1
    _qr_update_queue_label()


func _on_repeat_pressed(label: String) -> void:
    if qr_last_index == -1:
        return
    var mult := int(label.substr(1))
    qr_queue[qr_last_index]["count"] = mult
    _qr_update_queue_label()


func _qr_update_queue_label() -> void:
    var parts := []
    for entry in qr_queue:
        var txt := "d" + str(entry["faces"])
        if entry["count"] > 1:
            txt += _qr_superscript(entry["count"])
        parts.append(txt)
    qr_label_queue.text = "Queue: " + " ".join(parts)


func _qr_superscript(num: int) -> String:
    var digits := []
    var n := num
    if n == 0:
        return QR_SUPERSCRIPTS[0]
    while n > 0:
        digits.push_front(QR_SUPERSCRIPTS[n % 10])
        n = int(n / 10)
    return "".join(digits)


func _roll_dice() -> void:
    if qr_queue.is_empty():
        return
    var expr_parts := []
    for entry in qr_queue:
        expr_parts.append(str(entry["count"]) + "d" + str(entry["faces"]))
    var expr := "+".join(expr_parts)
    var result := qr_parser.evaluate(expr)
    qr_label_result.text = "Result: " + str(result["total"])
    qr_queue.clear()
    qr_last_index = -1
    _qr_update_queue_label()
