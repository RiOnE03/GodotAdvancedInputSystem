extends MarginContainer




signal input_updated(old_input: InputMetadata, new_input: InputMetadata)

const input_display_row_script:= preload("res://Input_System_Demo/Settings/Script/input_displayer_row.gd")

const warning_window_scene:= preload("res://Input_System_Demo/Settings/Scene/InvalidInputWindow.tscn")

@export var acceptible_input_types: Array[input_display_row_script.InputTypes]

@export var apply_changes: Button
@export var reset: Button


@export var focus: Control

var effecting_profiles: Array[InputProfile]

var new_slot: Dictionary
var current_slot: Dictionary

func _ready() -> void:
	for child in find_children("*"):
		if child.has_signal("Invalid_input"):
			child.acceptable_input_types = acceptible_input_types
			child.input_updated.connect(_input_updated)
			new_slot[child] = child.default_metadata
			current_slot[child] = child.default_metadata
	apply_changes.pressed.connect(_apply_changes)
	reset.pressed.connect(_reset_to_default)


func _input_updated(node: Control, input: InputMetadata)->void:
	new_slot[node] = input
	for child in new_slot:
		if child == node:
			continue
		var holding_input: InputMetadata = child.current_input_metadata
		if holding_input and holding_input.is_same_metadata(input):
			child.current_input_metadata = null
			new_slot[child] = null
	if focus:
		node.grab_row_focus()

func selected()->void:
	if focus:
		focus.grab_row_focus()

func _get_base_control(control: Node)->Node:
	var root: Node = get_tree().root
	if not control or control is CanvasLayer or control == root:
		return control
	return _get_base_control(control.get_parent())

# When pressed "Apply Changes" button
func _apply_changes()->void:
	for child in new_slot:
		if child.current_input_metadata == null:
			var parent: Node = _get_base_control(self)
			if parent:
				var warning: Control = warning_window_scene.instantiate()
				warning.set_text("All inputs are not provided!")
				warning.destroyed.connect(func(): selected())
				parent.add_child(warning)
			return
	for child in new_slot:
		for profile in effecting_profiles:
			profile.replace_metadata_for_all_actions(current_slot[child], new_slot[child])
		input_updated.emit(current_slot[child], new_slot[child])
	current_slot = new_slot.duplicate()

# When returning to the game from the key remapping
func cancel_changes()->void:
	for child in current_slot:
		child.current_input_metadata = current_slot[child]



# When pressed "Reset to default" button
func _reset_to_default()->void:
	for child in new_slot:
		var metadata: InputMetadata = child.default_metadata
		for profile in effecting_profiles:
			profile.replace_metadata_for_all_actions(current_slot[child], metadata)
		new_slot[child] = metadata
		current_slot[child] = metadata
		child.current_input_metadata = metadata
		input_updated.emit(current_slot[child], metadata)
