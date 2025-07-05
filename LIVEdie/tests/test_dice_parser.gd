# gdlint:disable = function-name,class-variable-name
extends SceneTree
var _failed := false


func _initialize():
    var parser = DiceParser.new()
    _check(parser.evaluate("2d6+1", 1).total == 6, "basic add")
    _check(parser.evaluate("1d6!", 5).total == 8, "explode")
    _check(parser.evaluate("4d6kh3", 1).total == 11, "keep highest")
    _check(parser.evaluate("4d6>=5", 2).successes == 1, "success count")
    _check(parser.evaluate("2d6ro1", 9).total == 8, "reroll once")
    var sorted = parser.evaluate("3d6sd", 4).rolls
    _check(sorted == [4, 4, 1], "sorting desc")
    _check(parser.evaluate("2d6*2", 1).total == 10, "multiply")
    if _failed:
        printerr("Tests failed")
        quit(1)
        return
    print("All tests passed")
    quit()


func _check(cond: bool, label: String):
    if not cond:
        _failed = true
        printerr("FAIL: ", label)
