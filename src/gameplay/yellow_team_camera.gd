extends Camera2D

const EDGE_MARGIN_PIXELS: float = 250.0
const POSITION_SMOOTHING_SPEED: float = 2.0
const ZOOM_SMOOTHING_SPEED: float = 2.5
const CONTROL_POINTS_GROUP: StringName = &"control_points"

var _has_initial_frame: bool = false


func _ready() -> void:
	make_current()
	position_smoothing_enabled = false


func _process(delta: float) -> void:
	var yellow_units: Array[Unit] = []
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Unit.Team.YELLOW and unit.unit_health.current_health > 0.0:
			yellow_units.append(unit)

	if yellow_units.is_empty():
		return

	var bounds_min: Vector2 = yellow_units[0].global_position
	var bounds_max: Vector2 = bounds_min
	for unit: Unit in yellow_units:
		var radius: float = unit.class_definition.body_radius
		var unit_min: Vector2 = unit.global_position - Vector2.ONE * radius
		var unit_max: Vector2 = unit.global_position + Vector2.ONE * radius
		bounds_min = bounds_min.min(unit_min)
		bounds_max = bounds_max.max(unit_max)
	for node: Node in get_tree().get_nodes_in_group(CONTROL_POINTS_GROUP):
		var control_point: ControlPoint = node as ControlPoint
		if control_point == null:
			continue
		var radius: float = ControlPoint.HEXAGON_RADIUS
		var point_min: Vector2 = control_point.global_position - Vector2.ONE * radius
		var point_max: Vector2 = control_point.global_position + Vector2.ONE * radius
		bounds_min = bounds_min.min(point_min)
		bounds_max = bounds_max.max(point_max)

	var target_position: Vector2 = (bounds_min + bounds_max) * 0.5
	var viewport_size: Vector2 = get_viewport_rect().size
	var framed_size: Vector2 = bounds_max - bounds_min + Vector2.ONE * EDGE_MARGIN_PIXELS * 2.0
	var fit_zoom: float = minf(viewport_size.x / framed_size.x, viewport_size.y / framed_size.y)
	var target_zoom: Vector2 = Vector2.ONE * fit_zoom

	if not _has_initial_frame:
		global_position = target_position
		zoom = target_zoom
		_has_initial_frame = true
		return

	var position_weight: float = 1.0 - exp(-POSITION_SMOOTHING_SPEED * delta)
	var zoom_weight: float = 1.0 - exp(-ZOOM_SMOOTHING_SPEED * delta)
	global_position = global_position.lerp(target_position, position_weight)
	zoom = zoom.lerp(target_zoom, zoom_weight)