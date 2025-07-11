###############################################################
# LIVEdie/GOGOT/scripts/HistoryTab.gd
# Key Classes      • HistoryTab – records executed rolls
# Key Functions    • _on_roll_executed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • RollExecutor.gd
# Last Major Rev   • 24-07-11 – initial stub
###############################################################
class_name HistoryTab
extends VBoxContainer


func _ready() -> void:
    get_node("/root/RollExecutor").roll_executed.connect(_on_roll_executed)


func _on_roll_executed(result: Dictionary) -> void:
    var entry := Label.new()
    var parts := []
    for sec in result.sections:
        if sec.rolls.size() > 1:
            parts.append(sec.rolls.map(func(r): return str(r)).join(" + "))
        else:
            parts.append(str(sec.value))
    entry.text = "%s → %s" % [result.notation, " | ".join(parts)]
    add_child(entry)
