class_name UnitMovement
extends Node

signal move_order_completed

const PATH_DESIRED_DISTANCE_PIXELS: float = 8.0
const TARGET_DESIRED_DISTANCE_PIXELS: float = 8.0

var movement_speed: float = 150.0

var _has_active_move_order: bool = false

@onready var _unit_body: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _navigation_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	_navigation_agent.path_desired_distance = PATH_DESIRED_DISTANCE_PIXELS
	_navigation_agent.target_desired_distance = TARGET_DESIRED_DISTANCE_PIXELS


func move_to(target_position: Vector2) -> void:
	_navigation_agent.target_position = target_position
	_has_active_move_order = true


func has_active_move_order() -> bool:
	return _has_active_move_order


# Starts at the unit's current position, followed by the waypoints it has not reached yet.
func get_remaining_path_points() -> PackedVector2Array:
	var full_path: PackedVector2Array = _navigation_agent.get_current_navigation_path()
	var next_waypoint_index: int = _navigation_agent.get_current_navigation_path_index()

	var remaining_path_points: PackedVector2Array = PackedVector2Array([_unit_body.global_position])
	remaining_path_points.append_array(full_path.slice(next_waypoint_index))
	return remaining_path_points


func _physics_process(_delta: float) -> void:
	if not _has_active_move_order:
		return

	if _navigation_agent.is_navigation_finished():
		_has_active_move_order = false
		_unit_body.velocity = Vector2.ZERO
		move_order_completed.emit()
		return

	var next_waypoint_position: Vector2 = _navigation_agent.get_next_path_position()
	var direction_to_waypoint: Vector2 = _unit_body.global_position.direction_to(next_waypoint_position)
	_unit_body.velocity = direction_to_waypoint * movement_speed
	_unit_body.move_and_slide()