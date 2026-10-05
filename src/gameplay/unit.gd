@icon("res://addons/at-icons/node2d/icons.svg")
class_name Unit
extends CharacterBody2D

enum Team {YELLOW, RED}
const TEAM_COLORS = {Team.YELLOW: "#D5E839", Team.RED: "#E8594F"}

const COMMANDABLE_UNITS_GROUP: StringName = &"commandable_units"
const SELECTION_PADDING_PIXELS: float = 100

@export var class_definition: ClassDefinition
@export var team: Team = Team.YELLOW
@onready var unit_movement: UnitMovement = $UnitMovement
@onready var unit_shape_renderer: UnitShapeRenderer = $UnitShapeRenderer


func _ready() -> void:
	add_to_group(COMMANDABLE_UNITS_GROUP)

	var body_collision_shape: CircleShape2D = CircleShape2D.new()
	body_collision_shape.radius = class_definition.body_radius
	$CollisionShape2D.shape = body_collision_shape

	unit_movement.movement_speed = class_definition.movement_speed
	unit_shape_renderer.unit = self


func issue_move_order(target_position: Vector2) -> void:
	unit_movement.move_to(target_position)


func is_point_over_unit(world_position: Vector2) -> bool:
	var pick_radius: float = class_definition.body_radius + SELECTION_PADDING_PIXELS
	return global_position.distance_to(world_position) <= pick_radius
