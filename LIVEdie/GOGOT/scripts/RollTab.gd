###############################################################
# LIVEdie/GOGOT/scripts/RollTab.gd
# Key Classes      • RollTab – handles roll animation placeholder
# Key Functions    • _on_roll_executed
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • UIEventBus.gd
# Last Major Rev   • 24-07-11 – initial stub
###############################################################
class_name RollTab
extends Control

@onready var RT_dice_area_SH: Control = $DiceArea
var RT_rng_IN: RandomNumberGenerator


func _ready() -> void:
    RT_rng_IN = RandomNumberGenerator.new()
    RT_rng_IN.randomize()
    get_node("/root/RollExecutor").roll_executed.connect(_on_roll_executed)


func _on_roll_executed(result: Dictionary) -> void:
    print("Result:", result)
    play_basic_animation()


func play_basic_animation() -> void:
    var area_size: Vector2 = RT_dice_area_SH.size
    for i in range(3):
        var lbl := Label.new()
        lbl.text = str(RT_rng_IN.randi_range(1, 6))
        lbl.modulate.a = 0.0
        RT_dice_area_SH.add_child(lbl)
        var pos_x := RT_rng_IN.randi_range(0, int(area_size.x) - lbl.size.x)
        var pos_y := RT_rng_IN.randi_range(0, int(area_size.y) - lbl.size.y)
        lbl.position = Vector2(pos_x, pos_y)
        var tw := create_tween()
        tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
        tw.tween_property(lbl, "modulate:a", 0.0, 0.15).set_delay(0.15)
        tw.finished.connect(lbl.queue_free)
