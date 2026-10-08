@icon("res://addons/at-icons/node2d/arrow_clockwise.svg")
class_name UnitRespawnController
extends Node2D

signal unit_spawned(unit: Unit)

const RESPAWN_DELAY_SECONDS: float = 5.0
const RESPAWN_POINTS_GROUP: StringName = &"respawn_points"
const UNIT_SCENE: PackedScene = preload("res://src/gameplay/unit.tscn")

@export var _unit_container: Node2D
@export var _projectile_pool: UnitProjectilePool

var _respawn_points: Dictionary = {}
var _is_shutting_down: bool = false
var _respawns_enabled: bool = true


func _ready() -> void:
	var match_controller: MatchController = get_tree().get_first_node_in_group(&"match_controllers") as MatchController
	if is_instance_valid(match_controller):
		match_controller.match_finished.connect(_on_match_finished)
		_respawns_enabled = match_controller.phase != MatchController.Phase.FINISHED
	for node: Node in get_tree().get_nodes_in_group(RESPAWN_POINTS_GROUP):
		var respawn_point: Node2D = node as Node2D
		if respawn_point != null:
			_respawn_points[int(respawn_point.get("team"))] = respawn_point

	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null:
			_register_unit(unit)


func _exit_tree() -> void:
	_is_shutting_down = true


func _register_unit(unit: Unit) -> void:
	unit.unit_health.died.connect(_on_unit_died.bind(unit))
	unit_spawned.emit(unit)


func _on_unit_died(unit: Unit) -> void:
	if _is_shutting_down or not _respawns_enabled or not is_inside_tree():
		return

	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = RESPAWN_DELAY_SECONDS
	timer.timeout.connect(_respawn_unit.bind(unit.team, unit.unit_class, timer))
	add_child(timer)
	timer.start()


func _respawn_unit(team: Unit.Team, unit_class: Unit.Class, timer: Timer) -> void:
	timer.queue_free()
	if _is_shutting_down or not _respawns_enabled or not is_inside_tree():
		return

	var respawn_point: Node2D = _respawn_points.get(team) as Node2D
	if not is_instance_valid(respawn_point):
		push_error("No respawn point configured for team %s." % team)
		return

	if not is_instance_valid(_unit_container) or not is_instance_valid(_projectile_pool):
		push_error("UnitRespawnController requires a unit container and projectile pool.")
		return

	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	unit.team = team
	unit.unit_class = unit_class
	unit.projectile_pool = _projectile_pool
	unit.position = _unit_container.to_local(respawn_point.global_position)
	_unit_container.add_child(unit)
	_register_unit(unit)


func _on_match_finished(_winning_team: int) -> void:
	_respawns_enabled = false