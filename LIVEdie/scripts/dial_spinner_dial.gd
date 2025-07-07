extends Control

var spinner: DialSpinner


func _draw() -> void:
    if spinner == null:
        return
    var center: Vector2 = size / 2
    var radius: float = min(size.x, size.y) / 5
    var segs := 20
    var seg_angle := TAU / segs
    for i in range(segs):
        var c: Color = (
            Color(0.4, 0.6, 1.0) if (i + int(spinner._flash)) % 2 == 0 else Color(0.6, 0.4, 1.0)
        )
        var a0 := seg_angle * i + spinner._dial_angle
        var a1 := a0 + seg_angle
        draw_arc(center, radius, a0, a1, segs, c, 100)
