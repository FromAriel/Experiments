###############################################################
# LIVEdie/GOGOT/scripts/HistoryTab.gd
# Key Classes      • HistoryTab – records executed rolls
# Key Functions    • _on_roll_executed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • RollExecutor.gd, TimeUtils.gd
# Last Major Rev   • 24-07-14 – roll history UI
###############################################################
class_name HistoryTab
extends VBoxContainer
signal history_updated

const HT_ENTRY_SCENE_IN := preload("res://scenes/ui/RollHistoryEntry.tscn")
const HT_TIME_UTILS_IN := preload("res://helpers/TimeUtils.gd")


func _ready() -> void:
    get_node("/root/RollExecutor").roll_executed.connect(_on_roll_executed)


func _on_roll_executed(result: Dictionary) -> void:
    var entry: RollHistoryEntry = HT_ENTRY_SCENE_IN.instantiate()
    var ts_lbl: Label = entry.get_node("BG/Main/Header/TimestampLabel")
    ts_lbl.text = HT_TIME_UTILS_IN.friendly(result.timestamp)
    var sec = result.timestamp / 1000
    ts_lbl.hint_tooltip = Time.get_datetime_string_from_unix_time(sec, true)
    var sum_lbl: Label = entry.get_node("BG/Main/Header/SummaryLabel")
    sum_lbl.text = (
        "%s → %s = %d"
        % [result.notation, " + ".join(result.rolls.map(func(r): return str(r))), result.total]
    )
    var meta_lbl: Label = entry.get_node("BG/Main/Expanded/MetaLabel")
    meta_lbl.text = (
        "Succ: %d | Crit: %d | Fail: %d" % [result.meta.succ, result.meta.crit, result.meta.fail]
    )
    var json_lbl: Label = entry.get_node("BG/Main/Expanded/JSONLabel")
    json_lbl.text = JSON.stringify(result, "\t")
    var bg: ColorRect = entry.get_node("BG")
    bg.color = Color("#1c1c1c") if get_child_count() % 2 == 0 else Color("#222222")
    add_child(entry)
    move_child(entry, 0)
    await get_tree().process_frame
    if get_parent() is ScrollContainer:
        (get_parent() as ScrollContainer).scroll_vertical = 0
    history_updated.emit()
