@icon("res://addons/at-icons/node2d/push_button.svg")
class_name UnitCommandController
extends Node2D

const MINIMUM_DRAG_DISTANCE_PIXELS: float = 12.0
const DRAG_GOAL_RING_RADIUS: float = 10.0

var _dragged_unit: Unit = null
var _drag_goal_ring: ShapeDefinition
@onready var _shape_tool: ShapeTool = $ShapeTool


func _ready() -> void:
	_drag_goal_ring = ShapeDefinition.new()
	_drag_goal_ring.shape = ShapeDefinition.Shape.CIRCLE
	_drag_goal_ring.radius = DRAG_GOAL_RING_RADIUS
	_drag_goal_ring.fill_enabled = false
	_drag_goal_ring.line_width = 2.0
	_shape_tool.definitions = [_drag_goal_ring]
	_shape_tool.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var match_controller: MatchController = get_tree().get_first_node_in_group(&"match_controllers") as MatchController
	if is_instance_valid(match_controller) and match_controller.phase == MatchController.Phase.FINISHED:
		_dragged_unit = null
		queue_redraw()
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null or mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if mouse_button_event.pressed:
		_dragged_unit = _find_closest_unit_under_position(get_global_mouse_position())
	else:
		_finish_drag()


func _process(_delta: float) -> void:
	if _dragged_unit != null:
		queue_redraw()


func _draw() -> void:
	if _dragged_unit == null:
		_shape_tool.visible = false
		return
	var ring_color: Color = Color.html(Unit.TEAM_COLORS[_dragged_unit.team])
	ring_color.a = 0.5
	_drag_goal_ring.offset = to_local(get_global_mouse_position())
	_drag_goal_ring.outline_color = ring_color
	_shape_tool.visible = true


func _finish_drag() -> void:
	if _dragged_unit == null:
		return

	var drop_position: Vector2 = get_global_mouse_position()
	var drag_distance: float = _dragged_unit.global_position.distance_to(drop_position)
	if drag_distance >= MINIMUM_DRAG_DISTANCE_PIXELS:
		var match_controller: MatchController = get_tree().get_first_node_in_group(&"match_controllers") as MatchController
		if is_instance_valid(match_controller):
			match_controller.queue_player_order(_dragged_unit, drop_position)
		else:
			_dragged_unit.issue_move_order(drop_position)

	_dragged_unit = null
	queue_redraw()


func _find_closest_unit_under_position(world_position: Vector2) -> Unit:
	var closest_unit: Unit = null
	var closest_distance: float = INF

	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or unit.team != Unit.Team.YELLOW or not unit.is_point_over_unit(world_position):
			continue
		var distance: float = unit.global_position.distance_to(world_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_unit = unit

	return closest_unit
