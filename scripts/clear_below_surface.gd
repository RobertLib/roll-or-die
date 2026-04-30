@tool
extends EditorScript

## Removes tiles that were added by fill_below_surface.gd.
## Requires fill_below_surface.gd to have been run first (it stores fill data in GridMap metadata).


func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("No scene is open!")
		return

	var grid_map := _find_grid_map(root)
	if grid_map == null:
		push_error("No GridMap node found in the scene!")
		return

	if not grid_map.has_meta("fill_surface_min_y") or not grid_map.has_meta("fill_depth"):
		push_error("No fill data found on GridMap. Run fill_below_surface.gd first!")
		return

	var column_min_y: Dictionary = grid_map.get_meta("fill_surface_min_y")
	var fill_depth: int = grid_map.get_meta("fill_depth")

	print("Clearing %d fill columns (%d layers each)..." % [column_min_y.size(), fill_depth])

	var remove_count := 0
	for key: Vector2i in column_min_y:
		var min_y: int = column_min_y[key]
		for dy in range(1, fill_depth + 1):
			var fill_pos := Vector3i(key.x, min_y - dy, key.y)
			if grid_map.get_cell_item(fill_pos) != GridMap.INVALID_CELL_ITEM:
				grid_map.set_cell_item(fill_pos, GridMap.INVALID_CELL_ITEM)
				remove_count += 1

	grid_map.remove_meta("fill_surface_min_y")
	grid_map.remove_meta("fill_depth")

	print("Done! Removed %d fill tiles." % remove_count)


func _find_grid_map(node: Node) -> GridMap:
	if node is GridMap:
		return node
	for child in node.get_children():
		var result := _find_grid_map(child)
		if result != null:
			return result
	return null
