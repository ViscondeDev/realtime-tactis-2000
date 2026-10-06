@icon("res://addons/at-icons/node2d/ammunition.svg")
class_name UnitProjectilePool
extends Node2D

const PROJECTILE_SCENE: PackedScene = preload("res://src/gameplay/unit_projectile.tscn")
const CLASS_RESOURCE_PATHS: Array[String] = [
	"res://src/resources/classes/quick.tres",
	"res://src/resources/classes/smart.tres",
	"res://src/resources/classes/strong.tres",
]

@export_range(0, 512, 1) var initial_pool_size: int = 48

var _inactive_projectiles: Array[CharacterBody2D] = []
var _active_projectiles: Array[CharacterBody2D] = []
var _cull_bounds: Rect2
var _has_cull_bounds: bool = false
var _cull_padding: float = 0.0


func _ready() -> void:
	_cull_padding = _get_max_projectile_range()
	for _index: int in range(initial_pool_size):
		_inactive_projectiles.append(_create_projectile())


func _process(_delta: float) -> void:
	if not _has_cull_bounds:
		_refresh_cull_bounds()
	if not _has_cull_bounds:
		return

	for projectile_index: int in range(_active_projectiles.size() - 1, -1, -1):
		var projectile: CharacterBody2D = _active_projectiles[projectile_index]
		if not is_instance_valid(projectile) or not _cull_bounds.has_point(projectile.global_position):
			recycle(projectile)


func fire(
	spawn_position: Vector2,
	direction: Vector2,
	team: int,
	damage: float,
	speed: float,
	max_range: float
) -> void:
	if direction.is_zero_approx() or max_range <= 0.0:
		return
	var projectile: CharacterBody2D = _inactive_projectiles.pop_back() if not _inactive_projectiles.is_empty() else _create_projectile()
	_active_projectiles.append(projectile)
	projectile.call("activate", self, spawn_position, direction, team, damage, speed, max_range)


func recycle(projectile: CharacterBody2D) -> void:
	if not is_instance_valid(projectile) or not _active_projectiles.has(projectile):
		return
	_active_projectiles.erase(projectile)
	projectile.call("deactivate")
	_inactive_projectiles.append(projectile)


func _create_projectile() -> CharacterBody2D:
	var projectile: CharacterBody2D = PROJECTILE_SCENE.instantiate() as CharacterBody2D
	add_child(projectile)
	return projectile


func _refresh_cull_bounds() -> void:
	var level_visual: LevelVisual = get_node_or_null("../LevelBuilder/GeneratedLevel/LevelVisual") as LevelVisual
	if level_visual == null:
		return

	var minimum: Vector2 = Vector2(INF, INF)
	var maximum: Vector2 = Vector2(-INF, -INF)
	for polygon: PackedVector2Array in level_visual.floor_polygons:
		for point: Vector2 in polygon:
			var world_point: Vector2 = level_visual.to_global(point)
			minimum.x = minf(minimum.x, world_point.x)
			minimum.y = minf(minimum.y, world_point.y)
			maximum.x = maxf(maximum.x, world_point.x)
			maximum.y = maxf(maximum.y, world_point.y)

	if minimum.x == INF:
		return
	_cull_bounds = Rect2(minimum, maximum - minimum).grow(_cull_padding)
	_has_cull_bounds = true


func _get_max_projectile_range() -> float:
	var maximum_range: float = 0.0
	for resource_path: String in CLASS_RESOURCE_PATHS:
		var class_definition: ClassDefinition = load(resource_path) as ClassDefinition
		if class_definition != null:
			maximum_range = maxf(maximum_range, class_definition.attack_range)
	return maximum_range