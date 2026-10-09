extends AnimationPlayer

const MAX_DAMAGE_SKEW = 0.5

@export var _unit: Unit
@export var skew_rate: float = 0:
	set(value):
		skew_rate = value
		if is_instance_valid(_unit):
			_unit.skew = _current_rand_skew * value

var _current_rand_skew: float = 0


func _on_take_damage():
	stop()
	play("take_damage")
	_randomize_skew()


func _randomize_skew():
	# randomize value between -MAX_DAMAGE_SKEW and MAX_DAMAGE_SKEW and apply to the unit body
	randomize()
	var rand_skew = randf_range(-MAX_DAMAGE_SKEW, MAX_DAMAGE_SKEW)
	_current_rand_skew = rand_skew
