###############################################################
# fishtank/scripts/tank_collider.gd
# Key Classes      • TankCollider – rectangular tank collision
# Key Functions    • TC_get_bounds_IN() – return local bounds
# Editor Exports   • TC_size_IN: Vector2
# Dependencies     • None
# Last Major Rev   • 24-07-05 – initial creation
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,class-definitions-order

class_name TankCollider
extends Area2D

@export var TC_size_IN: Vector2 = Vector2(640, 360)
@onready var TC_shape_IN: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var TC_bounds_SH: Rect2


func _ready() -> void:
    _TC_update_shape_IN()
    _TC_update_bounds_IN()


func _TC_update_shape_IN() -> void:
    if TC_shape_IN == null:
        TC_shape_IN = CollisionShape2D.new()
        add_child(TC_shape_IN)
    var rect := RectangleShape2D.new()
    rect.size = TC_size_IN
    TC_shape_IN.shape = rect
    TC_shape_IN.position = Vector2.ZERO


func _TC_update_bounds_IN() -> void:
    TC_bounds_SH = Rect2(position - TC_size_IN / 2.0, TC_size_IN)


func TC_get_bounds_IN() -> Rect2:
    return TC_bounds_SH
