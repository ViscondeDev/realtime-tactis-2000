extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var shape_tool: ShapeTool = ShapeTool.new()
	root.add_child(shape_tool)
	var definition: ShapeDefinition = shape_tool.definitions[0]
	definition.radius = ShapeTool.MAX_RADIUS
	assert(definition.radius == 500.0)
	assert(shape_tool._export_size() == Vector2i(1006, 1006))
	definition.mark_count = 1000
	definition.segment_length = 10000.0
	assert(shape_tool._effective_mark_count(definition) == ShapeTool.MAX_MARK_COUNT)
	assert(shape_tool._effective_segment_length(definition) == ShapeTool.MAX_RADIUS * 2.0)
	var too_many_definitions: Array[ShapeDefinition] = []
	for definition_index: int in range(ShapeTool.MAX_DEFINITION_COUNT + 1):
		too_many_definitions.append(ShapeDefinition.new())
	shape_tool.definitions = too_many_definitions
	assert(shape_tool.definitions.size() == 1)
	shape_tool.definitions = [definition]

	for candidate_shape: ShapeDefinition.Shape in [
		ShapeDefinition.Shape.CIRCLE,
		ShapeDefinition.Shape.SQUARE,
		ShapeDefinition.Shape.TRIANGLE,
		ShapeDefinition.Shape.HEXAGON,
		ShapeDefinition.Shape.LINE,
		ShapeDefinition.Shape.DOT,
	]:
		definition.shape = candidate_shape
		var shape_image: Image = Image.new()
		assert(shape_image.load_svg_from_string(shape_tool._build_svg()) == OK)
	for candidate_style: ShapeDefinition.LineStyle in [
		ShapeDefinition.LineStyle.CONTINUOUS,
		ShapeDefinition.LineStyle.DOTTED,
		ShapeDefinition.LineStyle.SEGMENTED,
	]:
		definition.line_style = candidate_style
		var style_image: Image = Image.new()
		assert(style_image.load_svg_from_string(shape_tool._build_svg()) == OK)

	shape_tool.definitions.clear()
	var left_shape: ShapeDefinition = ShapeDefinition.new()
	left_shape.shape = ShapeDefinition.Shape.CIRCLE
	left_shape.radius = 40.0
	left_shape.offset = Vector2(-100.0, 0.0)
	left_shape.fill_color = Color.RED
	left_shape.outline_enabled = false
	var right_shape: ShapeDefinition = ShapeDefinition.new()
	right_shape.shape = ShapeDefinition.Shape.HEXAGON
	right_shape.radius = 40.0
	right_shape.offset = Vector2(100.0, 0.0)
	right_shape.fill_color = Color.GREEN
	right_shape.outline_enabled = false
	shape_tool.definitions = [left_shape, right_shape]
	var combined_bounds: Rect2 = shape_tool._combined_bounds()
	var expected_export_size: Vector2i = shape_tool._export_size()
	assert(expected_export_size.x < 1024 and expected_export_size.y < 512)
	shape_tool.png_path = "user://shape_tool_smoke.png"
	await shape_tool._export_png()

	var exported_image: Image = Image.new()
	var load_error: Error = exported_image.load(ProjectSettings.globalize_path(shape_tool.png_path))
	assert(load_error == OK)
	assert(exported_image.get_size() == expected_export_size)
	var left_center: Vector2i = Vector2i(roundi(left_shape.offset.x - combined_bounds.position.x), roundi(-combined_bounds.position.y))
	var right_center: Vector2i = Vector2i(roundi(right_shape.offset.x - combined_bounds.position.x), roundi(-combined_bounds.position.y))
	var gap_center: Vector2i = Vector2i(roundi(-combined_bounds.position.x), roundi(-combined_bounds.position.y))
	var left_pixel: Color = exported_image.get_pixelv(left_center)
	var right_pixel: Color = exported_image.get_pixelv(right_center)
	assert(left_pixel.r > 0.9 and left_pixel.a > 0.9)
	assert(right_pixel.g > 0.9 and right_pixel.a > 0.9)
	assert(exported_image.get_pixelv(gap_center).a == 0.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(shape_tool.png_path))
	shape_tool.free()
	print("ShapeTool smoke test passed.")
	quit()