###############################################################
# LIVEdie/scripts/main.gd
# Key Classes      • Main – project root
# Key Functions    • _ready() – apply default fonts
# Critical Consts  • none
# Dependencies     • none
# Last Major Rev   • 24-07-XX – set global fonts
###############################################################
extends Control

@export var main_default_font_size: int = 32


func _ready() -> void:
    var theme := ThemeDB.get_default_theme()
    var base_font: Font = load("res://fonts/NotoSans-VariableFont_wdth,wght.ttf")
    var emoji_font: Font = load("res://fonts/NotoColorEmoji-Regular.ttf")
    base_font.fallbacks = [emoji_font]
    theme.default_font = base_font
    theme.default_font_size = main_default_font_size
