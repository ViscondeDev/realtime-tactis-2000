class_name UnitProjectile
extends CharacterBody2D

const YELLOW_TEAM: int = 0
const RED_TEAM: int = 1
const YELLOW_LAYER: int = 2
const RED_LAYER: int = 3
const GOALS_LAYER: int = 5

var _pool: Node
var _team: int
var _damage: float
var _speed: float
var _remaining_range: float
var _active: bool = false

@onready var _projectile_visual: Polygon2D = $Polygon2D


func _ready() -> void:
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	hide()


func activate(
	pool: Node,
	spawn_position: Vector2,
	direction: Vector2,
	team: int,
	damage: float,
	speed: float,
	max_range: float
) -> void:
	_pool = pool
	_team = team
	_damage = damage
	_speed = speed
	_remaining_range = maxf(max_range, 0.0)
	global_position = spawn_position
	rotation = direction.angle()
	velocity = direction.normalized() * _speed
	collision_layer = 0
	collision_mask = 1 | (1 << (RED_LAYER - 1) if team == YELLOW_TEAM else 1 << (YELLOW_LAYER - 1)) | (1 << (GOALS_LAYER - 1))
	_projectile_visual.color = Color("#e8e84b") if team == YELLOW_TEAM else Color("#e8594f")
	_active = true
	show()
	set_physics_process(true)


func deactivate() -> void:
	_active = false
	velocity = Vector2.ZERO
	collision_mask = 0
	set_physics_process(false)
	hide()


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var travel_distance: float = minf(_speed * delta, _remaining_range)
	var collision: KinematicCollision2D = move_and_collide(velocity.normalized() * travel_distance)
	_remaining_range -= travel_distance
	if collision != null:
		var hit_unit: Unit = collision.get_collider() as Unit
		if hit_unit != null and hit_unit.team != _team and is_instance_valid(hit_unit.unit_health):
			hit_unit.unit_health.take_damage(_damage)
		var hit_structure: Object = collision.get_collider()
		if hit_structure.has_method("take_damage") and int(hit_structure.get("team")) != _team:
			hit_structure.call("take_damage", _damage)
		_pool.call("recycle", self)
	elif _remaining_range <= 0.0:
		_pool.call("recycle", self)