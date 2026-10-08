extends Node2D

const LEVEL_DIRECTORY: String = "res://src/levels"
const MATCH_HUD_SCENE: PackedScene = preload("res://src/gameplay/match_hud.tscn")
const INITIAL_ENEMY_ISSUE_DELAY: float = 2.5
const RESULT_DISPLAY_SECONDS: float = 10.0
const MINIMUM_LOADING_SCREEN_SECONDS: float = 0.35

@onready var _match_container: Node2D = $MatchContainer
@onready var _menu_canvas: CanvasLayer = $MainMenuUI
@onready var _menu_panel: Control = $MainMenuUI/Screen/MenuCenter/MenuPanel
@onready var _loading_screen: Control = $MainMenuUI/LoadingScreen
@onready var _level_selector: OptionButton = $MainMenuUI/Screen/MenuCenter/MenuPanel/Content/LevelSelector
@onready var _start_button: Button = $MainMenuUI/Screen/MenuCenter/MenuPanel/Content/StartButton
@onready var _status_label: Label = $MainMenuUI/Screen/MenuCenter/MenuPanel/Content/StatusLabel
@onready var _loading_progress: ProgressBar = $MainMenuUI/LoadingScreen/Center/Content/Progress

var enemy_issue_delay_seconds: float = INITIAL_ENEMY_ISSUE_DELAY

var _level_paths: Array[String] = []
var _loading_path: String = ""
var _loading_elapsed_seconds: float = 0.0
var _match_level: Node2D
var _match_hud: MatchHUD
var _match_controller: MatchController
var _result_return_timer: Timer


func _ready() -> void:
	_result_return_timer = Timer.new()
	_result_return_timer.one_shot = true
	_result_return_timer.wait_time = RESULT_DISPLAY_SECONDS
	_result_return_timer.timeout.connect(_return_to_menu)
	add_child(_result_return_timer)
	_start_button.pressed.connect(_begin_load)
	_refresh_level_list()


func _process(delta: float) -> void:
	if _loading_path.is_empty():
		return
	_loading_elapsed_seconds += delta

	var load_progress: Array = []
	var load_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_loading_path, load_progress)
	if not load_progress.is_empty():
		_loading_progress.value = float(load_progress[0]) * 100.0

	match load_status:
		ResourceLoader.THREAD_LOAD_LOADED:
			if _loading_elapsed_seconds < MINIMUM_LOADING_SCREEN_SECONDS:
				return
			var loaded_path: String = _loading_path
			_loading_path = ""
			var level_scene: PackedScene = ResourceLoader.load_threaded_get(loaded_path) as PackedScene
			if level_scene == null:
				_set_loading_error("The selected level could not be opened.")
			else:
				_launch_match(level_scene)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_loading_path = ""
			_set_loading_error("Level loading failed. Choose a level and try again.")


func _refresh_level_list() -> void:
	_level_selector.clear()
	_level_paths.clear()
	var directory: DirAccess = DirAccess.open(LEVEL_DIRECTORY)
	if directory == null:
		_set_loading_error("Level directory is unavailable.")
		_start_button.disabled = true
		return

	for file_name: String in directory.get_files():
		if file_name.get_extension().to_lower() != "tscn":
			continue
		_level_paths.append(LEVEL_DIRECTORY.path_join(file_name))
	_level_paths.sort()
	for index: int in range(_level_paths.size()):
		var level_title: String = _level_paths[index].get_file().get_basename().replace("_", " ").capitalize()
		_level_selector.add_item(level_title, index)

	_start_button.disabled = _level_paths.is_empty()
	if _level_paths.is_empty():
		_status_label.text = "NO LEVELS AVAILABLE"


func _begin_load() -> void:
	if not _loading_path.is_empty() or _level_paths.is_empty():
		return
	_status_label.add_theme_color_override("font_color", Color("#9ba8a6"))
	var selected_index: int = _level_selector.get_selected_id()
	if selected_index < 0 or selected_index >= _level_paths.size():
		return

	_loading_path = _level_paths[selected_index]
	_loading_elapsed_seconds = 0.0
	_loading_progress.value = 0.0
	_loading_screen.show()
	_start_button.disabled = true
	_level_selector.disabled = true
	_status_label.text = "LOADING LEVEL  /  PLEASE WAIT"
	var request_status: Error = ResourceLoader.load_threaded_request(_loading_path, "PackedScene")
	if request_status != OK:
		_loading_path = ""
		_set_loading_error("Could not start loading the selected level.")


func _launch_match(level_scene: PackedScene) -> void:
	var level: Node2D = level_scene.instantiate() as Node2D
	if level == null:
		_set_loading_error("The selected scene is not a playable level.")
		return

	var match_controller: MatchController = level.find_child("MatchController", true, false) as MatchController
	var red_team_ai: RedTeamAI = level.find_child("RedTeamAI", true, false) as RedTeamAI
	if match_controller == null or red_team_ai == null:
		level.free()
		_set_loading_error("The selected level is missing required match systems.")
		return

	red_team_ai.issue_delay_seconds = enemy_issue_delay_seconds
	level.process_mode = Node.PROCESS_MODE_DISABLED
	var camera: Camera2D = level.find_child("YellowTeamCamera", true, false) as Camera2D
	if is_instance_valid(camera):
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
	var command_controller: UnitCommandController = level.find_child("UnitCommandController", true, false) as UnitCommandController
	if is_instance_valid(command_controller):
		command_controller.process_mode = Node.PROCESS_MODE_ALWAYS
	match_controller.match_started.connect(_on_match_started.bind(level))
	match_controller.match_finished.connect(_on_match_finished)
	_match_level = level
	_match_controller = match_controller
	_match_container.add_child(level)

	_match_hud = MATCH_HUD_SCENE.instantiate() as MatchHUD
	_match_hud.match_controller = match_controller
	_match_hud.respawn_controller = level.find_child("UnitRespawnController", true, false) as UnitRespawnController
	_match_hud.return_to_menu_requested.connect(_return_to_menu)
	_match_container.add_child(_match_hud)
	_loading_screen.hide()
	_menu_canvas.hide()


func _on_match_started(level: Node2D) -> void:
	if is_instance_valid(level):
		level.process_mode = Node.PROCESS_MODE_INHERIT


func _on_match_finished(winning_team: int) -> void:
	if winning_team == Unit.Team.YELLOW:
		enemy_issue_delay_seconds = maxf(enemy_issue_delay_seconds - 1.0, 0.0)
	else:
		enemy_issue_delay_seconds = minf(enemy_issue_delay_seconds + 1.0, 5.0)
	_status_label.text = "ENEMY ORDER DELAY  /  %.1f SECONDS" % enemy_issue_delay_seconds
	_status_label.add_theme_color_override("font_color", Color("#9ba8a6"))
	_result_return_timer.start()


func _return_to_menu() -> void:
	_result_return_timer.stop()
	for child: Node in _match_container.get_children():
		child.queue_free()
	_match_level = null
	_match_hud = null
	_match_controller = null
	_menu_canvas.show()
	_menu_panel.show()
	_level_selector.disabled = false
	_start_button.disabled = _level_paths.is_empty()
	_status_label.text = "ENEMY ORDER DELAY  /  %.1f SECONDS" % enemy_issue_delay_seconds
	_status_label.add_theme_color_override("font_color", Color("#9ba8a6"))


func _set_loading_error(message: String) -> void:
	_loading_screen.hide()
	_menu_canvas.show()
	_menu_panel.show()
	_level_selector.disabled = false
	_start_button.disabled = _level_paths.is_empty()
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("#e8594f"))