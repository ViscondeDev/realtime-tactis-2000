class_name LevelVisual
extends Node2D

var floor_polygons: Array[PackedVector2Array] = []
var obstacle_polygons: Array[PackedVector2Array] = []
var wall_polylines: Array[PackedVector2Array] = []

var floor_color: Color = Color.WHITE
var obstacle_color: Color = Color.BLACK
var wall_line_color: Color = Color.WHITE
var wall_line_width: float = 6.0


func _draw() -> void:
	for floor_polygon: PackedVector2Array in floor_polygons:
		_draw_filled_polygon(floor_polygon, floor_color)
	for obstacle_polygon: PackedVector2Array in obstacle_polygons:
		_draw_filled_polygon(obstacle_polygon, obstacle_color)
	for wall_polyline: PackedVector2Array in wall_polylines:
		draw_polyline(wall_polyline, wall_line_color, wall_line_width, true)


func _draw_filled_polygon(polygon: PackedVector2Array, color: Color) -> void:
	# Self-intersecting polygons cannot be triangulated; skip them instead of spamming errors.
	if Geometry2D.triangulate_polygon(polygon).is_empty():
		push_warning("LevelVisual: skipped a polygon that cannot be filled (self-intersecting?).")
		return
	draw_colored_polygon(polygon, color)