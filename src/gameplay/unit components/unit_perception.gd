@icon("res://addons/at-icons/node2d/eye.svg")

class_name UnitPerception
extends Area2D

var friendly_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var onsight_enemy_units: Array[Unit] = []

@export var _unit: Unit
@onready var sight_line: RayCast2D = $SightLine


func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

	for body in get_overlapping_bodies():
		_on_body_entered(body)
	
	await get_tree().create_timer(1.0).timeout
	_sight_line_check()


func _on_body_entered(body: Node2D) -> void:
	if body is Unit:
		if body.team == _unit.team:
			friendly_units.append(body)
		else:
			enemy_units.append(body)
		print("Unit entered perception area")


func _on_body_exited(body: Node2D) -> void:
	if body is Unit:
		friendly_units.erase(body)
		enemy_units.erase(body)


func _sight_line_check() -> void:
	if _unit.team == Unit.Team.YELLOW:
		sight_line.set_collision_mask_value(Unit.RED_LAYER, true)
		sight_line.set_collision_mask_value(Unit.YELLOW_LAYER, false)

	for enemy in enemy_units:
		sight_line.look_at(enemy.global_position)
		sight_line.force_raycast_update()
		if sight_line.get_collider() == enemy:
			if not onsight_enemy_units.has(enemy):
				onsight_enemy_units.append(enemy)
		else:
			onsight_enemy_units.erase(enemy)
	
	if _unit.team == Unit.Team.YELLOW:
		print("Sight check: enemy units in sight: " + str(onsight_enemy_units.size()))
	
	await get_tree().create_timer(_unit.class_definition.sight_update_interval).timeout
	_sight_line_check()
