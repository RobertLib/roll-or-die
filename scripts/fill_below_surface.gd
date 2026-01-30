@tool
extends EditorScript

## Number of layers to fill below the surface.
const FILL_DEPTH := 50

## Tile item ID to use for fill (0 = first tile in the library).
const FILL_ITEM := 0

## Orientation of the fill tile.
const FILL_ORIENTATION := 0


func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("No scene is open!")
		return

	var grid_map := _find_grid_map(root)
	if grid_map == null:
		push_error("No GridMap node found in the scene!")
		return

	print("Found GridMap: %s" % grid_map.name)

	# For each (X, Z) column find the lowest existing tile Y.
	var column_min_y: Dictionary = {} # Vector2i(x, z) -> int (lowest Y per column)

	for cell: Vector3i in grid_map.get_used_cells():
		var key := Vector2i(cell.x, cell.z)
		if key not in column_min_y:
			column_min_y[key] = cell.y
		else:
			column_min_y[key] = min(column_min_y[key], cell.y)

	print("Columns to fill: %d" % column_min_y.size())

	# Fill FILL_DEPTH layers below each column.
	var fill_count := 0
	for key: Vector2i in column_min_y:
		var min_y: int = column_min_y[key]
		for dy in range(1, FILL_DEPTH + 1):
			var fill_pos := Vector3i(key.x, min_y - dy, key.y)
			# Skip cells that already have a tile.
			if grid_map.get_cell_item(fill_pos) == GridMap.INVALID_CELL_ITEM:
				grid_map.set_cell_item(fill_pos, FILL_ITEM, FILL_ORIENTATION)
				fill_count += 1

	print("Done! Added %d tiles across %d layers below the surface." % [fill_count, FILL_DEPTH])


func _find_grid_map(node: Node) -> GridMap:
	if node is GridMap:
		return node
	for child in node.get_children():
		var result := _find_grid_map(child)
		if result != null:
			return result
	return null
