@icon("res://addons/at-icons/node/brain.svg")
class_name UnitAutonomousBehavior
extends Node

enum State {IDLE, MOVING, ENGAGING}

const RETREAT_HEALTH_RATIO: float = 0.4

@export var _unit: Unit
@export var retreat_distance: float = 300.0

var state: State = State.IDLE
var _target_enemy: Unit
var _fire_timer: float = 0.0
var _retreat_leg_started: bool = false

@onready var _perception: UnitPerception = get_parent().get_node("UnitPerception")
@onready var _movement: UnitMovement = get_parent().get_node("UnitMovement")


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_update_idle()
		State.MOVING:
			_update_moving()
		State.ENGAGING:
			_update_engaging(delta)


func _update_idle() -> void:
	if _acquire_visible_enemy():
		_transition_to(State.ENGAGING)
	elif _movement.has_active_move_order():
		_transition_to(State.MOVING)


func _update_moving() -> void:
	if _acquire_visible_enemy():
		_transition_to(State.ENGAGING)
	elif not _movement.has_active_move_order():
		_transition_to(State.IDLE)


func _update_engaging(delta: float) -> void:
	if not is_instance_valid(_target_enemy) or _target_enemy.unit_health.current_health <= 0.0:
		_end_engagement()
		return

	if not _perception.onsight_enemy_units.has(_target_enemy):
		_end_engagement()
		return

	_update_engagement_movement()

	_fire_timer += delta
	if _fire_timer >= _unit.class_definition.fire_interval:
		_fire_timer = 0.0
		_target_enemy.unit_health.take_damage(_unit.class_definition.hp_per_shot)


func _update_engagement_movement() -> void:
	var health_ratio: float = _unit.unit_health.current_health / _unit.unit_health.max_health
	var direction_away_from_enemy: Vector2 = _target_enemy.global_position.direction_to(_unit.global_position)
	if direction_away_from_enemy == Vector2.ZERO:
		direction_away_from_enemy = Vector2.RIGHT

	if health_ratio <= RETREAT_HEALTH_RATIO:
		if not _retreat_leg_started or _movement.is_autonomous_move_finished():
			_movement.set_autonomous_move_target(_unit.global_position + direction_away_from_enemy * retreat_distance)
			_retreat_leg_started = true
	else:
		_retreat_leg_started = false
		var optimal_distance: float = _unit.class_definition.optimal_engagement_distance
		var engagement_position: Vector2 = _target_enemy.global_position + direction_away_from_enemy * optimal_distance
		_movement.set_autonomous_move_target(engagement_position)


func _end_engagement() -> void:
	_target_enemy = null
	_fire_timer = 0.0
	_retreat_leg_started = false
	if _movement.has_active_move_order():
		_transition_to(State.MOVING)
	else:
		_transition_to(State.IDLE)


func _transition_to(next_state: State) -> void:
	if state == next_state:
		return
	_exit_state(state)
	state = next_state
	_enter_state(state)


func _enter_state(entered_state: State) -> void:
	if entered_state == State.ENGAGING:
		_retreat_leg_started = false
		_update_engagement_movement()


func _exit_state(exited_state: State) -> void:
	if exited_state == State.ENGAGING:
		_movement.clear_autonomous_move_target()


func _acquire_visible_enemy() -> bool:
	_target_enemy = _find_visible_enemy()
	return _target_enemy != null


func _find_visible_enemy() -> Unit:
	for enemy: Unit in _perception.onsight_enemy_units:
		if is_instance_valid(enemy) and enemy.unit_health.current_health > 0.0:
			return enemy
	return null