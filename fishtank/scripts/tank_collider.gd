###############################################################
# fishtank/scripts/tank_collider.gd
# Key Classes      • TankCollider – rectangular tank boundaries
# Key Functions    • TC_confine_IN() – constrain fish to tank
# Editor Exports   • TC_margin_IN: float
# Dependencies     • boid_fish.gd
# Last Major Rev   • 25-07-06 – added bounce reflection
###############################################################
class_name TankCollider
extends Node2D

# gdlint:disable = class-variable-name,function-name

@export var TC_margin_IN: float = 30.0
@export var TC_bounce_damping_IN: float = 0.8
@onready var TC_shape_UP: RectangleShape2D = null


func _ready() -> void:
    var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if col != null and col.shape is RectangleShape2D:
        TC_shape_UP = col.shape as RectangleShape2D
    else:
        TC_shape_UP = RectangleShape2D.new()
        TC_shape_UP.extents = Vector2(640, 360)
        if col == null:
            col = CollisionShape2D.new()
            add_child(col)
        col.shape = TC_shape_UP


func TC_get_rect_IN() -> Rect2:
    var pos: Vector2 = global_position - TC_shape_UP.extents
    return Rect2(pos, TC_shape_UP.extents * 2.0)


func TC_confine_IN(fish: BoidFish, _delta: float, _decel: float) -> void:
    var rect: Rect2 = TC_get_rect_IN()
    var pos: Vector2 = Vector2(fish.BF_position_UP.x, fish.BF_position_UP.y)
    var vel: Vector3 = fish.BF_velocity_UP

    if pos.x < rect.position.x + TC_margin_IN:
        pos.x = rect.position.x + TC_margin_IN
        if vel.x < 0.0:
            vel.x = abs(vel.x) * TC_bounce_damping_IN
    elif pos.x > rect.position.x + rect.size.x - TC_margin_IN:
        pos.x = rect.position.x + rect.size.x - TC_margin_IN
        if vel.x > 0.0:
            vel.x = -abs(vel.x) * TC_bounce_damping_IN

    if pos.y < rect.position.y + TC_margin_IN:
        pos.y = rect.position.y + TC_margin_IN
        if vel.y < 0.0:
            vel.y = abs(vel.y) * TC_bounce_damping_IN
    elif pos.y > rect.position.y + rect.size.y - TC_margin_IN:
        pos.y = rect.position.y + rect.size.y - TC_margin_IN
        if vel.y > 0.0:
            vel.y = -abs(vel.y) * TC_bounce_damping_IN

    fish.BF_position_UP.x = pos.x
    fish.BF_position_UP.y = pos.y
    fish.position = pos
    fish.BF_velocity_UP = vel
# gdlint:enable = class-variable-name,function-name
