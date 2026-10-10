extends Node2D


@onready var unit: Unit = $".."
@onready var weapon_sfx_node: AudioStreamPlayer2D = $Weapon

# Map each class to its respective .tscn scene file
const CLASS_WEAPON_SCENES = {
	Unit.Class.STRONG: preload("res://Audio/weapon_class/machine_gun.tscn"),
	Unit.Class.QUICK: preload("res://Audio/weapon_class/mini_shotgun.tscn"),
	Unit.Class.SMART: preload("res://Audio/weapon_class/shotgun.tscn"),
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var weapon_resource = CLASS_WEAPON_SCENES[unit.unit_class]
	$Weapon.replace_by(weapon_resource.instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_unit_health_health_changed(new_health: float) -> void:
	pass
	#if new_health < _current_health:
		##$Hit.play()
		#print("qqq")
	#else:
		##$Heal.play()
		#print("heal")
	#_current_health = new_health
