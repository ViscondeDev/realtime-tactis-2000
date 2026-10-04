class_name Unit
extends CharacterBody2D

const COMMANDABLE_UNITS_GROUP: StringName = &"commandable_units"
const SELECTION_PADDING_PIXELS: float = 200

@export var definition: UnitDefinition

@onready var unit_movement: UnitMovement = $UnitMovement
@onready var unit_shape_renderer: UnitShapeRenderer = $UnitShapeRenderer


func _ready() -> void:
	add_to_group(COMMANDABLE_UNITS_GROUP)

	var body_collision_shape: CircleShape2D = CircleShape2D.new()
	body_collision_shape.radius = definition.body_radius
	$CollisionShape2D.shape = body_collision_shape

	unit_movement.movement_speed = definition.movement_speed
	unit_shape_renderer.definition = definition


func issue_move_order(target_position: Vector2) -> void:
	unit_movement.move_to(target_position)


func is_point_over_unit(world_position: Vector2) -> bool:
	var pick_radius: float = definition.body_radius + SELECTION_PADDING_PIXELS
	return global_position.distance_to(world_position) <= pick_radius