@icon("res://addons/at-icons/node2d/motion_vector.svg")
class_name UnitMovement
extends Node

signal move_order_completed

const PATH_DESIRED_DISTANCE_PIXELS: float = 8.0
const TARGET_DESIRED_DISTANCE_PIXELS: float = 8.0
const AUTONOMOUS_TARGET_UPDATE_DISTANCE_PIXELS: float = 16.0

@export var _unit_body: CharacterBody2D

var movement_speed: float
var _has_active_move_order: bool = false
var _has_autonomous_move_target: bool = false
var _autonomous_target_position: Vector2

@onready var _navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _move_order_navigation_agent: NavigationAgent2D = $MoveOrderNavigationAgent2D


func _ready() -> void:
	_navigation_agent.path_desired_distance = PATH_DESIRED_DISTANCE_PIXELS
	_navigation_agent.target_desired_distance = TARGET_DESIRED_DISTANCE_PIXELS
	_move_order_navigation_agent.path_desired_distance = PATH_DESIRED_DISTANCE_PIXELS
	_move_order_navigation_agent.target_desired_distance = TARGET_DESIRED_DISTANCE_PIXELS


func move_to(target_position: Vector2) -> void:
	_move_order_navigation_agent.target_position = target_position
	_has_active_move_order = true
	if not _has_autonomous_move_target:
		_navigation_agent.target_position = target_position


func set_autonomous_move_target(target_position: Vector2) -> void:
	if _has_autonomous_move_target and _autonomous_target_position.distance_to(target_position) <= AUTONOMOUS_TARGET_UPDATE_DISTANCE_PIXELS:
		return
	_has_autonomous_move_target = true
	_autonomous_target_position = target_position
	_navigation_agent.target_position = target_position


func clear_autonomous_move_target() -> void:
	if not _has_autonomous_move_target:
		return
	_has_autonomous_move_target = false
	if _has_active_move_order:
		_navigation_agent.target_position = _move_order_navigation_agent.target_position
	else:
		_stop_unit_body()


func is_autonomous_move_finished() -> bool:
	return not _has_autonomous_move_target or _navigation_agent.is_navigation_finished()


func has_active_move_order() -> bool:
	return _has_active_move_order


# Starts at the unit's current position, followed by the waypoints it has not reached yet.
func get_remaining_move_order_path_points() -> PackedVector2Array:
	var full_path: PackedVector2Array = _move_order_navigation_agent.get_current_navigation_path()
	var next_waypoint_index: int = _move_order_navigation_agent.get_current_navigation_path_index()

	var remaining_path_points: PackedVector2Array = PackedVector2Array([_unit_body.global_position])
	remaining_path_points.append_array(full_path.slice(next_waypoint_index))
	return remaining_path_points


func _physics_process(_delta: float) -> void:
	if _has_active_move_order:
		_move_order_navigation_agent.get_next_path_position()

	if not _has_active_move_order and not _has_autonomous_move_target:
		return

	if _navigation_agent.is_navigation_finished():
		_stop_unit_body()
		if _has_active_move_order and not _has_autonomous_move_target:
			_has_active_move_order = false
			move_order_completed.emit()
		return

	var next_waypoint_position: Vector2 = _navigation_agent.get_next_path_position()
	var direction_to_waypoint: Vector2 = _unit_body.global_position.direction_to(next_waypoint_position)
	_unit_body.velocity = direction_to_waypoint * movement_speed
	_unit_body.move_and_slide()


func _stop_unit_body() -> void:
	_unit_body.velocity = Vector2.ZERO
	_unit_body.move_and_slide()
