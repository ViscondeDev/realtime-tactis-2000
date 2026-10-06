class_name ClassDefinition
extends Resource

enum BodyShape {TRIANGLE, SQUARE, CIRCLE}

@export_category("Unit")
@export var display_name: String = "Unit"
@export var body_shape: BodyShape = BodyShape.CIRCLE
@export var body_radius: float = 16.0

@export_group("Movement")
@export var movement_speed: float = 150.0
@export var sight_update_interval: float = 0.5

@export_group("Combat")
@export var max_health: float = 100.0
@export var fire_interval: float = 1.0
@export var hp_per_shot: float = 10