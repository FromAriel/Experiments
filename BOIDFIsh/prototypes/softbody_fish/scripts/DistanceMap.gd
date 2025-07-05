# gdlint:disable = class-variable-name,function-name
# Helper node to capture the fish silhouette into a viewport and
# produce a blurred distance map image for shader use.

class_name DistanceMap
extends Node

@export var DM_viewport_size_IN: Vector2i = Vector2i(128, 128)
@export var DM_blur_downscale_IN: int = 4

var DM_viewport_RD: Viewport
var DM_polygon_RD: Polygon2D
var DM_distance_texture_RD: ImageTexture


func _ready() -> void:
    DM_viewport_RD = Viewport.new()
    DM_viewport_RD.disable_3d = true
    DM_viewport_RD.size = DM_viewport_size_IN
    DM_viewport_RD.render_target_update_mode = Viewport.UPDATE_ALWAYS
    DM_viewport_RD.render_target_v_flip = true
    DM_viewport_RD.clear_color = Color.BLACK
    add_child(DM_viewport_RD)
    DM_viewport_RD.hide()

    DM_polygon_RD = Polygon2D.new()
    DM_polygon_RD.color = Color.WHITE
    DM_viewport_RD.add_child(DM_polygon_RD)

    DM_distance_texture_RD = ImageTexture.create_from_image(
        Image.create(DM_viewport_size_IN.x, DM_viewport_size_IN.y, false, Image.FORMAT_RF)
    )


func update_polygon(points: PackedVector2Array) -> void:
    var offset := Vector2(DM_viewport_size_IN) * 0.5
    var pts := PackedVector2Array()
    for p in points:
        pts.append(p + offset)
    DM_polygon_RD.polygon = pts
    _update_distance_texture()


func _update_distance_texture() -> void:
    var img := DM_viewport_RD.get_texture().get_image()
    var tmp := img.duplicate()
    if DM_blur_downscale_IN > 1:
        (
            tmp
            . resize(
                DM_viewport_size_IN.x / DM_blur_downscale_IN,
                DM_viewport_size_IN.y / DM_blur_downscale_IN,
                Image.INTERPOLATE_BILINEAR,
            )
        )
        tmp.resize(DM_viewport_size_IN.x, DM_viewport_size_IN.y, Image.INTERPOLATE_BILINEAR)
    DM_distance_texture_RD.set_image(tmp)
