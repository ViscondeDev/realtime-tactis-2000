class_name ClassDefinition
extends Resource

enum BodyShape {TRIANGLE, SQUARE, CIRCLE}

@export var display_name: String = "Unit"
@export var body_shape: BodyShape = BodyShape.CIRCLE
@export var body_radius: float = 16.0
@export var movement_speed: float = 150.0
@export var sight_update_interval: float = 0.5