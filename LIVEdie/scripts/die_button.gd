###############################################################
# LIVEdie/scripts/die_button.gd
# Key Classes      • DieButton – button with dice glyph overlay
# Key Functions    • _update_glyphs() – refresh label styles
# Critical Consts  • none
# Dependencies     • none
# Last Major Rev   • 24-06-XX – initial implementation
###############################################################
class_name DieButton
extends Button

@export var db_faces: int = 4:
    set(value):
        db_faces = value
        if is_inside_tree():
            _update_glyphs()

@export var db_shape_glyph: String = "▲":
    set(value):
        db_shape_glyph = value
        if is_inside_tree():
            _update_glyphs()

@export var db_shape_color: Color = Color.WHITE:
    set(value):
        db_shape_color = value
        if is_inside_tree():
            _update_glyphs()

@export var db_number_color: Color = Color.BLACK:
    set(value):
        db_number_color = value
        if is_inside_tree():
            _update_glyphs()

@export var db_shape_font_size: int = 60:
    set(value):
        db_shape_font_size = value
        if is_inside_tree():
            _update_glyphs()

@export var db_number_font_size: int = 32:
    set(value):
        db_number_font_size = value
        if is_inside_tree():
            _update_glyphs()

var db_shape_label: Label
var db_number_label: Label


func _ready() -> void:
    text = "D%d" % db_faces
    add_theme_color_override("font_color", Color(0, 0, 0, 0))
    db_shape_label = Label.new()
    db_number_label = Label.new()
    db_shape_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    db_shape_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    db_shape_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    db_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    db_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    db_number_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    add_child(db_shape_label)
    add_child(db_number_label)
    set_meta("faces", db_faces)
    _update_glyphs()


func _update_glyphs() -> void:
    db_shape_label.text = db_shape_glyph
    db_number_label.text = str(db_faces)
    db_shape_label.add_theme_color_override("font_color", db_shape_color)
    db_number_label.add_theme_color_override("font_color", db_number_color)
    db_shape_label.add_theme_font_size_override("font_size", db_shape_font_size)
    db_number_label.add_theme_font_size_override("font_size", db_number_font_size)
