class_name UnitDefinition
extends Resource

enum BodyShape { TRIANGLE, SQUARE, CIRCLE }

@export var display_name: String = "Unit"
@export var body_shape: BodyShape = BodyShape.CIRCLE
@export var body_color: Color = Color.WHITE
@export var body_radius: float = 16.0
@export var movement_speed: float = 150.0