@icon("res://addons/at-icons/node2d/mesh_polygon.svg")
class_name UnitShapeRenderer
extends Node2D

const OVERHEAL_RING_PADDING: float = 6.0
const OVERHEAL_RING_WIDTH: float = 3.0

var unit: Unit:
	set(new_unit):
		if is_instance_valid(unit) and is_instance_valid(unit.unit_health):
			unit.unit_health.health_changed.disconnect(_on_health_changed)
		unit = new_unit
		_definition = unit.class_definition
		unit.unit_health.health_changed.connect(_on_health_changed)
		_update_shape_definitions()

var _definition: ClassDefinition:
	set(new_definition):
		_definition = new_definition
		_update_shape_definitions()

@onready var _shape_tool: ShapeTool = $ShapeTool
var _body_shape: ShapeDefinition
var _overheal_ring: ShapeDefinition


func _ready() -> void:
	_body_shape = ShapeDefinition.new()
	_overheal_ring = ShapeDefinition.new()
	_overheal_ring.shape = ShapeDefinition.Shape.CIRCLE
	_overheal_ring.fill_enabled = false
	_overheal_ring.line_width = OVERHEAL_RING_WIDTH
	_shape_tool.definitions = [_body_shape, _overheal_ring]


func _draw() -> void:
	if unit == null:
		return

	_update_shape_definitions()


func _update_shape_definitions() -> void:
	if not is_instance_valid(_shape_tool) or _definition == null or unit == null:
		return

	var color: Color = Color.html(Unit.TEAM_COLORS[unit.team])
	match _definition.body_shape:
		ClassDefinition.BodyShape.TRIANGLE:
			_body_shape.shape = ShapeDefinition.Shape.TRIANGLE
		ClassDefinition.BodyShape.SQUARE:
			_body_shape.shape = ShapeDefinition.Shape.SQUARE
		ClassDefinition.BodyShape.CIRCLE:
			_body_shape.shape = ShapeDefinition.Shape.CIRCLE
	_body_shape.radius = minf(_definition.body_radius, ShapeTool.MAX_RADIUS)
	_body_shape.fill_color = color
	_body_shape.outline_enabled = false
	_overheal_ring.radius = minf(_definition.body_radius + OVERHEAL_RING_PADDING, ShapeTool.MAX_RADIUS)
	_overheal_ring.outline_color = color
	_overheal_ring.outline_enabled = unit.unit_health.current_health > unit.unit_health.max_health


func _on_health_changed(_new_health: float) -> void:
	_update_shape_definitions()