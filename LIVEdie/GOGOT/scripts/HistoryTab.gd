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
            parts.append(" + ".join(sec.rolls.map(func(r): return str(r))))
        else:
            parts.append(str(sec.value))
    var text := "%s → %s" % [result.notation, " | ".join(parts)]
    if result.sections.size() == 1 and result.sections[0].has("meta"):
        var m = result.sections[0].meta
        var extras := []
        if m.succ > 0:
            extras.append("%d successes" % m.succ)
        if m.crit > 0:
            extras.append("%d crit" % m.crit)
        if extras.size() > 0:
            text += " (" + ", ".join(extras) + ")"
    entry.text = text
    add_child(entry)
