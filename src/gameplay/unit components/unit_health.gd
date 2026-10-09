@icon("res://addons/at-icons/node/heart.svg")
class_name UnitHealth
extends Node

signal health_changed(new_health: float)
signal died

const OVERHEAL_MULTIPLIER: float = 1.5
const OVERHEAL_DECAY_SECONDS: float = 7.0

@export var _unit: Unit

var _max_health: float
var _current_health: float
var _overheal_sources: Dictionary[int, WeakRef] = {}

var max_health: float:
	get:
		return _max_health

var current_health: float:
	get:
		return _current_health

var overheal_max_health: float:
	get:
		return _max_health * OVERHEAL_MULTIPLIER


func _ready() -> void:
	if not _unit.is_node_ready():
		await _unit.ready
	_max_health = _unit.class_definition.max_health
	_current_health = _max_health
	health_changed.emit(_current_health)
	_update_low_health_report()
	set_process(true)


func _process(delta: float) -> void:
	_prune_overheal_sources()
	if not _overheal_sources.is_empty() or _current_health <= _max_health:
		return
	_set_current_health(_current_health - _max_health * (OVERHEAL_MULTIPLIER - 1.0) * delta / OVERHEAL_DECAY_SECONDS)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or _current_health <= 0.0:
		return
	_set_current_health(_current_health - amount)


func heal(amount: float) -> void:
	if amount <= 0.0 or _current_health <= 0.0:
		return
	_set_current_health(_current_health + amount)


func set_overheal_source(source: Node, active: bool) -> void:
	if not is_instance_valid(source):
		return
	var source_id: int = source.get_instance_id()
	if active:
		_overheal_sources[source_id] = weakref(source)
	else:
		_overheal_sources.erase(source_id)


func healing_ceiling(overheal_allowed: bool) -> float:
	return overheal_max_health if overheal_allowed else _max_health


func _set_current_health(value: float) -> void:
	var previous_health: float = _current_health
	var allowed_health: float = _max_health * (OVERHEAL_MULTIPLIER if not _overheal_sources.is_empty() else 1.0)
	var health_ceiling: float = maxf(_current_health, allowed_health)
	_current_health = clampf(value, 0.0, health_ceiling)
	health_changed.emit(_current_health)
	_update_low_health_report()
	if previous_health > 0.0 and _current_health == 0.0:
		died.emit()


func _prune_overheal_sources() -> void:
	for source_id: int in _overheal_sources.keys():
		var source: Object = _overheal_sources[source_id].get_ref()
		if not is_instance_valid(source):
			_overheal_sources.erase(source_id)


func _update_low_health_report() -> void:
	var is_low_health: bool = _max_health > 0.0 and _current_health / _max_health <= 0.3
	_unit.set_condition(&"low_health", is_low_health)
