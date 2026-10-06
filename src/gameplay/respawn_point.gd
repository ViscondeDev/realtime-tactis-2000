@tool
@icon("res://addons/at-icons/node2d/wing.svg")

class_name RespawnPoint
extends Node2D

const RING_RADIUS: float = 120.0
const RING_WIDTH: float = 10.0
const TEAM_DOT_RADIUS: float = 20.0

@export var team: Unit.Team = Unit.Team.YELLOW:
	set(value):
		team = value
		queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 48, Color.WHITE, RING_WIDTH, true)
	draw_circle(Vector2.ZERO, TEAM_DOT_RADIUS, Color.html(Unit.TEAM_COLORS[team]))