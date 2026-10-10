class_name MatchController
extends Node

signal match_started
signal match_finished(winning_team: int)
signal control_point_captured(team: Unit.Team)

const CONTROL_POINTS_GROUP: StringName = &"control_points"
const MATCH_DURATION_SECONDS: float = 120.0
const COUNTDOWN_DURATION_SECONDS: float = 5.0
const RESULT_DISPLAY_SECONDS: float = 10.0

enum Phase {COUNTDOWN, ACTIVE, FINISHED}

var yellow_control_time_remaining: float = MATCH_DURATION_SECONDS
var red_control_time_remaining: float = MATCH_DURATION_SECONDS
var winner_team: int = -1
var phase: Phase = Phase.COUNTDOWN
var countdown_seconds_remaining: float = COUNTDOWN_DURATION_SECONDS
var result_seconds_remaining: float = 0.0

var _control_point: ControlPoint
var _controlling_team: Unit.Team = -1:
	set(value):
		if value != _controlling_team:
			_controlling_team = value
			control_point_captured.emit(value)

var _pending_player_orders: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"match_controllers")
	for node: Node in get_tree().get_nodes_in_group(CONTROL_POINTS_GROUP):
		_control_point = node as ControlPoint
		if _control_point != null:
			control_point_captured.connect(_control_point.takeover)
			break
	if _control_point == null:
		push_error("MatchController requires a control point in the '%s' group." % CONTROL_POINTS_GROUP)


func _process(delta: float) -> void:
	if phase == Phase.COUNTDOWN:
		countdown_seconds_remaining = maxf(countdown_seconds_remaining - delta, 0.0)
		if countdown_seconds_remaining <= 0.0:
			_start_match()
		return
	if phase == Phase.FINISHED:
		result_seconds_remaining = maxf(result_seconds_remaining - delta, 0.0)
		return
	if phase != Phase.ACTIVE or not is_instance_valid(_control_point):
		return

	if _control_point.capture_progress >= 1.0:
		_controlling_team = Unit.Team.YELLOW
	elif _control_point.capture_progress <= -1.0:
		_controlling_team = Unit.Team.RED

	if _controlling_team == Unit.Team.YELLOW:
		yellow_control_time_remaining = maxf(yellow_control_time_remaining - delta, 0.0)
		if yellow_control_time_remaining <= 0.0:
			winner_team = Unit.Team.YELLOW
	elif _controlling_team == Unit.Team.RED:
		red_control_time_remaining = maxf(red_control_time_remaining - delta, 0.0)
		if red_control_time_remaining <= 0.0:
			_finish_match(Unit.Team.RED)


func queue_player_order(unit: Unit, target_position: Vector2) -> void:
	if not is_instance_valid(unit) or phase == Phase.FINISHED:
		return
	if phase == Phase.COUNTDOWN:
		_pending_player_orders[unit] = target_position
	elif phase == Phase.ACTIVE:
		unit.issue_move_order(target_position)


func _start_match() -> void:
	phase = Phase.ACTIVE
	for unit_variant: Variant in _pending_player_orders.keys():
		var unit: Unit = unit_variant as Unit
		if is_instance_valid(unit):
			unit.issue_move_order(_pending_player_orders[unit])
	_pending_player_orders.clear()
	match_started.emit()


func _finish_match(winning_team: int) -> void:
	if phase == Phase.FINISHED:
		return
	winner_team = winning_team
	phase = Phase.FINISHED
	result_seconds_remaining = RESULT_DISPLAY_SECONDS
	match_finished.emit(winner_team)