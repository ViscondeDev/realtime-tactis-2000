@tool
@icon("res://addons/at-icons/node2d/heart.svg")
class_name HealthDispenser
extends StaticBody2D

const GOALS_LAYER: int = 5
const BUILD_SECONDS: float = 5.0
const DOT_RADIUS: float = 8.0
const CROSS_HALF_LENGTH: float = 20.0
const CROSS_WIDTH: float = 8.0
const DOTTED_RING_COUNT: int = 48
const DOTTED_RING_RADIUS: float = 2.5
const HEALTH_DISPENSER_GROUP: StringName = &"health_dispensers"

@export_range(40.0, 1000.0, 1.0) var healing_radius: float = 240.0:
	set(value):
		healing_radius = value
		queue_redraw()
@export_range(1.0, 1000.0, 1.0) var maximum_health: float = 250.0
@export_range(0.0, 100.0, 0.5) var healing_per_second: float = 20.0

@export var team: Unit.Team = Unit.Team.YELLOW
var is_building: bool = false
@export var is_built: bool = false
var _construction_elapsed: float = 0.0
var current_health: float = maximum_health
var _collision_shape: CollisionShape2D


func _ready() -> void:
	add_to_group(HEALTH_DISPENSER_GROUP)
	collision_layer = 0
	set_collision_layer_value(GOALS_LAYER, true)
	collision_mask = 0
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = CircleShape2D.new()
	(_collision_shape.shape as CircleShape2D).radius = CROSS_HALF_LENGTH
	_collision_shape.disabled = true
	add_child(_collision_shape)
	set_process(not Engine.is_editor_hint())


func begin_construction(builder: Unit) -> bool:
	if not is_instance_valid(builder) or builder.unit_class != Unit.Class.SMART:
		return false
	if not is_instance_valid(builder.unit_health) or builder.unit_health.current_health <= 0.0:
		return false
	if is_building or is_built:
		return false

	team = builder.team
	is_building = true
	_construction_elapsed = 0.0
	queue_redraw()
	return true


func take_damage(amount: float) -> void:
	if not is_built or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	if current_health == 0.0:
		_collision_shape.set_deferred("disabled", true)
		queue_free()


func _process(delta: float) -> void:
	if is_building:
		_construction_elapsed += delta
		if _construction_elapsed >= BUILD_SECONDS:
			_finish_construction()
		return
	if is_built:
		_heal_nearby_units(delta)


func _finish_construction() -> void:
	_construction_elapsed = BUILD_SECONDS
	is_building = false
	is_built = true
	current_health = maximum_health
	_collision_shape.set_deferred("disabled", false)
	queue_redraw()


func _heal_nearby_units(delta: float) -> void:
	var radius_squared: float = healing_radius * healing_radius
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or unit.team != team:
			continue
		if unit.unit_health.current_health <= 0.0:
			continue
		if unit.global_position.distance_squared_to(global_position) > radius_squared:
			continue
		unit.unit_health.heal(healing_per_second * delta)


func _draw() -> void:
	if not is_built:
		draw_circle(Vector2.ZERO, DOT_RADIUS, Color.WHITE)
		return

	var team_color: Color = Color.html(Unit.TEAM_COLORS[team])
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
		draw_circle(dot_position, DOTTED_RING_RADIUS, Color.WHITE)