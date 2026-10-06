@tool
class_name ControlPoint
extends Node2D

const CAPTURE_SECONDS: float = 10.0
const HEXAGON_RADIUS: float = 80.0
const HEXAGON_OUTLINE_WIDTH: float = 5.0
const PROGRESS_BAR_SIZE: Vector2 = Vector2(110.0, 18.0)
const PROGRESS_BAR_POSITION: Vector2 = Vector2(-55.0, 14.0)

@export_range(1.0, 1000.0, 1.0) var capture_radius: float = 160.0

var capture_progress: float = 0.0:
	set(value):
		capture_progress = clampf(value, -1.0, 1.0)
		queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var yellow_inside: bool = false
	var red_inside: bool = false
	var radius_squared: float = capture_radius * capture_radius
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit == null or unit.global_position.distance_squared_to(global_position) > radius_squared:
			continue
		if unit.team == Unit.Team.YELLOW:
			yellow_inside = true
		else:
			red_inside = true

	if yellow_inside == red_inside:
		return

	var progress_delta: float = delta / CAPTURE_SECONDS
	capture_progress += progress_delta if yellow_inside else -progress_delta


func _draw() -> void:
	var hexagon: PackedVector2Array = PackedVector2Array()
	for corner: int in range(6):
		var angle: float = -PI / 2.0 + TAU * float(corner) / 6.0
		hexagon.append(Vector2(cos(angle), sin(angle)) * HEXAGON_RADIUS)
	var closed_outline: PackedVector2Array = hexagon.duplicate()
	closed_outline.append(hexagon[0])

	draw_colored_polygon(hexagon, Color(1.0, 1.0, 1.0, 0.08))
	draw_polyline(closed_outline, Color.WHITE, HEXAGON_OUTLINE_WIDTH, true)
	_draw_progress_bar()


func _draw_progress_bar() -> void:
	var bar_rect: Rect2 = Rect2(PROGRESS_BAR_POSITION, PROGRESS_BAR_SIZE)
	var yellow_width: float = (capture_progress + 1.0) * 0.5 * PROGRESS_BAR_SIZE.x
	var yellow_color: Color = Color.html(Unit.TEAM_COLORS[Unit.Team.YELLOW])
	var red_color: Color = Color.html(Unit.TEAM_COLORS[Unit.Team.RED])

	draw_rect(bar_rect, Color(0.08, 0.08, 0.08, 0.9))
	if yellow_width > 0.0:
		draw_rect(Rect2(bar_rect.position, Vector2(yellow_width, bar_rect.size.y)), yellow_color)
	if yellow_width < bar_rect.size.x:
		draw_rect(
			Rect2(Vector2(bar_rect.position.x + yellow_width, bar_rect.position.y), Vector2(bar_rect.size.x - yellow_width, bar_rect.size.y)),
			red_color
		)
	draw_rect(bar_rect, Color.WHITE, false, 2.0, true)