###############################################################
# scripts/boids/SpatialHash2D.gd
# Key funcs/classes: \u2022 SpatialHash2D – uniform grid for neighbors
# Critical consts    \u2022 NONE
###############################################################

class_name SpatialHash2D
extends Node

var cell_size: float
var _grid: Dictionary = {}
var _cells: Dictionary = {}
var _positions: Dictionary = {}


func _init(p_cell_size: float = 32.0) -> void:
    cell_size = p_cell_size


func _hash(pos: Vector2) -> Vector2:
    return Vector2(floor(pos.x / cell_size), floor(pos.y / cell_size))


func update(id, pos: Vector2) -> void:
    var cell := _hash(pos)
    var prev = _cells.get(id)
    if prev != null and _grid.has(prev):
        _grid[prev].erase(id)
        if _grid[prev].is_empty():
            _grid.erase(prev)
    _cells[id] = cell
    _positions[id] = pos
    if not _grid.has(cell):
        _grid[cell] = {}
    _grid[cell][id] = pos


func query_range(pos: Vector2, radius: float) -> Array:
    var results: Array = []
    var min_cell := _hash(pos - Vector2(radius, radius))
    var max_cell := _hash(pos + Vector2(radius, radius))
    for x in range(min_cell.x, max_cell.x + 1):
        for y in range(min_cell.y, max_cell.y + 1):
            var cell := Vector2(x, y)
            if _grid.has(cell):
                for id in _grid[cell].keys():
                    var p = _grid[cell][id] as Vector2
                    if p.distance_to(pos) <= radius:
                        results.append(id)
    return results


func clear() -> void:
    _grid.clear()
    _cells.clear()
    _positions.clear()
