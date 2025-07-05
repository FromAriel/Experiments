# gdlint:disable = class-variable-name,function-name,class-definitions-order,max-returns
###############################################################
# LIVEdie/scripts/dice_parser.gd
# Key Classes      • DiceParser – evaluate dice notation strings
# Key Functions    • evaluate() – parse and execute a dice expression
# Dependencies     • none
# Last Major Rev   • 24-05-27 – initial parser implementation
###############################################################
class_name DiceParser
extends RefCounted

var _rng: RandomNumberGenerator
var _last_result: Dictionary = {}


func evaluate(expr: String, seed: int = -1) -> Dictionary:
    _rng = RandomNumberGenerator.new()
    if seed != -1:
        _rng.seed = seed
    var rewritten := _rewrite_expression(expr.replace(" ", ""))
    var e := Expression.new()
    var status := e.parse(rewritten)
    if status != OK:
        return {"error": e.get_error_text()}
    var value = e.execute([], self)
    return {
        "total": value,
        "rolls": _last_result.get("rolls", []),
        "successes": _last_result.get("successes", null)
    }


func roll_dice(token: String) -> int:
    var spec := _parse_roll(token)
    var result := _roll_spec(spec)
    _last_result = result
    return result.total


func _rewrite_expression(expr: String) -> String:
    var out := ""
    var i := 0
    while i < expr.length():
        var c := expr[i]
        if c >= "0" and c <= "9":
            var j := i
            while j < expr.length() and expr[j] >= "0" and expr[j] <= "9":
                j += 1
            if j < expr.length() and expr[j] == "d":
                j += 1
                while j < expr.length() and expr[j] not in ["+", "-", "*", "/", "(", ")"]:
                    j += 1
                var token := expr.substr(i, j - i)
                out += 'roll_dice("%s")' % token
                i = j
                continue
            else:
                out += expr.substr(i, j - i)
                i = j
                continue
        elif c == "d":
            var j := i + 1
            while j < expr.length() and expr[j] not in ["+", "-", "*", "/", "(", ")"]:
                j += 1
            var token := expr.substr(i, j - i)
            out += 'roll_dice("%s")' % token
            i = j
            continue
        else:
            out += c
            i += 1
    return out


func _parse_roll(token: String) -> Dictionary:
    var spec: Dictionary = {
        "count": 1,
        "faces": 6,
        "explode": false,
        "recursive": false,
        "keep_type": null,
        "keep_count": 0,
        "reroll_once": false,
        "reroll_op": null,
        "reroll_target": 0,
        "sort": null,
        "cond_op": null,
        "cond_target": 0
    }
    var cond_regex := RegEx.new()
    cond_regex.compile("(>=|<=|>|<|=)(\\d+)")
    var m := cond_regex.search(token)
    if m:
        spec.cond_op = m.get_string(1)
        spec.cond_target = int(m.get_string(2))
        token = token.replace(m.get_string(0), "")
    var reroll_regex := RegEx.new()
    reroll_regex.compile("ro([<>]?\\d+)")
    m = reroll_regex.search(token)
    if m:
        spec.reroll_once = true
        var t := m.get_string(1)
        if t.begins_with(">"):
            spec.reroll_op = ">"
            spec.reroll_target = int(t.substr(1))
        elif t.begins_with("<"):
            spec.reroll_op = "<"
            spec.reroll_target = int(t.substr(1))
        else:
            spec.reroll_op = "=="
            spec.reroll_target = int(t)
        token = token.replace(m.get_string(0), "")
    if token.find("!!") != -1:
        spec.explode = true
        spec.recursive = true
        token = token.replace("!!", "")
    elif token.find("!") != -1:
        spec.explode = true
        token = token.replace("!", "")
    var sort_regex := RegEx.new()
    sort_regex.compile("s([ad])?")
    m = sort_regex.search(token)
    if m:
        var s := m.get_string(1)
        if s == "a":
            spec.sort = "a"
        elif s == "d":
            spec.sort = "d"
        else:
            spec.sort = "a"
        token = token.replace(m.get_string(0), "")
    var keep_regex := RegEx.new()
    keep_regex.compile("kh(\\d+)")
    m = keep_regex.search(token)
    if m:
        spec.keep_type = "kh"
        spec.keep_count = int(m.get_string(1))
        token = token.replace(m.get_string(0), "")
    var base_regex := RegEx.new()
    base_regex.compile("^(\\d*)d(\\d+|%)$")
    m = base_regex.search(token)
    if not m:
        push_error("Invalid dice syntax: %s" % token)
        return spec
    spec.count = int(m.get_string(1)) if m.get_string(1) != "" else 1
    var faces_str := m.get_string(2)
    spec.faces = 100 if faces_str == "%" else int(faces_str)
    if spec.count <= 0 or spec.faces <= 1:
        push_error("Illegal dice size: %s" % token)
    return spec


func _roll_spec(spec: Dictionary) -> Dictionary:
    var rolls: Array[int] = []
    for i in range(spec.count):
        var v := _rng.randi_range(1, spec.faces)
        if spec.reroll_once and _check(v, spec.reroll_op, spec.reroll_target):
            v = _rng.randi_range(1, spec.faces)
        rolls.append(v)
        if spec.explode and v == spec.faces:
            var extra := _rng.randi_range(1, spec.faces)
            rolls.append(extra)
            while spec.recursive and extra == spec.faces:
                extra = _rng.randi_range(1, spec.faces)
                rolls.append(extra)
    if spec.sort == "a":
        rolls.sort()
    elif spec.sort == "d":
        rolls.sort()
        rolls.reverse()
    if spec.keep_type == "kh" and spec.keep_count < rolls.size():
        rolls.sort()
        rolls = rolls.slice(rolls.size() - spec.keep_count, rolls.size())
    var total := 0
    for r in rolls:
        total += r
    var successes: Variant = null
    if spec.cond_op:
        successes = 0
        for r in rolls:
            if _check(r, spec.cond_op, spec.cond_target):
                successes += 1
    return {"rolls": rolls, "total": total, "successes": successes}


func _check(val: int, op: String, target: int) -> bool:
    match op:
        ">":
            return val > target
        ">=":
            return val >= target
        "<":
            return val < target
        "<=":
            return val <= target
        "==":
            return val == target
        "=":
            return val == target
        _:
            return false
