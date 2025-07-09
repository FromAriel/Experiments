###############################################################
# DieGlyphButton.gd – Glyph dice button (80×80 default)
# Godot 4.4.1-stable, no inline-if assignments.
###############################################################
extends Button
class_name DieGlyphButton

# ───────── Glyph table ───────────────────────────────────────
const GLYPH_MAP: Dictionary = {
    2:  "💰",
    4:  "▲",
    6:  "■",
    8:  "⬟",
    10: "⬙",
    12: "⬢",
    20: "✪",
    100: "✪"   # D%
}

# ───────── Backing fields ────────────────────────────────────
var _die_faces       : int    = 6
var _override_glyph  : String = ""
var _glyph_color     : Color  = Color("#333333")
var _number_color    : Color  = Color.WHITE
var _glyph_pt        : int    = 54
var _number_pt       : int    = 28
var _glyph_font      : Font   = null
var _number_font     : Font   = null
var _font_scale      : float  = 1.0

# runtime nodes
var _glyph_lbl : Label = null
var _num_lbl   : Label = null

# ───────── Exported API ──────────────────────────────────────
@export var die_faces: int:
    get: return _die_faces
    set(value):
        _die_faces = max(value, 1)
        _refresh_labels()

@export var override_glyph: String:
    get: return _override_glyph
    set(value):
        _override_glyph = value
        _refresh_labels()

@export var glyph_color: Color:
    get: return _glyph_color
    set(value):
        _glyph_color = value
        if _glyph_lbl != null:
            _glyph_lbl.modulate = _glyph_color

@export var number_color: Color:
    get: return _number_color
    set(value):
        _number_color = value
        if _num_lbl != null:
            _num_lbl.modulate = _number_color

@export var glyph_font_size: int:
    get: return _glyph_pt
    set(value):
        _glyph_pt = value
        _apply_fonts()

@export var number_font_size: int:
    get: return _number_pt
    set(value):
        _number_pt = value
        _apply_fonts()

@export var glyph_font: Font:
    get: return _glyph_font
    set(value):
        _glyph_font = value
        _apply_fonts()

@export var number_font: Font:
    get: return _number_font
    set(value):
        _number_font = value
        _apply_fonts()

@export var font_scale: float:
    get: return _font_scale
    set(value):
        _font_scale = clamp(value, 0.25, 4.0)
        _apply_fonts()

# ───────── Ready ────────────────────────────────────────────
func _ready() -> void:
    # hide built-in Button text & colours
    text = ""
    var clear := Color(0, 0, 0, 0)
    add_theme_color_override("font_color", clear)
    add_theme_color_override("font_hover_color", clear)
    add_theme_color_override("font_pressed_color", clear)

    # overlay labels
    _glyph_lbl = _make_full_label()
    _num_lbl   = _make_full_label()
    add_child(_glyph_lbl)
    add_child(_num_lbl)

    _refresh_labels()
    _apply_fonts()

# ───────── Helpers ──────────────────────────────────────────
func _make_full_label() -> Label:
    var l := Label.new()
    l.anchor_left   = 0.0
    l.anchor_top    = 0.0
    l.anchor_right  = 1.0
    l.anchor_bottom = 1.0
    l.offset_left   = 0.0
    l.offset_top    = 0.0
    l.offset_right  = 0.0
    l.offset_bottom = 0.0
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    l.mouse_filter         = Control.MOUSE_FILTER_IGNORE
    return l

func _chosen_glyph() -> String:
    if _override_glyph.strip_edges() != "":
        return _override_glyph
    return GLYPH_MAP.get(_die_faces, "✪")

func _refresh_labels() -> void:
    if _glyph_lbl != null:
        _glyph_lbl.text     = _chosen_glyph()
        _glyph_lbl.modulate = _glyph_color
    if _num_lbl != null:
        _num_lbl.text       = str(_die_faces)
        _num_lbl.modulate   = _number_color

func _apply_fonts() -> void:
    var g_pt_scaled: int = int(_glyph_pt  * _font_scale)
    var n_pt_scaled: int = int(_number_pt * _font_scale)

    if _glyph_lbl != null:
        _glyph_lbl.add_theme_font_override("font", _glyph_font)
        _glyph_lbl.add_theme_font_size_override("font_size", g_pt_scaled)
    if _num_lbl != null:
        _num_lbl.add_theme_font_override("font", _number_font)
        _num_lbl.add_theme_font_size_override("font_size", n_pt_scaled)
