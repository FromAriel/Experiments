# gdlint:disable = class-variable-name,function-name,class-definitions-order
###############################################################
# BOIDFIsh/fishyfishyfishy/scripts/softbody/tail_controller.gd
# Key Classes      • TailController – noisy target motion for tail
# Key Functions    • _physics_process() – animate target with noise
# Editor Exports   • TC_amplitude_IN: Vector2 – sine-wave amplitude
# Dependencies     • FastNoiseLite (built-in)
# Last Major Rev   • 24-XX-XX – initial creation
###############################################################

extends Node2D
class_name TailController

@export var TC_amplitude_IN: Vector2 = Vector2(2.0, 1.0)
@export var TC_frequency_IN: float = 1.5

var TC_noise_RD: FastNoiseLite
var TC_time_UP: float = 0.0


func _ready() -> void:
    TC_noise_RD = FastNoiseLite.new()
    TC_noise_RD.seed = randi()
    set_physics_process(true)


func _physics_process(delta: float) -> void:
    TC_time_UP += delta
    var n := TC_noise_RD.get_noise_1d(TC_time_UP * TC_frequency_IN)
    position = Vector2(sin(TC_time_UP * TC_frequency_IN) * TC_amplitude_IN.x, n * TC_amplitude_IN.y)
