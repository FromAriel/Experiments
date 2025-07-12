###############################################################
# LIVEdie/GOGOT/scripts/HistoryTab.gd
# Key Classes      • HistoryTab – records executed rolls
# Key Functions    • _on_roll_executed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • RollExecutor.gd
# Last Major Rev   • 24-07-14 – add dynamic history entries
###############################################################
class_name HistoryTab
extends VBoxContainer
signal history_updated

const HT_ENTRY_SCENE_IN := preload("res://scenes/ui/RollHistoryEntry.tscn")
const HT_TIME_UTIL_IN := preload("res://helpers/TimeUtils.gd")


func _ready() -> void:
    get_node("/root/RollExecutor").roll_executed.connect(_on_roll_executed)
    if has_node("HistoryPlaceholder"):
        get_node("HistoryPlaceholder").queue_free()


func _on_roll_executed(result: Dictionary) -> void:
    var entry: RollHistoryEntry = HT_ENTRY_SCENE_IN.instantiate()
    var ts: int = result.get("timestamp", int(Time.get_unix_time_from_system() * 1000))
    entry.get_node("BG/Main/Header/TimestampLabel").text = HT_TIME_UTIL_IN.friendly(ts)
    entry.get_node("BG/Main/Header/TimestampLabel").tooltip_text = (
        Time.get_datetime_string_from_unix_time(ts / 1000.0, true)
    )
    var rolls: Array = []
    for r in result.get("rolls", []):
        rolls.append(str(r))
    entry.get_node("BG/Main/Header/SummaryLabel").text = (
        "%s → %s = %d"
        % [result.get("notation", ""), " + ".join(rolls), int(result.get("total", 0))]
    )
    var meta: Dictionary = result.get("meta", {"succ": 0, "crit": 0, "fail": 0})
    entry.get_node("BG/Main/Expanded/MetaLabel").text = (
        "Succ: %d | Crit: %d | Fail: %d"
        % [int(meta.get("succ", 0)), int(meta.get("crit", 0)), int(meta.get("fail", 0))]
    )
    entry.get_node("BG/Main/Expanded/JSONLabel").text = JSON.stringify(result, "\t")
    var idx := get_child_count()
    entry.get_node("BG").color = Color("#1c1c1c") if idx % 2 == 0 else Color("#222222")
    add_child(entry, true, 0)
    await get_tree().process_frame
    (get_parent() as ScrollContainer).scroll_vertical = 0
    history_updated.emit()
