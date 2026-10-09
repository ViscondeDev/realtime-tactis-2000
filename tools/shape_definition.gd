@tool
class_name ShapeDefinition
extends Resource

enum Shape {CIRCLE, SQUARE, TRIANGLE, HEXAGON, LINE, DOT}
enum LineStyle {CONTINUOUS, DOTTED, SEGMENTED}

@export var shape: Shape = Shape.CIRCLE:
	set(value):
		shape = value
		emit_changed()
@export var line_style: LineStyle = LineStyle.CONTINUOUS:
	set(value):
		line_style = value
		emit_changed()
@export var offset: Vector2 = Vector2.ZERO:
	set(value):
		offset = value
		emit_changed()
@export var rotation: float = 0.0:
	set(value):
		rotation = value
		emit_changed()
@export_range(1.0, 500.0, 1.0) var radius: float = 64.0:
	set(value):
		radius = clampf(value, 1.0, 500.0)
		emit_changed()
@export var fill_enabled: bool = true:
	set(value):
		fill_enabled = value
		emit_changed()
@export var fill_color: Color = Color.WHITE:
	set(value):
		fill_color = value
		emit_changed()
@export var outline_enabled: bool = true:
	set(value):
		outline_enabled = value
		emit_changed()
@export var outline_color: Color = Color.BLACK:
	set(value):
		outline_color = value
		emit_changed()
@export_range(0.5, 128.0, 0.5) var line_width: float = 4.0:
	set(value):
		line_width = clampf(value, 0.5, 128.0)
		emit_changed()
@export_range(2, 256, 1) var mark_count: int = 16:
	set(value):
		mark_count = clampi(value, 2, 256)
		emit_changed()
@export_range(1.0, 1000.0, 1.0) var segment_length: float = 16.0:
	set(value):
		segment_length = clampf(value, 1.0, 1000.0)
		emit_changed()