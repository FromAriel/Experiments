extends SceneTree


func _init() -> void:
    var ht: HistoryTab = preload("res://scripts/HistoryTab.gd").new()
    root.add_child(ht)
    var dummy := {"notation": "3d6", "sections": [{"rolls": [4, 2, 6], "value": 12}]}
    ht._on_roll_executed(dummy)
    assert(ht.get_child_count() == 1)
    assert(ht.get_child(0).text.ends_with("4 + 2 + 6"))
    print("History join test passed")
    quit()
