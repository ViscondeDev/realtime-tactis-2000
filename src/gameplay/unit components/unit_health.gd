@icon("res://addons/at-icons/node/heart.svg")
class_name UnitHealth
extends Node

signal health_changed(new_health: float)
signal died

@export var _unit: Unit

var _max_health: float
var _current_health: float

var max_health: float:
	get:
		return _max_health

var current_health: float:
	get:
		return _current_health


func _ready() -> void:
	if not _unit.is_node_ready():
		await _unit.ready
	_max_health = _unit.class_definition.max_health
	_current_health = _max_health
	health_changed.emit(_current_health)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or _current_health <= 0.0:
		return
	_set_current_health(_current_health - amount)


func heal(amount: float) -> void:
	if amount <= 0.0 or _current_health <= 0.0:
		return
	_set_current_health(_current_health + amount)


func _set_current_health(value: float) -> void:
	var previous_health: float = _current_health
	_current_health = clampf(value, 0.0, _max_health)
	health_changed.emit(_current_health)
	if previous_health > 0.0 and _current_health == 0.0:
		died.emit()