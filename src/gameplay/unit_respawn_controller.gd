class_name UnitRespawnController
extends Node2D

const RESPAWN_DELAY_SECONDS: float = 5.0
const RESPAWN_POINTS_GROUP: StringName = &"respawn_points"
const UNIT_SCENE: PackedScene = preload("res://src/gameplay/unit.tscn")

var _respawn_points: Dictionary = {}
var _is_shutting_down: bool = false


func _ready() -> void:
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


func _on_unit_died(unit: Unit) -> void:
	if _is_shutting_down or not is_inside_tree():
		return

	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = RESPAWN_DELAY_SECONDS
	timer.timeout.connect(_respawn_unit.bind(unit.team, unit.unit_class, timer))
	add_child(timer)
	timer.start()


func _respawn_unit(team: Unit.Team, unit_class: Unit.Class, timer: Timer) -> void:
	timer.queue_free()
	if _is_shutting_down or not is_inside_tree():
		return

	var respawn_point: Node2D = _respawn_points.get(team) as Node2D
	if not is_instance_valid(respawn_point):
		push_error("No respawn point configured for team %s." % team)
		return

	var game_root: Node2D = get_parent() as Node2D
	if game_root == null:
		push_error("UnitRespawnController must be a child of a Node2D game root.")
		return

	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	unit.team = team
	unit.unit_class = unit_class
	unit.position = game_root.to_local(respawn_point.global_position)
	game_root.add_child(unit)
	_register_unit(unit)