extends SceneTree


func _init() -> void:
    var parser := DiceParser.new()
    var plan := parser.DP_parse_expression("4d6kh3+2")
    assert(plan.dice_groups.size() == 1)
    var g = plan.dice_groups[0]
    assert(g.num == 4 and g.sides == 6)
    assert(g.mods.size() == 1)
    assert(g.mods[0].type == "kh" and g.mods[0].count == 3)
    assert(plan.ast.type == "binary")
    assert(plan.constants.has(2))

    var plan2 := parser.DP_parse_expression("2d20adv")
    assert(plan2.dice_groups.size() == 1)
    var g2 = plan2.dice_groups[0]
    assert(g2.num == 2 and g2.sides == 20)
    assert(g2.mods.size() == 1)
    assert(g2.mods[0].type == "kh" and g2.mods[0].count == 1)

    var plan3 := parser.DP_parse_expression("1d%+5")
    assert(plan3.dice_groups.size() == 1)
    assert(plan3.dice_groups[0].sides == "%")
    assert(plan3.constants.has(5))

    var plan4 := parser.DP_parse_expression("4F-2")
    assert(plan4.dice_groups.size() == 1)
    assert(plan4.dice_groups[0].sides == "F")
    assert(plan4.constants.has(2))

    var plan5 := parser.DP_parse_expression("3d6+2*5")
    assert(plan5.dice_groups.size() == 1)
    assert(plan5.constants.size() == 2)
    assert(plan5.ast.right.op == "*")

    print("All DiceParser tests passed")
    quit()
