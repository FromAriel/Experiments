# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/prototypes/softbody_fish/scripts/PillowNormal.gd
# Key Classes      • PillowNormal – dynamic heightmap generator
# Key Functions    • PN_update_points() – updates polygon data
# Critical Consts  • PN_MARGIN_SH – padding around polygon
# Editor Exports   • PN_texture_size_IN: Vector2i
# Dependencies     • shaders/gaussian_blur.gdshader
# Last Major Rev   • 24-05-01 – initial version
###############################################################
class_name PillowNormal
extends Node2D

const PN_MARGIN_SH: float = 2.0

@export var PN_texture_size_IN: Vector2i = Vector2i(128, 64)

var PN_heightmap_RD: Texture2D

var _sil_vp: Viewport
var _h_vp: Viewport
var _v_vp: Viewport
var _poly: Polygon2D
var _h_mat: ShaderMaterial
var _v_mat: ShaderMaterial
var _h_rect: ColorRect
var _v_rect: ColorRect


func _ready() -> void:
    _init_viewports()
    PN_heightmap_RD = _v_vp.get_texture()


func _init_viewports() -> void:
    _sil_vp = _make_viewport()
    _h_vp = _make_viewport()
    _v_vp = _make_viewport()
    add_child(_sil_vp)
    add_child(_h_vp)
    add_child(_v_vp)

    _poly = Polygon2D.new()
    _poly.color = Color.WHITE
    _sil_vp.add_child(_poly)

    _h_rect = _make_blur_rect(_sil_vp.get_texture(), Vector2(1.0, 0.0))
    _h_vp.add_child(_h_rect)

    _v_rect = _make_blur_rect(_h_vp.get_texture(), Vector2(0.0, 1.0))
    _v_vp.add_child(_v_rect)


func _make_viewport() -> SubViewport:
    var vp: SubViewport = SubViewport.new()
    vp.disable_3d = true
    vp.transparent_bg = false
    vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    vp.size = PN_texture_size_IN
    return vp


func _make_blur_rect(base_tex: Texture2D, dir: Vector2) -> ColorRect:
    var rect: ColorRect = ColorRect.new()
    rect.size = PN_texture_size_IN
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var mat: ShaderMaterial = ShaderMaterial.new()
    mat.shader = load("res://shaders/gaussian_blur.gdshader")
    mat.set_shader_parameter("base_texture", base_tex)
    mat.set_shader_parameter("tex_size", Vector2(PN_texture_size_IN))
    mat.set_shader_parameter("blur_direction", dir)
    rect.material = mat
    if dir.x > 0.0:
        _h_mat = mat
    else:
        _v_mat = mat
    return rect


func PN_update_points(points: PackedVector2Array) -> void:
    if points.is_empty():
        return
    var rect: Rect2 = Rect2(points[0], Vector2.ZERO)
    for p in points:
        rect = rect.expand(p)
    rect = rect.grow(PN_MARGIN_SH)
    var size: Vector2i = rect.size.ceil()
    _sil_vp.size = size
    _h_vp.size = size
    _v_vp.size = size
    _h_rect.size = size
    _v_rect.size = size
    _h_mat.set_shader_parameter("tex_size", Vector2(size))
    _v_mat.set_shader_parameter("tex_size", Vector2(size))
    var poly: PackedVector2Array = PackedVector2Array()
    for p in points:
        poly.append(p - rect.position)
    _poly.polygon = poly
    PN_heightmap_RD = _v_vp.get_texture()


func PN_get_size() -> Vector2i:
    return _v_vp.size
