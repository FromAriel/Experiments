###############################################################
# scripts/entities/fish_body.gd
# Key funcs/classes: \u2022 FishBody – soft-body fish controller
# Critical consts    \u2022 NONE
###############################################################

class_name FishBody
extends Node2D

@export var spring_stiffness: float = 8.0
@export var spring_damping: float = 0.7
@export var segment_length: float = 20.0

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
        add_child(seg)
        segments.append(seg)
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
