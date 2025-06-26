###############################################################
# scripts/entities/fish_body.gd
# Key funcs/classes: • FishBody – soft-body fish controller
# Critical consts    • NONE
###############################################################

class_name FishBody
extends Node2D

const MIN_SCALE := 0.6
const MAX_SCALE := 1.0
const MIN_ALPHA := 0.5
const MAX_ALPHA := 1.0

@export var spring_stiffness: float = 8.0
@export var spring_damping: float = 0.7
@export var segment_length: float = 20.0
@export_range(0.0, 5.5) var z_depth: float = 0.0
@export var tank_size: Vector3 = Vector3(16.0, 9.0, 5.5)

var soft_body_params: Dictionary
var segments: Array = []
var joints: Array = []


func _ready() -> void:
    if soft_body_params:
        _build_segments()
    else:
        _collect_existing()
    _apply_joint_params()


func _build_segments() -> void:
    var node_count: int = soft_body_params.get("node_count", 4)
    var masses: Array = soft_body_params.get("masses", [])
    for i in range(node_count):
        var seg := RigidBody2D.new()
        seg.name = "segment_%d" % i
        seg.position = Vector2(-i * segment_length, 0)
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


func apply_steering_force(force: Vector2) -> void:
    if segments.size() > 0:
        var head: RigidBody2D = segments[0]
        head.apply_central_force(force)


func _physics_process(_delta: float) -> void:
    _update_depth_visuals()
    _clamp_position()


func _update_depth_visuals() -> void:
    var t: float = clamp((tank_size.z - z_depth) / tank_size.z, 0.0, 1.0)
    var sc: float = lerp(MIN_SCALE, MAX_SCALE, t)
    scale = Vector2(sc, sc)
    var a: float = lerp(MIN_ALPHA, MAX_ALPHA, t)
    modulate.a = a


func _clamp_position() -> void:
    global_position.x = clamp(global_position.x, 0.0, tank_size.x)
    global_position.y = clamp(global_position.y, 0.0, tank_size.y)
    z_depth = clamp(z_depth, 0.0, tank_size.z)
