extends GPUParticles2D


@export var _unit:Unit

func _ready() -> void:
	if _unit.team == Unit.Team.RED:
		process_material = load("uid://dvva10ym4a276")
	else:
		process_material = load("uid://cn38iqhxrk58e")