class_name UnitStatusRow
extends PanelContainer

signal unit_selected(unit: Unit)

@export var alert_style: StyleBox

const CLASS_ICONS: Array[Texture2D] = [
	preload("res://addons/at-icons/node/square.svg"),
	preload("res://addons/at-icons/node/triangle.svg"),
	preload("res://addons/at-icons/node/circle.svg"),
]
const ALERT_FLASH_HOLD_SECONDS: float = 0.12
const ALERT_FLASH_FADE_SECONDS: float = 0.32

@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _state: Label = %State
@onready var _health: ProgressBar = %Health
@onready var _health_value: Label = %HealthValue
@onready var _alert_flash: ColorRect = %AlertFlash

var _overheal_fill_style: StyleBoxFlat
var _unit: Unit
var _last_state: String = ""
var _is_alert: bool = false
var _mouse_pressed: bool = false
var _touch_pressed: bool = false
var _flash_tween: Tween


func _ready() -> void:
	gui_input.connect(_on_gui_input)


func set_unit(unit: Unit) -> void:
	_unit = unit
	_icon.texture = CLASS_ICONS[unit.unit_class]
	_title.text = "%s  /  %s" % [unit.class_definition.display_name.to_upper(), unit.name.to_upper()]
	unit.unit_health.health_changed.connect(_on_health_changed)
	unit.report_condition_changed.connect(_on_report_condition_changed)
	_on_health_changed(unit.unit_health.current_health)
	_refresh_state()


func _on_gui_input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_event.pressed:
			_mouse_pressed = true
		elif _mouse_pressed:
			_mouse_pressed = false
			_accept_selection()
		return
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null:
		if touch_event.pressed:
			_touch_pressed = true
		elif _touch_pressed:
			_touch_pressed = false
			_accept_selection()


func _accept_selection() -> void:
	if is_instance_valid(_unit):
		unit_selected.emit(_unit)
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if is_instance_valid(_unit):
		_refresh_state()


func _on_health_changed(new_health: float) -> void:
	if not is_instance_valid(_unit):
		return
	var maximum_health: float = _unit.unit_health.max_health
	_health.max_value = _unit.unit_health.overheal_max_health
	_health.value = new_health
	_health_value.text = "%d%%" % roundi(100.0 * new_health / maximum_health) if maximum_health > 0.0 else "0%"
	if new_health > maximum_health:
		_health.add_theme_stylebox_override("fill", _get_overheal_fill_style())
	else:
		_health.remove_theme_stylebox_override("fill")
	_refresh_state()


func _get_overheal_fill_style() -> StyleBoxFlat:
	if _overheal_fill_style == null:
		var fill_style: StyleBoxFlat = _health.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style != null:
			_overheal_fill_style = fill_style.duplicate()
			_overheal_fill_style.bg_color = Color(0.22, 0.82, 0.72, 1.0)
	return _overheal_fill_style


func _on_report_condition_changed(_condition: StringName, _active: bool) -> void:
	_refresh_state()


func _refresh_state() -> void:
	if not is_instance_valid(_unit):
		return
	var state_text: String
	var low_health: bool = _unit.is_report_condition_active(&"low_health")
	var outnumbered: bool = _unit.is_report_condition_active(&"outnumbered")
	var awaiting_orders: bool = _unit.is_report_condition_active(&"idle_without_order")
	if low_health:
		state_text = "LOW HEALTH"
	elif outnumbered:
		state_text = "OUTNUMBERED"
	elif awaiting_orders:
		state_text = "AWAITING ORDERS"
	elif _unit.unit_autonomous_behavior.is_building_dispenser:
		state_text = "BUILDING"
	else:
		match _unit.unit_autonomous_behavior.state:
			UnitAutonomousBehavior.State.IDLE:
				state_text = "IDLE"
			UnitAutonomousBehavior.State.MOVING:
				state_text = "MOVING"
			UnitAutonomousBehavior.State.ENGAGING:
				state_text = "ENGAGING"
	if state_text != _last_state:
		_state.text = state_text
		_last_state = state_text
	var is_alert: bool = low_health or outnumbered or awaiting_orders
	if is_alert != _is_alert:
		_is_alert = is_alert
		if is_alert:
			_flash_on_alert()
		if is_alert and alert_style != null:
			add_theme_stylebox_override("panel", alert_style)
		else:
			remove_theme_stylebox_override("panel")
		_state.add_theme_color_override("font_color", Color(0.96, 0.42, 0.35, 1.0) if low_health else Color(0.91, 0.82, 0.35, 1.0) if is_alert else Color(0.64, 0.7, 0.71, 1.0))


func _flash_on_alert() -> void:
	if is_instance_valid(_flash_tween) and _flash_tween.is_running():
		_flash_tween.kill()
	_alert_flash.visible = true
	_alert_flash.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_interval(ALERT_FLASH_HOLD_SECONDS)
	_flash_tween.tween_property(_alert_flash, "modulate:a", 0.0, ALERT_FLASH_FADE_SECONDS)
	_flash_tween.tween_callback(_hide_alert_flash)


func _hide_alert_flash() -> void:
	_alert_flash.visible = false
