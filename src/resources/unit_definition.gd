class_name UnitDefinition
extends Resource

enum BodyShape {TRIANGLE, SQUARE, CIRCLE}
enum Team {BLUE, RED}

const TEAM_COLORS = {Team.BLUE: "#D5E839", Team.RED: "#E8594F"}

@export var display_name: String = "Unit"
@export var body_shape: BodyShape = BodyShape.CIRCLE
@export var body_team: Team = Team.BLUE
@export var body_radius: float = 16.0
@export var movement_speed: float = 150.0