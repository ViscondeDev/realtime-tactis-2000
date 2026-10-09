@tool
@icon("res://addons/at-icons/node2d/heart.svg")
class_name HealthDispenser
extends StaticBody2D

const GOALS_LAYER: int = 5
const BUILD_SITES_LAYER: int = 6
const BUILD_SECONDS: float = 5.0
const DOT_RADIUS: float = 8.0
const CROSS_HALF_LENGTH: float = 20.0
const CROSS_WIDTH: float = 8.0
const CONNECTOR_WIDTH: float = 3.0
const DOTTED_RING_COUNT: int = 48
const DOTTED_RING_RADIUS: float = 2.5
const HEALTH_DISPENSER_GROUP: StringName = &"health_dispensers"

@export_range(40.0, 1000.0, 1.0) var healing_radius: float = 240.0:
	set(value):
		healing_radius = value
		queue_redraw()
@export_range(1.0, 1000.0, 1.0) var maximum_health: float = 125.0
@export_range(0.0, 100.0, 0.5) var healing_per_second: float = 20.0
@export var overheal_enabled: bool = true

@export var team: Unit.Team = Unit.Team.YELLOW
var is_building: bool = false
@export var is_built: bool = false
var builder: Unit
var _construction_elapsed: float = 0.0
var current_health: float = maximum_health
var _collision_shape: CollisionShape2D
var _healing_units: Array[Unit] = []
var _serviced_units: Array[Unit] = []


func _ready() -> void:
	add_to_group(HEALTH_DISPENSER_GROUP)
	collision_layer = 0
	set_collision_layer_value(GOALS_LAYER if is_built else BUILD_SITES_LAYER, true)
	collision_mask = 0
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = CircleShape2D.new()
	(_collision_shape.shape as CircleShape2D).radius = CROSS_HALF_LENGTH
	_collision_shape.disabled = Engine.is_editor_hint()
	add_child(_collision_shape)
	set_process(not Engine.is_editor_hint())


func begin_construction(requesting_builder: Unit) -> bool:
	if not is_instance_valid(requesting_builder) or requesting_builder.unit_class != Unit.Class.SMART:
		return false
	if not is_instance_valid(requesting_builder.unit_health) or requesting_builder.unit_health.current_health <= 0.0:
		return false
	if is_building or is_built:
		return false

	team = requesting_builder.team
	self.builder = requesting_builder
	is_building = true
	_construction_elapsed = 0.0
	queue_redraw()
	return true


func cancel_construction(requesting_builder: Unit) -> void:
	if not is_building or builder != requesting_builder:
		return
	is_building = false
	self.builder = null
	_construction_elapsed = 0.0
	queue_redraw()


func take_damage(amount: float) -> void:
	if not is_built or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	if current_health == 0.0:
		is_built = false
		is_building = false
		builder = null
		_construction_elapsed = 0.0
		current_health = maximum_health
		_clear_serviced_units()
		set_collision_layer_value(GOALS_LAYER, false)
		set_collision_layer_value(BUILD_SITES_LAYER, true)
		queue_redraw()


func _process(delta: float) -> void:
	if is_building:
		_construction_elapsed += delta
		queue_redraw()
		if _construction_elapsed >= BUILD_SECONDS:
			_finish_construction()
		return
	if is_built:
		var had_healing_units: bool = not _healing_units.is_empty()
		_heal_nearby_units(delta)
		if had_healing_units or not _healing_units.is_empty():
			queue_redraw()


func _finish_construction() -> void:
	_construction_elapsed = BUILD_SECONDS
	is_building = false
	is_built = true
	current_health = maximum_health
	set_collision_layer_value(BUILD_SITES_LAYER, false)
	set_collision_layer_value(GOALS_LAYER, true)
	_collision_shape.set_deferred("disabled", false)
	queue_redraw()


func _heal_nearby_units(delta: float) -> void:
	_healing_units.clear()
	var nearby_units: Array[Unit] = []

	var radius_squared: float = healing_radius * healing_radius
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or unit.team != team:
			continue
		if not is_instance_valid(unit.unit_health) or unit.unit_health.current_health <= 0.0:
			continue
		if unit.global_position.distance_squared_to(global_position) > radius_squared:
			continue
		nearby_units.append(unit)
		unit.unit_health.set_overheal_source(self, overheal_enabled)
		if healing_per_second > 0.0 and unit.unit_health.current_health < unit.unit_health.healing_ceiling(overheal_enabled):
			_healing_units.append(unit)
			unit.unit_health.heal(healing_per_second * delta)

	for unit: Unit in _serviced_units:
		if is_instance_valid(unit) and not nearby_units.has(unit) and is_instance_valid(unit.unit_health):
			unit.unit_health.set_overheal_source(self, false)
	_serviced_units = nearby_units


func _clear_serviced_units() -> void:
	for unit: Unit in _serviced_units:
		if is_instance_valid(unit) and is_instance_valid(unit.unit_health):
			unit.unit_health.set_overheal_source(self, false)
	_serviced_units.clear()
	_healing_units.clear()


func _draw() -> void:
	if not is_built:
		if is_building and is_instance_valid(builder):
			draw_line(
				Vector2.ZERO,
				to_local(builder.global_position),
				Color.html(Unit.TEAM_COLORS[team]),
				CONNECTOR_WIDTH,
				true
			)
		draw_circle(Vector2.ZERO, DOT_RADIUS, Color.html("#263b46"))
		return

	var team_color: Color = Color.html(Unit.TEAM_COLORS[team])
	for unit: Unit in _healing_units:
		if is_instance_valid(unit):
			draw_line(
				Vector2.ZERO,
				to_local(unit.global_position),
				team_color,
				CONNECTOR_WIDTH,
				true
			)
	draw_line(
		Vector2(-CROSS_HALF_LENGTH, 0.0),
		Vector2(CROSS_HALF_LENGTH, 0.0),
		team_color,
		CROSS_WIDTH,
		true
	)
	draw_line(
		Vector2(0.0, -CROSS_HALF_LENGTH),
		Vector2(0.0, CROSS_HALF_LENGTH),
		team_color,
		CROSS_WIDTH,
		true
	)
	for dot_index: int in range(DOTTED_RING_COUNT):
		var angle: float = TAU * float(dot_index) / float(DOTTED_RING_COUNT)
		var dot_position: Vector2 = Vector2(cos(angle), sin(angle)) * healing_radius
		draw_circle(dot_position, DOTTED_RING_RADIUS, Color.html("#263b46"))