@tool
extends PanelContainer


signal row_deleted(row : Control)
signal child_row_selected(row : Control)

# --- SCENE PRELOADS ---
const MODIFIER_ROW_SCENE = preload("res://addons/GodotAdvancedInputSystem/InputProfileUI/Scene/SelectableRow.tscn")
const INPUT_SELECTOR_SCENE = preload("res://addons/GodotAdvancedInputSystem/InputSelectorUI/Scene/InputUISelector.tscn")

@onready var expand_btn : Button = $MarginContainer/VBoxContainer/HBoxContainer/Expand
@onready var input_selector : PanelContainer = $MarginContainer/VBoxContainer/HBoxContainer/InputSelector
@onready var add_modifers : Button = $"MarginContainer/VBoxContainer/HBoxContainer/Add Modifier"
@onready var delete_row : Button = $MarginContainer/VBoxContainer/HBoxContainer/Delete
@onready var InputName: Label = $MarginContainer/VBoxContainer/HBoxContainer/InputSelector/InputName
@onready var modifiers_container : VBoxContainer = $MarginContainer/VBoxContainer/MarginContainer/SideEffect/gap/Modifier_container


var current_input: InputBindings.InputMetadataAndModifiers = null


@onready var icon_collapsed = get_theme_icon("GuiTreeArrowRight", "EditorIcons")
@onready var icon_expanded = get_theme_icon("GuiTreeArrowDown", "EditorIcons")

var head: Control

func _setup(data : InputBindings.InputMetadataAndModifiers, Inhead: Control)->void:
	head = Inhead
	current_input = data
	_on_input_changed(current_input.binded_input)
	for modifier in current_input.modifiers:
		var new_row := MODIFIER_ROW_SCENE.instantiate()
		
		modifiers_container.add_child(new_row)
		
		new_row.resource_picker.base_type = "InputModifier"
		new_row.resource_picker.edited_resource = modifier
		
		new_row.row_selected.connect(_on_modifier_row_selected)
		new_row.row_deleted.connect(_on_modifier_row_deleted)
		new_row.resource_changed.connect(_on_modifier_row_resource_updated)



func _ready() -> void:
	if add_modifers.icon == null:
		add_modifers.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
	
	if delete_row.icon == null:
		delete_row.icon = get_theme_icon("clear", "LineEdit")
	
	if expand_btn.icon != icon_collapsed:
		expand_btn.icon = icon_collapsed
		modifiers_container.hide()
	
	add_modifers.pressed.connect(_on_add_modifier_pressed)
	delete_row.pressed.connect(func(): row_deleted.emit(self); queue_free())
	expand_btn.toggled.connect(_on_expand_toggle)
	
	input_selector.mouse_entered.connect(func(): input_selector.theme_type_variation = "HoverEffect")
	input_selector.mouse_exited.connect(func(): input_selector.theme_type_variation = "")
	input_selector.gui_input.connect(_on_input_selection_pressed)

func _on_expand_toggle(toggle: bool)->void:
	if toggle:
		expand_btn.icon = icon_expanded
		modifiers_container.show()
	else:
		expand_btn.icon = icon_collapsed
		modifiers_container.hide()

func _on_input_selection_pressed(event: InputEvent)->void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var selector_instance := INPUT_SELECTOR_SCENE.instantiate()
	selector_instance.metadata_generated.connect(_on_input_changed) 
	EditorInterface.get_base_control().add_child(selector_instance)


func _on_input_changed(input_metadata: InputMetadata)->void:
	current_input.binded_input = input_metadata
	if input_metadata:
		InputName.text = input_metadata.CategoryName + ": " + input_metadata.InputName
		InputName.tooltip_text = InputName.text
	else:
		InputName.text = "None"
		InputName.tooltip_text = ""
	head._save_bindings()



func _on_add_modifier_pressed() -> void:
	var new_row := MODIFIER_ROW_SCENE.instantiate()
	modifiers_container.add_child(new_row)
	
	new_row.resource_picker.base_type = "InputModifier"
	
	new_row.row_selected.connect(_on_modifier_row_selected)
	new_row.row_deleted.connect(_on_modifier_row_deleted)
	new_row.resource_changed.connect(_on_modifier_row_resource_updated)
	
	current_input.modifiers.append(null)
	
	expand_btn.button_pressed = true
	_on_expand_toggle(true)
	
	head._save_bindings()


func _on_modifier_row_deleted(clicked_row: Control)->void:
	current_input.modifiers.remove_at(clicked_row.get_index()-1)
	head._save_bindings()




func _on_modifier_row_resource_updated(res: InputModifier , clicked_row: Control) -> void:
	current_input.modifiers[clicked_row.get_index()-1] = res
	head._save_bindings()



func _on_modifier_row_selected(clicked_row: Control) -> void:
	child_row_selected.emit(clicked_row)
