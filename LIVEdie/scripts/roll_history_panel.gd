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

@export var rhp_entry_font_size: int = 24

@onready var _entries: VBoxContainer = $Scroll/Entries


func add_entry(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.custom_minimum_size.y = 48
    label.add_theme_font_size_override("font_size", rhp_entry_font_size)
    _entries.add_child(label)
    _entries.move_child(label, 0)
    $Scroll.scroll_vertical = 0


func show_panel() -> void:
    show()


func hide_panel() -> void:
    hide()
