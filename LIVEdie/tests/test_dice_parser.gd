#
# LIVEdie/tests/test_dice_parser.gd
# Test suite for DiceParser
###############################################################
extends SceneTree


func _initialize() -> void:
    var parser = DiceParser.new()
    var res = parser.evaluate("2d6")
    assert(res["total"] >= 2 and res["total"] <= 12)

    res = parser.evaluate("4d6kh3")
    assert(res["total"] >= 3 and res["total"] <= 18)

    res = parser.evaluate("1d4!!")
    assert(res["total"] >= 1)

    res = parser.evaluate("3d6>=4")
    assert(res.has("success"))

    res = parser.evaluate("2d6ro1", 9)
    assert(res["total"] == 8)

    print("All dice parser tests passed")
    quit()
