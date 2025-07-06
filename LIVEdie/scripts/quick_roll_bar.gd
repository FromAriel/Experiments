###############################################################
# LIVEdie/scripts/quick_roll_bar.gd
# Key Classes      • QuickRollBar – UI for rapid dice selection
# Key Functions    • _on_die_pressed() – handle die tap
#                   • _on_repeat_pressed() – handle repeater buttons
#                   • _update_queue_label() – refresh queue text
# Critical Consts  • QRB_SUPERSCRIPTS – map digits to superscripts
# Dependencies     • dice_parser.gd
# Last Major Rev   • 24-05-08 – initial version
###############################################################
class_name QuickRollBar
extends Control

const QRB_SUPERSCRIPTS := {
    "0": "⁰",
    "1": "¹",
    "2": "²",
    "3": "³",
    "4": "⁴",
    "5": "⁵",
    "6": "⁶",
    "7": "⁷",
    "8": "⁸",
    "9": "⁹",
}

var qrb_dice_queue: Array = []
var qrb_last_faces: int = 6

var qrb_standard_row: HBoxContainer
var qrb_advanced_row: HBoxContainer
var qrb_repeat_row: HBoxContainer
var qrb_queue_label: Label


func _ready() -> void:
    var vbox := VBoxContainer.new()
    vbox.anchor_right = 1.0
    vbox.anchor_bottom = 1.0
    add_child(vbox)

    qrb_standard_row = HBoxContainer.new()
    vbox.add_child(qrb_standard_row)

    qrb_advanced_row = HBoxContainer.new()
    qrb_advanced_row.visible = false
    vbox.add_child(qrb_advanced_row)

    qrb_repeat_row = HBoxContainer.new()
    vbox.add_child(qrb_repeat_row)

    var qb := HBoxContainer.new()
    vbox.add_child(qb)
    qrb_queue_label = Label.new()
    qb.add_child(qrb_queue_label)

    _create_standard_buttons()
    _create_advanced_buttons()
    _create_repeat_buttons()
    _update_queue_label()


func _on_die_pressed(faces: int) -> void:
    qrb_dice_queue.append(faces)
    qrb_last_faces = faces
    _update_queue_label()


func _on_repeat_pressed(mult: int) -> void:
    for i in range(mult - 1):
        qrb_dice_queue.append(qrb_last_faces)
    _update_queue_label()


func _on_roll_pressed() -> void:
    var parser := DiceParser.new()
    var expr_parts := []
    var counts := {}
    for f in qrb_dice_queue:
        counts[f] = counts.get(f, 0) + 1
    for f in counts.keys():
        var c: int = counts[f]
        expr_parts.append("%dd%d" % [c, f])
    var expr := " + ".join(expr_parts)
    if expr_parts.size() > 0:
        var res := parser.evaluate(expr)
        print(res)
    qrb_dice_queue.clear()
    _update_queue_label()


func _on_toggle_advanced_pressed() -> void:
    qrb_advanced_row.visible = not qrb_advanced_row.visible


func _create_standard_buttons() -> void:
    var faces_list := [2, 4, 6, 8, 10, 12, 20, 100]
    for f in faces_list:
        var b := Button.new()
        var label := "D%d" % f
        if f == 100:
            label = "D%"
        b.text = label
        b.pressed.connect(_on_die_pressed.bind(f))
        qrb_standard_row.add_child(b)
    var toggle := Button.new()
    toggle.text = "\u25BC"
    toggle.pressed.connect(_on_toggle_advanced_pressed)
    qrb_standard_row.add_child(toggle)
    var roll := Button.new()
    roll.text = "ROLL"
    roll.pressed.connect(_on_roll_pressed)
    qrb_standard_row.add_child(roll)


func _create_advanced_buttons() -> void:
    var adv_faces := [13, 16, 24, 30, 60]
    for f in adv_faces:
        var b := Button.new()
        b.text = "D%d" % f
        b.pressed.connect(_on_die_pressed.bind(f))
        qrb_advanced_row.add_child(b)


func _create_repeat_buttons() -> void:
    var reps := [1, 2, 3, 4, 5, 10]
    for n in reps:
        var b := Button.new()
        b.text = "x%d" % n
        b.pressed.connect(_on_repeat_pressed.bind(n))
        qrb_repeat_row.add_child(b)


func _update_queue_label() -> void:
    var counts: Dictionary = {}
    for f in qrb_dice_queue:
        counts[f] = counts.get(f, 0) + 1
    var parts: Array = []
    for f in counts.keys():
        var c: int = counts[f]
        var s := "d%d" % f
        if c > 1:
            s += _to_superscript(str(c))
        parts.append(s)
    qrb_queue_label.text = " ".join(parts)


func _to_superscript(text: String) -> String:
    var out := ""
    for c in text:
        out += QRB_SUPERSCRIPTS.get(c, "")
    return out
