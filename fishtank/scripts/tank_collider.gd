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
# Soft proximity ratio (0.15 = within 15% of the wall)
@export var TC_proximity_ratio_IN: float = 0.15
# Impulse strength used when fish get stuck on the wall
@export var TC_nudge_force_IN: float = 50.0

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
    var pos: Vector2 = fish.position
    var vel: Vector2 = fish.BF_velocity_UP

    var nudge := Vector2.ZERO
    var prox_x := rect.size.x * TC_proximity_ratio_IN
    var prox_y := rect.size.y * TC_proximity_ratio_IN

    var left_dist := pos.x - rect.position.x
    var right_dist := rect.position.x + rect.size.x - pos.x
    var top_dist := pos.y - rect.position.y
    var bottom_dist := rect.position.y + rect.size.y - pos.y

    if left_dist < prox_x:
        if vel.x < 0:
            vel.x = move_toward(vel.x, 0.0, decel * delta)
        pos.x = max(pos.x, rect.position.x)
        nudge.x += 1.0 - clamp(left_dist / prox_x, 0.0, 1.0)
    elif right_dist < prox_x:
        if vel.x > 0:
            vel.x = move_toward(vel.x, 0.0, decel * delta)
        pos.x = min(pos.x, rect.position.x + rect.size.x)
        nudge.x -= 1.0 - clamp(right_dist / prox_x, 0.0, 1.0)

    if top_dist < prox_y:
        if vel.y < 0:
            vel.y = move_toward(vel.y, 0.0, decel * delta)
        pos.y = max(pos.y, rect.position.y)
        nudge.y += 1.0 - clamp(top_dist / prox_y, 0.0, 1.0)
    elif bottom_dist < prox_y:
        if vel.y > 0:
            vel.y = move_toward(vel.y, 0.0, decel * delta)
        pos.y = min(pos.y, rect.position.y + rect.size.y)
        nudge.y -= 1.0 - clamp(bottom_dist / prox_y, 0.0, 1.0)

    if nudge != Vector2.ZERO and vel.length() < 10.0:
        vel += nudge.normalized() * TC_nudge_force_IN * delta

    fish.position = pos
    fish.BF_velocity_UP = vel
# gdlint:enable = class-variable-name,function-name
