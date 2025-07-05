# gdlint:disable = class-variable-name,function-name
###############################################################
# BOIDFIsh/prototypes/softbody_fish/scripts/FishMaskDrawer.gd
# Key Classes      • FishMaskDrawer – renders silhouette mask
# Key Functions    • FMD_set_mesh() – update point buffer
# Dependencies     • none
# Last Major Rev   • 24-04-30 – initial version
###############################################################
class_name FishMaskDrawer
extends Node2D

var FMD_points_UP: PackedVector2Array = PackedVector2Array()
var FMD_triangles_UP: PackedInt32Array = PackedInt32Array()


func FMD_set_mesh(points: PackedVector2Array, tris: PackedInt32Array) -> void:
    FMD_points_UP = points
    FMD_triangles_UP = tris
    queue_redraw()


func _draw() -> void:
    if FMD_points_UP.size() == 0:
        return
    if FMD_triangles_UP.is_empty():
        draw_polyline(FMD_points_UP, Color.WHITE, 2.0, true)
    else:
        RenderingServer.canvas_item_add_triangle_array(
            get_canvas_item(),
            FMD_triangles_UP,
            FMD_points_UP,
            PackedColorArray(),
            PackedVector2Array()
        )
