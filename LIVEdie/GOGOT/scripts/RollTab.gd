###############################################################
# LIVEdie/GOGOT/scripts/RollTab.gd
# Key Classes      • RollTab – handles roll animation placeholder
# Key Functions    • _on_roll_executed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • UIEventBus.gd
# Last Major Rev   • 24-07-15 – add placeholder dice animation
###############################################################
class_name RollTab
extends Control

@onready var RT_dice_area_SH: Node = $DiceArea
var RT_rng_IN: RandomNumberGenerator


func _ready() -> void:
    RT_rng_IN = RandomNumberGenerator.new()
    RT_rng_IN.randomize()
    get_node("/root/RollExecutor").roll_executed.connect(_on_roll_executed)


func RT_play_basic_animation_IN() -> void:
    var sz := size
    for i in range(3):
        var lbl := Label.new()
        lbl.text = str(RT_rng_IN.randi_range(1, 6))
        lbl.modulate.a = 0.0
        lbl.position = Vector2(
            RT_rng_IN.randi_range(0, int(sz.x)), RT_rng_IN.randi_range(0, int(sz.y))
        )
        RT_dice_area_SH.add_child(lbl)
        var tw := create_tween()
        tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
        tw.tween_interval(0.15)
        tw.tween_property(lbl, "modulate:a", 0.0, 0.15)
        tw.tween_callback(Callable(lbl, "queue_free"))


func _on_roll_executed(result: Dictionary) -> void:
    print("Result:", result)
    RT_play_basic_animation_IN()
