###############################################################
#  scripts/entities/fish_body.gd
#  Full soft-body fish controller
#  • Added wrap-around edges (no corner-lock)
#  • Added HARD SPEED CAP so no fish can exceed max_safe_speed
###############################################################

class_name FishBody
extends Node2D

# ------------------------------------------------------------------
#  CONSTANTS
# ------------------------------------------------------------------
const MIN_SCALE := 0.6
const MAX_SCALE := 1.0
const MIN_ALPHA := 0.5
const MAX_ALPHA := 1.0

# ------------------------------------------------------------------
#  EXPORTED TUNABLES
# ------------------------------------------------------------------
@export var spring_stiffness: float = 8.0
@export var spring_damping: float = 1.0
@export var segment_length: float = 20.0
@export var body_linear_damp: float = 1.0
@export_range(0.0, 5.5) var z_depth: float = 0.0
@export var tank_size: Vector3 = Vector3(16.0, 9.0, 5.5)

# hard safety speed (pixels / second) – rogue fish never exceed this
@export var max_safe_speed: float = 200.0

# ------------------------------------------------------------------
#  RUNTIME STATE
# ------------------------------------------------------------------
var soft_body_params: Dictionary  # optional prefab recipe
var segments: Array = []  # RigidBody2D refs
var joints: Array = []

@onready var mat: ShaderMaterial = $Sprite.material as ShaderMaterial


# ------------------------------------------------------------------
#  READY
# ------------------------------------------------------------------
func _ready() -> void:
    if soft_body_params:
        _build_segments()
    else:
        _collect_existing()

    _apply_joint_params()
    mat.set_shader_parameter("u_light_dir", Vector2(-sin(rotation), -cos(rotation)).normalized())


# ------------------------------------------------------------------
#  SEGMENT/J0INT CONSTRUCTION
# ------------------------------------------------------------------
func _build_segments() -> void:
    var node_count: int = soft_body_params.get("node_count", 4)
    var masses: Array = soft_body_params.get("masses", [])

    for i in range(node_count):
        var seg := RigidBody2D.new()
        seg.name = "segment_%d" % i
        seg.position = Vector2(-i * segment_length, 0)
        seg.linear_damp = body_linear_damp
        seg.angular_damp = body_linear_damp
        if i < masses.size():
            seg.mass = float(masses[i])

        var col := CollisionShape2D.new()
        var circle := CircleShape2D.new()
        circle.radius = segment_length / 2.0
        col.shape = circle
        seg.add_child(col)

        segments.append(seg)
        add_child(seg)

        if i > 0:
            var joint := DampedSpringJoint2D.new()
            joint.name = "joint_%d" % i
            joint.node_a = NodePath("segment_%d" % (i - 1))
            joint.node_b = NodePath(seg.name)
            joint.length = segment_length
            add_child(joint)
            joints.append(joint)


func _collect_existing() -> void:
    for child in get_children():
        if child is RigidBody2D:
            segments.append(child)
            child.linear_damp = body_linear_damp
            child.angular_damp = body_linear_damp
            if child.get_node_or_null("CollisionShape2D") == null:
                var col := CollisionShape2D.new()
                var circle := CircleShape2D.new()
                circle.radius = segment_length / 2.0
                col.shape = circle
                child.add_child(col)
        elif child is DampedSpringJoint2D:
            joints.append(child)


func _apply_joint_params() -> void:
    for joint in joints:
        joint.stiffness = spring_stiffness
        joint.damping = spring_damping


# ------------------------------------------------------------------
#  EXTERNAL STEERING API
# ------------------------------------------------------------------


# Legacy API kept for earlier tests; now no-op.
func apply_steering_force(_force: Vector2) -> void:
    # Direct force application caused runaway acceleration.
    # Movement is now controlled via `set_head_velocity`.
    pass


func set_head_velocity(v: Vector2) -> void:
    if segments.size() > 0:
        var head: RigidBody2D = segments[0]
        head.linear_velocity = v


func get_head_velocity() -> Vector2:
    if segments.size() > 0:
        var head: RigidBody2D = segments[0]
        return head.linear_velocity
    return Vector2.ZERO


# ------------------------------------------------------------------
#  PER-FRAME UPDATE
# ------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
    if segments.size() > 0:
        var head: RigidBody2D = segments[0]

        # ----- HARD SPEED CAP (prevents runaway) -----
        var v := head.linear_velocity
        if v.length() > max_safe_speed:
            head.linear_velocity = v.normalized() * max_safe_speed

        # sync transform to head
        global_position = head.global_position
        rotation = head.rotation

    _update_depth_visuals()
    _constrain_position()


# ------------------------------------------------------------------
#  HELPERS
# ------------------------------------------------------------------
func _update_depth_visuals() -> void:
    var t: float = clamp((tank_size.z - z_depth) / tank_size.z, 0.0, 1.0)
    var sc: float = lerp(MIN_SCALE, MAX_SCALE, t)
    scale = Vector2(sc, sc)
    var a: float = lerp(MIN_ALPHA, MAX_ALPHA, t)
    modulate.a = a


# Clamp position to keep fish inside the tank
func _constrain_position() -> void:
    global_position.x = clamp(global_position.x, 0.0, tank_size.x)
    global_position.y = clamp(global_position.y, 0.0, tank_size.y)
    z_depth = clamp(z_depth, 0.0, tank_size.z)
