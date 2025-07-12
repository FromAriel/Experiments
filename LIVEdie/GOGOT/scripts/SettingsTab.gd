###############################################################
# LIVEdie/GOGOT/scripts/SettingsTab.gd
# Key Classes      • SettingsTab – user preferences panel
# Key Functions    • _on_UIScaleSlider_value_changed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • UIStyleManager.gd
# Last Major Rev   • 25-07-12 – connect UI scale slider
###############################################################
class_name SettingsTab
extends VBoxContainer

@onready var ST_ui_scale_slider_SH: HSlider = $UIScaleSlider


func _ready() -> void:
    ST_ui_scale_slider_SH.value_changed.connect(_on_UIScaleSlider_value_changed)


func _on_UIScaleSlider_value_changed(value: float) -> void:
    get_node("/root/UIStyleManager").set_scale(value)
