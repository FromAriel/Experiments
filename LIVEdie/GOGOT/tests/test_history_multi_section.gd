extends SceneTree


func _init() -> void:
    var ht: HistoryTab = preload("res://scripts/HistoryTab.gd").new()
    root.add_child(ht)
    var dummy = {
        "notation": "2d6>=5 | 1d20cs>=20",
        "rolls": [5, 6, 20],
        "total": 3,
        "meta": {"succ": 3, "crit": 1, "fail": 0}
    }
    ht._on_roll_executed(dummy)
    assert(ht.get_child_count() == 1)
    var entry = ht.get_child(0)
    var meta_text = entry.get_node("BG/Main/Expanded/MetaLabel").text
    assert(meta_text == "Succ: 3 | Crit: 1 | Fail: 0")
    print("History multi-section test passed")
    quit()
