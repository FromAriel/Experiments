# gdlint:disable = class-variable-name,function-name,class-definitions-order
# ===============================================================
#  File:  res://scripts/renderer/fish_renderer.gd
#  Desc:  2-D batched fish renderer with optional debug overlay.
#         ✔ Depth-based scale & tint  (fake 3-D)
#         ✔ Inspector-tweakable point radius + spine width
#         ✔ Godot 4.4.1-ready
# ===============================================================

extends Node2D
class_name FishRenderer

@export var FR_sprite_texture_IN: Texture2D
@export var FR_front_scale_SH: float = 1.0
@export var FR_back_scale_SH: float = 0.4

const FR_NEAR_BRIGHT_SH: float = 1.00
const FR_FAR_BRIGHT_SH: float = 0.55

@export_group("Debug Visuals")
@export_range(1.0, 20.0, 0.5, "suffix:px") var FR_dbg_point_radius_IN: float = 4.0
@export_range(1.0, 10.0, 0.5, "suffix:px") var FR_dbg_line_width_IN: float = 2.0
@export var FR_dbg_color_IN: Color = Color.YELLOW
@export_group("")

var FR_boid_system_RD: BoidSystem
var FR_multimesh_SH: MultiMesh = MultiMesh.new()
var FR_multimesh_instance_SH: MultiMeshInstance2D
var _gm: GameManager
var FR_rng_SH: RandomNumberGenerator = RandomNumberGenerator.new()
const FR_PALETTES_SH: Array[Color] = [
    Color("#ff5555"),
    Color("#55ff99"),
    Color("#5599ff"),
    Color("#ffcc55"),
    Color("#99ffaa"),
    Color("#cc55ff")
]


# ------------------------------------------------------------------ #
func _ready() -> void:
    FR_boid_system_RD = get_node_or_null("../FishBoidSim")
    if FR_boid_system_RD == null:
        push_error("FishRenderer: sibling 'FishBoidSim' not found.")
        return

    _gm = get_tree().root.get_node_or_null("GameManager")
    FR_rng_SH.randomize()

    FR_multimesh_SH.transform_format = MultiMesh.TRANSFORM_2D
    FR_multimesh_SH.use_colors = true
    var quad := QuadMesh.new()
    quad.size = Vector2.ONE
    FR_multimesh_SH.mesh = quad
    FR_multimesh_SH.instance_count = 0

    FR_multimesh_instance_SH = MultiMeshInstance2D.new()
    FR_multimesh_instance_SH.multimesh = FR_multimesh_SH
    if FR_sprite_texture_IN:
        FR_multimesh_instance_SH.texture = FR_sprite_texture_IN
    else:
        push_warning("FishRenderer: FR_sprite_texture_IN is null – fish will show as solid quads.")
    add_child(FR_multimesh_instance_SH)

    set_process(true)


func set_depth_scale(scale: float) -> void:
    FR_front_scale_SH = scale
    FR_back_scale_SH = clamp(scale * 0.4, 0.05, scale)


# ------------------------------------------------------------------ #
func _process(_delta: float) -> void:
    if FR_boid_system_RD == null:
        return

    var snapshot: Array = FR_boid_system_RD.get_snapshot()
    _resize_multimesh(snapshot.size())

    var tank_depth: float = FR_boid_system_RD.FB_tank_size_IN.z
    var i: int = 0

    for item in snapshot:
        var head: Vector3 = item["head"]
        var tail: Vector3 = item["tail"]

        var depth_ratio: float = head.z / max(tank_depth, 0.001)
        var scale: float = lerp(FR_front_scale_SH, FR_back_scale_SH, depth_ratio)
        var brightness: float = lerp(FR_NEAR_BRIGHT_SH, FR_FAR_BRIGHT_SH, depth_ratio)

        var head2: Vector2 = Vector2(head.x, head.y)
        var tail2: Vector2 = Vector2(tail.x, tail.y)
        var angle: float = (head2 - tail2).angle()
        var length_px: float = head2.distance_to(tail2)

        var species_id: int = int(item["species_id"])
        var arch_index: int = clamp(species_id, 0, FR_boid_system_RD.FB_archetypes_IN.size() - 1)
        var arch: FishArchetype = FR_boid_system_RD.FB_archetypes_IN[arch_index]

        var xf := Transform2D.IDENTITY
        xf = xf.scaled(Vector2(arch.FA_size_vec3_IN.x * scale, length_px * scale))
        xf = xf.rotated(angle)
        xf = xf.translated((head2 + tail2) * 0.5)

        FR_multimesh_SH.set_instance_transform_2d(i, xf)

        var palette_idx: int = arch.FA_palette_id_IN

        var base_col: Color = FR_PALETTES_SH[palette_idx % FR_PALETTES_SH.size()]
        FR_rng_SH.seed = species_id * 4096 + i
        var shift: float = FR_rng_SH.randf_range(-0.1, 0.1)
        var tint: Color
        if shift >= 0.0:
            tint = base_col.lightened(shift)
        else:
            tint = base_col.darkened(-shift)
        var final_col: Color = Color(
            tint.r * brightness, tint.g * brightness, tint.b * brightness, 1.0
        )
        FR_multimesh_SH.set_instance_color(i, final_col)
        i += 1

    if _gm and _gm.GM_debug_enabled_SH and _gm.GM_draw_spines_SH:
        queue_redraw()


# ------------------------------------------------------------------ #
func _draw() -> void:
    if not (_gm and _gm.GM_debug_enabled_SH and _gm.GM_draw_spines_SH):
        return

    # *** FIXED LINE (identity transform for drawing) ***
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    var snapshot: Array = FR_boid_system_RD.get_snapshot()
    var tank_depth: float = FR_boid_system_RD.FB_tank_size_IN.z
    for item in snapshot:
        var head: Vector3 = item["head"]
        var tail: Vector3 = item["tail"]

        var depth_ratio: float = head.z / max(tank_depth, 0.001)
        var scale: float = lerp(FR_front_scale_SH, FR_back_scale_SH, depth_ratio)

        var head2: Vector2 = Vector2(head.x, head.y)
        var tail2: Vector2 = Vector2(tail.x, tail.y)
        var tail2_scaled: Vector2 = head2 + (tail2 - head2) * scale

        draw_line(tail2_scaled, head2, FR_dbg_color_IN, FR_dbg_line_width_IN * scale, true)
        draw_circle(head2, FR_dbg_point_radius_IN * scale, FR_dbg_color_IN)
        draw_circle(tail2_scaled, FR_dbg_point_radius_IN * scale, FR_dbg_color_IN)


# ------------------------------------------------------------------ #
func _resize_multimesh(required: int) -> void:
    if FR_multimesh_SH.instance_count != required:
        FR_multimesh_SH.instance_count = required
