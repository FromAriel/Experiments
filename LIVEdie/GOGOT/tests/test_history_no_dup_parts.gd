extends SceneTree


func _init() -> void:
    var ht: HistoryTab = preload("res://scripts/HistoryTab.gd").new()
    root.add_child(ht)
    var dummy = {"notation": "1d4 | 1d6", "rolls": [3, 5], "total": 8}
    ht._on_roll_executed(dummy)
    var text = ht.get_child(0).get_node("BG/Main/Header/SummaryLabel").text
    assert(text == "1d4 | 1d6 \u2192 3 + 5 = 8")
    print("History no dup parts test passed")
    quit()
