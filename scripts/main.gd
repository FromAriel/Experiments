###############################################################
# scripts/main.gd
# Key Classes      • Main – loads the FishFlock scene
# Key Functions    • _ready() – instantiates FishFlock
# Dependencies     • scenes/FishFlock.tscn
###############################################################

extends Node2D

@onready var fish_scene: PackedScene = preload("res://scenes/FishFlock.tscn")


func _ready() -> void:
    var flock = fish_scene.instantiate()
    add_child(flock)
