extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func start_level() -> void:
	## AUDIO ##
	var music: AudioStreamPlayer = AudioGlobal.get_node("Music")
	var interactive_music := music.get_stream_playback() as AudioStreamPlaybackInteractive
	interactive_music.switch_to_clip_by_name("Level")
	## AUDIO END ##
