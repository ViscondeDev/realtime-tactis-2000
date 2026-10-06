class_name MatchHUD
extends CanvasLayer

const MAX_VISIBLE_REPORTS: int = 6
const PANEL_COLOR: Color = Color(0.035, 0.055, 0.065, 0.9)
const BORDER_COLOR: Color = Color(0.76, 0.84, 0.87, 0.35)

var _match_controller: Node
var _control_point: ControlPoint
var _report_list: VBoxContainer
var _progress_bar: Control
var _yellow_timer_label: Label
var _red_timer_label: Label
var _match_result_label: Label
var _reports: Array[Dictionary] = []
var _last_yellow_seconds: int = -1
var _last_red_seconds: int = -1


func _ready() -> void:
	layer = 10
	_match_controller = %MatchController
	_control_point = _find_control_point()
	_build_hud()
	for node: Node in get_tree().get_nodes_in_group(Unit.COMMANDABLE_UNITS_GROUP):
		_register_unit(node as Unit)
	var respawn_controller: UnitRespawnController = %UnitRespawnController
	if is_instance_valid(respawn_controller):
		respawn_controller.unit_spawned.connect(_register_unit)


func _process(_delta: float) -> void:
	if not is_instance_valid(_match_controller) or not is_instance_valid(_control_point):
		return

	var yellow_seconds: int = ceili(float(_match_controller.get("yellow_control_time_remaining")))
	var red_seconds: int = ceili(float(_match_controller.get("red_control_time_remaining")))
	if yellow_seconds != _last_yellow_seconds:
		_yellow_timer_label.text = _format_time(yellow_seconds)
		_last_yellow_seconds = yellow_seconds
	if red_seconds != _last_red_seconds:
		_red_timer_label.text = _format_time(red_seconds)
		_last_red_seconds = red_seconds
	_progress_bar.queue_redraw()
	var winner_team: int = int(_match_controller.get("winner_team"))
	_match_result_label.visible = winner_team >= 0
	if winner_team >= 0:
		_match_result_label.text = "%s TEAM WINS" % ("YELLOW" if winner_team == Unit.Team.YELLOW else "RED")


func _find_control_point() -> ControlPoint:
	for node: Node in get_tree().get_nodes_in_group(&"control_points"):
		var control_point: ControlPoint = node as ControlPoint
		if control_point != null:
			return control_point
	return null


func _build_hud() -> void:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var status_panel: PanelContainer = _make_panel()
	status_panel.anchor_left = 0.5
	status_panel.anchor_right = 0.5
	status_panel.offset_left = -250.0
	status_panel.offset_right = 250.0
	status_panel.offset_top = 18.0
	status_panel.offset_bottom = 88.0
	root.add_child(status_panel)

	var status_margin: MarginContainer = MarginContainer.new()
	status_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_margin.add_theme_constant_override("margin_left", 14)
	status_margin.add_theme_constant_override("margin_top", 10)
	status_margin.add_theme_constant_override("margin_right", 14)
	status_margin.add_theme_constant_override("margin_bottom", 10)
	status_panel.add_child(status_margin)
	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_theme_constant_override("separation", 12)
	status_margin.add_child(status_row)

	_yellow_timer_label = _make_timer_label(Unit.Team.YELLOW)
	status_row.add_child(_yellow_timer_label)
	_progress_bar = _make_progress_bar()
	status_row.add_child(_progress_bar)
	_red_timer_label = _make_timer_label(Unit.Team.RED)
	status_row.add_child(_red_timer_label)

	_match_result_label = Label.new()
	_match_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_match_result_label.add_theme_font_size_override("font_size", 18)
	_match_result_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_match_result_label.offset_top = 98.0
	_match_result_label.offset_bottom = 126.0
	_match_result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_match_result_label.visible = false
	root.add_child(_match_result_label)

	var report_panel: PanelContainer = _make_panel()
	report_panel.offset_left = 18.0
	report_panel.offset_top = 132.0
	report_panel.offset_right = 330.0
	report_panel.offset_bottom = 492.0
	root.add_child(report_panel)

	var report_margin: MarginContainer = MarginContainer.new()
	report_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	report_margin.add_theme_constant_override("margin_left", 14)
	report_margin.add_theme_constant_override("margin_top", 12)
	report_margin.add_theme_constant_override("margin_right", 14)
	report_margin.add_theme_constant_override("margin_bottom", 12)
	report_panel.add_child(report_margin)
	var report_column: VBoxContainer = VBoxContainer.new()
	report_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	report_column.add_theme_constant_override("separation", 8)
	report_margin.add_child(report_column)

	var report_heading: Label = Label.new()
	report_heading.text = "YELLOW // FIELD REPORTS"
	report_heading.add_theme_color_override("font_color", Color.html(Unit.TEAM_COLORS[Unit.Team.YELLOW]))
	report_heading.add_theme_font_size_override("font_size", 16)
	report_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	report_column.add_child(report_heading)
	var divider: HSeparator = HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	report_column.add_child(divider)
	_report_list = VBoxContainer.new()
	_report_list.add_theme_constant_override("separation", 10)
	_report_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	report_column.add_child(_report_list)
	_refresh_reports()


func _make_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _make_timer_label(team: Unit.Team) -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(76.0, 24.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.html(Unit.TEAM_COLORS[team]))
	label.add_theme_font_size_override("font_size", 19)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_progress_bar() -> Control:
	var bar: Control = Control.new()
	bar.custom_minimum_size = Vector2(290.0, 22.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_progress_bar.bind(bar))
	return bar


func _draw_progress_bar(bar: Control) -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO, bar.size)
	var yellow_width: float = (_control_point.capture_progress + 1.0) * 0.5 * bar.size.x
	bar.draw_rect(bounds, Color(0.08, 0.1, 0.11, 1.0))
	if yellow_width > 0.0:
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(yellow_width, bar.size.y)), Color.html(Unit.TEAM_COLORS[Unit.Team.YELLOW]))
	if yellow_width < bar.size.x:
		bar.draw_rect(Rect2(Vector2(yellow_width, 0.0), Vector2(bar.size.x - yellow_width, bar.size.y)), Color.html(Unit.TEAM_COLORS[Unit.Team.RED]))
	bar.draw_rect(bounds, BORDER_COLOR, false, 1.0)


func _register_unit(unit: Unit) -> void:
	if not is_instance_valid(unit) or unit.team != Unit.Team.YELLOW:
		return
	unit.status_reported.connect(_on_unit_status_reported.bind(unit))


func _on_unit_status_reported(report_type: StringName, active: bool, unit: Unit) -> void:
	if not is_instance_valid(unit):
		return
	var report_text: String = _describe_report(report_type, active)
	if report_text.is_empty():
		return
	_reports.push_front({"unit": unit.name, "text": report_text, "active": active})
	if _reports.size() > MAX_VISIBLE_REPORTS:
		_reports.resize(MAX_VISIBLE_REPORTS)
	_refresh_reports()


func _describe_report(report_type: StringName, active: bool) -> String:
	match report_type:
		&"low_health":
			return "Low health" if active else "Health stabilized"
		&"outnumbered":
			return "Outnumbered" if active else "Numbers even"
		&"idle_without_order":
			return "Awaiting orders" if active else "Orders received"
	return ""


func _refresh_reports() -> void:
	for child: Node in _report_list.get_children():
		_report_list.remove_child(child)
		child.queue_free()
	if _reports.is_empty():
		_report_list.add_child(_make_report_label("No field reports", false))
		return
	for report: Dictionary in _reports:
		var report_label: Label = _make_report_label("%s  /  %s" % [report["unit"], report["text"]], report["active"])
		_report_list.add_child(report_label)


func _make_report_label(text: String, active: bool) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0.0, 32.0)
	label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.92, 1.0) if active else Color(0.64, 0.7, 0.71, 1.0))
	label.add_theme_font_size_override("font_size", 14)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _format_time(total_seconds: int) -> String:
	var minutes: int = floori(float(total_seconds) / 60.0)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]