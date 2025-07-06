###############################################################
# LIVEdie/scripts/roll_history_panel.gd
# Key Classes      • RollHistoryPanel – slide-up drawer for rolls
# Key Functions    • add_entry() – append log entry
#                   show_panel() – open drawer
#                   hide_panel() – close drawer
# Dependencies     • none
# Last Major Rev   • 24-06-XX – initial implementation
###############################################################
class_name RollHistoryPanel
extends PanelContainer

@onready var _entries: VBoxContainer = $Scroll/Entries


func add_entry(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.custom_minimum_size.y = 48
    _entries.add_child(label)


func show_panel() -> void:
    show()


func hide_panel() -> void:
    hide()
