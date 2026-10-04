class_name UnitCommandController
extends Node2D

const MINIMUM_DRAG_DISTANCE_PIXELS: float = 12.0
const DRAG_GOAL_RING_RADIUS: float = 10.0

var _dragged_unit: Unit = null


func _unhandled_input(event: InputEvent) -> void:
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
		return
	var ring_color: Color = _dragged_unit.definition.body_color
	ring_color.a = 0.5
	draw_arc(to_local(get_global_mouse_position()), DRAG_GOAL_RING_RADIUS, 0.0, TAU, 32, ring_color, 2.0)


func _finish_drag() -> void:
	if _dragged_unit == null:
		return

	var drop_position: Vector2 = get_global_mouse_position()
	var drag_distance: float = _dragged_unit.global_position.distance_to(drop_position)
	if drag_distance >= MINIMUM_DRAG_DISTANCE_PIXELS:
		_dragged_unit.issue_move_order(drop_position)

	_dragged_unit = null
	queue_redraw()


func _find_closest_unit_under_position(world_position: Vector2) -> Unit:
	var closest_unit: Unit = null
	var closest_distance: float = INF

	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or not unit.is_point_over_unit(world_position):
			continue
		var distance: float = unit.global_position.distance_to(world_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_unit = unit

	return closest_unit
