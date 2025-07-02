# ===============================================================
#  File:  res://scripts/soft_body/tail_controller.gd
#  Desc:  Simple kinematic driver with sine/noise jitter.
# ===============================================================
# gdlint:disable = class-variable-name,function-name,class-definitions-order
class_name TailController
extends Node2D

# ------------------------------------------------------------------ #
#  Editor Exports                                                    #
# ------------------------------------------------------------------ #
@export var TC_amplitude_IN: float = 3.0
@export var TC_frequency_IN: float = 2.0
@export var TC_noise_amplitude_IN: float = 1.0
@export var TC_noise_frequency_IN: float = 0.5

var TC_base_pos_SH: Vector2
var TC_time_UP: float = 0.0
var TC_noise_UP := FastNoiseLite.new()


func _ready() -> void:
    TC_base_pos_SH = position
    TC_noise_UP.seed = randi()
    TC_noise_UP.frequency = TC_noise_frequency_IN


func _physics_process(delta: float) -> void:
    TC_time_UP += delta
    var wave := Vector2(sin(TC_time_UP * TC_frequency_IN) * TC_amplitude_IN, 0.0)
    var n := Vector2(
        TC_noise_UP.get_noise_1d(TC_time_UP) * TC_noise_amplitude_IN,
        TC_noise_UP.get_noise_1d(TC_time_UP + 100.0) * TC_noise_amplitude_IN
    )
    position = TC_base_pos_SH + wave + n
