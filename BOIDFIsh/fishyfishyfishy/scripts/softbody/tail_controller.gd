# gdlint:disable = class-variable-name,function-name,class-definitions-order
extends Node2D
class_name TailController

@export var TC_amplitude_IN: float = 20.0
@export var TC_frequency_IN: float = 1.5

var TC_base_pos_UP: Vector2
var TC_noise_UP := OpenSimplexNoise.new()
var TC_time_UP: float = 0.0


func _ready() -> void:
    TC_base_pos_UP = position
    TC_noise_UP.seed = randi()
    TC_noise_UP.octaves = 2
    TC_noise_UP.period = 4.0
    TC_noise_UP.persistence = 0.8


func _physics_process(delta: float) -> void:
    TC_time_UP += delta * TC_frequency_IN
    var offset := (
        Vector2(TC_noise_UP.get_noise_1d(TC_time_UP), TC_noise_UP.get_noise_1d(TC_time_UP + 100.0))
        * TC_amplitude_IN
    )
    position = TC_base_pos_UP + offset
