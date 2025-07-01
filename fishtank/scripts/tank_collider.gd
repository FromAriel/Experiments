###############################################################
# fishtank/scripts/tank_collider.gd
# Key Classes      • TankCollider – rectangular tank boundaries
# Key Functions    • TC_confine_IN() – constrain fish to tank
#                   • TC_apply_avoidance_IN() – steer away from walls
# Editor Exports   • TC_margin_IN: float
#                   • TC_avoid_margin_IN: float
#                   • TC_impulse_IN: float
# Dependencies     • boid_fish.gd
# Last Major Rev   • 24-07-06 – initial collider script
###############################################################
class_name TankCollider
extends Node2D

# gdlint:disable = class-variable-name,function-name,class-definitions-order

@export var TC_margin_IN: float = 30.0
@export var TC_avoid_margin_IN: float = 60.0
@export var TC_impulse_IN: float = 50.0
@onready var TC_shape_UP: RectangleShape2D = null
var TC_rng_UP := RandomNumberGenerator.new()


func _ready() -> void:
    TC_rng_UP.randomize()
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


func TC_apply_avoidance_IN(fish: BoidFish, delta: float) -> void:
    var rect: Rect2 = TC_get_rect_IN()
    var pos: Vector2 = Vector2(fish.BF_position_UP.x, fish.BF_position_UP.y)

    var near := (
        pos.x < rect.position.x + TC_avoid_margin_IN
        or pos.x > rect.position.x + rect.size.x - TC_avoid_margin_IN
        or pos.y < rect.position.y + TC_avoid_margin_IN
        or pos.y > rect.position.y + rect.size.y - TC_avoid_margin_IN
    )
    if not near:
        return

    var center := Vector3(
        rect.position.x + rect.size.x * 0.5,
        rect.position.y + rect.size.y * 0.5,
        fish.BF_position_UP.z,
    )
    var random_vec := Vector3(
        TC_rng_UP.randf_range(-1.0, 1.0),
        TC_rng_UP.randf_range(-1.0, 1.0),
        TC_rng_UP.randf_range(-0.5, 0.5),
    )
    var desired_dir := (center - fish.BF_position_UP + random_vec).normalized()
    var speed := fish.BF_velocity_UP.length()
    fish.BF_velocity_UP = (
        fish
        . BF_velocity_UP
        . move_toward(
            desired_dir * speed,
            TC_impulse_IN * delta,
        )
    )
    fish.BF_velocity_UP += desired_dir * TC_impulse_IN * delta


func TC_confine_IN(fish: BoidFish, delta: float, decel: float) -> void:
    var rect: Rect2 = TC_get_rect_IN()
    var pos: Vector2 = Vector2(fish.BF_position_UP.x, fish.BF_position_UP.y)
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

    fish.BF_position_UP.x = pos.x
    fish.BF_position_UP.y = pos.y
    fish.position = pos
    fish.BF_velocity_UP = vel
# gdlint:enable = class-variable-name,function-name
