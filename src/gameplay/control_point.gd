@tool
@icon("res://addons/at-icons/node2d/target.svg")

class_name ControlPoint
extends Node2D

const CAPTURE_SECONDS: float = 5.0
const HEXAGON_RADIUS: float = 80.0
const HEXAGON_OUTLINE_WIDTH: float = 5.0
const PROGRESS_BAR_SIZE: Vector2 = Vector2(110.0, 18.0)
const PROGRESS_BAR_POSITION: Vector2 = Vector2(-55.0, 14.0)

const SHAPE_DEFINITIONS = {
	Unit.Team.RED :
		{
			"segmented_outline" : "uid://72xvfwvamx5d",
			"small_hexagon" : "uid://b6ever8neba32",
			"medium_hexagon" : "uid://d4kv6oddpp7hs",
			"big_hexagon" : "uid://k5ov6sdd3q5r"
		},
		Unit.Team.YELLOW:
			{
				"segmented_outline" : "uid://72xvfwvamx5d",
				"small_hexagon" : "uid://bd2r4n7qvyvv0",
				"medium_hexagon" : "uid://dfb7o2hokg5ke",
				"big_hexagon" : "uid://dr8wcvx05qn2"
			}
}

@export_range(1.0, 1000.0, 1.0) var capture_radius: float = 160.0
@onready var shape: ShapeTool = $ShapeTool

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

func takeover(team: Unit.Team):
	print("Takeover called for team: %s" % team)
	shape.definitions.clear()
	shape.definitions = [load(SHAPE_DEFINITIONS[team]["segmented_outline"])]
	
	var small_hexagon : ShapeDefinition = load(SHAPE_DEFINITIONS[team]["small_hexagon"])
	var medium_hexagon : ShapeDefinition = load(SHAPE_DEFINITIONS[team]["medium_hexagon"])
	var big_hexagon : ShapeDefinition = load(SHAPE_DEFINITIONS[team]["big_hexagon"])

	for s: ShapeDefinition in [small_hexagon, medium_hexagon, big_hexagon]:
		shape.definitions.push_front(s)
		await get_tree().create_timer(0.2).timeout
		shape.queue_redraw()