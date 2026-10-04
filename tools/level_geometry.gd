class_name LevelGeometry
extends RefCounted

# Returns the wall lines of the level: the boundary of
#   (union of all floors) minus (union of all obstacles)
# as open polylines. Interior edges where two floors overlap are removed,
# which is what turns overlapping rooms and corridors into one connected space.
static func compute_wall_polylines(
	floor_polygons: Array[PackedVector2Array],
	obstacle_polygons: Array[PackedVector2Array]
) -> Array[PackedVector2Array]:
	var wall_polylines: Array[PackedVector2Array] = []

	# Floor boundaries: each floor outline, minus every other floor and every obstacle.
	for floor_index: int in range(floor_polygons.size()):
		var remaining_pieces: Array[PackedVector2Array] = [_close_polygon_into_polyline(floor_polygons[floor_index])]
		for other_floor_index: int in range(floor_polygons.size()):
			if other_floor_index != floor_index:
				remaining_pieces = _subtract_polygon_from_polylines(remaining_pieces, floor_polygons[other_floor_index])
		for obstacle_polygon: PackedVector2Array in obstacle_polygons:
			remaining_pieces = _subtract_polygon_from_polylines(remaining_pieces, obstacle_polygon)
		wall_polylines.append_array(remaining_pieces)

	# Obstacle boundaries: the part of each obstacle outline lying on a floor, minus other obstacles.
	for obstacle_index: int in range(obstacle_polygons.size()):
		var obstacle_outline: PackedVector2Array = _close_polygon_into_polyline(obstacle_polygons[obstacle_index])
		var pieces_on_floor: Array[PackedVector2Array] = []
		for floor_polygon: PackedVector2Array in floor_polygons:
			pieces_on_floor.append_array(Geometry2D.intersect_polyline_with_polygon(obstacle_outline, floor_polygon))
		for other_obstacle_index: int in range(obstacle_polygons.size()):
			if other_obstacle_index != obstacle_index:
				pieces_on_floor = _subtract_polygon_from_polylines(pieces_on_floor, obstacle_polygons[other_obstacle_index])
		wall_polylines.append_array(pieces_on_floor)

	return wall_polylines


static func _close_polygon_into_polyline(polygon: PackedVector2Array) -> PackedVector2Array:
	var closed_polyline: PackedVector2Array = PackedVector2Array(polygon)
	closed_polyline.append(polygon[0])
	return closed_polyline


static func _subtract_polygon_from_polylines(
	polylines: Array[PackedVector2Array],
	polygon_to_subtract: PackedVector2Array
) -> Array[PackedVector2Array]:
	var remaining_polylines: Array[PackedVector2Array] = []
	for polyline: PackedVector2Array in polylines:
		remaining_polylines.append_array(Geometry2D.clip_polyline_with_polygon(polyline, polygon_to_subtract))
	return remaining_polylines