extends Control

@onready var _speech_display: Label = %Label
@onready var _animation: AnimationPlayer = $AnimationPlayer

@export var _camera: YellowCamera
@export var _spawn_visibility: VisibleOnScreenNotifier2D
@export var _dispenser_visibility: VisibleOnScreenNotifier2D
@export var _unit_command_controller: UnitCommandController
@export var _yellow_dispenser: HealthDispenser
@export var _control_point: ControlPoint

enum TutorialSteps {WELCOME, CONTROL_POINT,CAMERA, STRONG, QUICK, SMART, DISPENSER, FIRST_COMMANDS, DONE}

var _current_step: TutorialSteps = TutorialSteps.WELCOME

var speech_text: String:
	set(value):
		speech_text = value
		_speech_display.text = value


func _ready() -> void:
	_update_step()

func _update_step() -> void:
	match _current_step:
		TutorialSteps.WELCOME:
			speech_text = "Welcome, commander!\nGet comfortable.\n\nThis is where you win wars."
			_animation.play("new_text")
		TutorialSteps.CONTROL_POINT:
			speech_text = "The goal:\nCapture and hold the control\npoint for two minutes."
			_animation.play("cp_Highlight")
		TutorialSteps.CAMERA:
			speech_text = "Use the right mouse button to move\nthe camera.\nUse the scroll to zoom."
			_animation.play("new_task")
			await _camera.moved
			speech_text = "Find your units spawn point."
			_animation.play("spawn_highlight")
			await _spawn_visibility.screen_entered
			if not _spawn_visibility.is_on_screen():
				await _spawn_visibility.screen_entered
			speech_text = "Here is your spawn point.\n\nNow, let's meet your team."
			_animation.play("new_text")
		TutorialSteps.STRONG:
			speech_text = "This is Strong.\n\nTough guy..."
			_animation.play("strong")
		TutorialSteps.QUICK:
			speech_text = "This is Quick.\n\nIt loves getting behind the enemy\n lines."
			_animation.play("quick")
		TutorialSteps.SMART:
			speech_text = "This is Smart.\n\nEssential to keep a team alive."
			_animation.play("smart")
		TutorialSteps.DISPENSER:
			speech_text = "Smart units can build health \ndispensers."
			_animation.play("new_text")
		TutorialSteps.FIRST_COMMANDS:
			speech_text = "Issue your first commands.\n\nClick and drag on a unit."
			_animation.play("first_commands")
			await _unit_command_controller.order_issued
			speech_text = "Find a dispenser site.\nLook for a cross inside a circle."
			_animation.play("dispenser_task")
			await _animation.animation_finished
			if not _dispenser_visibility.is_on_screen():
				await _dispenser_visibility.screen_entered
			speech_text = "Issue the smart unit to enter the\n dispenser site.\n\nIt takes 5 seconds to build."
			_animation.play("new_task")
			await _yellow_dispenser.built
			speech_text = "Units heal and when near a \ndispenser.\nNow, capture the control point.\nMantain yellow units inside it!"
			_control_point.process_mode = PROCESS_MODE_INHERIT
			_animation.play("build_dispenser")
			await _control_point.taken_over
			speech_text = "Keep the control point for 90 \nseconds to win. \n\nLet's get you in a real battle!"
			_animation.play("new_text")
		TutorialSteps.DONE:
			speech_text = "You're all set! Good luck!"
			_animation.play("new_text")
			await get_tree().create_timer(2.0).timeout
			Game.current.return_to_menu()
	_current_step += 1
	AudioGlobal.get_node("Order").play()
