@icon("res://addons/at-icons/node2d/itinerary.svg")
class_name UnitPathRenderer
extends Node2D

@export var _unit: Unit
@export var dot_radius: float = 2.5
@export var dot_spacing: float = 15.0
@export var goal_marker_radius: float = 10.0
@export var goal_marker_line_width: float = 6
@export var path_opacity: float = 0.75

const DOTS_PER_SHAPE_TOOL: int = 64
const MAX_PATH_DOTS: int = DOTS_PER_SHAPE_TOOL * 3

var _was_drawing_last_frame: bool = false
var _goal_marker: ShapeDefinition
@onready var _shape_tool: ShapeTool = $GoalMarkerShapes
@onready var _path_dot_tools: Array[ShapeTool] = [
	$PathDotShapes1,
	$PathDotShapes2,
	$PathDotShapes3,
]
var _path_dot_definitions: Array[ShapeDefinition] = []



func _ready() -> void:
	# Detach from the unit's transform so path points can be drawn in world coordinates.
	top_level = true
	_goal_marker = ShapeDefinition.new()
	_goal_marker.shape = ShapeDefinition.Shape.CIRCLE
	_goal_marker.fill_enabled = false
	_shape_tool.definitions = [_goal_marker]
	_shape_tool.visible = false
	for path_dot_tool: ShapeTool in _path_dot_tools:
		path_dot_tool.visible = false


func _process(_delta: float) -> void:
	var should_draw_now: bool = _unit.unit_movement.has_active_move_order()
	# One extra redraw after the order ends, so the old line gets cleared.
	if should_draw_now or _was_drawing_last_frame:
		queue_redraw()
	_was_drawing_last_frame = should_draw_now


func _draw() -> void:
	if not _unit.unit_movement.has_active_move_order():
		_shape_tool.visible = false
		_hide_path_dot_tools()
		return

	var path_points: PackedVector2Array = _unit.unit_movement.get_remaining_move_order_path_points()
	if path_points.size() < 2:
		_shape_tool.visible = false
		_hide_path_dot_tools()
		return

	var path_color: Color = Color.html(Unit.TEAM_COLORS[_unit.team])
	path_color.a = path_opacity

	var goal_position: Vector2 = path_points[path_points.size() - 1]
	_goal_marker.offset = goal_position
	_goal_marker.radius = goal_marker_radius
	_goal_marker.outline_color = path_color
	_goal_marker.line_width = goal_marker_line_width
	_shape_tool.visible = true

	# Dots are laid out starting from the goal, so they stay fixed in the world
	# instead of shimmering as the unit moves.
	path_points.reverse()
	_draw_dotted_polyline(path_points, path_color)


func _draw_dotted_polyline(points: PackedVector2Array, color: Color) -> void:
	var distance_until_next_dot: float = 0.0
	var dot_positions: Array[Vector2] = []

	for segment_index: int in range(points.size() - 1):
		var segment_start: Vector2 = points[segment_index]
		var segment_end: Vector2 = points[segment_index + 1]
		var segment_length: float = segment_start.distance_to(segment_end)
		var segment_direction: Vector2 = segment_start.direction_to(segment_end)

		var distance_along_segment: float = distance_until_next_dot
		while distance_along_segment < segment_length:
			dot_positions.append(segment_start + segment_direction * distance_along_segment)
			distance_along_segment += dot_spacing

		# Carry the leftover spacing across corners so dot spacing stays even.
		distance_until_next_dot = distance_along_segment - segment_length
	_update_path_dot_tools(dot_positions, color)


func _update_path_dot_tools(dot_positions: Array[Vector2], color: Color) -> void:
	var drawable_dot_count: int = mini(dot_positions.size(), MAX_PATH_DOTS)
	if dot_positions.size() > MAX_PATH_DOTS:
		push_warning("UnitPathRenderer: path marker capped at %d dots." % MAX_PATH_DOTS)

	for tool_index: int in range(_path_dot_tools.size()):
		var path_dot_tool: ShapeTool = _path_dot_tools[tool_index]
		var first_dot_index: int = tool_index * DOTS_PER_SHAPE_TOOL
		if first_dot_index >= drawable_dot_count:
			path_dot_tool.visible = false
			continue

		var last_dot_index: int = mini(first_dot_index + DOTS_PER_SHAPE_TOOL, drawable_dot_count)
		var definitions: Array[ShapeDefinition] = []
		for dot_index: int in range(first_dot_index, last_dot_index):
			while _path_dot_definitions.size() <= dot_index:
				var dot_definition: ShapeDefinition = ShapeDefinition.new()
				dot_definition.shape = ShapeDefinition.Shape.DOT
				dot_definition.radius = dot_radius
				dot_definition.outline_enabled = false
				_path_dot_definitions.append(dot_definition)
			var definition: ShapeDefinition = _path_dot_definitions[dot_index]
			definition.radius = dot_radius
			definition.offset = dot_positions[dot_index]
			definition.fill_color = color
			definitions.append(definition)
		path_dot_tool.definitions = definitions
		path_dot_tool.visible = true


func _hide_path_dot_tools() -> void:
	for path_dot_tool: ShapeTool in _path_dot_tools:
		path_dot_tool.visible = false
