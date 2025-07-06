###############################################################
# LIVEdie/scripts/roll_history_panel.gd
# Key Classes      • RollHistoryPanel – slide-up log of dice rolls
# Key Functions    • add_entry() – append roll text
#                   toggle() – expand or collapse panel
# Critical Consts  • none
# Dependencies     • none
# Last Major Rev   • 24-06-XX – initial version
###############################################################
class_name RollHistoryPanel
extends PanelContainer

@export var rhp_collapsed_height: int = 40
@export var rhp_expanded_height: int = 320

var rhp_open: bool = false

@onready var _list: VBoxContainer = $ScrollContainer/VBox
@onready var _close_btn: Button = $HeaderBar/CloseButton


func _ready() -> void:
    _close_btn.pressed.connect(toggle)
    collapse()


func toggle() -> void:
    if rhp_open:
        collapse()
    else:
        expand()


func expand() -> void:
    rhp_open = true
    anchor_bottom = 1.0
    anchor_top = 1.0
    offset_top = -rhp_expanded_height
    offset_bottom = 0


func collapse() -> void:
    rhp_open = false
    anchor_bottom = 1.0
    anchor_top = 1.0
    offset_top = -rhp_collapsed_height
    offset_bottom = 0


func add_entry(text: String) -> void:
    var row := HBoxContainer.new()
    var label := Label.new()
    label.text = text
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)
    _list.add_child(row)
