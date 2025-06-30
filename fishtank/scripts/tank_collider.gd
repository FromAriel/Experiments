###############################################################
# fishtank/scripts/tank_collider.gd
# Key Classes      • TankCollider – rectangular tank boundaries
# Key Functions    • TC_confine_IN() – constrain fish to tank
# Editor Exports   • TC_margin_IN: float
# Dependencies     • boid_fish.gd
# Last Major Rev   • 24-07-06 – initial collider script
###############################################################
class_name TankCollider
extends Node2D

# gdlint:disable = class-variable-name,function-name

@export var TC_margin_IN: float = 30.0
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


func TC_confine_IN(fish: BoidFish, delta: float, decel: float) -> void:
    var rect: Rect2 = TC_get_rect_IN()
    var pos: Vector3 = fish.BF_position_UP
    var vel: Vector3 = fish.BF_velocity_UP

    if pos.x < rect.position.x + TC_margin_IN:
        vel.x = move_toward(vel.x, 0.0, decel * delta)
        pos.x = max(pos.x, rect.position.x)
    elif pos.x > rect.position.x + rect.size.x - TC_margin_IN:
        vel.x = move_toward(vel.x, 0.0, decel * delta)
        pos.x = min(pos.x, rect.position.x + rect.size.x)

    if pos.y < rect.position.y + TC_margin_IN:
        vel.y = move_toward(vel.y, 0.0, decel * delta)
        pos.y = max(pos.y, rect.position.y)
    elif pos.y > rect.position.y + rect.size.y - TC_margin_IN:
        vel.y = move_toward(vel.y, 0.0, decel * delta)
        pos.y = min(pos.y, rect.position.y + rect.size.y)

    fish.BF_position_UP = pos
    fish.position = Vector2(pos.x, pos.y)
    fish.BF_velocity_UP = vel
# gdlint:enable = class-variable-name,function-name
