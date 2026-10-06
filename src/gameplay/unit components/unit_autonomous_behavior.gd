@icon("res://addons/at-icons/node/brain.svg")
class_name UnitAutonomousBehavior
extends Node

enum State {IDLE, MOVING, ENGAGING}

@export var _unit: Unit

var state: State = State.IDLE
var _target_enemy: Unit
var _fire_timer: float = 0.0

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
		_target_enemy = null
		_fire_timer = 0.0
		if _movement.has_active_move_order():
			_transition_to(State.MOVING)
		else:
			_transition_to(State.IDLE)
		return

	if not _perception.onsight_enemy_units.has(_target_enemy):
		_fire_timer = 0.0
		return

	_fire_timer += delta
	if _fire_timer >= _unit.class_definition.fire_interval:
		_fire_timer = 0.0
		_target_enemy.unit_health.take_damage(_unit.class_definition.hp_per_shot)


func _transition_to(next_state: State) -> void:
	if state == next_state:
		return
	_exit_state(state)
	state = next_state
	_enter_state(state)


func _enter_state(entered_state: State) -> void:
	if entered_state == State.ENGAGING:
		_movement.set_paused(true)


func _exit_state(exited_state: State) -> void:
	if exited_state == State.ENGAGING:
		_movement.set_paused(false)


func _acquire_visible_enemy() -> bool:
	_target_enemy = _find_visible_enemy()
	return _target_enemy != null


func _find_visible_enemy() -> Unit:
	for enemy: Unit in _perception.onsight_enemy_units:
		if is_instance_valid(enemy) and enemy.unit_health.current_health > 0.0:
			return enemy
	return null