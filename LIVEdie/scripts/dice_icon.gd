###############################################################
# LIVEdie/scripts/dice_icon.gd
# Key Classes      • DiceIcon – draws a glyph-based die icon
# Key Functions    • _draw() – render shape and number glyphs
# Critical Consts  • none
# Dependencies     • none
# Last Major Rev   • 2025-07-07 – initial implementation
###############################################################
class_name DiceIcon
extends Control

@export var di_shape_glyph: String = "▲":
    set(value):
        di_shape_glyph = value
        if is_inside_tree():
            queue_redraw()

@export var di_number_glyph: String = "4":
    set(value):
        di_number_glyph = value
        if is_inside_tree():
            queue_redraw()

@export var di_shape_color: Color = Color(1, 1, 1):
    set(value):
        di_shape_color = value
        if is_inside_tree():
            queue_redraw()

@export var di_number_color: Color = Color(0, 0, 0):
    set(value):
        di_number_color = value
        if is_inside_tree():
            queue_redraw()

@export var di_shape_font_size: int = 40:
    set(value):
        di_shape_font_size = value
        if is_inside_tree():
            queue_redraw()

@export var di_number_font_size: int = 24:
    set(value):
        di_number_font_size = value
        if is_inside_tree():
            queue_redraw()

@export var di_font: Font


func _ready() -> void:
    queue_redraw()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()


func _draw() -> void:
    var font := di_font if di_font != null else get_theme_default_font()
    var w: float = size.x
    var shape_y := _center_y(font, di_shape_font_size)
    draw_string(
        font,
        Vector2(w / 2.0, shape_y),
        di_shape_glyph,
        HORIZONTAL_ALIGNMENT_CENTER,
        w,
        di_shape_font_size,
        di_shape_color
    )
    var num_y := _center_y(font, di_number_font_size)
    draw_string(
        font,
        Vector2(w / 2.0, num_y),
        di_number_glyph,
        HORIZONTAL_ALIGNMENT_CENTER,
        w,
        di_number_font_size,
        di_number_color
    )


func _center_y(font: Font, font_size: int) -> float:
    var h: float = font.get_height(font_size)
    var asc: float = font.get_ascent(font_size)
    return (size.y - h) / 2.0 + asc
