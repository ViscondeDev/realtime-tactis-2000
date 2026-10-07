@icon("res://addons/at-icons/node/brain.svg")
class_name UnitAutonomousBehavior
extends Node

enum State {IDLE, MOVING, ENGAGING}

const RETREAT_HEALTH_RATIO: float = 0.4

@export var _unit: Unit
@export var retreat_distance: float = 300.0
var projectile_pool: UnitProjectilePool

var state: State = State.IDLE
var _target_enemy: Unit
var _target_dispenser: HealthDispenser
var _control_point_target: ControlPoint
var _fire_timer: float = 0.0
var _burst_rounds_remaining: int = 0
var _burst_timer: float = 0.0
var _burst_round_damage: float = 0.0
var _retreat_leg_started: bool = false

@onready var _perception: UnitPerception = %UnitPerception
@onready var _movement: UnitMovement = %UnitMovement


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
		_unit.set_report_condition(&"idle_without_order", false)
		_transition_to(State.ENGAGING)
	elif _can_acquire_dispenser() and _acquire_visible_dispenser():
		_unit.set_report_condition(&"idle_without_order", false)
		_transition_to(State.ENGAGING)
	elif _movement.has_active_move_order():
		_unit.set_report_condition(&"idle_without_order", false)
		_transition_to(State.MOVING)
	elif _hold_visible_control_point():
		_unit.set_report_condition(&"idle_without_order", false)
	else:
		if _unit.unit_class == Unit.Class.SMART:
			_try_build_visible_dispenser()
		_unit.set_report_condition(&"idle_without_order", true)


func _update_moving() -> void:
	if _acquire_visible_enemy():
		_transition_to(State.ENGAGING)
	elif _can_acquire_dispenser() and _acquire_visible_dispenser():
		_transition_to(State.ENGAGING)
	elif not _movement.has_active_move_order():
		_transition_to(State.IDLE)


func _update_engaging(delta: float) -> void:
	if is_instance_valid(_target_dispenser):
		var visible_enemy: Unit = _find_visible_enemy()
		if visible_enemy != null:
			_target_enemy = visible_enemy
			_target_dispenser = null
			_fire_timer = 0.0
	if is_instance_valid(_target_enemy):
		if _target_enemy.unit_health.current_health <= 0.0 or not _perception.onsight_enemy_units.has(_target_enemy):
			_end_engagement()
			return
	elif (
		not is_instance_valid(_target_dispenser)
		or not _target_dispenser.is_built
		or _target_dispenser.current_health <= 0.0
		or _target_dispenser.team == _unit.team
		or not _perception.onsight_areas.has(_target_dispenser)
	):
		_end_engagement()
		return

	_update_engagement_movement()

	var class_definition: ClassDefinition = _unit.class_definition
	var target: Node2D = _target_enemy if is_instance_valid(_target_enemy) else _target_dispenser
	if _unit.global_position.distance_to(target.global_position) > class_definition.attack_range:
		_burst_rounds_remaining = 0
		_burst_timer = 0.0
		return

	if _burst_rounds_remaining > 0:
		_burst_timer += delta
		while _burst_rounds_remaining > 0 and _burst_timer >= class_definition.burst_interval:
			_burst_timer -= class_definition.burst_interval
			_fire_round(target, _burst_round_damage)
			_burst_rounds_remaining -= 1
		return

	_fire_timer += delta
	if _fire_timer < class_definition.fire_interval:
		return
	_fire_timer -= class_definition.fire_interval

	var burst_count: int = maxi(class_definition.burst_projectile_count, 1)
	if burst_count > 1:
		_burst_rounds_remaining = burst_count - 1
		_burst_timer = 0.0
		_burst_round_damage = class_definition.hp_per_shot / float(burst_count)
		_fire_round(target, _burst_round_damage)
		return

	var pellet_count: int = maxi(class_definition.pellet_count, 1)
	var pellet_damage: float = class_definition.hp_per_shot / float(pellet_count)
	for _pellet_index: int in range(pellet_count):
		_fire_round(target, pellet_damage)


func _fire_round(target: Node2D, damage: float) -> void:
	if not is_instance_valid(projectile_pool):
		push_error("UnitAutonomousBehavior requires a projectile pool.")
		return
	var class_definition: ClassDefinition = _unit.class_definition
	var aim_direction: Vector2 = _unit.global_position.direction_to(target.global_position)
	if target is Unit:
		aim_direction = _calculate_intercept_direction(target, class_definition.projectile_speed)
	aim_direction = aim_direction.rotated(deg_to_rad(randf_range(
		-class_definition.bullet_spread_degrees,
		class_definition.bullet_spread_degrees
	)))
	var spawn_position: Vector2 = _unit.global_position + aim_direction * (_unit.class_definition.body_radius + 4.0)
	projectile_pool.fire(
		spawn_position,
		aim_direction,
		_unit.team,
		damage,
		class_definition.projectile_speed,
		class_definition.attack_range
	)


func _calculate_intercept_direction(target: Unit, projectile_speed: float) -> Vector2:
	var relative_position: Vector2 = target.global_position - _unit.global_position
	var target_velocity: Vector2 = target.get_real_velocity()
	var quadratic_a: float = target_velocity.length_squared() - projectile_speed * projectile_speed
	var quadratic_b: float = 2.0 * relative_position.dot(target_velocity)
	var quadratic_c: float = relative_position.length_squared()
	var intercept_time: float = -1.0

	if absf(quadratic_a) < 0.001:
		if absf(quadratic_b) > 0.001:
			intercept_time = -quadratic_c / quadratic_b
	else:
		var discriminant: float = quadratic_b * quadratic_b - 4.0 * quadratic_a * quadratic_c
		if discriminant >= 0.0:
			var root: float = sqrt(discriminant)
			var first_time: float = (-quadratic_b - root) / (2.0 * quadratic_a)
			var second_time: float = (-quadratic_b + root) / (2.0 * quadratic_a)
			if first_time > 0.0 and second_time > 0.0:
				intercept_time = minf(first_time, second_time)
			elif first_time > 0.0:
				intercept_time = first_time
			elif second_time > 0.0:
				intercept_time = second_time

	if intercept_time > 0.0:
		var intercept_vector: Vector2 = relative_position + target_velocity * intercept_time
		if not intercept_vector.is_zero_approx():
			return intercept_vector.normalized()
	return relative_position.normalized()


func _update_engagement_movement() -> void:
	var health_ratio: float = _unit.unit_health.current_health / _unit.unit_health.max_health
	var target: Node2D = _target_enemy if is_instance_valid(_target_enemy) else _target_dispenser
	var direction_away_from_enemy: Vector2 = target.global_position.direction_to(_unit.global_position)
	if direction_away_from_enemy == Vector2.ZERO:
		direction_away_from_enemy = Vector2.RIGHT

	if is_instance_valid(_target_enemy) and health_ratio <= RETREAT_HEALTH_RATIO:
		if not _retreat_leg_started or _movement.is_autonomous_move_finished():
			_movement.set_autonomous_move_target(_unit.global_position + direction_away_from_enemy * retreat_distance)
			_retreat_leg_started = true
	else:
		_retreat_leg_started = false
		var optimal_distance: float = _unit.class_definition.optimal_engagement_distance
		var engagement_position: Vector2 = target.global_position + direction_away_from_enemy * optimal_distance
		_movement.set_autonomous_move_target(engagement_position)


func _end_engagement() -> void:
	_target_enemy = null
	_target_dispenser = null
	_fire_timer = 0.0
	_burst_rounds_remaining = 0
	_burst_timer = 0.0
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


func _can_acquire_dispenser() -> bool:
	if _unit.unit_class == Unit.Class.QUICK:
		return true
	return _unit.unit_class == Unit.Class.STRONG and _find_visible_enemy() == null


func _acquire_visible_dispenser() -> bool:
	_target_dispenser = _find_visible_enemy_dispenser()
	return is_instance_valid(_target_dispenser)


func _find_visible_enemy_dispenser() -> HealthDispenser:
	var nearest_dispenser: HealthDispenser = null
	var nearest_distance_squared: float = INF
	for dispenser: HealthDispenser in _perception.onsight_areas:
		if (
			not is_instance_valid(dispenser)
			or not dispenser.is_built
			or dispenser.current_health <= 0.0
			or dispenser.team == _unit.team
		):
			continue
		var distance_squared: float = _unit.global_position.distance_squared_to(dispenser.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_dispenser = dispenser
	return nearest_dispenser


func _try_build_visible_dispenser() -> void:
	if _unit.unit_class != Unit.Class.SMART or _movement.has_active_move_order():
		return
	for dispenser: HealthDispenser in _perception.onsight_areas:
		if is_instance_valid(dispenser) and not dispenser.is_built and not dispenser.is_building:
			if dispenser.begin_construction(_unit):
				return


func _hold_visible_control_point() -> bool:
	var visible_control_point: ControlPoint
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group(&"control_points"):
		var control_point: ControlPoint = node as ControlPoint
		if control_point == null or not _perception.can_see_position(control_point.global_position):
			continue
		var distance_squared: float = _unit.global_position.distance_squared_to(control_point.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			visible_control_point = control_point

	if visible_control_point != null:
		_control_point_target = visible_control_point
		_movement.set_autonomous_move_target(visible_control_point.global_position)
		return true

	if is_instance_valid(_control_point_target):
		_control_point_target = null
		_movement.clear_autonomous_move_target()
	return false


func _find_visible_enemy() -> Unit:
	for enemy: Unit in _perception.onsight_enemy_units:
		if is_instance_valid(enemy) and enemy.unit_health.current_health > 0.0:
			return enemy
	return null
