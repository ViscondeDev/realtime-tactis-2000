@tool
@icon("res://addons/at-icons/node2d/hammer.svg")
class_name LevelBuilder
extends Node2D

const GENERATED_ROOT_NAME: StringName = &"GeneratedLevel"
const BORDER_SIZE: int = 180
const WALLS_COLLISION_LAYER_VALUE: int = 1  # Physics layer 1.

@export var navigation_agent_radius: float = 80.0
@export var floor_color: Color = Color("e6e6ee")
@export var void_and_obstacle_color: Color = Color("1b1b24")
@export var wall_line_color: Color = Color("5a5a6e")
@export var wall_line_width: float = 6.0

@export_tool_button("Rebuild Level", "Reload") var rebuild_level_action: Callable = rebuild_level

var _generated_root: Node2D


func _ready() -> void:
	rebuild_level()


func rebuild_level() -> void:
	if is_instance_valid(_generated_root):
		_generated_root.free()

	var floor_polygons: Array[PackedVector2Array] = []
	var obstacle_polygons: Array[PackedVector2Array] = []
	_collect_polygons(self, floor_polygons, obstacle_polygons)

	if floor_polygons.is_empty():
		return

	var wall_polylines: Array[PackedVector2Array] = LevelGeometry.compute_wall_polylines(floor_polygons, obstacle_polygons)

	# Not setting an owner on purpose: the generated nodes are rebuilt, never saved in the scene file.
	var generated_root: Node2D = Node2D.new()
	generated_root.name = GENERATED_ROOT_NAME
	add_child(generated_root)
	_generated_root = generated_root

	_build_visual(generated_root, floor_polygons, obstacle_polygons, wall_polylines)
	_build_navigation_region(generated_root, floor_polygons, obstacle_polygons)
	_build_wall_collision(generated_root, wall_polylines)


func _collect_polygons(
	node: Node,
	floor_polygons: Array[PackedVector2Array],
	obstacle_polygons: Array[PackedVector2Array]
) -> void:
	for child: Node in node.get_children():
		if child.name == GENERATED_ROOT_NAME:
			continue

		var level_polygon: LevelPolygon = child as LevelPolygon
		if level_polygon != null:
			var polygon_in_builder_space: PackedVector2Array = level_polygon.get_polygon_in_space_of(self)
			if polygon_in_builder_space.size() < 3:
				push_warning("LevelBuilder: '%s' has fewer than 3 points and was ignored." % level_polygon.name)
			elif level_polygon.polygon_kind == LevelPolygon.PolygonKind.FLOOR:
				floor_polygons.append(polygon_in_builder_space)
			else:
				obstacle_polygons.append(polygon_in_builder_space)

		_collect_polygons(child, floor_polygons, obstacle_polygons)


func _build_visual(
	parent: Node2D,
	floor_polygons: Array[PackedVector2Array],
	obstacle_polygons: Array[PackedVector2Array],
	wall_polylines: Array[PackedVector2Array]
) -> void:
	var level_visual: LevelVisual = LevelVisual.new()
	level_visual.floor_polygons = floor_polygons
	level_visual.obstacle_polygons = obstacle_polygons
	level_visual.wall_polylines = wall_polylines
	level_visual.floor_color = floor_color
	level_visual.obstacle_color = void_and_obstacle_color
	level_visual.wall_line_color = wall_line_color
	level_visual.wall_line_width = wall_line_width
	parent.add_child(level_visual)


func _build_navigation_region(
	parent: Node2D,
	floor_polygons: Array[PackedVector2Array],
	obstacle_polygons: Array[PackedVector2Array]
) -> void:
	# The baker merges all traversable outlines and subtracts the obstructions,
	# then shrinks the result by the agent radius.
	var source_geometry_data: NavigationMeshSourceGeometryData2D = NavigationMeshSourceGeometryData2D.new()
	for floor_polygon: PackedVector2Array in floor_polygons:
		source_geometry_data.add_traversable_outline(floor_polygon)
	for obstacle_polygon: PackedVector2Array in obstacle_polygons:
		source_geometry_data.add_obstruction_outline(obstacle_polygon)

	var navigation_polygon: NavigationPolygon = NavigationPolygon.new()
	navigation_polygon.agent_radius = navigation_agent_radius
	NavigationServer2D.bake_from_source_geometry_data(navigation_polygon, source_geometry_data)

	var navigation_region: NavigationRegion2D = NavigationRegion2D.new()
	navigation_region.navigation_polygon = navigation_polygon
	parent.add_child(navigation_region)


func _build_wall_collision(parent: Node2D, wall_polylines: Array[PackedVector2Array]) -> void:
	var wall_segments: PackedVector2Array = PackedVector2Array()
	for wall_polyline: PackedVector2Array in wall_polylines:
		for point_index: int in range(wall_polyline.size() - 1):
			wall_segments.append(wall_polyline[point_index])
			wall_segments.append(wall_polyline[point_index + 1])

	if wall_segments.is_empty():
		return

	var wall_shape: ConcavePolygonShape2D = ConcavePolygonShape2D.new()
	wall_shape.segments = wall_segments

	var wall_collision_shape: CollisionShape2D = CollisionShape2D.new()
	wall_collision_shape.shape = wall_shape

	var wall_body: StaticBody2D = StaticBody2D.new()
	wall_body.collision_layer = WALLS_COLLISION_LAYER_VALUE
	wall_body.collision_mask = 0
	wall_body.add_child(wall_collision_shape)
	parent.add_child(wall_body)