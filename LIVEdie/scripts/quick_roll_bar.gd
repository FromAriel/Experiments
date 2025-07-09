###############################################################
# quick_roll_bar.gd – unified Quick-Roll Bar (Godot 4.4.1)
###############################################################
extends VBoxContainer
class_name QuickRollBar

# ───────── Inspector knobs ───────────────────────────────────
@export_range(1.0, 3.0, 0.05) var ui_scale      : float = 1.0
@export                   var chip_font_size  : int   = 28
@export                   var button_font_size: int   = 35
@export                   var roll_font_size  : int   = 28

# ───────── Internal state ────────────────────────────────────
var _queue      : Array[Dictionary] = []   # [{faces:int, count:int}, …]
var _last_faces : int = 0

# long-press helpers
var _lp_type      : String = ""   # "die" | "rep"
var _lp_param     : int    = 0
var _lp_triggered : bool   = false
var _lp_btn       : Button = null

const SUPER: Dictionary = { "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴",
                            "5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹" }

# ───────── Scene caches ──────────────────────────────────────
@onready var _std_row : HFlowContainer = $StandardRow
@onready var _adv_row : HFlowContainer = $AdvancedRow
@onready var _rep_row : HFlowContainer = $RepeaterRow

@onready var _chip_box: HBoxContainer = $QueueRow/HScroll/DiceChips
@onready var _preview : AcceptDialog  = $PreviewDialog
@onready var _spinner : DialSpinner   = $DialSpinner
@onready var _lp_timer: Timer         = $LongPressTimer

@onready var _hist_btn: Button            = $"../HistoryButton"
@onready var _hist_pan: RollHistoryPanel  = $"../RollHistoryPanel"

# ───────── Ready ────────────────────────────────────────────
func _ready() -> void:
    _bind_dice_buttons()
    _bind_repeat_buttons()

    _std_row.get_node("AdvancedToggle").pressed.connect(_toggle_adv)
    _rep_row.get_node("RollButton").pressed.connect(_roll_pressed)
    _rep_row.get_node("DelButton").pressed.connect(_del_pressed)
    _rep_row.get_node("DieX").pressed.connect(_custom_die_pressed)

    _lp_timer.timeout.connect(_on_long_press)
    _preview.confirmed.connect(_on_preview_accept)
    _spinner.confirmed.connect(_on_spinner_accept)
    _hist_btn.pressed.connect(_toggle_history)

    _apply_scale()

# ───────── Binding helpers ──────────────────────────────────
func _bind_dice_buttons() -> void:
    for row in [_std_row, _adv_row]:
        for n in row.get_children():
            if n is Button:
                var faces: int = _extract_faces(n)
                if faces > 0:
                    var b := n as Button
                    b.button_down.connect(_die_down.bind(faces, b))
                    b.button_up.connect(_die_up.bind(faces, b))

func _extract_faces(n: Node) -> int:
    # Preferred: DieGlyphButton export
    if n.has_method("get") and n.has_method("get_property_list"):
        for p: Dictionary in n.get_property_list():
            if p.name == "die_faces":
                return int(n.get("die_faces"))
    # Fallback: legacy D6 text
    if n is Button:
        var t: String = (n as Button).text
        if t == "D%":
            return 100
        if t.begins_with("D") and t.substr(1).is_valid_int():
            return int(t.substr(1))
    return 0

func _bind_repeat_buttons() -> void:
    for n in _rep_row.get_children():
        if n is Button and n.name.begins_with("X"):
            var mult: int = int((n as Button).text.substr(1))
            (n as Button).button_down.connect(_rep_down.bind(mult, n))
            (n as Button).button_up.connect(_rep_up.bind(mult, n))

# ───────── Queue helpers ────────────────────────────────────
func _queue_add(faces: int, qty: int) -> void:
    if _queue.is_empty() or _queue[-1]["faces"] != faces:
        _queue.append({ "faces": faces, "count": qty })
    else:
        _queue[-1]["count"] += qty
    _last_faces = faces
    _queue_refresh()

func _queue_refresh() -> void:
    for c in _chip_box.get_children():
        c.queue_free()
    if _queue.is_empty():
        $QueueRow.hide()
        return

    $QueueRow.show()
    for e in _queue:
        var lbl := Label.new()
        lbl.text = "D%d×%d" % [e["faces"], e["count"]]
        lbl.custom_minimum_size = Vector2(90, 40) * ui_scale
        lbl.add_theme_font_size_override("font_size", chip_font_size * ui_scale)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _chip_box.add_child(lbl)

# ───────── Long-press handling ──────────────────────────────
func _die_down(faces: int, btn: Button) -> void:
    _lp_type = "die"
    _lp_param = faces
    _lp_btn = btn
    _lp_triggered = false
    _lp_timer.start()

func _die_up(faces: int, _btn: Button) -> void:
    if _lp_timer.time_left > 0.0:
        _lp_timer.stop()
        _queue_add(faces, 1)
    elif not _lp_triggered:
        _queue_add(faces, 1)

func _rep_down(mult: int, btn: Button) -> void:
    _lp_type = "rep"
    _lp_param = mult
    _lp_btn = btn
    _lp_triggered = false
    _lp_timer.start()

func _rep_up(mult: int, _btn: Button) -> void:
    if _lp_timer.time_left > 0.0:
        _lp_timer.stop()
        _apply_multiplier(mult)
    elif not _lp_triggered:
        _apply_multiplier(mult)

func _on_long_press() -> void:
    _lp_triggered = true
    if _lp_type == "rep":
        _show_preview(_lp_param)
    else:
        _spinner.ds_value = 1
        _spinner.open_dial_at(_lp_btn.get_global_rect().get_center())

# ───────── Repeat logic ─────────────────────────────────────
func _apply_multiplier(mult: int) -> void:
    if _last_faces == 0:
        return
    if not _queue.is_empty() and _queue[-1]["faces"] == _last_faces and _queue[-1]["count"] == 1:
        _queue[-1]["count"] = mult
    else:
        _queue_add(_last_faces, mult)
    _queue_refresh()

# ───────── Preview & Spinner accept ─────────────────────────
func _show_preview(mult: int) -> void:
    var parts: Array[String] = []
    for e in _queue:
        parts.append("d%d%s" % [e["faces"], _superscript(e["count"] * mult)])
    _preview.dialog_text = "×%d  →  %s" % [mult, " + ".join(parts)]
    _preview.popup_centered()

func _superscript(n: int) -> String:
    var out := ""
    for ch in str(n):
        out += SUPER.get(ch, ch)
    return out

func _on_preview_accept() -> void:
    for e in _queue:
        e["count"] *= _lp_param
    _queue_refresh()

func _on_spinner_accept() -> void:
    _queue_add(_lp_param, int(_spinner.ds_value))

# ───────── Custom DX? ───────────────────────────────────────
func _custom_die_pressed() -> void:
    _spinner.ds_value = 4
    _spinner.open_dial_at(Vector2.ZERO)
    _spinner.confirmed.connect(_custom_die_callback, Object.CONNECT_ONE_SHOT)

func _custom_die_callback() -> void:
    var faces_val: int = int(_spinner.ds_value)
    _queue_add(faces_val, 1)

# ───────── Delete / Roll / History ──────────────────────────
func _del_pressed() -> void:
    if _queue.is_empty():
        return
    _queue.pop_back()
    _last_faces = _queue[-1]["faces"] if not _queue.is_empty() else 0
    _queue_refresh()

func _roll_pressed() -> void:
    if _queue.is_empty():
        return
    var expr: String = _queue_to_expr()
    var parser := DiceParser.new()
    var res := parser.evaluate(expr)
    var total :Variant= res.get("total")
    _hist_pan.add_entry("%s → %s" % [expr, total])
    _queue.clear()
    _last_faces = 0
    _queue_refresh()

func _queue_to_expr() -> String:
    var parts: Array[String] = []
    for e in _queue:
        parts.append("%dd%d" % [e["count"], e["faces"]])
    return " + ".join(parts)

func _toggle_history() -> void:
    if _hist_pan.visible:
        _hist_pan.hide_panel()
    else:
        _hist_pan.show_panel()

# ───────── UI helpers ───────────────────────────────────────
func _toggle_adv() -> void:
    _adv_row.visible = not _adv_row.visible

func _apply_scale() -> void:
    var btn_size: Vector2 = Vector2(80, 80) * ui_scale
    for row in [_std_row, _adv_row, _rep_row]:
        row.add_theme_constant_override("separation", int(30 * ui_scale))
        for n in row.get_children():
            if n is Button:
                var b := n as Button
                b.custom_minimum_size = btn_size
                var fs: int = button_font_size * ui_scale
                if b == _rep_row.get_node("RollButton"):
                    fs = roll_font_size * ui_scale
                b.add_theme_font_size_override("font_size", fs)
