###############################################################
# fishtank/scripts/data/archetype_loader.gd
# Key Classes      • ArchetypeLoader – loads archetype data
# Key Functions    • AL_load_archetypes_IN() – parse JSON to resources
# Critical Consts  • AL_default_texture_IN: Texture2D
# Editor Exports   • None
# Dependencies     • fish_archetype.gd
# Last Major Rev   • 24-06-28 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,loop-variable-name

class_name ArchetypeLoader
extends Node

var AL_default_texture_IN: Texture2D


func _init() -> void:
    var AL_shape_gen_UP: Node = load("res://fishtank/art/shape_generator.gd").new()
    AL_shape_gen_UP.SG_generate_shapes_IN()
    var AL_default_path_UP := "res://fishtank/art/ellipse_placeholder.png"
    if ResourceLoader.exists(AL_default_path_UP):
        AL_default_texture_IN = load(AL_default_path_UP)
    else:
        AL_default_texture_IN = preload("res://fishtank/art/placeholder_fish.png")


func AL_load_archetypes_IN(json_path: String) -> Array[FishArchetype]:
    var AL_archetypes_UP: Array[FishArchetype] = []
    if not FileAccess.file_exists(json_path):
        push_error("Archetype JSON not found: %s" % json_path)
        return AL_archetypes_UP

    var AL_json_string_UP = FileAccess.get_file_as_string(json_path)
    var AL_parser_UP := JSON.new()
    var AL_error_UP = AL_parser_UP.parse(AL_json_string_UP)
    if AL_error_UP != OK:
        push_error("Failed to parse %s: %s" % [json_path, AL_error_UP])
        return AL_archetypes_UP

    for AL_entry_UP in AL_parser_UP.data:
        var AL_resource_UP := FishArchetype.new()
        AL_resource_UP.FA_name_IN = AL_entry_UP.get("name", "")
        AL_resource_UP.FA_species_list_IN = []
        for AL_species_UP in AL_entry_UP.get("species_list", []):
            AL_resource_UP.FA_species_list_IN.append(str(AL_species_UP))

        var AL_tex_path_UP: String = AL_entry_UP.get("placeholder_texture", "")
        if AL_tex_path_UP != "" and ResourceLoader.exists(AL_tex_path_UP):
            AL_resource_UP.FA_placeholder_texture_IN = load(AL_tex_path_UP)
        else:
            AL_resource_UP.FA_placeholder_texture_IN = AL_default_texture_IN

        AL_resource_UP.FA_base_color_IN = Color(AL_entry_UP.get("base_color", "#ffffff"))
        AL_archetypes_UP.append(AL_resource_UP)

    return AL_archetypes_UP
# gdlint:enable = class-variable-name,function-name,function-variable-name,loop-variable-name
