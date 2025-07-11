# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/RollExecutor.gd
# Key Classes      • RollExecutor – executes parsed dice rolls
# Key Functions    • RE_eval_ast_IN, RE_roll_group_IN
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • DiceParser.gd, RNGManager.gd, UIEventBus.gd
# Last Major Rev   • 24-07-10 – initial implementation
###############################################################
class_name RollExecutor
extends Node

signal roll_executed(result: Dictionary)
signal roll_failed(message: String)

var RE_parser_IN: DiceParser
var RE_last_result_SH: Dictionary = {}


func _ready() -> void:
    RE_parser_IN = DiceParser.new()
    get_node("/root/UIEventBus").roll_requested.connect(_on_roll_requested)


func _on_roll_requested(notation: String) -> void:
    print("\u25B6 RollExecutor got:", notation)
    var plan := RE_parser_IN.DP_parse_expression(notation)
    if plan.errors.size() > 0:
        RE_last_result_SH = {}
        roll_failed.emit(" ".join(plan.errors.map(func(e): return e.msg)))
        return
    var groups: Array = []
    for g in plan.dice_groups:
        var res := RE_roll_group_IN(g)
        g["result"] = res
        groups.append(res)
    var total := 0
    var rolls: Array = []
    var kept: Array = []
    for ast in plan.asts:
        var res := RE_eval_ast_IN(ast)
        total += res.value
        rolls += res.rolls
        kept += res.kept
    RE_last_result_SH = {
        "notation": notation,
        "total": total,
        "rolls": rolls,
        "kept": kept,
        "groups": groups,
    }
    roll_executed.emit(RE_last_result_SH)


func RE_eval_ast_IN(node: Variant) -> Dictionary:
    if typeof(node) == TYPE_DICTIONARY and node.has("type"):
        match node.type:
            "number":
                return {"value": node.value, "rolls": [], "kept": []}
            "dice":
                if node.has("result"):
                    return node.result
                return RE_roll_group_IN(node)
            "binary":
                var left := RE_eval_ast_IN(node.left)
                var right := RE_eval_ast_IN(node.right)
                var val := 0
                match node.op:
                    "+":
                        val = left.value + right.value
                    "-":
                        val = left.value - right.value
                    "*":
                        val = left.value * right.value
                    "/":
                        if right.value == 0:
                            val = 0
                        else:
                            val = left.value / right.value
                return {
                    "value": val,
                    "rolls": left.rolls + right.rolls,
                    "kept": left.kept + right.kept,
                }
    return {"value": 0, "rolls": [], "kept": []}


func RE_roll_group_IN(group: Dictionary) -> Dictionary:
    var results: Array = []
    for i in range(group.num):
        if typeof(group.sides) == TYPE_STRING and group.sides == "F":
            results.append(get_node("/root/RNGManager").RM_generate_fudge_SH())
        else:
            var sides_val := 0
            if typeof(group.sides) == TYPE_STRING:
                if group.sides == "%":
                    sides_val = 100
                else:
                    sides_val = int(group.sides)
            else:
                sides_val = int(group.sides)
            results.append(get_node("/root/RNGManager").RM_generate_roll_SH(sides_val))
    var kept := results.duplicate()
    for mod in group.mods:
        kept = _RE_apply_keepdrop_IN(kept, mod)
    var sum := 0
    for v in kept:
        sum += v
    return {"value": sum, "rolls": results, "kept": kept}


func _RE_apply_keepdrop_IN(results: Array, mod: Dictionary) -> Array:
    var sorted := results.duplicate()
    sorted.sort()
    var out: Array = []
    var c := int(mod.count)
    match mod.type:
        "kh":
            for i in range(max(0, sorted.size() - c), sorted.size()):
                out.append(sorted[i])
        "kl":
            for i in range(min(c, sorted.size())):
                out.append(sorted[i])
        "dh":
            for i in range(max(0, sorted.size() - c)):
                out.append(sorted[i])
        "dl":
            for i in range(c, sorted.size()):
                out.append(sorted[i])
        _:
            out = sorted
    return out
