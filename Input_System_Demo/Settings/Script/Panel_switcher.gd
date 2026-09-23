extends TabContainer


signal input_updated(old_input: InputMetadata, new_input: InputMetadata)

@export var profiles: Array[InputProfile]

@export var cancel_buttons: Array[Button]


var providers_registry: = InputProvidersRegistry.new()

var invalid_input_window_scene: PackedScene = preload("res://Input_System_Demo/Settings/Scene/InvalidInputWindow.tscn")

func _ready() -> void:
	set_deferred("size", Vector2(950, 550))
	position = Vector2(100,50)
	for child in find_children("*"):
		if child.has_method("_setup"):
			child._setup(providers_registry)
			child.Invalid_input.connect(_show_invalid_input_window)
	for child in get_children():
		child.effecting_profiles = profiles
		child.input_updated.connect(func(old, new): input_updated.emit(old, new))

func _get_base_control(control: Node)->Node:
	var root: Node = get_tree().root
	if not control or control is CanvasLayer or control == root:
		return control
	return _get_base_control(control.get_parent())

func _show_invalid_input_window()->void:
	var parent: Node = _get_base_control(self)
	
	if parent:
		var popup:= invalid_input_window_scene.instantiate()
		popup.destroyed.connect(func(): get_child(current_tab).selected())
		parent.add_child(popup)
	else:
		return


func cancel_changes()->void:
	for child in get_children():
		child.cancel_changes()

func _open()->void:
	for child in get_children():
		child.selected()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_tab != 1:
			current_tab = 1
			get_child(1).selected()
	elif event is InputEventMouse or event is InputEventKey:
		if current_tab != 0:
			current_tab = 0
			get_child(0).selected()
