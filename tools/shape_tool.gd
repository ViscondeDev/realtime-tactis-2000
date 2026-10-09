@tool
class_name ShapeTool
extends Node2D

const MAX_EXPORT_SIZE: int = 8192
const MAX_RADIUS: float = 500.0
const MAX_LINE_WIDTH: float = 128.0
const MAX_MARK_COUNT: int = 256
const MAX_DEFINITION_COUNT: int = 64
const CIRCLE_POINT_COUNT: int = 192
const SQUARE_SIZE_RATIO: float = 0.85
const TRIANGLE_HALF_WIDTH_RATIO: float = 0.866
const TRIANGLE_BOTTOM_HEIGHT_RATIO: float = 0.5

@export var definitions: Array[ShapeDefinition] = [ShapeDefinition.new()]:
	set(value):
		if value.size() > MAX_DEFINITION_COUNT:
			push_warning("ShapeTool: no more than %d shape definitions are supported." % MAX_DEFINITION_COUNT)
			return
		definitions = value
		_sync_definition_signals()
		queue_redraw()
@export_file("*.png") var png_path: String = "res://generated_shape.png"
@export_tool_button("Export PNG", "Image") var export_png_button: Callable = _export_png


func _ready() -> void:
	_sync_definition_signals()


func _draw() -> void:
	if definitions.size() > MAX_DEFINITION_COUNT:
		push_warning("ShapeTool: only the first %d definitions are rendered." % MAX_DEFINITION_COUNT)
	for definition_index: int in range(mini(definitions.size(), MAX_DEFINITION_COUNT)):
		var definition: ShapeDefinition = definitions[definition_index]
		if definition != null:
			_draw_definition(definition)


func _draw_definition(definition: ShapeDefinition) -> void:
	var points: PackedVector2Array = _shape_points(definition)
	if points.is_empty():
		return

	var shape_type: int = clampi(definition.shape, ShapeDefinition.Shape.CIRCLE, ShapeDefinition.Shape.DOT)
	var radius: float = _effective_radius(definition)
	if definition.fill_enabled and shape_type != ShapeDefinition.Shape.LINE:
		if shape_type == ShapeDefinition.Shape.CIRCLE or shape_type == ShapeDefinition.Shape.DOT:
			draw_circle(definition.offset, radius, definition.fill_color)
		else:
			draw_colored_polygon(_offset_points(_open_polygon_points(points), definition.offset), definition.fill_color)

	if definition.outline_enabled:
		_draw_styled_outline(points, definition)


func _shape_points(definition: ShapeDefinition) -> PackedVector2Array:
	var effective_radius: float = _effective_radius(definition)
	var shape_type: int = clampi(definition.shape, ShapeDefinition.Shape.CIRCLE, ShapeDefinition.Shape.DOT)
	match shape_type:
		ShapeDefinition.Shape.CIRCLE, ShapeDefinition.Shape.DOT:
			var circle_points: PackedVector2Array = PackedVector2Array()
			for point_index: int in range(CIRCLE_POINT_COUNT + 1):
				var angle: float = TAU * float(point_index) / float(CIRCLE_POINT_COUNT)
				circle_points.append(Vector2(cos(angle), sin(angle)) * effective_radius)
			return circle_points
		ShapeDefinition.Shape.SQUARE:
			var half_side: float = effective_radius * SQUARE_SIZE_RATIO
			return _closed_points(PackedVector2Array([
				Vector2(-half_side, -half_side),
				Vector2(half_side, -half_side),
				Vector2(half_side, half_side),
				Vector2(-half_side, half_side),
			]))
		ShapeDefinition.Shape.TRIANGLE:
			return _closed_points(PackedVector2Array([
				Vector2(0.0, -effective_radius),
				Vector2(effective_radius * TRIANGLE_HALF_WIDTH_RATIO, effective_radius * TRIANGLE_BOTTOM_HEIGHT_RATIO),
				Vector2(-effective_radius * TRIANGLE_HALF_WIDTH_RATIO, effective_radius * TRIANGLE_BOTTOM_HEIGHT_RATIO),
			]))
		ShapeDefinition.Shape.HEXAGON:
			var hexagon_points: PackedVector2Array = PackedVector2Array()
			for point_index: int in range(6):
				var angle: float = -PI / 2.0 + TAU * float(point_index) / 6.0
				hexagon_points.append(Vector2(cos(angle), sin(angle)) * effective_radius)
			return _closed_points(hexagon_points)
		ShapeDefinition.Shape.LINE:
			return PackedVector2Array([Vector2(-effective_radius, 0.0), Vector2(effective_radius, 0.0)])
	return PackedVector2Array()


func _effective_radius(definition: ShapeDefinition) -> float:
	return clampf(definition.radius, 1.0, MAX_RADIUS)


func _effective_line_width(definition: ShapeDefinition) -> float:
	return clampf(definition.line_width, 0.5, MAX_LINE_WIDTH)


func _effective_mark_count(definition: ShapeDefinition) -> int:
	return clampi(definition.mark_count, 2, MAX_MARK_COUNT)


func _effective_segment_length(definition: ShapeDefinition) -> float:
	return clampf(definition.segment_length, 1.0, MAX_RADIUS * 2.0)


func _open_polygon_points(points: PackedVector2Array) -> PackedVector2Array:
	var open_points: PackedVector2Array = points.duplicate()
	if open_points.size() > 1 and open_points[0].is_equal_approx(open_points[open_points.size() - 1]):
		open_points.remove_at(open_points.size() - 1)
	return open_points


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	if not points.is_empty():
		points.append(points[0])
	return points


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		result.append(point + offset)
	return result


func _draw_styled_outline(points: PackedVector2Array, definition: ShapeDefinition) -> void:
	if points.size() < 2:
		return

	var path_length: float = _path_length(points)
	if path_length <= 0.0:
		return

	var offset_points: PackedVector2Array = _offset_points(points, definition.offset)
	var line_width: float = _effective_line_width(definition)
	var mark_count: int = _effective_mark_count(definition)
	match definition.line_style:
		ShapeDefinition.LineStyle.CONTINUOUS:
			draw_polyline(offset_points, definition.outline_color, line_width, true)
		ShapeDefinition.LineStyle.DOTTED:
			var dot_radius: float = maxf(line_width * 0.5, 0.5)
			for mark_index: int in range(mark_count):
				var distance: float = path_length * (float(mark_index) + 0.5) / float(mark_count)
				draw_circle(_point_at_distance(points, distance, path_length) + definition.offset, dot_radius, definition.outline_color)
		ShapeDefinition.LineStyle.SEGMENTED:
			var spacing: float = path_length / float(mark_count)
			var drawn_length: float = minf(_effective_segment_length(definition), spacing * 0.9)
			for mark_index: int in range(mark_count):
				var segment_points: PackedVector2Array = _offset_points(
					_slice_path(points, spacing * float(mark_index), spacing * float(mark_index) + drawn_length, path_length),
					definition.offset
				)
				if segment_points.size() >= 2:
					draw_polyline(segment_points, definition.outline_color, line_width, true)


func _path_length(points: PackedVector2Array) -> float:
	var total_length: float = 0.0
	for point_index: int in range(points.size() - 1):
		total_length += points[point_index].distance_to(points[point_index + 1])
	return total_length


func _point_at_distance(points: PackedVector2Array, distance: float, path_length: float) -> Vector2:
	var remaining_distance: float = clampf(distance, 0.0, path_length)
	for point_index: int in range(points.size() - 1):
		var segment_length: float = points[point_index].distance_to(points[point_index + 1])
		if remaining_distance <= segment_length:
			return points[point_index].lerp(points[point_index + 1], remaining_distance / segment_length)
		remaining_distance -= segment_length
	return points[points.size() - 1]


func _slice_path(
	points: PackedVector2Array,
	start_distance: float,
	end_distance: float,
	path_length: float
) -> PackedVector2Array:
	var start: float = clampf(start_distance, 0.0, path_length)
	var end: float = clampf(end_distance, 0.0, path_length)
	if end <= start:
		return PackedVector2Array()

	var result: PackedVector2Array = PackedVector2Array([_point_at_distance(points, start, path_length)])
	var distance_along_path: float = 0.0
	for point_index: int in range(points.size() - 1):
		distance_along_path += points[point_index].distance_to(points[point_index + 1])
		if distance_along_path > start and distance_along_path < end:
			result.append(points[point_index + 1])
	result.append(_point_at_distance(points, end, path_length))
	return result


func _export_png() -> void:
	if definitions.is_empty():
		push_error("ShapeTool: add at least one shape definition before exporting.")
		return
	if definitions.size() > MAX_DEFINITION_COUNT:
		push_error("ShapeTool: no more than %d shape definitions can be exported." % MAX_DEFINITION_COUNT)
		return
	if png_path.is_empty() or png_path.get_extension().to_lower() != "png":
		push_error("ShapeTool: choose a valid .png output path before exporting.")
		return

	var absolute_path: String = ProjectSettings.globalize_path(png_path)
	if not DirAccess.dir_exists_absolute(absolute_path.get_base_dir()):
		push_error("ShapeTool: the PNG output folder does not exist.")
		return

	for definition: ShapeDefinition in definitions:
		if definition == null:
			push_error("ShapeTool: remove empty shape definitions before exporting.")
			return
		if not _is_valid_definition(definition):
			push_error("ShapeTool: each shape must use a valid shape and line style.")
			return

	var export_size: Vector2i = _export_size()
	if export_size.x > MAX_EXPORT_SIZE or export_size.y > MAX_EXPORT_SIZE:
		push_error("ShapeTool: combined shape dimensions cannot exceed %d pixels per side." % MAX_EXPORT_SIZE)
		return

	var svg: String = _build_svg()
	if svg.is_empty():
		push_error("ShapeTool: no drawable shapes were found to export.")
		return
	var image: Image = Image.new()
	var raster_error: Error = image.load_svg_from_string(svg)
	if raster_error != OK:
		push_error("ShapeTool: failed to rasterize the shapes (error %d)." % raster_error)
		return
	var save_error: Error = image.save_png(absolute_path)
	if save_error != OK:
		push_error("ShapeTool: failed to save PNG (error %d)." % save_error)
		return
	print("ShapeTool: exported %d shapes to %s" % [definitions.size(), absolute_path])


func _definition_bounds(definition: ShapeDefinition) -> Rect2:
	var points: PackedVector2Array = _shape_points(definition)
	if points.is_empty():
		return Rect2()

	var first_point: Vector2 = points[0] + definition.offset
	var bounds: Rect2 = Rect2(first_point, Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point + definition.offset)
	var stroke_margin: float = _effective_line_width(definition) * 0.5 if definition.outline_enabled else 0.0
	return bounds.grow(stroke_margin + 1.0)


func _combined_bounds() -> Rect2:
	var has_bounds: bool = false
	var combined_bounds: Rect2 = Rect2()
	for definition: ShapeDefinition in definitions:
		if definition == null:
			continue
		var definition_bounds: Rect2 = _definition_bounds(definition)
		if not has_bounds:
			combined_bounds = definition_bounds
			has_bounds = true
		else:
			combined_bounds = combined_bounds.merge(definition_bounds)
	return combined_bounds if has_bounds else Rect2()


func _export_size() -> Vector2i:
	var bounds: Rect2 = _combined_bounds()
	var width: float = maxf(1.0, ceilf(bounds.size.x - 0.001))
	var height: float = maxf(1.0, ceilf(bounds.size.y - 0.001))
	return Vector2i(
		mini(int(minf(width, float(MAX_EXPORT_SIZE + 1))), MAX_EXPORT_SIZE + 1),
		mini(int(minf(height, float(MAX_EXPORT_SIZE + 1))), MAX_EXPORT_SIZE + 1)
	)


func _is_valid_definition(definition: ShapeDefinition) -> bool:
	return (
		definition.shape >= ShapeDefinition.Shape.CIRCLE
		and definition.shape <= ShapeDefinition.Shape.DOT
		and definition.line_style >= ShapeDefinition.LineStyle.CONTINUOUS
		and definition.line_style <= ShapeDefinition.LineStyle.SEGMENTED
		and is_finite(definition.offset.x)
		and is_finite(definition.offset.y)
	)


func _build_svg() -> String:
	var bounds: Rect2 = _combined_bounds()
	var export_size: Vector2i = _export_size()
	var width: int = export_size.x
	var height: int = export_size.y
	var offset: Vector2 = -bounds.position
	var svg_shapes: String = ""
	for definition: ShapeDefinition in definitions:
		if definition == null:
			continue
		var points: PackedVector2Array = _shape_points(definition)
		if points.size() < 2:
			continue
		var is_closed: bool = definition.shape != ShapeDefinition.Shape.LINE
		var fill: String = "#" + definition.fill_color.to_html(false) if definition.fill_enabled and is_closed else "none"
		var fill_opacity: String = " fill-opacity=\"%s\"" % String.num(definition.fill_color.a, 4) if fill != "none" else ""
		var stroke_attributes: String = ""
		if definition.outline_enabled:
			stroke_attributes = " stroke=\"%s\" stroke-opacity=\"%s\" stroke-width=\"%s\" stroke-linecap=\"round\" stroke-linejoin=\"round\"" % [
				"#" + definition.outline_color.to_html(false),
				String.num(definition.outline_color.a, 4),
				String.num(_effective_line_width(definition), 4),
			]
			var path_length: float = _path_length(points)
			var mark_count: int = _effective_mark_count(definition)
			if definition.line_style == ShapeDefinition.LineStyle.DOTTED:
				var spacing: float = path_length / float(mark_count)
				stroke_attributes += " stroke-dasharray=\"0 %s\" stroke-dashoffset=\"%s\"" % [
					String.num(spacing, 4), String.num(spacing * 0.5, 4),
				]
			elif definition.line_style == ShapeDefinition.LineStyle.SEGMENTED:
				var spacing: float = path_length / float(mark_count)
				var drawn_length: float = minf(_effective_segment_length(definition), spacing * 0.9)
				stroke_attributes += " stroke-dasharray=\"%s %s\"" % [
					String.num(drawn_length, 4), String.num(spacing - drawn_length, 4),
				]
		var path_data: String = _svg_path_data(points, is_closed, offset + definition.offset)
		svg_shapes += "<path d=\"%s\" fill=\"%s\"%s%s/>" % [path_data, fill, fill_opacity, stroke_attributes]
	if svg_shapes.is_empty():
		return ""
	return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\">%s</svg>" % [
		width, height, width, height, svg_shapes,
	]


func _svg_path_data(points: PackedVector2Array, is_closed: bool, offset: Vector2) -> String:
	var point_count: int = points.size()
	if is_closed and points[0].is_equal_approx(points[point_count - 1]):
		point_count -= 1

	var path_data: String = ""
	for point_index: int in range(point_count):
		var point: Vector2 = points[point_index] + offset
		var command: String = "M" if point_index == 0 else "L"
		path_data += "%s%s %s " % [command, String.num(point.x, 4), String.num(point.y, 4)]
	if is_closed:
		path_data += "Z"
	return path_data


func _sync_definition_signals() -> void:
	for definition: ShapeDefinition in definitions:
		if definition != null and not definition.changed.is_connected(_on_definition_changed):
			definition.changed.connect(_on_definition_changed)


func _on_definition_changed() -> void:
	queue_redraw()