###############################################################
# LIVEdie/scripts/main.gd
# Key Classes      • Main – root controller
# Key Functions    • _on_history_button_pressed() – toggle history drawer
# Critical Consts  • none
# Dependencies     • RollHistoryPanel
# Last Major Rev   • 24-06-XX – add history support
###############################################################
class_name Main
extends Control

@onready var _history: RollHistoryPanel = $RollHistoryPanel


func _ready() -> void:
    $HistoryButton.pressed.connect(_on_history_button_pressed)


func _on_history_button_pressed() -> void:
    _history.toggle()
