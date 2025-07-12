###############################################################
# LIVEdie/GOGOT/scripts/SettingsTab.gd
# Key Classes      • SettingsTab – handles settings interactions
# Key Functions    • _on_scale_changed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • UIStyleManager.gd
# Last Major Rev   • 24-07-13 – connect UI scale slider
###############################################################
class_name SettingsTab
extends VBoxContainer

@onready var ST_scale_slider_SH: HSlider = $UIScaleSlider


func _ready() -> void:
    ST_scale_slider_SH.value_changed.connect(_on_scale_changed)
    ST_scale_slider_SH.value = get_node("/root/UIStyleManager").US_scale_SH


func _on_scale_changed(value: float) -> void:
    get_node("/root/UIStyleManager").set_scale(value)
