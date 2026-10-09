@icon("res://addons/at-icons/node2d/diamond.svg")
class_name Unit
extends CharacterBody2D

enum Class {STRONG, QUICK, SMART}
enum Team {YELLOW, RED}

const TEAM_COLORS = {Team.YELLOW: "#F2C94C", Team.RED: "#D94747"}
const CLASS_RESOURCES = {Class.STRONG: "uid://beiw7m8hmc0nj", Class.QUICK: "uid://ch8prcptxdl31", Class.SMART: "uid://c3yjuhcf2tds4"}

const COMMANDABLE_UNITS_GROUP: StringName = &"commandable_units"
const SELECTION_PADDING_PIXELS: float = 100

const YELLOW_LAYER:int = 2
const RED_LAYER:int = 3
const COLLECTABLES_LAYER:int = 4

signal condition_changed(condition: StringName, active: bool)
signal report_condition_changed(condition: StringName, active: bool)

@export var team: Team = Team.YELLOW
@export var unit_class: Class = Class.STRONG
@export var projectile_pool: UnitProjectilePool

@onready var class_definition: ClassDefinition = load(CLASS_RESOURCES[unit_class])
@onready var unit_movement: UnitMovement = %UnitMovement
@onready var unit_perception: UnitPerception = %UnitPerception
@onready var unit_shape_renderer: UnitShapeRenderer = %UnitShapeRenderer
@onready var unit_autonomous_behavior: UnitAutonomousBehavior = %UnitAutonomousBehavior
@onready var unit_health: UnitHealth = $Behavior/UnitHealth
@onready var shot_particles: GPUParticles2D = $Rendering/ShotParticles
@onready var death_particles: GPUParticles2D = $Rendering/DeathParticles

var _conditions: Dictionary = {}


func _ready() -> void:
	add_to_group(COMMANDABLE_UNITS_GROUP)

	if team == Team.YELLOW:
		set_collision_layer_value(YELLOW_LAYER, true)
		set_collision_mask_value(RED_LAYER, true)
	elif team == Team.RED:
		set_collision_layer_value(RED_LAYER, true)
		set_collision_mask_value(YELLOW_LAYER, true)

	var body_collision_shape: CircleShape2D = CircleShape2D.new()
	body_collision_shape.radius = class_definition.body_radius
	$CollisionShape2D.shape = body_collision_shape

	unit_movement.movement_speed = class_definition.movement_speed
	unit_autonomous_behavior.projectile_pool = projectile_pool
	unit_shape_renderer.unit = self
	unit_health.died.connect(_die)


func issue_move_order(target_position: Vector2) -> void:
	unit_autonomous_behavior.on_player_move_order_issued()
	unit_movement.move_to(target_position)


func set_condition(condition: StringName, active: bool) -> void:
	if _conditions.get(condition, false) == active:
		return
	_conditions[condition] = active
	condition_changed.emit(condition, active)
	report_condition_changed.emit(condition, active)


func is_report_condition_active(condition: StringName) -> bool:
	return _conditions.get(condition, false)


func is_point_over_unit(world_position: Vector2) -> bool:
	var pick_radius: float = class_definition.body_radius + SELECTION_PADDING_PIXELS
	return global_position.distance_to(world_position) <= pick_radius


func _die():
	unit_shape_renderer.visible = false
	death_particles.emitting = true
	process_mode = Node.PROCESS_MODE_DISABLED
	await death_particles.finished
	queue_free()
