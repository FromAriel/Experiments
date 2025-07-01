extends Resource
class_name FishArchetype
#@icon("res://icon.svg") # Placeholder icon for the inspector.

#/* -------------------------------------------------------------------- *
# *  FishArchetype – tweakable per-species parameters                    *
# * -------------------------------------------------------------------- */

@export_category("Size & Movement")
@export var FA_size_vec3_IN: Vector3 = Vector3(120.0, 40.0, 120.0)
@export var FA_max_speed_IN: float = 140.0
@export var FA_wander_weight_IN: float = 1.0
@export_enum(
    "SCHOOL",
    "SHOAL",
    "LONER",
    "BOTTOM_DWELLER",
    "CRUISER"
)
var FA_flock_type_IN: String = "SCHOOL"
@export_range(0.0, 1.0, 0.01) var FA_depth_pref_IN: float = 0.5

@export_category("Soft-Body Deformation")
@export var FA_z_steer_weight_IN: float = 1.0
@export var FA_deform_min_x_IN: float = 0.85
@export var FA_deform_max_y_IN: float = 1.15
@export var FA_flip_thresh_IN: float = 0.0

@export_category("Rendering")
@export var FA_palette_id_IN: int = 0
