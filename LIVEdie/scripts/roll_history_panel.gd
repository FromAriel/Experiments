###############################################################
# LIVEdie/scripts/roll_history_panel.gd
# Key Classes      • RollHistoryPanel – slide-up history drawer
# Key Functions    • add_entry() – record a new roll
# Dependencies     • none
# Last Major Rev   • 24-06-XX – initial history panel
###############################################################
class_name RollHistoryPanel
extends PanelContainer

var rhp_entries: Array = []

@onready var rhp_vbox: VBoxContainer = $ScrollContainer/VBox


func add_entry(expr: String, result: String) -> void:
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 48
    var label := Label.new()
    label.text = "%s -> %s" % [expr, result]
    row.add_child(label)
    rhp_vbox.add_child(row)
    rhp_entries.push_front({"expr": expr, "result": result})
