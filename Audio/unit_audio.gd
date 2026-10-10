extends Node2D


@onready var unit: Unit = $".."
@onready var weapon_sfx_node: AudioStreamPlayer2D = $Weapon

# Map each class to its respective .tscn scene file
const CLASS_WEAPON_SCENES = {
	Unit.Class.STRONG: preload("res://Audio/weapon_class/machine_gun.tscn"),
	Unit.Class.QUICK: preload("res://Audio/weapon_class/mini_shotgun.tscn"),
	Unit.Class.SMART: preload("res://Audio/weapon_class/shotgun.tscn"),
}

# Map each class to its respective .tscn scene file
const DEAD_TEAM_SCENES = {
	Unit.Team.YELLOW: preload("res://Audio/dead_team/dead_friendly.tscn"),
	Unit.Team.RED: preload("res://Audio/dead_team/dead_enemy.tscn"),
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var weapon_resource = CLASS_WEAPON_SCENES[unit.unit_class]
	$Weapon.replace_by(weapon_resource.instantiate())
	
	var dead_resource = DEAD_TEAM_SCENES[unit.team]
	$Dead.replace_by(dead_resource.instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_unit_health_health_changed(_new_health: float) -> void:
	pass
	#if _new_health < _current_health:
		##$Hit.play()
		#print("qqq")
	#else:
		##$Heal.play()
		#print("heal")
	#_current_health = _new_health


func _on_unit_health_died() -> void:
	var dead_sfx_node = $Dead
	dead_sfx_node.reparent(get_tree().get_root())
	dead_sfx_node.play()
	dead_sfx_node.finished.connect(dead_sfx_node.queue_free)
