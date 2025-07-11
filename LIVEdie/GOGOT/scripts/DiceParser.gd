# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/DiceParser.gd
# Key Classes      • DiceParser – parse dice notation into roll plan
# Key Functions    • DP_parse_expression
# Critical Consts  • DP_TOKEN_REGEX
# Editor Exports   • (none)
# Dependencies     • VARIABLE_NAMING.md for identifier style
# Last Major Rev   • 24-07-10 – initial implementation
###############################################################
class_name DiceParser
extends RefCounted

const DP_TOKEN_REGEX: String = (
    "(\\d+|adv|dis|kh|kl|dh|dl|ro|ra|r|cs|cf|count|VS|"
    + ">=|<=|>|<|!!|p!!|!|p|\\(|\\)|[+\\-*/,|]|d|F|f|%|[A-Za-z_][A-Za-z0-9_]*)"
)

var DP_token_list_IN: Array = []
var DP_index_IN: int = 0


func DP_parse_expression(notation: String) -> Dictionary:
    DP_token_list_IN = _DP_tokenize_IN(notation)
    DP_index_IN = 0
    var sections: Array = []
    var dice_groups: Array = []
    var constants: Array = []
    var errors: Array = []

    var current
    if DP_index_IN < DP_token_list_IN.size() and DP_token_list_IN[DP_index_IN].type == "PIPE":
        errors.append({"msg": "Empty roll before/after pipe"})
        current = {"type": "number", "value": 0}
        _DP_match_type_IN("PIPE")
    else:
        current = _DP_parse_sum_IN(dice_groups, constants, errors)
    while _DP_match_type_IN("PIPE"):
        sections.append(current)
        if _DP_peek_pipe_or_EOF_IN():
            errors.append({"msg": "Empty roll before/after pipe"})
            break
        current = _DP_parse_sum_IN(dice_groups, constants, errors)
    sections.append(current)

    if DP_index_IN < DP_token_list_IN.size():
        errors.append({"msg": "Unexpected input after '%s'" % _DP_previous_token_IN().value})

    return {
        "sections": sections, "dice_groups": dice_groups, "constants": constants, "errors": errors
    }


func _DP_tokenize_IN(expr: String) -> Array:
    var regex = RegEx.new()
    regex.compile(DP_TOKEN_REGEX)
    var result = regex.search_all(expr)
    var tokens: Array = []
    for r in result:
        var t: String = r.get_string()
        if t.is_valid_int():
            tokens.append({"type": "NUMBER", "value": int(t)})
        elif t == "|":
            tokens.append({"type": "PIPE", "value": t})
        elif t in ["+", "-", "*", "/", ",", "(", ")", "d", "F", "f", "%"]:
            tokens.append({"type": "SYMBOL", "value": t})
        elif t in ["kh", "kl", "dh", "dl"]:
            tokens.append({"type": "KEEPDROP", "value": t})
        elif t in ["adv", "dis"]:
            tokens.append({"type": "ADV", "value": t})
        elif t in ["ro", "ra", "r"]:
            tokens.append({"type": "REROLL", "value": t})
        elif t in ["cs", "cf"]:
            tokens.append({"type": "SUCCESS_TYPE", "value": t})
        elif t == "count":
            tokens.append({"type": "COUNT", "value": t})
        elif t in [">=", "<=", ">", "<"]:
            tokens.append({"type": "COMPARE", "value": t})
        elif t in ["!!", "!", "p", "p!!"]:
            tokens.append({"type": "EXPLODE", "value": t})
        elif t == "VS":
            tokens.append({"type": "VS", "value": t})
        elif t.is_valid_identifier():
            tokens.append({"type": "IDENT", "value": t})
        else:
            push_warning("Unknown token: " + t)
    return tokens


func _DP_collect_dice_IN(node: Variant, out: Array) -> void:
    if typeof(node) == TYPE_DICTIONARY and node.has("type"):
        var typ = node["type"]
        if typ == "dice":
            out.append(node)
        elif typ == "binary":
            _DP_collect_dice_IN(node.left, out)
            _DP_collect_dice_IN(node.right, out)


func _DP_collect_constants_IN(node: Variant, out: Array) -> void:
    if typeof(node) == TYPE_DICTIONARY and node.has("type"):
        var typ = node["type"]
        if typ == "number":
            out.append(node.value)
        elif typ == "binary":
            _DP_collect_constants_IN(node.left, out)
            _DP_collect_constants_IN(node.right, out)


func _DP_parse_expr_IN() -> Dictionary:
    var node = _DP_parse_term_IN()
    while true:
        if _DP_match_type_IN("VS"):
            var right = _DP_parse_term_IN()
            node = {"type": "binary", "op": "vs", "left": node, "right": right}
        elif _DP_match_symbol_IN("+") or _DP_match_symbol_IN("-"):
            var op = _DP_previous_token_IN().value
            var right = _DP_parse_term_IN()
            node = {"type": "binary", "op": op, "left": node, "right": right}
        else:
            break
    return node


func _DP_parse_term_IN() -> Dictionary:
    var node = _DP_parse_factor_IN()
    while _DP_match_symbol_IN("*") or _DP_match_symbol_IN("/"):
        var op = _DP_previous_token_IN().value
        var right = _DP_parse_factor_IN()
        node = {"type": "binary", "op": op, "left": node, "right": right}
    return node


func _DP_parse_factor_IN() -> Dictionary:
    if _DP_match_symbol_IN("("):
        var expr = _DP_parse_expr_IN()
        _DP_expect_symbol_IN(")")
        return expr
    elif _DP_check_dice_ahead_IN():
        return _DP_parse_dice_IN()
    elif _DP_match_type_IN("IDENT"):
        var name = _DP_previous_token_IN().value
        if _DP_match_symbol_IN("("):
            return _DP_parse_function_IN(name)
        return {"type": "number", "value": 0}
    elif _DP_match_type_IN("NUMBER"):
        return {"type": "number", "value": _DP_previous_token_IN().value}
    return {"type": "number", "value": 0}


func _DP_parse_dice_IN() -> Dictionary:
    var num = 1
    if _DP_match_type_IN("NUMBER"):
        num = _DP_previous_token_IN().value
    var sides: Variant = 0
    var saw_d := false
    if _DP_match_symbol_IN("d"):
        saw_d = true
        if _DP_match_symbol_IN("%"):
            sides = "%"
        elif _DP_match_symbol_IN("F") or _DP_match_symbol_IN("f"):
            sides = "F"
        elif _DP_match_type_IN("NUMBER"):
            sides = _DP_previous_token_IN().value
    elif _DP_match_symbol_IN("F") or _DP_match_symbol_IN("f"):
        sides = "F"
    elif _DP_match_symbol_IN("%"):
        sides = "%"
    else:
        _DP_expect_symbol_IN("d")
    if saw_d and typeof(sides) == TYPE_INT and sides == 0:
        return {"error": "Dice group missing sides"}
    var mods: Array = []
    while true:
        if _DP_match_type_IN("KEEPDROP"):
            var kd = _DP_previous_token_IN().value
            var cnt = 1
            if _DP_match_type_IN("NUMBER"):
                cnt = _DP_previous_token_IN().value
            mods.append({"type": kd, "count": cnt})
            continue
        elif _DP_match_type_IN("ADV"):
            var adv = _DP_previous_token_IN().value
            var kd_mod = "kh"
            if adv == "dis":
                kd_mod = "kl"
            mods.append({"type": kd_mod, "count": 1})
            continue
        elif _DP_match_type_IN("REROLL"):
            var rtype = _DP_previous_token_IN().value
            var comp = ""
            var val = 0
            if _DP_match_type_IN("COMPARE"):
                comp = _DP_previous_token_IN().value
                if _DP_match_type_IN("NUMBER"):
                    val = _DP_previous_token_IN().value
            mods.append({"type": "reroll", "method": rtype, "compare": comp, "target": val})
            continue
        elif _DP_match_type_IN("EXPLODE"):
            var etype = _DP_previous_token_IN().value
            var comp_e = ""
            var val_e = 0
            if _DP_match_type_IN("COMPARE"):
                comp_e = _DP_previous_token_IN().value
                if _DP_match_type_IN("NUMBER"):
                    val_e = _DP_previous_token_IN().value
            mods.append({"type": "explode", "style": etype, "compare": comp_e, "target": val_e})
            continue
        elif _DP_match_type_IN("SUCCESS_TYPE"):
            var stype = _DP_previous_token_IN().value
            var comp_s = ""
            var val_s = 0
            if _DP_match_type_IN("COMPARE"):
                comp_s = _DP_previous_token_IN().value
                if _DP_match_type_IN("NUMBER"):
                    val_s = _DP_previous_token_IN().value
            mods.append({"type": stype, "compare": comp_s, "target": val_s})
            continue
        elif _DP_match_type_IN("COMPARE"):
            var comp_only = _DP_previous_token_IN().value
            var val_only = 0
            if _DP_match_type_IN("NUMBER"):
                val_only = _DP_previous_token_IN().value
            mods.append({"type": "success", "compare": comp_only, "target": val_only})
            continue
        elif _DP_match_type_IN("COUNT"):
            if _DP_match_type_IN("NUMBER"):
                mods.append({"type": "count", "target": _DP_previous_token_IN().value})
            continue
        else:
            break
    return {"type": "dice", "num": num, "sides": sides, "mods": mods}


func _DP_parse_function_IN(name: String) -> Dictionary:
    var args: Array = []
    if not _DP_match_symbol_IN(")"):
        args.append(_DP_parse_expr_IN())
        while _DP_match_symbol_IN(","):
            args.append(_DP_parse_expr_IN())
        _DP_expect_symbol_IN(")")
    return {"type": "func", "name": name, "args": args}


func _DP_check_dice_ahead_IN() -> bool:
    var idx = DP_index_IN
    if (
        idx < DP_token_list_IN.size()
        and DP_token_list_IN[idx].type == "NUMBER"
        and idx + 1 < DP_token_list_IN.size()
        and DP_token_list_IN[idx + 1].type == "SYMBOL"
        and DP_token_list_IN[idx + 1].value in ["d", "F", "f"]
    ):
        return true
    if (
        idx < DP_token_list_IN.size()
        and DP_token_list_IN[idx].type == "SYMBOL"
        and DP_token_list_IN[idx].value in ["d", "F", "f", "%"]
    ):
        return true
    return false


func _DP_peek_pipe_or_EOF_IN() -> bool:
    if DP_index_IN >= DP_token_list_IN.size():
        return true
    return DP_token_list_IN[DP_index_IN].type == "PIPE"


func _DP_parse_sum_IN(groups: Array, consts: Array, errs: Array) -> Dictionary:
    var items: Array = []
    var start_idx := DP_index_IN
    var ast = _DP_parse_expr_IN()
    if DP_index_IN == start_idx:
        errs.append({"msg": "Unexpected input"})
        return {"type": "number", "value": 0}
    items.append(ast)
    while _DP_match_symbol_IN(","):
        if DP_index_IN >= DP_token_list_IN.size():
            errs.append({"msg": "Unexpected input after '%s'" % _DP_previous_token_IN().value})
            break
        start_idx = DP_index_IN
        var nxt = _DP_parse_expr_IN()
        if DP_index_IN == start_idx:
            errs.append({"msg": "Unexpected input"})
            break
        items.append(nxt)
    for it in items:
        if it.has("error"):
            errs.append({"msg": it.error})
        else:
            _DP_collect_dice_IN(it, groups)
            _DP_collect_constants_IN(it, consts)
            if typeof(it) == TYPE_DICTIONARY and it.type == "number":
                groups.append({"type": "number", "value": it.value})
    var node = items[0]
    for i in range(1, items.size()):
        node = {"type": "binary", "op": "+", "left": node, "right": items[i]}
    return node


func _DP_previous_token_IN() -> Dictionary:
    return DP_token_list_IN[DP_index_IN - 1]


func _DP_match_symbol_IN(sym: String) -> bool:
    if (
        DP_index_IN < DP_token_list_IN.size()
        and DP_token_list_IN[DP_index_IN].type == "SYMBOL"
        and DP_token_list_IN[DP_index_IN].value == sym
    ):
        DP_index_IN += 1
        return true
    return false


func _DP_expect_symbol_IN(sym: String) -> void:
    if not _DP_match_symbol_IN(sym):
        push_error("Expected symbol: " + sym)


func _DP_match_type_IN(tp: String) -> bool:
    if DP_index_IN < DP_token_list_IN.size() and DP_token_list_IN[DP_index_IN].type == tp:
        DP_index_IN += 1
        return true
    return false
