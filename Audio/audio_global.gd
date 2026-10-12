extends Node2D

var prev_countdown_seconds = 100
var _tween = create_tween()

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
		start_level()
	elif countdown_seconds < prev_countdown_seconds:
		$Countdown.play()
	prev_countdown_seconds = countdown_seconds

func control_point_enemy() -> void:
	# Stop the previous tween if it's still running
	if _tween.is_valid():
		_tween.kill()
	
	var music: AudioStreamPlayer = AudioGlobal.get_node("Music")
	var stream_interactive: AudioStreamInteractive = music.stream
	var synchronized_music_level: AudioStreamSynchronized = stream_interactive.get_clip_stream(1)
	
	# Stream index 1 = Bells
	var stream_vol = synchronized_music_level.get_sync_stream_volume(1)
	#synchronized_music_level.set_sync_stream_volume(1, -6)
	
	_tween = create_tween()
	_tween.tween_method(
		func(vol: float): synchronized_music_level.set_sync_stream_volume(1, vol),
		stream_vol,
		-6,
		5
	)
	

func control_point_friendly() -> void:
	# Stop the previous tween if it's still running
	if _tween.is_valid():
		_tween.kill()
	
	var music: AudioStreamPlayer = AudioGlobal.get_node("Music")
	var stream_interactive: AudioStreamInteractive = music.stream
	var synchronized_music_level: AudioStreamSynchronized = stream_interactive.get_clip_stream(1)
	
	# Stream index 1 = Bells
	var stream_vol = synchronized_music_level.get_sync_stream_volume(1)
	#synchronized_music_level.set_sync_stream_volume(1, -60)
	
	_tween = create_tween()
	_tween.tween_method(
		func(vol: float): synchronized_music_level.set_sync_stream_volume(1, vol),
		stream_vol,
		-60,
		5
	)
