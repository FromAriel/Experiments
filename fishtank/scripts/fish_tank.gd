###############################################################
# gdlint:disable = function-variable-name
# fishtank/scripts/fish_tank.gd
# Key Classes      • FishTank – root controller for the aquarium
# Key Functions    • _ready() – load archetypes
# Dependencies     • archetype_loader.gd
# Last Major Rev   • 24-06-28 – load archetypes
###############################################################

extends Node2D


func _ready() -> void:
    var FT_loader_IN := ArchetypeLoader.new()
    var FT_archetypes_UP := FT_loader_IN.AL_load_archetypes_IN("res://data/archetypes.json")
    print("Loaded %d archetypes" % FT_archetypes_UP.size())
# gdlint:enable = function-variable-name
