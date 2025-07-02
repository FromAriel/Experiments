# gdlint:disable = class-variable-name,function-name,class-definitions-order
# ===============================================================
#  File:  res://scripts/renderer/fish_renderer.gd
#  Desc:  2-D batched fish renderer with optional debug overlay.
#         • Depth-based uniform scale (front ⇢ back)
#         • X-stretch from projected head–tail length
#         • ONE scale-call per sprite (rotate → scale → translate)
#         • Fully-typed, idiomatic GDScript 4.4.1
# ===============================================================

extends Node2D
class_name FishRenderer

# ------------------------------------------------------------------ #
#  Inspector                                                          #
# ------------------------------------------------------------------ #
@export var FR_sprite_texture_IN: Texture2D

@export_range(0.1, 4.0, 0.01, "suffix:×") var FR_front_scale_SH: float = 1.0
@export_range(0.05, 4.0, 0.01, "suffix:×") var FR_back_scale_SH: float  = 0.4

# ------------------------------------------------------------------ #
#  Rendering constants                                                #
# ------------------------------------------------------------------ #
# Brightness fade with depth (1.0 = no fade).
const FR_NEAR_BRIGHT_SH: float = 1.0
const FR_FAR_BRIGHT_SH:  float = 0.55

# X-stretch clamps (ratio of projected length ÷ native sprite length).
const FR_MIN_STRETCH_SH: float = 0.5
const FR_MAX_STRETCH_SH: float = 2.5

# Placeholder sprite size when no texture is supplied (pixels).
const FR_FALLBACK_SPRITE_LEN_PX_SH: float = 80.0
const FR_FALLBACK_SPRITE_HT_PX_SH:  float = 24.0

# ------------------------------------------------------------------ #
#  Debug overlay                                                      #
# ------------------------------------------------------------------ #
@export_group("Debug Visuals")
@export_range(1.0, 20.0, 0.5, "suffix:px") var FR_dbg_point_radius_IN: float = 4.0
@export_range(1.0, 10.0, 0.5, "suffix:px") var FR_dbg_line_width_IN:  float = 2.0
@export var FR_dbg_color_IN: Color = Color.YELLOW
@export_group("")

# ------------------------------------------------------------------ #
#  Runtime references & data                                          #
# ------------------------------------------------------------------ #
var FR_boid_system_RD: BoidSystem
var FR_multimesh_SH:    MultiMesh             = MultiMesh.new()
var FR_multimesh_inst_SH: MultiMeshInstance2D
var _gm: GameManager
var FR_rng_SH: RandomNumberGenerator          = RandomNumberGenerator.new()

# Cached native sprite length (pixels, nose-to-tail at scale = 1).
var FR_sprite_native_len_SH: float = FR_FALLBACK_SPRITE_LEN_PX_SH

# Simple palette (cycled per species).
const FR_PALETTES_SH: Array[Color] = [
    Color("#ff5555"),
    Color("#55ff99"),
    Color("#5599ff"),
    Color("#ffcc55"),
    Color("#99ffaa"),
    Color("#cc55ff"),
]

# ------------------------------------------------------------------ #
#  Lifecycle                                                          #
# ------------------------------------------------------------------ #
func _ready() -> void:
    # --- node look-ups ------------------------------------------------
    FR_boid_system_RD = get_node_or_null("../FishBoidSim")
    if FR_boid_system_RD == null:
        push_error("FishRenderer: sibling 'FishBoidSim' not found.")
        return

    _gm = get_tree().root.get_node_or_null("GameManager")
    FR_rng_SH.randomize()

    # --- mesh & multimesh -------------------------------------------
    var quad: QuadMesh = QuadMesh.new()
    if FR_sprite_texture_IN:
        FR_sprite_native_len_SH = float(FR_sprite_texture_IN.get_width())
        quad.size               = Vector2(FR_sprite_texture_IN.get_width(),
                                           FR_sprite_texture_IN.get_height())
    else:
        quad.size = Vector2(FR_FALLBACK_SPRITE_LEN_PX_SH, FR_FALLBACK_SPRITE_HT_PX_SH)
        push_warning("FishRenderer: FR_sprite_texture_IN is null – showing procedural quads.")

    FR_multimesh_SH.transform_format = MultiMesh.TRANSFORM_2D
    FR_multimesh_SH.use_colors       = true
    FR_multimesh_SH.mesh             = quad
    FR_multimesh_SH.instance_count   = 0

    FR_multimesh_inst_SH             = MultiMeshInstance2D.new()
    FR_multimesh_inst_SH.multimesh   = FR_multimesh_SH
    if FR_sprite_texture_IN:
        FR_multimesh_inst_SH.texture = FR_sprite_texture_IN
    add_child(FR_multimesh_inst_SH)

    set_process(true)

# Public helper for GameManager.
func set_depth_scale(scale: float) -> void:
    FR_front_scale_SH = scale
    FR_back_scale_SH  = clamp(scale * 0.4, 0.05, scale)

# ------------------------------------------------------------------ #
#  Per-frame update                                                   #
# ------------------------------------------------------------------ #
func _process(_delta: float) -> void:
    if FR_boid_system_RD == null:
        return

    var snapshot: Array = FR_boid_system_RD.get_snapshot()
    _resize_multimesh(snapshot.size())

    var tank_depth: float = FR_boid_system_RD.FB_tank_size_IN.z
    var i: int = 0

    for item in snapshot:
        # -- raw screen-space points (no scaling!) --------------------
        var head3: Vector3 = item["head"]
        var tail3: Vector3 = item["tail"]
        var p_head: Vector2 = Vector2(head3.x, head3.y)
        var p_tail: Vector2 = Vector2(tail3.x, tail3.y)

        # -- depth-based uniform scale --------------------------------
        var depth_ratio: float  = head3.z / max(tank_depth, 0.001)
        var depth_scale: float  = lerp(FR_front_scale_SH, FR_back_scale_SH, depth_ratio)

        # -- x-stretch from projected length --------------------------
        var proj_len: float = p_head.distance_to(p_tail)
        var x_stretch: float = clamp(
            proj_len / FR_sprite_native_len_SH,
            FR_MIN_STRETCH_SH,
            FR_MAX_STRETCH_SH
        )

        # -- final scale vector (x = depth*stretch, y = depth) --------
        var final_scale: Vector2 = Vector2(depth_scale * x_stretch, depth_scale)

        # -- orientation & midpoint -----------------------------------
        var angle: float   = (p_head - p_tail).angle()
        var mid:   Vector2 = p_tail.lerp(p_head, 0.5)

        # -- build transform: rotate → scale → translate --------------
        var xf := Transform2D.IDENTITY
        xf = xf.rotated(angle)
        xf = xf.scaled(final_scale)
        xf = xf.translated(mid)

        FR_multimesh_SH.set_instance_transform_2d(i, xf)

        # -- per-instance colour --------------------------------------
        var brightness: float = lerp(FR_NEAR_BRIGHT_SH, FR_FAR_BRIGHT_SH, depth_ratio)
        var species_id: int   = int(item["species_id"])
        var palette_idx: int  = 0
        if species_id < FR_boid_system_RD.FB_archetypes_IN.size():
            palette_idx = FR_boid_system_RD.FB_archetypes_IN[species_id].FA_palette_id_IN

        var base_col: Color = FR_PALETTES_SH[palette_idx % FR_PALETTES_SH.size()]
        FR_rng_SH.seed = species_id * 4096 + i
        var shift: float = FR_rng_SH.randf_range(-0.1, 0.1)
        var tint: Color = base_col.lightened(shift) if shift >= 0.0 else base_col.darkened(-shift)
        var final_col: Color = Color(
            tint.r * brightness, tint.g * brightness, tint.b * brightness, 1.0
        )
        FR_multimesh_SH.set_instance_color(i, final_col)

        i += 1

    if _gm and _gm.GM_debug_enabled_SH and _gm.GM_draw_spines_SH:
        queue_redraw()

# ------------------------------------------------------------------ #
#  Debug overlay                                                      #
# ------------------------------------------------------------------ #
func _draw() -> void:
    if not (_gm and _gm.GM_debug_enabled_SH and _gm.GM_draw_spines_SH):
        return

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # identity

    var snapshot: Array = FR_boid_system_RD.get_snapshot()
    var tank_depth: float = FR_boid_system_RD.FB_tank_size_IN.z

    for item in snapshot:
        var head3: Vector3 = item["head"]
        var tail3: Vector3 = item["tail"]
        var p_head: Vector2 = Vector2(head3.x, head3.y)
        var p_tail: Vector2 = Vector2(tail3.x, tail3.y)

        var depth_ratio: float = head3.z / max(tank_depth, 0.001)
        var depth_scale: float = lerp(FR_front_scale_SH, FR_back_scale_SH, depth_ratio)

        var x_stretch: float = clamp(
            p_head.distance_to(p_tail) / FR_sprite_native_len_SH,
            FR_MIN_STRETCH_SH,
            FR_MAX_STRETCH_SH
        )
        var final_scale: Vector2 = Vector2(depth_scale * x_stretch, depth_scale)

        var angle: float   = (p_head - p_tail).angle()
        var mid:   Vector2 = p_tail.lerp(p_head, 0.5)

        # projected head-tail line (yellow)
        var lw: float = FR_dbg_line_width_IN * depth_scale
        draw_line(p_tail, p_head, FR_dbg_color_IN, lw, true)
        draw_circle(p_head, FR_dbg_point_radius_IN * depth_scale, FR_dbg_color_IN)
        draw_circle(p_tail, FR_dbg_point_radius_IN * depth_scale, FR_dbg_color_IN)

        # sprite’s actual span (darker)
        var half_len_vec: Vector2 = Vector2(FR_sprite_native_len_SH * final_scale.x * 0.5, 0.0)
        half_len_vec = half_len_vec.rotated(angle)
        var sprite_tail: Vector2 = mid - half_len_vec
        var sprite_head: Vector2 = mid + half_len_vec

        draw_line(
            sprite_tail,
            sprite_head,
            FR_dbg_color_IN.darkened(0.25),
            lw,
            true
        )

# ------------------------------------------------------------------ #
#  Helpers                                                            #
# ------------------------------------------------------------------ #
func _resize_multimesh(required: int) -> void:
    if FR_multimesh_SH.instance_count != required:
        FR_multimesh_SH.instance_count = required
