#
# LIVEdie/scripts/dice_parser.gd
# Key Classes      • DiceParser – evaluate dice notation
# Key Functions    • evaluate() – evaluate dice expression
# Critical Consts  • DP_DICE_RE – regex for dice pattern
# Dependencies     • none
# Last Major Rev   • 24-04-XX – initial version
###############################################################
class_name DiceParser
extends RefCounted

var dp_dice_re := RegEx.new()
var dp_condition_re := RegEx.new()

var dp_rng := RandomNumberGenerator.new()


func _init() -> void:
    dp_dice_re.compile("^(?P<count>\\d*)d(?P<faces>\\d+|%)")
    dp_condition_re.compile("([<>!=]=?|==)(\\d+)$")
    dp_rng.randomize()


func _dp_is_digit(c: String) -> bool:
    return c >= "0" and c <= "9"


func evaluate(expr: String, seed: int = -1) -> Dictionary:
    var clean := expr.strip_edges().replace(" ", "")
    if seed != -1:
        dp_rng.seed = seed
    var parsed := _dp_parse_expression(clean)
    var total = _dp_eval_node(parsed)
    var result := {"total": total, "rolls": parsed.get("rolls", [])}
    if (
        typeof(parsed) == TYPE_DICTIONARY
        and parsed.has("condition")
        and parsed["condition"] != null
    ):
        var cond = parsed["condition"]
        result["success"] = _dp_eval_condition(total, cond)
    return result


func _dp_eval_condition(val: int, cond: Dictionary) -> bool:
    match cond["op"]:
        "==":
            return val == cond["num"]
        "!=":
            return val != cond["num"]
        ">=":
            return val >= cond["num"]
        "<=":
            return val <= cond["num"]
        ">":
            return val > cond["num"]
        "<":
            return val < cond["num"]
    return false


func _dp_check(val: int, cond: String) -> bool:
    var m := dp_condition_re.search(cond)
    if m:
        var op := m.get_string(1)
        var num := int(m.get_string(2))
        match op:
            "==":
                return val == num
            "!=":
                return val != num
            ">=":
                return val >= num
            "<=":
                return val <= num
            ">":
                return val > num
            "<":
                return val < num
    return false


func _dp_parse_expression(text: String, index: int = 0) -> Dictionary:
    var node := _dp_parse_term(text, index)
    index = node["index"]
    while index < text.length():
        var op := text[index]
        if op != "+" and op != "-":
            break
        index += 1
        var right := _dp_parse_term(text, index)
        index = right["index"]
        node = {"type": "op", "op": op, "left": node, "right": right}
    node["index"] = index
    return node


func _dp_parse_term(text: String, index: int) -> Dictionary:
    var node := _dp_parse_factor(text, index)
    index = node["index"]
    while index < text.length():
        var op := text[index]
        if op != "*" and op != "/":
            break
        index += 1
        var right := _dp_parse_factor(text, index)
        index = right["index"]
        node = {"type": "op", "op": op, "left": node, "right": right}
    node["index"] = index
    return node


func _dp_parse_factor(text: String, index: int) -> Dictionary:
    if text[index] == "(":
        index += 1
        var node := _dp_parse_expression(text, index)
        index = node["index"]
        if index >= text.length() or text[index] != ")":
            push_error("Unmatched parentheses")
            return {"type": "num", "value": 0, "index": index}
        index += 1
        node["index"] = index
        return node
    return _dp_parse_number_or_dice(text, index)


func _dp_parse_number_or_dice(text: String, index: int) -> Dictionary:
    var start := index
    while index < text.length() and _dp_is_digit(text[index]):
        index += 1
    var digits := text.substr(start, index - start)
    var has_d := index < text.length() and (text[index] == "d" or text[index] == "D")
    if not has_d:
        return {"type": "num", "value": int(digits), "index": index}
    var count := 1
    if digits != "":
        count = int(digits)
    index += 1
    var faces_start := index
    while index < text.length() and (_dp_is_digit(text[index]) or text[index] == "%"):
        index += 1
    var faces_str := text.substr(faces_start, index - faces_start)
    if faces_str == "%":
        faces_str = "100"
    var faces := int(faces_str)
    if count <= 0 or faces <= 1:
        push_error("Illegal dice size: %s" % text.substr(start, index - start))
    var mods := {}
    while index < text.length():
        var c := text[index]
        if c == "!":
            var recursive := false
            index += 1
            if index < text.length() and text[index] == "!":
                recursive = true
                index += 1
            mods["explode"] = recursive
            continue
        elif c == "k" or c == "d":
            var keep := c == "k"
            index += 1
            var high := true
            if index < text.length() and (text[index] == "h" or text[index] == "l"):
                high = text[index] == "h"
                index += 1
            var num_start := index
            while index < text.length() and _dp_is_digit(text[index]):
                index += 1
            var num := int(text.substr(num_start, index - num_start))
            var key := "drop"
            if keep:
                key = "keep"
            mods[key] = {"high": high, "count": num}
            continue
        elif c == "r" or c == "R":
            var indefinite := c == "R"
            index += 1
            var once := false
            if index < text.length() and text[index] == "o":
                once = true
                index += 1
            var cond_start := index
            while index < text.length() and text[index] in ["<", ">", "=", "!"]:
                index += 1
            while index < text.length() and _dp_is_digit(text[index]):
                index += 1
            var cond_str := text.substr(cond_start, index - cond_start)
            if (
                cond_str != ""
                and not cond_str.begins_with("<")
                and not cond_str.begins_with(">")
                and not cond_str.begins_with("=")
                and not cond_str.begins_with("!")
            ):
                cond_str = "==" + cond_str
            mods["reroll"] = {"indef": indefinite, "once": once, "cond": cond_str}
            continue
        elif c == "s":
            index += 1
            var mode := "asc"
            if index < text.length() and (text[index] == "a" or text[index] == "d"):
                if text[index] == "d":
                    mode = "desc"
                else:
                    mode = "asc"
                index += 1
            mods["sort"] = mode
            continue
        else:
            break
    var cond := _dp_parse_condition(text, index)
    index = cond.get("index", index)
    return {
        "type": "dice",
        "count": count,
        "faces": faces,
        "mods": mods,
        "condition": cond.get("cond", null),
        "index": index
    }


func _dp_parse_condition(text: String, index: int) -> Dictionary:
    if index >= text.length():
        return {"index": index}
    var remain := text.substr(index)
    var match := dp_condition_re.search(remain)
    if match and match.get_start() == 0:
        var op := match.get_string(1)
        var num := int(match.get_string(2))
        index += match.get_end()
        return {"cond": {"op": op, "num": num}, "index": index}
    return {"index": index}


func _dp_eval_node(node):
    if node["type"] == "num":
        return node["value"]
    elif node["type"] == "op":
        var l = _dp_eval_node(node["left"])
        var r = _dp_eval_node(node["right"])
        var result := 0
        match node["op"]:
            "+":
                result = l + r
            "-":
                result = l - r
            "*":
                result = l * r
            "/":
                result = int(l / r)
        node["rolls"] = []
        if typeof(node["left"]) == TYPE_DICTIONARY and node["left"].has("rolls"):
            node["rolls"] += node["left"]["rolls"]
        if typeof(node["right"]) == TYPE_DICTIONARY and node["right"].has("rolls"):
            node["rolls"] += node["right"]["rolls"]
        return result
    elif node["type"] == "dice":
        var rolls := []
        for i in node["count"]:
            var v := dp_rng.randi_range(1, node["faces"])
            if node["mods"].has("reroll"):
                var rr = node["mods"]["reroll"]
                if _dp_check(v, rr["cond"]):
                    if rr["once"]:
                        v = dp_rng.randi_range(1, node["faces"])
                    else:
                        var limit := 100 if rr["indef"] else 1
                        var tries := 0
                        while _dp_check(v, rr["cond"]) and tries < limit:
                            v = dp_rng.randi_range(1, node["faces"])
                            tries += 1
            rolls.append(v)
        if node["mods"].has("explode"):
            var exploding := true
            while exploding:
                exploding = false
                for i in range(rolls.size()):
                    if rolls[i] == node["faces"]:
                        var new_val := dp_rng.randi_range(1, node["faces"])
                        rolls.append(new_val)
                        exploding = node["mods"]["explode"]
        if node["mods"].has("sort"):
            if node["mods"]["sort"] == "asc":
                rolls.sort()
            elif node["mods"]["sort"] == "desc":
                rolls.sort()
                rolls.reverse()
        if node["mods"].has("keep"):
            var opt = node["mods"]["keep"]
            rolls.sort()
            if opt["high"]:
                rolls = rolls.slice(rolls.size() - opt["count"], rolls.size())
            else:
                rolls = rolls.slice(0, opt["count"])
        if node["mods"].has("drop"):
            var opt2 = node["mods"]["drop"]
            rolls.sort()
            if opt2["high"]:
                rolls = rolls.slice(0, rolls.size() - opt2["count"])
            else:
                rolls = rolls.slice(opt2["count"], rolls.size())
        var sum := 0
        for v in rolls:
            sum += v
        node["rolls"] = rolls
        return sum
    return 0
