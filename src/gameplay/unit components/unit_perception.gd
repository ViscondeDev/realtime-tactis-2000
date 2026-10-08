@icon("res://addons/at-icons/node2d/eye.svg")

class_name UnitPerception
extends Area2D

var friendly_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var areas: Array[HealthDispenser] = []
var onsight_friendly_units: Array[Unit] = []
var onsight_enemy_units: Array[Unit] = []
var onsight_areas: Array[HealthDispenser] = []

@export var _unit: Unit
@onready var sight_line: RayCast2D = $SightLine


func _ready() -> void:
	if not _unit.is_node_ready():
		await _unit.ready

	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	sight_line.add_exception(_unit)

	for body in get_overlapping_bodies():
		_on_body_entered(body)
	
	while is_inside_tree():
		_sight_line_check()
		await get_tree().create_timer(_unit.class_definition.sight_update_interval).timeout


func _on_body_entered(body: Node2D) -> void:
	if body is Unit:
		if body.team == _unit.team:
			if not friendly_units.has(body):
				friendly_units.append(body)
		else:
			if not enemy_units.has(body):
				enemy_units.append(body)
	elif body is HealthDispenser:
		areas.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is Unit:
		friendly_units.erase(body)
		enemy_units.erase(body)
		onsight_friendly_units.erase(body)
		onsight_enemy_units.erase(body)
	elif body is HealthDispenser:
		areas.erase(body)
		onsight_areas.erase(body)


func can_see_position(world_position: Vector2) -> bool:
	var perception_shape: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
	if perception_shape == null:
		return false
	if _unit.global_position.distance_squared_to(world_position) > perception_shape.radius * perception_shape.radius:
		return false

	var original_target_position: Vector2 = sight_line.target_position
	sight_line.target_position = sight_line.to_local(world_position)
	sight_line.force_raycast_update()
	var has_line_of_sight: bool = not sight_line.is_colliding()
	sight_line.target_position = original_target_position
	return has_line_of_sight


func _sight_line_check() -> void:
	sight_line.set_collision_mask_value(Unit.YELLOW_LAYER, true)
	sight_line.set_collision_mask_value(Unit.RED_LAYER, true)
	sight_line.set_collision_mask_value(HealthDispenser.GOALS_LAYER, true)
	sight_line.set_collision_mask_value(HealthDispenser.BUILD_SITES_LAYER, true)

	_update_visible_unit(friendly_units, onsight_friendly_units)
	_update_visible_unit(enemy_units, onsight_enemy_units)
	_update_visible_area(areas, onsight_areas)
	
	var visible_allies: int = 1 if _unit.unit_health.current_health > 0.0 else 0
	var visible_enemies: int = 0
	for ally: Unit in onsight_friendly_units:
		if is_instance_valid(ally) and ally.unit_health.current_health > 0.0:
			visible_allies += 1
	for enemy: Unit in onsight_enemy_units:
		if is_instance_valid(enemy) and enemy.unit_health.current_health > 0.0:
			visible_enemies += 1
	_unit.set_condition(&"outnumbered", visible_enemies > visible_allies)


func _update_visible_unit(candidates: Array[Unit], visible_units: Array[Unit]) -> void:
	for candidate: Unit in candidates:
		if not is_instance_valid(candidate) or candidate.unit_health.current_health <= 0.0:
			visible_units.erase(candidate)
			continue
		sight_line.look_at(candidate.global_position)
		sight_line.force_raycast_update()
		if sight_line.get_collider() == candidate:
			if not visible_units.has(candidate):
				visible_units.append(candidate)
		else:
			visible_units.erase(candidate)

func _update_visible_area(candidates: Array[HealthDispenser], visible_areas: Array[HealthDispenser]) -> void:
	for candidate: HealthDispenser in candidates:
		if not is_instance_valid(candidate):
			visible_areas.erase(candidate)
			continue
		sight_line.look_at(candidate.global_position)
		sight_line.force_raycast_update()
		if sight_line.get_collider() == candidate:
			if not visible_areas.has(candidate):
				visible_areas.append(candidate)
		else:
			visible_areas.erase(candidate)
