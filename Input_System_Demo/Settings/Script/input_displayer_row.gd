@tool
extends HBoxContainer

enum InputTypes{
	MOUSE_INPUT,
	KEYBOARD_INPUT,
	CONTROLLER_INPUT
}


signal Invalid_input()
signal input_updated(node: Control, input: InputMetadata)

var icon_registry: InputIconsRegistry = preload("res://Input_System_Demo/Settings/Input_to_Icons/Input-Icon mapper.tres")

@onready var input_label: Label = $InputTitle
@onready var input_button: Button = $InputKey

@export var input_name: String:
	set(value):
		input_name = value
		if input_label:
			input_label.text = value

@export var acceptable_inputs_domain: InputProvidersRegistry.variant


@export_tool_button("Select Default Input")
var select:Callable = _input_selector_popup


@export_storage var default_metadata: InputMetadata:
	set(value):
		if not Engine.is_editor_hint() and default_metadata:
			return
		default_metadata = value
		if default_metadata:
			_set_input_button(icon_registry.get_display_item(default_metadata))
		else:
			input_button.text = ""
			input_button.icon = null

var current_input_metadata: InputMetadata:
	set(value):
		current_input_metadata = value
		if value:
			_set_input_button(icon_registry.get_display_item(value))
		else:
			input_button.icon = null
			input_button.text = "..."

# This will be filled but the Key remapping window script
var acceptable_input_types: Array[InputTypes] # for filtering types that should not be allowed like screen touch

# To be filled at runtime when it'll be used again and again and creating the registry object every time is not optimal.
var input_providers_registry: InputProvidersRegistry

const input_selector_ui_path : String= "res://addons/InputManager/InputSelectorUI/Scene/InputUISelector.tscn"



func _ready() -> void:
	if input_label:
		input_label.text = input_name
	if Engine.is_editor_hint():
		default_metadata = default_metadata
		return
	input_button.pressed.connect(_start_listening)



func _setup(providers_registry: InputProvidersRegistry)->void:
	input_providers_registry = providers_registry # for actual input metadata at runtime
	current_input_metadata = default_metadata

func _set_input_button(value: Variant)->void:
	if not input_button:
		return
	if not value:
		print("Logic Error: Icon is missing in the registry.")
	if value:
		if value is String:
			input_button.icon = null
			input_button.text = value
		else:
			input_button.icon = value
			input_button.text = ""

func _input_selector_popup()->void:
	var selector: Node = load(input_selector_ui_path).instantiate()
	selector.metadata_generated.connect(func(metadata: InputMetadata): default_metadata = metadata)
	EditorInterface.get_base_control().add_child(selector)


func grab_row_focus()->void:
	input_button.grab_focus()

var listener_overlay: Control

func _get_base_control(control: Node)->Node:
	var root: Node = get_tree().root
	if not control or control is CanvasLayer or control == root:
		return control
	return _get_base_control(control.get_parent())

func _start_listening() -> void:
	var parent: Node = _get_base_control(self)
	
	if parent:
		listener_overlay = Control.new()
		parent.add_child(listener_overlay)
	else:
		return
	
	listener_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	listener_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	listener_overlay.focus_mode = Control.FOCUS_ALL
	
	listener_overlay.grab_focus()
	
	listener_overlay.gui_input.connect(listner_input)
	
	input_button.icon = null
	input_button.text = "..."

func listner_input(event: InputEvent) -> void:
	# Ignore mouse motion
	if event is InputEventMouseMotion:
		return
	InputManager.skip_event_start()
	
	listener_overlay.queue_free()
	
	if not _is_event_acceptable(event):
		print("invalid")
		Invalid_input.emit()
		return
	
	var new_metadata:InputMetadata = _get_metadata_from_event(event)
	
	if not new_metadata:
		Invalid_input.emit()
		return
	input_updated.emit(self, new_metadata)
	current_input_metadata = new_metadata
	
	var button_dislpay: Variant = icon_registry.get_display_item(current_input_metadata)
	_set_input_button(button_dislpay)
	



func _get_metadata_from_event(event: InputEvent)->InputMetadata:
	return input_providers_registry.get_metadata_from_event(event,acceptable_inputs_domain)

func _is_event_acceptable(event: InputEvent)->bool:
	for acceptable in acceptable_input_types:
		match acceptable:
			InputTypes.MOUSE_INPUT:
				if event is InputEventMouseButton:
					return true
			InputTypes.KEYBOARD_INPUT:
				if event is InputEventKey:
					return true
			InputTypes.CONTROLLER_INPUT:
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					return true
	return false
