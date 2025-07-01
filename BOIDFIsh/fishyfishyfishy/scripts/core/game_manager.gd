# gdlint:disable = class-variable-name,function-name,class-definitions-order
class_name GameManager
extends Node
## Singleton that exposes user settings & debug flags.

# --------------------------------------------------------------------- #
#  Inspector – User-Facing Settings                                     #
# --------------------------------------------------------------------- #
@export_range(50, 600, 1) var GM_fish_count_IN: int = 300
@export_range(0.5, 1.5, 0.01) var GM_depth_scale_IN: float = 1.0
@export_enum("Community", "Reef", "Night") var GM_theme_IN: String = "Community"
@export var GM_archetypes_override_IN: Array[FishArchetype] = []

# --------------------------------------------------------------------- #
#  Inspector – Debug Flags                                              #
# --------------------------------------------------------------------- #
@export_group("Debug Flags")
@export var GM_debug_enabled_SH: bool = false
@export var GM_draw_spines_SH: bool = false
@export var GM_log_fish_SH: bool = false
@export var GM_dump_placeholders_SH: bool = false
@export var GM_show_grid_SH: bool = false

# --------------------------------------------------------------------- #
#  Runtime references                                                   #
# --------------------------------------------------------------------- #
var GM_boid_system_RD: BoidSystem
var GM_renderer_RD: FishRenderer

# --------------------------------------------------------------------- #
#  Signals                                                              #
# --------------------------------------------------------------------- #
signal fish_count_changed(new_count: int)
signal depth_scale_changed(new_scale: float)
signal theme_changed(new_theme: String)
signal debug_toggled(enabled: bool)


# --------------------------------------------------------------------- #
#  Lifecycle                                                            #
# --------------------------------------------------------------------- #
func _ready() -> void:
    GM_boid_system_RD = get_node_or_null("FishBoidSim")
    GM_renderer_RD = get_node_or_null("FishRenderer")

    if GM_boid_system_RD == null:
        push_error("GameManager could not find FishBoidSim child node.")
    else:
        if not GM_archetypes_override_IN.is_empty():
            GM_boid_system_RD.FB_archetypes_IN = GM_archetypes_override_IN.duplicate()
        GM_boid_system_RD.set_fish_count(GM_fish_count_IN)

    if GM_renderer_RD == null:
        push_error("GameManager could not find FishRenderer child node.")
    else:
        GM_renderer_RD.set_depth_scale(GM_depth_scale_IN)


# --------------------------------------------------------------------- #
#  Input – hidden F3 debug toggle                                       #
# --------------------------------------------------------------------- #
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.is_pressed():
        if event.keycode == KEY_F3:
            GM_debug_enabled_SH = !GM_debug_enabled_SH
            debug_toggled.emit(GM_debug_enabled_SH)
        else:
            pass
    else:
        pass


# --------------------------------------------------------------------- #
#  Setters (called by UI or hotkeys)                                    #
# --------------------------------------------------------------------- #
func set_fish_count(count: int) -> void:
    GM_fish_count_IN = clamp(count, 50, 600)

    if GM_boid_system_RD != null:
        GM_boid_system_RD.set_fish_count(GM_fish_count_IN)
    else:
        pass

    fish_count_changed.emit(GM_fish_count_IN)


func set_depth_scale(scale: float) -> void:
    GM_depth_scale_IN = clamp(scale, 0.5, 1.5)

    if GM_renderer_RD != null:
        GM_renderer_RD.set_depth_scale(GM_depth_scale_IN)
    else:
        pass

    depth_scale_changed.emit(GM_depth_scale_IN)


func set_theme(theme: String) -> void:
    GM_theme_IN = theme
    theme_changed.emit(theme)
