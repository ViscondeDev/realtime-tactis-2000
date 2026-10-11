extends Node2D

var prev_countdown_seconds = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func start_level() -> void:
	var music: AudioStreamPlayer = AudioGlobal.get_node("Music")
	var interactive_music := music.get_stream_playback() as AudioStreamPlaybackInteractive
	interactive_music.switch_to_clip_by_name("Level")

func timer_sfx(countdown_seconds_remaining) -> void:
	var countdown_seconds = ceil(countdown_seconds_remaining)
	if countdown_seconds == 0:
		$CountdownEnd.play()
	elif countdown_seconds < prev_countdown_seconds:
		$Countdown.play()
	prev_countdown_seconds = countdown_seconds
