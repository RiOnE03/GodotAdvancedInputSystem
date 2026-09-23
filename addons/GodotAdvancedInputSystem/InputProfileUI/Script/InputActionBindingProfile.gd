@tool
extends Control

# --- SCENE PRELOADS ---
const ACTION_ROW_SCENE = preload("res://addons/GodotAdvancedInputSystem/InputProfileUI/Scene/SelectableRow.tscn")

# --- TOP PANEL NODES ---
@onready var Editing_resource_title : Label = $Header/TopRow/Title/ProfileName
@onready var block_input_checkbox : CheckBox = $Header/TopRow/CheckBox
#@onready var apply_changes_button: Button = $Header/TopRow/ApplyChangesBtn

# --- LEFT PANEL NODES ---
@onready var add_action_btn: Button = $"Header/MarginContainer/HSplitContainer/LeftScroll/Left Panel/LeftHeader/AddButton"
@onready var action_list_container: VBoxContainer = $"Header/MarginContainer/HSplitContainer/LeftScroll/Left Panel/ContentMargin/ContentList"

# --- RIGHT PANEL NODE ---
@onready var right_panel : ScrollContainer = $Header/MarginContainer/HSplitContainer/RightScroll

# --- STATE ---
var current_profile: InputProfile = null # Currently Editing Profile
var active_action_row: Control = null # Tracks which row on the left section is selected

# --- TRACKING DUPLICATE STATE ---
var action_list: Array[InputAction]
var bindings_list: Array[InputBindings]


func _ready() -> void:
	add_action_btn.pressed.connect(_on_add_action_pressed)
	
	block_input_checkbox.toggled.connect(_checkbox_toggled)
	#apply_changes_button.pressed.connect(_save_resource)
	
	block_input_checkbox.disabled = true
	add_action_btn.disabled = true
	
	if Engine.is_editor_hint():
		_editor_settings()
		var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
		if not fs.filesystem_changed.is_connected(_on_filesystem_changed):
			fs.filesystem_changed.connect(_on_filesystem_changed)


#region UI style
const shade_effect: Gradient = preload("res://addons/GodotAdvancedInputSystem/Theme/ShadeEffect.tres")
var selected_effect: StyleBoxFlat = preload("res://addons/GodotAdvancedInputSystem/Theme/SelectedEffect.tres")
var side_effect: StyleBoxFlat = preload("res://addons/GodotAdvancedInputSystem/Theme/SideEffect.tres")

func _editor_settings()->void:
	if add_action_btn.icon == null:
		add_action_btn.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
	var base_color: Color = EditorInterface.get_editor_theme().get_color("accent_color", "Editor")
	
	selected_effect.border_color = base_color
	
	side_effect.border_color = base_color
	
	base_color.a = 1.0
	shade_effect.set_color(0, base_color)
	
	base_color.a = 0.3
	shade_effect.set_color(1, base_color)
	
	base_color.a = 0.1
	shade_effect.set_color(2, base_color)
	base_color.a = 0
	shade_effect.set_color(3, base_color)

#endregion

func _checkbox_toggled(toggle: bool)->void:
	if toggle != current_profile.block_input_propagation:
		current_profile.block_input_propagation = toggle

func _on_filesystem_changed() -> void:
	# When ANY file changes, check if our specific profile was deleted
	if current_profile:
		if not FileAccess.file_exists(current_profile.resource_path):
			load_profile(null)
			# The file was deleted.



func _save_bindings()->void:
	current_profile._bindings_list = bindings_list.duplicate()

#func _save_resource()->void:
	#if current_profile:
		#current_profile.block_input_propagation = block_input_checkbox.button_pressed
		#current_profile._action_list = action_list.duplicate()
		#current_profile._bindings_list = bindings_list.duplicate()
		#ResourceSaver.save(current_profile)



func load_profile(profile: InputProfile)->void:
	current_profile = profile
	add_action_btn.disabled = ( current_profile == null )
	block_input_checkbox.disabled = ( current_profile == null )
	Editing_resource_title.text = "None"
	block_input_checkbox.set_pressed_no_signal(false)
	right_panel._rebuild_section(null)
	
	action_list.clear()
	bindings_list.clear()
	
	for child in action_list_container.get_children():
		child.queue_free()
	
	if not profile:
		return
	
	Editing_resource_title.text = profile.resource_path.get_file().get_basename()
	block_input_checkbox.button_pressed = profile.block_input_propagation 
	action_list = current_profile._action_list.duplicate()
	bindings_list = current_profile._bindings_list.duplicate()

	for item in action_list:
		var new_row := ACTION_ROW_SCENE.instantiate()
		action_list_container.add_child(new_row)
		new_row.resource_picker.edited_resource = item
		
		new_row.row_selected.connect(_on_action_row_selected)
		new_row.row_deleted.connect(_on_action_row_deleted)
		new_row.resource_changed.connect(_on_action_row_resource_updated)


# ---------------------------------------------------------
# LEFT PANEL LOGIC
# ---------------------------------------------------------
func _on_add_action_pressed() -> void:
	var new_row := ACTION_ROW_SCENE.instantiate()
	
	action_list_container.add_child(new_row)
	
	new_row.row_selected.connect(_on_action_row_selected)
	new_row.row_deleted.connect(_on_action_row_deleted)
	new_row.resource_changed.connect(_on_action_row_resource_updated)
	
	action_list.append(null)
	bindings_list.append(InputBindings.new())
	
	# Force update
	current_profile._action_list = action_list.duplicate()
	current_profile._bindings_list = bindings_list.duplicate()
	

func _on_action_row_deleted(clicked_row: Control)->void:
	var index: int = clicked_row.get_index()
	
	action_list.remove_at(index)
	bindings_list.remove_at(index)
	
	# Force update
	current_profile._action_list = action_list.duplicate()
	current_profile._bindings_list = bindings_list.duplicate()
	
	if action_list.is_empty():
		right_panel._rebuild_section(null)




func _on_action_row_resource_updated(res: InputAction , clicked_row: Control) -> void:
	action_list[clicked_row.get_index()] = res
	current_profile._action_list = action_list.duplicate()


func _on_action_row_selected(clicked_row: Control) -> void:
	if clicked_row == active_action_row:
		return
	if active_action_row !=null:
		active_action_row.set_selected(false)
	
	active_action_row = clicked_row
	
	active_action_row.set_selected(true)
	
	var index: int = clicked_row.get_index()
	
	EditorInterface.edit_resource(action_list[index])
	
	right_panel._rebuild_section(bindings_list[index])
