@icon("res://addons/at-icons/node2d/eye.svg")

class_name UnitPerception
extends Area2D

var friendly_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var onsight_enemy_units: Array[Unit] = []

@export var _unit: Unit
@onready var sight_line: RayCast2D = $SightLine


func _ready() -> void:
	if not _unit.is_node_ready():
		await _unit.ready

	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

	for body in get_overlapping_bodies():
		_on_body_entered(body)
	
	while is_inside_tree():
		_sight_line_check()
		await get_tree().create_timer(_unit.class_definition.sight_update_interval).timeout


func _on_body_entered(body: Node2D) -> void:
	if body is Unit:
		if body.team == _unit.team:
			friendly_units.append(body)
		else:
			enemy_units.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is Unit:
		friendly_units.erase(body)
		enemy_units.erase(body)
		onsight_enemy_units.erase(body)


func _sight_line_check() -> void:
	if _unit.team == Unit.Team.YELLOW:
		sight_line.set_collision_mask_value(Unit.RED_LAYER, true)
		sight_line.set_collision_mask_value(Unit.YELLOW_LAYER, false)
	elif _unit.team == Unit.Team.RED:
		sight_line.set_collision_mask_value(Unit.YELLOW_LAYER, true)
		sight_line.set_collision_mask_value(Unit.RED_LAYER, false)

	for enemy in enemy_units:
		sight_line.look_at(enemy.global_position)
		sight_line.force_raycast_update()
		if sight_line.get_collider() == enemy:
			if not onsight_enemy_units.has(enemy):
				onsight_enemy_units.append(enemy)
		else:
			onsight_enemy_units.erase(enemy)
