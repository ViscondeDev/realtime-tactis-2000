@icon("res://addons/at-icons/node2d/diamond.svg")
class_name Unit
extends CharacterBody2D

enum Class {STRONG, QUICK, SMART}
enum Team {YELLOW, RED}

const TEAM_COLORS = {Team.YELLOW: "#D5E839", Team.RED: "#E8594F"}
const CLASS_RESOURCES = {Class.STRONG: "uid://beiw7m8hmc0nj", Class.QUICK: "uid://ch8prcptxdl31", Class.SMART: "uid://c3yjuhcf2tds4"}

const COMMANDABLE_UNITS_GROUP: StringName = &"commandable_units"
const SELECTION_PADDING_PIXELS: float = 100

@export var team: Team = Team.YELLOW
@export var unit_class: Class = Class.STRONG

@onready var class_definition: ClassDefinition = load(CLASS_RESOURCES[unit_class])
@onready var unit_movement: UnitMovement = %UnitMovement
@onready var unit_shape_renderer: UnitShapeRenderer = %UnitShapeRenderer


func _ready() -> void:
	add_to_group(COMMANDABLE_UNITS_GROUP)

	if team == Team.YELLOW:
		set_collision_layer_value(2, true)
		set_collision_mask_value(3, true)
	elif team == Team.RED:
		set_collision_layer_value(3, true)
		set_collision_mask_value(2, true)

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
