@icon("res://addons/at-icons/node2d/mesh_polygon.svg")
class_name UnitShapeRenderer
extends Node2D

const SQUARE_SIZE_RATIO: float = 0.85
const TRIANGLE_HALF_WIDTH_RATIO: float = 0.866 # cos(30 degrees)
const TRIANGLE_BOTTOM_HEIGHT_RATIO: float = 0.5 # sin(30 degrees)

var unit: Unit:
	set(new_unit):
		unit = new_unit
		_definition = unit.class_definition

var _definition: ClassDefinition:
	set(new_definition):
		_definition = new_definition
		queue_redraw()


func _draw() -> void:
	if unit == null:
		return

	var radius: float = _definition.body_radius
	var color: Color = Color.html(Unit.TEAM_COLORS[unit.team])

	match _definition.body_shape:
		ClassDefinition.BodyShape.TRIANGLE:
			var triangle_corners: PackedVector2Array = PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius * TRIANGLE_HALF_WIDTH_RATIO, radius * TRIANGLE_BOTTOM_HEIGHT_RATIO),
				Vector2(-radius * TRIANGLE_HALF_WIDTH_RATIO, radius * TRIANGLE_BOTTOM_HEIGHT_RATIO),
			])
			draw_colored_polygon(triangle_corners, color)
		ClassDefinition.BodyShape.SQUARE:
			var half_side: float = radius * SQUARE_SIZE_RATIO
			draw_rect(Rect2(-half_side, -half_side, half_side * 2.0, half_side * 2.0), color)
		ClassDefinition.BodyShape.CIRCLE:
			draw_circle(Vector2.ZERO, radius, color)