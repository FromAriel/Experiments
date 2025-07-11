# gdlint:disable=class-variable-name,function-name,class-definitions-order,max-returns
# gdlint:disable=no-elif-return,no-else-return
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
        if g.type == "number":
            groups.append({"value": g.value})
            continue
        var res := RE_roll_group_IN(g)
        g["result"] = res
        groups.append(res)
    var total := 0
    var rolls: Array = []
    var kept: Array = []
    var sections: Array = []
    for ast in plan.sections:
        var res := RE_eval_ast_IN(ast)
        total += res.value
        rolls += res.rolls
        kept += res.kept
        sections.append(res)
    RE_last_result_SH = {
        "notation": notation,
        "total": total,
        "rolls": rolls,
        "kept": kept,
        "groups": groups,
        "sections": sections,
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
                    "vs":
                        var lscore := _RE_vs_score_IN(left)
                        var rscore := _RE_vs_score_IN(right)
                        var win := "tie"
                        if lscore > rscore:
                            win = "lhs"
                        elif rscore > lscore:
                            win = "rhs"
                        return {
                            "value": 0,
                            "rolls": left.rolls + right.rolls,
                            "kept": left.kept + right.kept,
                            "winner": win,
                            "lhs": left,
                            "rhs": right,
                        }
                var ret := {
                    "value": val,
                    "rolls": left.rolls + right.rolls,
                    "kept": left.kept + right.kept,
                }
                if left.has("winner"):
                    ret.winner = left.winner
                    ret.lhs = left.lhs
                    ret.rhs = left.rhs
                elif right.has("winner"):
                    ret.winner = right.winner
                    ret.lhs = right.lhs
                    ret.rhs = right.rhs
                return ret
            "func":
                var args: Array = []
                for a in node.args:
                    args.append(RE_eval_ast_IN(a))
                return _RE_eval_function_IN(node.name, args)
    return {"value": 0, "rolls": [], "kept": []}


func RE_roll_group_IN(group: Dictionary) -> Dictionary:
    var results: Array = []
    for i in range(group.num):
        results.append(_RE_roll_die_IN(group.sides))

    var kept := results.duplicate()
    for mod in group.mods:
        if mod.type in ["kh", "kl", "dh", "dl"]:
            kept = _RE_apply_keepdrop_IN(kept, mod)

    var extras: Array = []
    for mod in group.mods:
        if mod.type == "reroll":
            var rr = _RE_apply_reroll_IN(kept, mod, group.sides)
            kept = rr.kept
            extras += rr.extra
        elif mod.type == "explode":
            var ex = _RE_apply_explode_IN(kept, mod, group.sides)
            kept = ex.kept
            extras += ex.extra

    var meta := {"succ": 0, "crit": 0, "fail": 0}
    var count_success := false
    for m in group.mods:
        if m.type in ["success", "cs", "cf"]:
            count_success = true
    var sum := 0
    for v in kept:
        var succ := false
        var crit := false
        var fail := false
        for m in group.mods:
            match m.type:
                "success":
                    succ = succ or _RE_compare_condition_IN(v, m.compare, m.target)
                "cs":
                    crit = crit or _RE_compare_condition_IN(v, m.compare, m.target)
                "cf":
                    fail = fail or _RE_compare_condition_IN(v, m.compare, m.target)
                "count":
                    succ = succ or v == int(m.target)
        if succ:
            meta.succ += 1
        if crit:
            meta.crit += 1
        if fail:
            meta.fail += 1
        sum += v
    var value := sum
    if count_success or meta.succ > 0 or meta.crit > 0 or meta.fail > 0:
        value = meta.succ
    return {
        "value": value,
        "rolls": results + extras,
        "kept": kept,
        "meta": meta,
    }


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


func _RE_roll_die_IN(sides: Variant) -> int:
    var rng := get_node("/root/RNGManager")
    if typeof(sides) == TYPE_STRING:
        if sides == "F":
            return rng.RM_generate_fudge_SH()
        elif sides == "%":
            return rng.RM_generate_roll_SH(100)
        else:
            return rng.RM_generate_roll_SH(int(sides))
    return rng.RM_generate_roll_SH(int(sides))


func _RE_compare_condition_IN(value: int, comp: String, target: int) -> bool:
    match comp:
        "<":
            return value < target
        "<=":
            return value <= target
        ">":
            return value > target
        ">=":
            return value >= target
        "":
            return value == target
    return false


func _RE_apply_reroll_IN(results: Array, mod: Dictionary, sides: Variant) -> Dictionary:
    var out := results.duplicate()
    var extra: Array = []
    for i in range(out.size()):
        if _RE_compare_condition_IN(out[i], mod.compare, mod.target):
            if mod.method == "ra":
                var loops := 0
                while _RE_compare_condition_IN(out[i], mod.compare, mod.target) and loops < 100:
                    out[i] = _RE_roll_die_IN(sides)
                    extra.append(out[i])
                    loops += 1
            else:
                out[i] = _RE_roll_die_IN(sides)
                extra.append(out[i])
    return {"kept": out, "extra": extra}


func _RE_should_explode_IN(value: int, mod: Dictionary, sides: Variant) -> bool:
    if mod.compare == "":
        var max_val := 0
        if typeof(sides) == TYPE_STRING:
            if sides == "%":
                max_val = 100
            elif sides == "F":
                max_val = 1
            else:
                max_val = int(sides)
        else:
            max_val = int(sides)
        return value == max_val
    return _RE_compare_condition_IN(value, mod.compare, mod.target)


func _RE_apply_explode_IN(results: Array, mod: Dictionary, sides: Variant) -> Dictionary:
    var out := results.duplicate()
    var extra: Array = []
    var compound = mod.style.find("!!") != -1
    var penetrate = mod.style.begins_with("p")
    for i in range(out.size()):
        var total_extra = 0
        var current = out[i]
        var loops = 0
        var triggered := false
        while _RE_should_explode_IN(current, mod, sides) and loops < 100:
            triggered = true
            var roll := _RE_roll_die_IN(sides)
            extra.append(roll)
            var add_val := roll
            if penetrate:
                add_val -= 1
            if compound:
                total_extra += add_val
            else:
                out.append(add_val)
            current = roll
            loops += 1
        if loops >= 100:
            push_warning("Explosion max iterations reached")
        if compound and triggered and total_extra != 0:
            out[i] += total_extra
    return {"kept": out, "extra": extra}


func _RE_vs_score_IN(data: Dictionary) -> int:
    var succ := 0
    var has := false
    if data.has("groups"):
        for g in data.groups:
            if typeof(g) == TYPE_DICTIONARY and g.has("meta") and g.meta.succ > 0:
                succ += g.meta.succ
                has = true
    if has:
        return succ
    var mx := 0
    for v in data.kept:
        mx = max(mx, int(v))
    return mx


func RE_roll_vs(lhs_notation: String, rhs_notation: String) -> Dictionary:
    var lhs := _debug_roll(lhs_notation)
    var rhs := _debug_roll(rhs_notation)
    var lscore := _RE_vs_score_IN(lhs)
    var rscore := _RE_vs_score_IN(rhs)
    var w := "tie"
    if lscore > rscore:
        w = "lhs"
    elif rscore > lscore:
        w = "rhs"
    return {"winner": w, "lhs": lhs, "rhs": rhs}


func RE_roll_with_wild(num_sides: int, wild_sides: int = 6) -> Dictionary:
    var normal = _debug_roll("1d" + str(num_sides) + "!")
    var wild = _debug_roll("1d" + str(wild_sides) + "!")
    var val = max(normal.total, wild.total)
    return {"value": val, "normal": normal, "wild": wild}


func _debug_roll(notation: String) -> Dictionary:
    var plan := RE_parser_IN.DP_parse_expression(notation)
    if plan.errors.size() > 0:
        return {
            "notation": notation, "total": 0, "rolls": [], "kept": [], "groups": [], "sections": []
        }
    var groups: Array = []
    for g in plan.dice_groups:
        if g.type == "number":
            groups.append({"value": g.value})
            continue
        var res := RE_roll_group_IN(g)
        g["result"] = res
        groups.append(res)
    var total := 0
    var rolls: Array = []
    var kept: Array = []
    var sections: Array = []
    for ast in plan.sections:
        var res := RE_eval_ast_IN(ast)
        total += res.value
        rolls += res.rolls
        kept += res.kept
        sections.append(res)
    return {
        "notation": notation,
        "total": total,
        "rolls": rolls,
        "kept": kept,
        "groups": groups,
        "sections": sections,
    }


func _RE_eval_function_IN(name: String, args: Array) -> Dictionary:
    var rolls: Array = []
    var kept: Array = []
    var values: Array = []
    for a in args:
        rolls += a.rolls
        kept += a.kept
        values.append(a.value)
    match name:
        "min":
            return {"value": min(values[0], values[1]), "rolls": rolls, "kept": kept}
        "max":
            return {"value": max(values[0], values[1]), "rolls": rolls, "kept": kept}
        "sum":
            var s := 0
            for v in values:
                s += v
            return {"value": s, "rolls": rolls, "kept": kept}
        "floor":
            return {"value": floor(values[0]), "rolls": rolls, "kept": kept}
        "ceil":
            return {"value": ceil(values[0]), "rolls": rolls, "kept": kept}
        "abs":
            return {"value": abs(values[0]), "rolls": rolls, "kept": kept}
        "sort":
            kept.sort()
            return {"value": values[0] if values.size() > 0 else 0, "rolls": rolls, "kept": kept}
        "rolls":
            return {"value": 0, "rolls": rolls, "kept": kept}
        _:
            return {"value": values[0] if values.size() > 0 else 0, "rolls": rolls, "kept": kept}
