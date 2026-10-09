@tool
@icon("res://addons/at-icons/node2d/wing.svg")

class_name RespawnPoint
extends Node2D

const RING_RADIUS: float = 120.0
const RING_WIDTH: float = 10.0
const TEAM_DOT_RADIUS: float = 5.0

@export var team: Unit.Team = Unit.Team.YELLOW:
	set(value):
		team = value
		if is_instance_valid(_team_dot):
			_team_dot.fill_color = Color.html(Unit.TEAM_COLORS[team])

@onready var _shape_tool: ShapeTool = $ShapeTool
var _team_dot: ShapeDefinition


func _ready() -> void:
	var ring: ShapeDefinition = ShapeDefinition.new()
	ring.shape = ShapeDefinition.Shape.CIRCLE
	ring.radius = RING_RADIUS
	ring.fill_enabled = false
	ring.outline_color = Color.html("#263b46")
	ring.line_width = RING_WIDTH
	_team_dot = ShapeDefinition.new()
	_team_dot.shape = ShapeDefinition.Shape.DOT
	_team_dot.radius = TEAM_DOT_RADIUS
	_team_dot.fill_color = Color.html(Unit.TEAM_COLORS[team])
	_team_dot.outline_enabled = false
	_shape_tool.definitions = [ring, _team_dot]


func _draw() -> void:
	pass