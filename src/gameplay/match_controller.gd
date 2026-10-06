class_name MatchController
extends Node

const CONTROL_POINTS_GROUP: StringName = &"control_points"
const MATCH_DURATION_SECONDS: float = 120.0

var yellow_control_time_remaining: float = MATCH_DURATION_SECONDS
var red_control_time_remaining: float = MATCH_DURATION_SECONDS
var winner_team: int = -1

var _control_point: ControlPoint
var _controlling_team: int = -1


func _ready() -> void:
	for node: Node in get_tree().get_nodes_in_group(CONTROL_POINTS_GROUP):
		_control_point = node as ControlPoint
		if _control_point != null:
			break
	if _control_point == null:
		push_error("MatchController requires a control point in the '%s' group." % CONTROL_POINTS_GROUP)


func _process(delta: float) -> void:
	if winner_team >= 0 or not is_instance_valid(_control_point):
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
			winner_team = Unit.Team.RED