# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/fishyfishyfishy/scripts/soft_body/tail_controller.gd
# Key Classes      • TailController – noisy tail target
# Key Functions    • _physics_process() – jitters position
# Critical Consts  • none
# Editor Exports   • TC_noise_amplitude_IN: float
# Dependencies     • FastNoiseLite
# Last Major Rev   • 24-05-21 – initial version
###############################################################

class_name TailController
extends Node2D

@export var TC_noise_amplitude_IN: float = 1.0
@export var TC_noise_speed_IN: float = 1.0
@export var TC_noise_frequency_IN: float = 0.5

var _TC_time_UP: float = 0.0
var _TC_noise_SH: FastNoiseLite = FastNoiseLite.new()


func _ready() -> void:
    _TC_noise_SH.frequency = TC_noise_frequency_IN
    _TC_noise_SH.seed = randi()


func _physics_process(delta: float) -> void:
    _TC_time_UP += delta * TC_noise_speed_IN
    var n := _TC_noise_SH.get_noise_1d(_TC_time_UP)
    position = Vector2(n * TC_noise_amplitude_IN, -n * TC_noise_amplitude_IN * 0.5)
