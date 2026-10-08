@icon("res://addons/at-icons/node2d/brain.svg")

class_name RedTeamAI
extends Node2D

@export_range(0.0, 10.0, 0.1, "or_greater") var issue_delay_seconds: float = 0.0

const CONTROL_POINTS_GROUP: StringName = &"control_points"
const RESPAWN_POINTS_GROUP: StringName = &"respawn_points"
const ORDER_REFRESH_INTERVAL: float = 0.25
const TARGET_UPDATE_DISTANCE: float = 20.0
const OBJECTIVE_ARRIVAL_DISTANCE: float = 48.0

var _control_point: ControlPoint
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
	if _order_refresh_timer >= ORDER_REFRESH_INTERVAL:
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
			if state.get("prepare_for_push", false):
				if unit.unit_health.current_health >= unit.unit_health.overheal_max_health:
					state["prepare_for_push"] = false
				elif _issue_preparation_order(unit, state):
					continue
				else:
					state["prepare_for_push"] = false
			if _is_retreating(state):
				_issue_retreat_order(unit, state)
			else:
				_issue_role_order(unit, state)
	_advance_pending_orders(delta)


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
		"prepare_for_push": false,
		"order_mode": "",
		"follow_unit": null,
		"target_position": Vector2.INF,
		"pending_order": {},
		"pending_order_elapsed": 0.0,
		"build_target": null,
	}
	unit.condition_changed.connect(_on_unit_condition_changed.bind(unit))
	unit.tree_exiting.connect(_on_unit_exiting.bind(unit_id))


func _on_unit_condition_changed(condition: StringName, active: bool, unit: Unit) -> void:
	if not is_instance_valid(unit):
		return
	var state: Dictionary = _unit_states.get(unit.get_instance_id(), {})
	if state.is_empty():
		return
	match condition:
		&"outnumbered":
			state["outnumbered"] = active
			if active and unit.unit_health.current_health < unit.unit_health.overheal_max_health:
				state["prepare_for_push"] = _find_nearest_health(unit, true) != null
		&"low_health":
			state["low_health"] = active
		&"idle_without_order":
			if active:
				if state.get("prepare_for_push", false):
					_issue_preparation_order(unit, state)
				elif not _is_retreating(state):
					_issue_role_order(unit, state)
			return
	if state.get("prepare_for_push", false) and _issue_preparation_order(unit, state):
		return
	if _is_retreating(state):
		_issue_retreat_order(unit, state)
	else:
		_issue_role_order(unit, state)


func _is_retreating(state: Dictionary) -> bool:
	return state.get("outnumbered", false) or state.get("low_health", false)


func _issue_preparation_order(unit: Unit, state: Dictionary) -> bool:
	var dispenser: HealthDispenser = _find_nearest_health(unit, true)
	if dispenser == null:
		return false
	_issue_order_if_changed(unit, state, "overheal", dispenser.global_position, null)
	return true


func _issue_objective_order(unit: Unit, state: Dictionary) -> void:
	if not is_instance_valid(_control_point):
		return
	var objective_position: Vector2 = _control_point.global_position
	if unit.global_position.distance_to(objective_position) <= OBJECTIVE_ARRIVAL_DISTANCE:
		if state.get("order_mode", "") != "objective":
			_issue_order_if_changed(unit, state, "objective", objective_position, null)
		return
	_issue_order_if_changed(unit, state, "objective", objective_position, null)


func _issue_role_order(unit: Unit, state: Dictionary) -> void:
	if unit.unit_class == Unit.Class.QUICK and _is_red_controlled():
		_issue_dispenser_raid_order(unit, state)
	elif unit.unit_class == Unit.Class.SMART:
		_issue_smart_build_order(unit, state)
	else:
		_issue_objective_order(unit, state)


func _issue_smart_build_order(unit: Unit, state: Dictionary) -> void:
	var active_build: HealthDispenser = _find_dispenser_being_built_by(unit)
	if active_build != null:
		_clear_pending_order(state)
		state["build_target"] = active_build
		state["order_mode"] = "build_wait"
		state["follow_unit"] = null
		state["target_position"] = active_build.global_position
		return

	var should_build_dispenser: bool = _is_red_controlled() or not _has_team_dispenser(Unit.Team.RED)
	if not should_build_dispenser:
		state["build_target"] = null
		_issue_objective_order(unit, state)
		return

	var target: HealthDispenser = state.get("build_target") as HealthDispenser
	if is_instance_valid(target) and not target.is_built:
		if target.is_building:
			_clear_pending_order(state)
			state["order_mode"] = "build_wait"
			state["follow_unit"] = null
			state["target_position"] = target.global_position
			return
		if (
			not unit.unit_movement.has_active_move_order()
			and unit.global_position.distance_to(target.global_position) <= UnitAutonomousBehavior.DISPENSER_BUILD_DISTANCE
			and unit.unit_autonomous_behavior.begin_dispenser_construction(target)
		):
			_clear_pending_order(state)
			state["order_mode"] = "build_wait"
			state["follow_unit"] = null
			state["target_position"] = target.global_position
			return
		_issue_order_if_changed(unit, state, "build_site", target.global_position, null)
		return

	state["build_target"] = null
	target = _find_nearest_available_build_site(unit)
	if target != null:
		state["build_target"] = target
		_issue_order_if_changed(unit, state, "build_site", target.global_position, null)
	else:
		_issue_objective_order(unit, state)


func _has_team_dispenser(team: Unit.Team) -> bool:
	for node: Node in get_tree().get_nodes_in_group(HealthDispenser.HEALTH_DISPENSER_GROUP):
		var dispenser: HealthDispenser = node as HealthDispenser
		if is_instance_valid(dispenser) and dispenser.team == team and (dispenser.is_built or dispenser.is_building):
			return true
	return false


func _find_dispenser_being_built_by(unit: Unit) -> HealthDispenser:
	for node: Node in get_tree().get_nodes_in_group(HealthDispenser.HEALTH_DISPENSER_GROUP):
		var candidate: HealthDispenser = node as HealthDispenser
		if is_instance_valid(candidate) and candidate.is_building and candidate.builder == unit:
			return candidate
	return null


func _find_nearest_available_build_site(unit: Unit) -> HealthDispenser:
	var nearest_site: HealthDispenser = null
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group(HealthDispenser.HEALTH_DISPENSER_GROUP):
		if not is_instance_valid(node):
			continue
		var candidate: HealthDispenser = node as HealthDispenser
		if candidate == null or candidate.is_built or candidate.is_building:
			continue
		var distance_squared: float = unit.global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_site = candidate
	return nearest_site


func _issue_dispenser_raid_order(unit: Unit, state: Dictionary) -> void:
	var target: HealthDispenser = _find_nearest_yellow_dispenser(unit)
	if target == null:
		_issue_objective_order(unit, state)
		return
	_issue_order_if_changed(unit, state, "dispenser_raid", target.global_position, null)


func _find_nearest_yellow_dispenser(unit: Unit) -> HealthDispenser:
	var nearest_dispenser: HealthDispenser = null
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group(HealthDispenser.HEALTH_DISPENSER_GROUP):
		if not is_instance_valid(node):
			continue
		var candidate: HealthDispenser = node as HealthDispenser
		if candidate == null or candidate.team != Unit.Team.YELLOW or not candidate.is_built:
			continue
		if candidate.current_health <= 0.0:
			continue
		var distance_squared: float = unit.global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_dispenser = candidate
	return nearest_dispenser


func _is_red_controlled() -> bool:
	return is_instance_valid(_control_point) and _control_point.capture_progress <= -1.0


func _issue_retreat_order(unit: Unit, state: Dictionary) -> void:
	var ally: Unit = _find_nearest_living_ally(unit)
	var health: HealthDispenser = _find_nearest_health(unit)
	if health != null:
		_issue_order_if_changed(unit, state, "retreat_health", health.global_position, null)
	elif ally != null:
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

func _find_nearest_health(unit: Unit, overheal_only: bool = false) -> HealthDispenser:
	var nearest_health: HealthDispenser = null
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group(HealthDispenser.HEALTH_DISPENSER_GROUP):
		if not is_instance_valid(node):
			continue
		var candidate: HealthDispenser = node as HealthDispenser
		if candidate == null or candidate.team != Unit.Team.RED or not candidate.is_built:
			continue
		if overheal_only and (not candidate.overheal_enabled or candidate.healing_per_second <= 0.0):
			continue
		if candidate.current_health <= 0.0:
			continue
		var distance_squared: float = unit.global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_health = candidate
	return nearest_health


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
		_clear_pending_order(state)
		return
	var pending_order: Dictionary = state.get("pending_order", {})
	if issue_delay_seconds > 0.0:
		if not pending_order.is_empty() and pending_order["mode"] == mode and pending_order["follow_unit"] == follow_unit:
			pending_order["target_position"] = target
			return
		state["pending_order"] = {
			"mode": mode,
			"follow_unit": follow_unit,
			"target_position": target,
		}
		state["pending_order_elapsed"] = 0.0
		return
	_clear_pending_order(state)
	_issue_move_order(unit, state, mode, target, follow_unit)


func _advance_pending_orders(delta: float) -> void:
	for unit_id: int in _unit_states.keys():
		var state: Dictionary = _unit_states[unit_id]
		var pending_order: Dictionary = state.get("pending_order", {})
		if pending_order.is_empty():
			continue
		var unit_object: Object = instance_from_id(unit_id)
		if not is_instance_valid(unit_object):
			_unit_states.erase(unit_id)
			continue
		var unit: Unit = unit_object as Unit
		if unit == null:
			_unit_states.erase(unit_id)
			continue
		var elapsed: float = state.get("pending_order_elapsed", 0.0) + delta
		state["pending_order_elapsed"] = elapsed
		if elapsed < issue_delay_seconds:
			continue
		_issue_move_order(
			unit,
			state,
			pending_order["mode"],
			pending_order["target_position"],
			pending_order["follow_unit"]
		)
		_clear_pending_order(state)


func _issue_move_order(unit: Unit, state: Dictionary, mode: String, target: Vector2, follow_unit: Unit) -> void:
	state["order_mode"] = mode
	state["follow_unit"] = follow_unit
	state["target_position"] = target
	unit.issue_move_order(target)


func _clear_pending_order(state: Dictionary) -> void:
	state["pending_order"] = {}
	state["pending_order_elapsed"] = 0.0


func _on_unit_exiting(unit_id: int) -> void:
	_unit_states.erase(unit_id)
