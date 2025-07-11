extends SceneTree


func _init() -> void:
    var ht: HistoryTab = preload("res://scripts/HistoryTab.gd").new()
    root.add_child(ht)
    var dummy = {
        "notation": "1d4 | 1d6",
        "sections": [{"rolls": [3], "value": 3}, {"rolls": [5], "value": 5}]
    }
    ht._on_roll_executed(dummy)
    var parts = ht.get_child(0).text.split(" → ")[1].split(" | ")
    assert(parts.size() == 2)
    print("History no dup parts test passed")
    quit()
