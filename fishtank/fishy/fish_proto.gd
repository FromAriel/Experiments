###############################################################
# fishtank/fishy/fish_proto.gd
# Key Classes      • FishProto – standalone soft-body fish sandbox
# Key Functions    • _ready() – setup scene
#                   • _process() / _physics_process() – idle motion
#                   • _draw() – debug springs & velocities
# Config embedded  • no external .tres needed
# Last Major Rev   • 24-07-30 – self-contained config
###############################################################
# gdlint:disable = class-variable-name,function-name,function-variable-name,loop-variable-name
class_name FishProtoscene
extends Node2D


# ——— Configuration (override in Inspector if desired) ———
@export var FP_segment_masses_IN: Array[float]     = [2.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5]
@export var FP_stiffness_IN: Array[float]          = [200.0, 150.0, 100.0, 75.0, 60.0, 50.0, 40.0, 25.0]
@export var FP_damping_IN: Array[float]            = [20.0, 18.0, 15.0, 12.0, 10.0, 8.0, 6.0, 5.0]
@export var FP_segment_spacing_IN: float           = 20.0

# ——— Runtime state ———
var FP_segments_UP: Array[RigidBody2D]             = []
var FP_joints_UP: Array[DampedSpringJoint2D]       = []
var FP_head_tex_UP: ImageTexture
var FP_body_tex_UP: ImageTexture
var FP_tail_tex_UP: ImageTexture
var FP_time_UP: float                              = 0.0


func _ready() -> void:
    # Generate procedural textures once
    _FP_generate_textures_IN()

    # Build the fish (segments + joints) and pin its head
    _FP_build_fish_IN()
    _FP_pin_head_IN()

    # Enable drawing + physics callbacks
    set_process(true)
    set_physics_process(true)


func _process(_delta: float) -> void:
    # Force a redraw so _draw() fires
    queue_redraw()


func _physics_process(delta: float) -> void:
    # Apply idle sinusoidal torque on body & tail segments
    FP_time_UP += delta
    var torque_val: float = sin(FP_time_UP * 2.0) * 5.0
    for i in range(1, FP_segments_UP.size()):
        var seg: RigidBody2D = FP_segments_UP[i]
        seg.apply_torque(torque_val)


func _draw() -> void:
    # Draw spring lines between segments
    for joint in FP_joints_UP:
        var a: RigidBody2D = get_node(joint.node_a) as RigidBody2D
        var b: RigidBody2D = get_node(joint.node_b) as RigidBody2D
        draw_line(a.position, b.position, Color(1, 1, 1, 0.5))

    # Draw velocity vectors for debugging
    for seg in FP_segments_UP:
        var start: Vector2 = seg.position
        var vel: Vector2 = seg.linear_velocity
        var finish: Vector2 = start + vel * 0.1
        draw_line(start, finish, Color(1, 0, 0))


func _FP_generate_textures_IN() -> void:
    FP_head_tex_UP = ImageTexture.create_from_image(_FP_create_ellipse_IN(32, 20))
    FP_body_tex_UP = ImageTexture.create_from_image(_FP_create_ellipse_IN(24, 16))
    FP_tail_tex_UP = ImageTexture.create_from_image(_FP_create_triangle_IN(20, 20))


func _FP_build_fish_IN() -> void:
    var count: int = FP_segment_masses_IN.size()
    for i in range(count):
        # 1) Create segment body
        var seg: RigidBody2D = RigidBody2D.new()
        seg.name = "Segment_%d" % i
        seg.position = Vector2(-i * FP_segment_spacing_IN, 0.0)
        seg.mass = FP_segment_masses_IN[i]

        # 2) Attach sprite with correct texture, tint, and scale
        var spr: Sprite2D = Sprite2D.new()
        if i == 0:
            spr.texture = FP_head_tex_UP
            spr.modulate = Color(0.4, 0.6, 1.0)
            spr.scale = Vector2(1.4, 1.4)
        elif i < count - 1:
            spr.texture = FP_body_tex_UP
            spr.modulate = Color(0.5, 1.0, 0.5)
            spr.scale = Vector2(1.1, 1.1)
        else:
            spr.texture = FP_tail_tex_UP
            spr.modulate = Color(1.0, 0.7, 0.3)
            spr.scale = Vector2(0.8, 0.8)

        seg.add_child(spr)
        add_child(seg)
        FP_segments_UP.append(seg)

        # 3) Link to previous via DampedSpringJoint2D
        if i > 0:
            var joint: DampedSpringJoint2D = DampedSpringJoint2D.new()
            joint.node_a = FP_segments_UP[i - 1].get_path()
            joint.node_b = seg.get_path()
            joint.length = FP_segment_spacing_IN

            # full if/else for stiffness
            if i - 1 < FP_stiffness_IN.size():
                joint.stiffness = FP_stiffness_IN[i - 1]
            else:
                joint.stiffness = joint.stiffness

            # full if/else for damping
            if i - 1 < FP_damping_IN.size():
                joint.damping = FP_damping_IN[i - 1]
            else:
                joint.damping = joint.damping

            add_child(joint)
            FP_joints_UP.append(joint)


func _FP_pin_head_IN() -> void:
    if FP_segments_UP.size() == 0:
        return

    var anchor: StaticBody2D = StaticBody2D.new()
    anchor.name = "Anchor"
    add_child(anchor)

    var pin: PinJoint2D = PinJoint2D.new()
    pin.node_a = anchor.get_path()
    pin.node_b = FP_segments_UP[0].get_path()
    add_child(pin)


func _FP_create_ellipse_IN(w: int, h: int) -> Image:
    var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var rx: float = float(w) / 2.0
    var ry: float = float(h) / 2.0

    for y in range(h):
        for x in range(w):
            var dx: float = (x - rx + 0.5) / rx
            var dy: float = (y - ry + 0.5) / ry
            if dx * dx + dy * dy <= 1.0:
                img.set_pixel(x, y, Color(1, 1, 1))

    return img


func _FP_create_triangle_IN(w: int, h: int) -> Image:
    var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var cx: float = float(w) / 2.0

    for y in range(h):
        var t: float = float(y) / float(max(h - 1, 1))
        var half: float = (w * t) / 2.0
        for x in range(w):
            if abs(x - cx) <= half:
                img.set_pixel(x, y, Color(1, 1, 1))

    return img

# gdlint:enable = class-variable-name,function-name,function-variable-name,loop-variable-name
