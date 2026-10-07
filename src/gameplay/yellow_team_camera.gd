extends Camera2D

const MIN_ZOOM: float = 0.25
const MAX_ZOOM: float = 2.5
const WHEEL_ZOOM_FACTOR: float = 1.1
const PAN_INERTIA_MULTIPLIER: float = 0.35
const PAN_INERTIA_FRICTION: float = 9.0
const PAN_INERTIA_STOP_SPEED: float = 8.0

var _is_mouse_panning: bool = false
var _pan_velocity: Vector2 = Vector2.ZERO
var _touch_positions: Dictionary = {}


func _ready() -> void:
	make_current()
	position_smoothing_enabled = false


func _process(delta: float) -> void:
	if _is_mouse_panning or _pan_velocity.length() <= PAN_INERTIA_STOP_SPEED:
		_pan_velocity = Vector2.ZERO if not _is_mouse_panning else _pan_velocity
		return
	global_position += _pan_velocity * delta
	_pan_velocity *= exp(-PAN_INERTIA_FRICTION * delta)


func _unhandled_input(event: InputEvent) -> void:
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null:
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			_is_mouse_panning = mouse_button_event.pressed
			if _is_mouse_panning:
				_pan_velocity = Vector2.ZERO
			get_viewport().set_input_as_handled()
		elif mouse_button_event.pressed and mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_screen_position(WHEEL_ZOOM_FACTOR, mouse_button_event.position)
			get_viewport().set_input_as_handled()
		elif mouse_button_event.pressed and mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_screen_position(1.0 / WHEEL_ZOOM_FACTOR, mouse_button_event.position)
			get_viewport().set_input_as_handled()
		return

	var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion_event != null and _is_mouse_panning:
		_pan_by_screen_delta(mouse_motion_event.relative)
		_pan_velocity = -mouse_motion_event.velocity / zoom * PAN_INERTIA_MULTIPLIER
		get_viewport().set_input_as_handled()
		return

	var screen_touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if screen_touch_event != null:
		if screen_touch_event.pressed:
			_touch_positions[screen_touch_event.index] = screen_touch_event.position
		else:
			_touch_positions.erase(screen_touch_event.index)
		get_viewport().set_input_as_handled()
		return

	var screen_drag_event: InputEventScreenDrag = event as InputEventScreenDrag
	if screen_drag_event != null and _touch_positions.has(screen_drag_event.index):
		_handle_touch_drag(screen_drag_event.index, screen_drag_event.position)
		get_viewport().set_input_as_handled()


func _pan_by_screen_delta(screen_delta: Vector2) -> void:
	global_position -= screen_delta / zoom


func _zoom_at_screen_position(factor: float, screen_position: Vector2) -> void:
	var world_position_before_zoom: Vector2 = get_canvas_transform().affine_inverse() * screen_position
	var next_zoom: float = clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2.ONE * next_zoom
	var world_position_after_zoom: Vector2 = get_canvas_transform().affine_inverse() * screen_position
	global_position += world_position_before_zoom - world_position_after_zoom


func _handle_touch_drag(touch_index: int, next_position: Vector2) -> void:
	var touch_indices: Array = _touch_positions.keys()
	if touch_indices.size() != 2:
		_touch_positions[touch_index] = next_position
		return

	var first_index: int = touch_indices[0]
	var second_index: int = touch_indices[1]
	var previous_first: Vector2 = _touch_positions[first_index]
	var previous_second: Vector2 = _touch_positions[second_index]
	var next_first: Vector2 = next_position if touch_index == first_index else previous_first
	var next_second: Vector2 = next_position if touch_index == second_index else previous_second
	var previous_center: Vector2 = (previous_first + previous_second) * 0.5
	var next_center: Vector2 = (next_first + next_second) * 0.5
	var previous_distance: float = previous_first.distance_to(previous_second)
	var next_distance: float = next_first.distance_to(next_second)

	_touch_positions[touch_index] = next_position
	_pan_by_screen_delta(next_center - previous_center)
	if previous_distance > 0.0 and next_distance > 0.0:
		_zoom_at_screen_position(next_distance / previous_distance, next_center)