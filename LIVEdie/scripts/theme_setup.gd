###############################################################
# LIVEdie/scripts/theme_setup.gd
# Key Classes      • ThemeSetup – sets project fonts
# Key Functions    • _ready() – apply font with emoji fallback
# Dependencies     • none
# Last Major Rev   • 24-07-07 – initial font setup
###############################################################
extends Node


func _ready() -> void:
    var base_font: Font = load("res://fonts/NotoSans-VariableFont_wdth,wght.ttf")
    var emoji_font: Font = load("res://fonts/NotoColorEmoji-Regular.ttf")
    if base_font and emoji_font:
        base_font.set_fallbacks([emoji_font])
        var theme := Theme.new()
        theme.set_default_font(base_font)
        get_tree().root.theme = theme
