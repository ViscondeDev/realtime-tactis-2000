extends Control

@onready var _speech_display: Label = %Label
@onready var _animation: AnimationPlayer = $AnimationPlayer

@export var _camera: YellowCamera
@export var _spawn_visibility: VisibleOnScreenNotifier2D

enum TutorialSteps {WELCOME, CONTROL_POINT,CAMERA, STRONG, QUICK, SMART, DISPENSER, DONE}

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
			speech_text = "Use the right mouse button \nto move the camera.\nscroll to zoom."
			_animation.play("new_task")
			await _camera.moved
			speech_text = "Find your units \nspawn point."
			_animation.play("spawn_highlight")
			await _spawn_visibility.screen_entered
			speech_text = "Here is your spawn point.\nNow, let's meet your team."
			_animation.play("new_text")
		TutorialSteps.QUICK:
			speech_text = "Use quick units to surprise your opponents."
		TutorialSteps.SMART:
			speech_text = "Make smart decisions and adapt your strategy."
		TutorialSteps.DISPENSER:
			speech_text = "Manage your resources and build dispensers for support."
		TutorialSteps.DONE:
			speech_text = "You're all set! Good luck!"
	_current_step += 1
