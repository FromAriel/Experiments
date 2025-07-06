#
# LIVEdie/scripts/quick_roll_bar.gd
# Key Classes      • QuickRollBar – UI for quick dice selection
# Key Functions    • _on_die_pressed() – queue dice
#                   • _on_repeat_pressed() – update last die count
# Critical Consts  • QRB_STANDARD_FACES – default dice set
# Dependencies     • none
# Last Major Rev   • 24-04-XX – initial version
###############################################################
class_name QuickRollBar
extends VBoxContainer

const QRB_STANDARD_FACES := [2, 4, 6, 8, 10, 12, 20, 100]
const QRB_ADVANCED_FACES := [13, 16, 24, 30, 60]
const QRB_REPEAT_COUNTS := [1, 2, 3, 4, 5, 10]

var qrb_queue := []
var qrb_last_index := -1


func _ready() -> void:
    _qrb_create_dice_buttons()
    _qrb_create_repeat_buttons()
    _qrb_update_queue()


func _qrb_create_dice_buttons() -> void:
    var standard := $StandardRow
    for f in QRB_STANDARD_FACES:
        var b := Button.new()
        var label := "D"
        if f == 100:
            label += "%"
        else:
            label += str(f)
        b.text = label
        b.pressed.connect(_on_die_pressed.bind(f))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        standard.add_child(b)

    var adv_toggle := Button.new()
    adv_toggle.text = "\u25BC"  # down chevron
    adv_toggle.pressed.connect(_on_toggle_advanced)
    adv_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    standard.add_child(adv_toggle)

    var roll := Button.new()
    roll.text = "ROLL"
    roll.pressed.connect(_on_roll)
    roll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    standard.add_child(roll)

    var advanced := $AdvancedRow
    for f in QRB_ADVANCED_FACES:
        var b2 := Button.new()
        b2.text = "D" + str(f)
        b2.pressed.connect(_on_die_pressed.bind(f))
        b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        advanced.add_child(b2)


func _qrb_create_repeat_buttons() -> void:
    var rep := $RepeaterRow
    for n in QRB_REPEAT_COUNTS:
        var b := Button.new()
        b.text = "x" + str(n)
        b.pressed.connect(_on_repeat_pressed.bind(n))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        rep.add_child(b)


func _on_toggle_advanced() -> void:
    $AdvancedRow.visible = not $AdvancedRow.visible


func _on_die_pressed(faces: int) -> void:
    var entry := {"faces": faces, "count": 1}
    qrb_queue.append(entry)
    qrb_last_index = qrb_queue.size() - 1
    _qrb_update_queue()


func _on_repeat_pressed(mult: int) -> void:
    if qrb_last_index >= 0 and qrb_last_index < qrb_queue.size():
        qrb_queue[qrb_last_index]["count"] = mult
        _qrb_update_queue()


func _on_roll() -> void:
    # Placeholder for integration with dice parser
    pass


func _qrb_update_queue() -> void:
    var text := ""
    for entry in qrb_queue:
        var faces = entry["faces"]
        var count = entry["count"]
        var die_label := "d"
        if faces == 100:
            die_label += "%"
        else:
            die_label += str(faces)
        text += die_label
        if count > 1:
            text += _qrb_superscript(count)
        text += " "
    $QueueLabel.text = text.strip_edges()


func _qrb_superscript(num: int) -> String:
    var digits := {
        "0": "\u2070",
        "1": "\u00B9",
        "2": "\u00B2",
        "3": "\u00B3",
        "4": "\u2074",
        "5": "\u2075",
        "6": "\u2076",
        "7": "\u2077",
        "8": "\u2078",
        "9": "\u2079",
    }
    var s := str(num)
    var out := ""
    for c in s:
        out += digits.get(c, "")
    return out
