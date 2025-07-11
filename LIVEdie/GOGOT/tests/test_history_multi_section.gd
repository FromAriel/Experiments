extends SceneTree


func _init() -> void:
    var ht: HistoryTab = preload("res://scripts/HistoryTab.gd").new()
    root.add_child(ht)
    var dummy = {
        "notation": "2d6>=5 | 1d20cs>=20",
        "sections":
        [
            {"rolls": [5, 6], "value": 2, "meta": {"succ": 2, "crit": 0, "fail": 0}},
            {"rolls": [20], "value": 1, "meta": {"succ": 1, "crit": 1, "fail": 0}}
        ]
    }
    ht._on_roll_executed(dummy)
    assert(ht.get_child_count() == 1)
    var text = ht.get_child(0).text
    var parts = text.split(" → ")[1].split(" | ")
    assert(parts.size() == 2)
    assert(parts[0].find("success") != -1)
    assert(parts[1].find("crit") != -1)
    print("History multi-section test passed")
    quit()
