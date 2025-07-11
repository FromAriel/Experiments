###############################################################
# LIVEdie/GOGOT/scripts/HistoryTab.gd
# Key Classes      • HistoryTab – records executed rolls
# Key Functions    • _on_roll_executed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • RollExecutor.gd
# Last Major Rev   • 24-07-12 – emit update signal
###############################################################
class_name HistoryTab
extends VBoxContainer
signal history_updated


func _ready() -> void:
    get_node("/root/RollExecutor").roll_executed.connect(_on_roll_executed)


func _HT_build_snippet_IN(sec: Dictionary) -> String:
    var snippet := ""
    if sec.rolls.size() > 1:
        snippet = " + ".join(sec.rolls.map(func(r): return str(r)))
    else:
        snippet = str(sec.value)
    if sec.has("meta"):
        var extras: Array = []
        if sec.meta.succ > 0:
            extras.append("%d successes" % sec.meta.succ)
        if sec.meta.crit > 0:
            extras.append("%d crit" % sec.meta.crit)
        if extras.size() > 0:
            snippet += " (" + ", ".join(extras) + ")"
    return snippet


func _on_roll_executed(result: Dictionary) -> void:
    var entry := Label.new()
    var parts: Array = []
    for sec in result.sections:
        parts.append(_HT_build_snippet_IN(sec))
    var text := "%s → %s" % [result.notation, " | ".join(parts)]
    entry.text = text
    add_child(entry)
    history_updated.emit()
