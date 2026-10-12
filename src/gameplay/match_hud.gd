class_name MatchHUD
extends CanvasLayer

signal return_to_menu_requested

const UNIT_ROW_SCENE: PackedScene = preload("res://src/gameplay/unit_status_row.tscn")
enum Status {COUNTDOWN, CONTROL}

@export var match_controller: Node
@export var respawn_controller: UnitRespawnController
@export var _red_controlling_style: StyleBox
@export var _yellow_controlling_style: StyleBox
@export var _red_countdown_style: StyleBox
@export var _yellow_countdown_style: StyleBox

@onready var _results_animation: AnimationPlayer = %ResultsAnimation
@onready var _support_phrase:Label = %SupportPhrase
@onready var _score_panel: PanelContainer = %ScorePanel
@onready var _yellow_timer_label: Label = %YellowTimer
@onready var _red_timer_label: Label = %RedTimer
@onready var _yellow_fill: ColorRect = %YellowFill
@onready var _red_fill: ColorRect = %RedFill
@onready var _match_result_label: Label = %MatchResult
@onready var _countdown_label: Label = %Countdown
@onready var _return_to_menu_button: Button = %ReturnToMenu
@onready var _unit_list: VBoxContainer = %UnitList
@onready var _empty_state: Label = %EmptyState
@onready var _result_panel: PanelContainer = %ResultPanel

var _control_point: ControlPoint
var _unit_rows: Dictionary = {}
var _last_yellow_seconds: int = -1
var _last_red_seconds: int = -1


func _ready() -> void:
	layer = 10
	_return_to_menu_button.pressed.connect(_on_return_to_menu_pressed)
	_control_point = _find_control_point()
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		_register_unit(node as Unit)
	if is_instance_valid(respawn_controller):
		respawn_controller.unit_spawned.connect(_register_unit)


func _process(_delta: float) -> void:
	if is_instance_valid(match_controller):
		var yellow_seconds: int = ceili(float(match_controller.get("yellow_control_time_remaining")))
		var red_seconds: int = ceili(float(match_controller.get("red_control_time_remaining")))
		if yellow_seconds != _last_yellow_seconds:
			_yellow_timer_label.text = _format_time(yellow_seconds)
			_last_yellow_seconds = yellow_seconds
		if red_seconds != _last_red_seconds:
			_red_timer_label.text = _format_time(red_seconds)
			_last_red_seconds = red_seconds
		var winner_team: int = int(match_controller.get("winner_team"))
		if winner_team >= 0 and not _result_panel.visible:
			_show_results_panel(winner_team)
			_match_result_label.text = "%s TEAM WINS" % ["YELLOW", "RED"][winner_team]
			_support_phrase.text = ["The game just got harder.", "I still believe in you."][winner_team]
		var phase: int = int(match_controller.get("phase"))
		_countdown_label.visible = phase == MatchController.Phase.COUNTDOWN
		if _countdown_label.visible:
			_countdown_label.text = "MATCH\nSTARTS IN\n%d" % ceili(float(match_controller.get("countdown_seconds_remaining")))

	if is_instance_valid(_control_point):
		var yellow_width: float = clampf((_control_point.capture_progress + 1.0) * 0.5, 0.0, 1.0)
		_yellow_fill.anchor_right = yellow_width
		_red_fill.anchor_left = yellow_width

	for unit: Variant in _unit_rows.keys():
		if not is_instance_valid(unit):
			var row: Control = _unit_rows[unit] as Control
			_unit_rows.erase(unit)
			if is_instance_valid(row):
				row.queue_free()
	_empty_state.visible = _unit_rows.is_empty()


func _on_return_to_menu_pressed() -> void:
	return_to_menu_requested.emit()

func _show_results_panel(winner_team: Unit.Team):
	if winner_team == Unit.Team.YELLOW:
		_results_animation.play("promotion")
	elif winner_team == Unit.Team.RED:
		_results_animation.play("demotion")


func _find_control_point() -> ControlPoint:
	for node: Node in get_tree().get_nodes_in_group(&"control_points"):
		var control_point: ControlPoint = node as ControlPoint
		if control_point != null:
			return control_point
	return null


func _register_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or unit.team != Unit.Team.YELLOW or _unit_rows.has(unit):
		return
	var row: UnitStatusRow = UNIT_ROW_SCENE.instantiate() as UnitStatusRow
	_unit_list.add_child(row)
	row.set_unit(unit)
	row.unit_selected.connect(_on_unit_selected)
	_unit_rows[unit] = row
	_empty_state.visible = false


func _on_unit_selected(unit: Unit) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if is_instance_valid(camera) and camera.has_method("focus_on_unit"):
		camera.call("focus_on_unit", unit)


func _format_time(total_seconds: int) -> String:
	var minutes: int = floori(float(total_seconds) / 60.0)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _update_stats_style(team:Unit.Team, status:Status):
	if status == Status.CONTROL:
		if team == Unit.Team.RED:
			_score_panel.add_theme_stylebox_override("panel", _red_controlling_style)
		elif team == Unit.Team.YELLOW:
			_score_panel.add_theme_stylebox_override("panel", _yellow_controlling_style)
	elif status == Status.COUNTDOWN:
		if team == Unit.Team.RED:
			_score_panel.add_theme_stylebox_override("panel", _red_countdown_style)
		elif team == Unit.Team.YELLOW:
			_score_panel.add_theme_stylebox_override("panel", _yellow_countdown_style)