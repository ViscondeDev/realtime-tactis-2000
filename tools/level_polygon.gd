@tool
@icon("res://addons/at-icons/node2d/mesh_plane.svg")

class_name LevelPolygon
extends Line2D

enum PolygonKind { FLOOR, OBSTACLE }

const FLOOR_EDITOR_COLOR: Color = Color(0.25, 0.85, 0.5)
const OBSTACLE_EDITOR_COLOR: Color = Color(0.95, 0.35, 0.35)
const EDITOR_LINE_WIDTH: float = 4.0

@export var polygon_kind: PolygonKind = PolygonKind.FLOOR:
	set(new_polygon_kind):
		polygon_kind = new_polygon_kind
		_apply_editor_appearance()


func _ready() -> void:
	closed = true
	width = EDITOR_LINE_WIDTH
	_apply_editor_appearance()
	# This node is only authoring data. The builder generates the real visuals and collisions.
	if not Engine.is_editor_hint():
		hide()


func get_polygon_in_space_of(reference_node: Node2D) -> PackedVector2Array:
	# Zero-length edges (duplicate points) break normalization and clipping, so drop them.
	var cleaned_points: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		var last_index: int = cleaned_points.size() - 1
		if cleaned_points.is_empty() or not cleaned_points[last_index].is_equal_approx(point):
			cleaned_points.append(point)

	var last_cleaned_index: int = cleaned_points.size() - 1
	if cleaned_points.size() > 1 and cleaned_points[0].is_equal_approx(cleaned_points[last_cleaned_index]):
		cleaned_points.remove_at(last_cleaned_index)

	var transform_to_reference_space: Transform2D = reference_node.global_transform.affine_inverse() * global_transform
	return transform_to_reference_space * cleaned_points


func _apply_editor_appearance() -> void:
	default_color = FLOOR_EDITOR_COLOR if polygon_kind == PolygonKind.FLOOR else OBSTACLE_EDITOR_COLOR