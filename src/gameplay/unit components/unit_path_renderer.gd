@icon("res://addons/at-icons/node2d/itinerary.svg")
class_name UnitPathRenderer
extends Node2D

@export var _unit: Unit
@export var dot_radius: float = 2.5
@export var dot_spacing: float = 12.0
@export var goal_marker_radius: float = 10.0
@export var goal_marker_line_width: float = 2.5
@export var path_opacity: float = 0.75

var _was_drawing_last_frame: bool = false



func _ready() -> void:
	# Detach from the unit's transform so path points can be drawn in world coordinates.
	top_level = true


func _process(_delta: float) -> void:
	var should_draw_now: bool = _unit.unit_movement.has_active_move_order()
	# One extra redraw after the order ends, so the old line gets cleared.
	if should_draw_now or _was_drawing_last_frame:
		queue_redraw()
	_was_drawing_last_frame = should_draw_now


func _draw() -> void:
	if not _unit.unit_movement.has_active_move_order():
		return

	var path_points: PackedVector2Array = _unit.unit_movement.get_remaining_path_points()
	if path_points.size() < 2:
		return

	var path_color: Color = Color.html(Unit.TEAM_COLORS[_unit.team])
	path_color.a = path_opacity

	var goal_position: Vector2 = path_points[path_points.size() - 1]
	draw_arc(goal_position, goal_marker_radius, 0.0, TAU, 32, path_color, goal_marker_line_width)

	# Dots are laid out starting from the goal, so they stay fixed in the world
	# instead of shimmering as the unit moves.
	path_points.reverse()
	_draw_dotted_polyline(path_points, path_color)


func _draw_dotted_polyline(points: PackedVector2Array, color: Color) -> void:
	var distance_until_next_dot: float = 0.0

	for segment_index: int in range(points.size() - 1):
		var segment_start: Vector2 = points[segment_index]
		var segment_end: Vector2 = points[segment_index + 1]
		var segment_length: float = segment_start.distance_to(segment_end)
		var segment_direction: Vector2 = segment_start.direction_to(segment_end)

		var distance_along_segment: float = distance_until_next_dot
		while distance_along_segment < segment_length:
			draw_circle(segment_start + segment_direction * distance_along_segment, dot_radius, color)
			distance_along_segment += dot_spacing

		# Carry the leftover spacing across corners so dot spacing stays even.
		distance_until_next_dot = distance_along_segment - segment_length
