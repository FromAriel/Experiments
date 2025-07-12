extends SceneTree


func _init() -> void:
    var ht: HistoryTab = preload("res://scripts/HistoryTab.gd").new()
    root.add_child(ht)
    var dummy := {"notation": "3d6", "rolls": [4, 2, 6], "total": 12}
    ht._on_roll_executed(dummy)
    assert(ht.get_child_count() == 1)
    var entry = ht.get_child(0)
    var text = entry.get_node("BG/Main/Header/SummaryLabel").text
    assert(text == "3d6 \u2192 4 + 2 + 6 = 12")
    print("History join test passed")
    quit()
