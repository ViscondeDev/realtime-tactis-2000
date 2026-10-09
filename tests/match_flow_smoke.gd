extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_scene: PackedScene = load("res://game.tscn") as PackedScene
	var game: Node2D = game_scene.instantiate() as Node2D
	root.add_child(game)
	await process_frame
	game.call("_begin_load")

	var attempts: int = 0
	while game.get("_match_level") == null and attempts < 300:
		await process_frame
		attempts += 1
	var level: Node2D = game.get("_match_level") as Node2D
	if level == null:
		push_error("Threaded level loading did not produce a match level.")
		quit(1)
		return

	var controller: MatchController = game.get("_match_controller") as MatchController
	var yellow_unit: Unit = null
	for node: Node in get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if is_instance_valid(unit) and unit.team == Unit.Team.YELLOW:
			yellow_unit = unit
			break
	if controller == null or yellow_unit == null:
		push_error("Loaded level is missing the match controller or yellow units.")
		quit(1)
		return
	if yellow_unit.get_node_or_null("Rendering/UnitShapeRenderer/ShapeTool") == null:
		push_error("Unit body ShapeTool is missing from the unit scene tree.")
		quit(1)
		return
	for shape_node_name: String in ["GoalMarkerShapes", "PathDotShapes1", "PathDotShapes2", "PathDotShapes3"]:
		if yellow_unit.get_node_or_null("Rendering/UnitPathRenderer/" + shape_node_name) == null:
			push_error("Unit path ShapeTool '%s' is missing from the unit scene tree." % shape_node_name)
			quit(1)
			return
	for shape_node_path: String in [
		"ControlPoint/ShapeTool",
		"RespawnPoints/Yellow/ShapeTool",
		"UnitCommandController/ShapeTool",
		"HealthDispenser3/ConstructionShapeTool",
		"HealthDispenser3/BuiltShapeTool",
	]:
		if level.get_node_or_null(shape_node_path) == null:
			push_error("Level ShapeTool '%s' is missing from the level scene tree." % shape_node_path)
			quit(1)
			return

	controller.queue_player_order(yellow_unit, yellow_unit.global_position + Vector2(100.0, 0.0))
	if yellow_unit.unit_movement.has_active_move_order():
		push_error("A countdown order executed before the match started.")
		quit(1)
		return

	controller._process(5.1)
	if controller.phase != MatchController.Phase.ACTIVE or not yellow_unit.unit_movement.has_active_move_order():
		push_error("Countdown completion did not activate queued orders.")
		quit(1)
		return

	controller._finish_match(Unit.Team.YELLOW)
	if absf(float(game.get("enemy_issue_delay_seconds")) - 1.5) > 0.001:
		push_error("A yellow win did not reduce the next-match AI delay by one second.")
		quit(1)
		return
	var match_hud: MatchHUD = game.get("_match_hud") as MatchHUD
	match_hud._process(0.0)
	var return_button: Button = match_hud.get_node("Root/ReturnToMenu") as Button
	if not return_button.visible:
		push_error("The return-to-menu button is not visible after match completion.")
		quit(1)
		return
	var previous_goal: Vector2 = yellow_unit.unit_movement.get_player_move_goal()
	controller.queue_player_order(yellow_unit, yellow_unit.global_position + Vector2(500.0, 0.0))
	if yellow_unit.unit_movement.get_player_move_goal() != previous_goal:
		push_error("A player order changed after match completion.")
		quit(1)
		return
	var command_controller: UnitCommandController = level.find_child("UnitCommandController", true, false) as UnitCommandController
	command_controller._unhandled_input(InputEventMouseButton.new())
	if command_controller.get("_dragged_unit") != null:
		push_error("Player input remained active after match completion.")
		quit(1)
		return
	var respawn_controller: UnitRespawnController = level.find_child("UnitRespawnController", true, false) as UnitRespawnController
	if respawn_controller.get("_respawns_enabled"):
		push_error("Respawns remained enabled after match completion.")
		quit(1)
		return
	var red_unit: Unit = null
	for node: Node in get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		var unit: Unit = node as Unit
		if is_instance_valid(unit) and unit.team == Unit.Team.RED:
			red_unit = unit
			break
	var projectile_pool: UnitProjectilePool = level.find_child("ProjectilePool", true, false) as UnitProjectilePool
	var behavior: UnitAutonomousBehavior = red_unit.unit_autonomous_behavior
	var projectile_count: int = (projectile_pool.get("_active_projectiles") as Array).size()
	behavior._fire_round(yellow_unit, 1.0)
	if (projectile_pool.get("_active_projectiles") as Array).size() != projectile_count:
		push_error("A losing-side unit launched a shot after the result.")
		quit(1)
		return

	return_button.pressed.emit()
	await process_frame
	if game.get_node("MatchContainer").get_child_count() != 0:
		push_error("The return-to-menu button did not remove the loaded match.")
		quit(1)
		return
	if not game.get_node("MainMenuUI").visible:
		push_error("The main menu remained hidden after using the return button.")
		quit(1)
		return
	game.call("_on_match_finished", Unit.Team.RED)
	if absf(float(game.get("enemy_issue_delay_seconds")) - 2.5) > 0.001:
		push_error("A red win did not increase the next-match AI delay by one second.")
		quit(1)
		return
	for _index: int in range(5):
		game.call("_on_match_finished", Unit.Team.RED)
	if absf(float(game.get("enemy_issue_delay_seconds")) - 5.0) > 0.001:
		push_error("Enemy AI delay did not clamp at five seconds.")
		quit(1)
		return
	for _index: int in range(10):
		game.call("_on_match_finished", Unit.Team.YELLOW)
	if absf(float(game.get("enemy_issue_delay_seconds"))) > 0.001:
		push_error("Enemy AI delay did not clamp at zero seconds.")
		quit(1)
		return
	var timer: Timer = game.get("_result_return_timer") as Timer
	timer.wait_time = 0.01
	var temporary_match: Node2D = Node2D.new()
	game.get_node("MatchContainer").add_child(temporary_match)
	game.call("_on_match_finished", Unit.Team.RED)
	await timer.timeout
	await process_frame
	if game.get_node("MatchContainer").get_child_count() != 0 or not game.get_node("MainMenuUI").visible:
		push_error("The automatic result timer did not return to the main menu.")
		quit(1)
		return

	print("Match flow smoke test passed.")
	quit(0)