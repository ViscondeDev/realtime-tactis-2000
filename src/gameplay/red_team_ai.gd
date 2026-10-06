@icon("res://addons/at-icons/node2d/brain.svg")

class_name RedTeamAI
extends Node2D

const CONTROL_POINTS_GROUP: StringName = &"control_points"
const RESPAWN_POINTS_GROUP: StringName = &"respawn_points"
const ORDER_REFRESH_INTERVAL: float = 0.25
const TARGET_UPDATE_DISTANCE: float = 20.0
const OBJECTIVE_ARRIVAL_DISTANCE: float = 48.0

var _control_point: Node2D
var _red_spawn: Node2D
var _unit_states: Dictionary = {}
var _order_refresh_timer: float = 0.0
@onready var _respawn_controller: UnitRespawnController = %UnitRespawnController


func _ready() -> void:
	_control_point = _find_group_node(CONTROL_POINTS_GROUP)
	_red_spawn = _find_red_spawn()
	if is_instance_valid(_respawn_controller):
		_respawn_controller.unit_spawned.connect(_register_unit)
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		if is_instance_valid(node):
			_register_unit(node as Unit)
	if _control_point == null:
		push_error("RedTeamAI requires a control point in the '%s' group." % CONTROL_POINTS_GROUP)
	if _red_spawn == null:
		push_error("RedTeamAI requires a red respawn point in the '%s' group." % RESPAWN_POINTS_GROUP)


func _process(delta: float) -> void:
	_order_refresh_timer += delta
	if _order_refresh_timer < ORDER_REFRESH_INTERVAL:
		return
	_order_refresh_timer = 0.0
	for unit_id: int in _unit_states.keys():
		var unit_object: Object = instance_from_id(unit_id)
		if not is_instance_valid(unit_object):
			_unit_states.erase(unit_id)
			continue
		var unit: Unit = unit_object as Unit
		if unit == null:
			_unit_states.erase(unit_id)
			continue
		var state: Dictionary = _unit_states[unit_id]
		if _is_retreating(state):
			_issue_retreat_order(unit, state)


func _find_group_node(group_name: StringName) -> Node2D:
	for node: Node in get_tree().get_nodes_in_group(group_name):
		if not is_instance_valid(node):
			continue
		var node_2d: Node2D = node as Node2D
		if node_2d != null:
			return node_2d
	return null


func _find_red_spawn() -> Node2D:
	for node: Node in get_tree().get_nodes_in_group(RESPAWN_POINTS_GROUP):
		if not is_instance_valid(node):
			continue
		var spawn: Node2D = node as Node2D
		if spawn != null and int(spawn.get("team")) == Unit.Team.RED:
			return spawn
	return null


func _register_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or unit.team != Unit.Team.RED:
		return
	var unit_id: int = unit.get_instance_id()
	if _unit_states.has(unit_id):
		return
	_unit_states[unit_id] = {
		"outnumbered": false,
		"low_health": false,
		"order_mode": "",
		"follow_unit": null,
		"target_position": Vector2.INF,
	}
	unit.status_reported.connect(_on_unit_status_reported.bind(unit))
	unit.tree_exiting.connect(_on_unit_exiting.bind(unit_id))


func _on_unit_status_reported(report_type: StringName, active: bool, unit: Unit) -> void:
	if not is_instance_valid(unit):
		return
	var state: Dictionary = _unit_states.get(unit.get_instance_id(), {})
	if state.is_empty():
		return
	match report_type:
		&"outnumbered":
			state["outnumbered"] = active
		&"low_health":
			state["low_health"] = active
		&"idle_without_order":
			if active and not _is_retreating(state):
				_issue_objective_order(unit, state)
			return
	if _is_retreating(state):
		_issue_retreat_order(unit, state)
	else:
		_issue_objective_order(unit, state)


func _is_retreating(state: Dictionary) -> bool:
	return state.get("outnumbered", false) or state.get("low_health", false)


func _issue_objective_order(unit: Unit, state: Dictionary) -> void:
	if not is_instance_valid(_control_point):
		return
	var objective_position: Vector2 = _control_point.global_position
	if unit.global_position.distance_to(objective_position) <= OBJECTIVE_ARRIVAL_DISTANCE:
		state["order_mode"] = "objective"
		state["follow_unit"] = null
		state["target_position"] = objective_position
		return
	_issue_order_if_changed(unit, state, "objective", objective_position, null)


func _issue_retreat_order(unit: Unit, state: Dictionary) -> void:
	var ally: Unit = _find_nearest_living_ally(unit)
	if ally != null:
		_issue_order_if_changed(unit, state, "retreat_ally", ally.global_position, ally)
	elif is_instance_valid(_red_spawn):
		_issue_order_if_changed(unit, state, "retreat_spawn", _red_spawn.global_position, null)


func _find_nearest_living_ally(unit: Unit) -> Unit:
	var nearest_ally: Unit = null
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		if not is_instance_valid(node):
			continue
		var candidate: Unit = node as Unit
		if candidate == null or candidate == unit or candidate.team != Unit.Team.RED:
			continue
		if candidate.unit_health.current_health <= 0.0:
			continue
		var distance_squared: float = unit.global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_ally = candidate
	return nearest_ally


func _issue_order_if_changed(unit: Unit, state: Dictionary, mode: String, target: Vector2, follow_unit: Unit) -> void:
	var previous_follow: Variant = state.get("follow_unit")
	if not is_instance_valid(previous_follow):
		previous_follow = null
	var previous_position: Vector2 = state.get("target_position", Vector2.INF)
	if (
		state.get("order_mode", "") == mode
		and previous_follow == follow_unit
		and previous_position.distance_to(target) <= TARGET_UPDATE_DISTANCE
	):
		return
	state["order_mode"] = mode
	state["follow_unit"] = follow_unit
	state["target_position"] = target
	unit.issue_move_order(target)


func _on_unit_exiting(unit_id: int) -> void:
	_unit_states.erase(unit_id)
