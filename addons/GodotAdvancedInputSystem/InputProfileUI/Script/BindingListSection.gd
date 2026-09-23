@tool
extends ScrollContainer

# --- SCENE PRELOADS ---
const BINDING_ROW_SCENE = preload("res://addons/GodotAdvancedInputSystem/InputProfileUI/Scene/BindingListRow.tscn")


# --- HEAD NODE ---
@onready var head: Control = $"../../../.."

# --- CHILD NODES ---
@onready var add_binding_btn: Button = $"RightPanel/RightHeader/Add Bindings"
@onready var binding_container: VBoxContainer = $"RightPanel/Scroll Container/ContentList"

# --- STATE ---

var current_bindings: InputBindings

var active_row : Control = null

func _ready() -> void:
	add_binding_btn.pressed.connect(_on_add_binding_pressed)
	if Engine.is_editor_hint() and add_binding_btn.icon == null:
		add_binding_btn.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")



func _rebuild_section(Inbindings : InputBindings)->void:
	add_binding_btn.disabled = (Inbindings  == null)
	current_bindings = Inbindings 
	for child in binding_container.get_children():
		child.queue_free()
	
	if not Inbindings:
		return
	
	for item in Inbindings._bindings:
		var binding_row := BINDING_ROW_SCENE.instantiate()
		
		binding_row.row_deleted.connect(_on_binding_row_deleted)
		binding_row.child_row_selected.connect(_on_modifier_selected)
		binding_container.add_child(binding_row)
		
		binding_row._setup(item, head)

func _on_binding_row_deleted(row : Control)->void:
	current_bindings._bindings.remove_at(row.get_index())
	head._save_bindings()


func _on_modifier_selected(selected : Control)->void:
	if active_row!=null:
		active_row.set_selected(false)
	
	active_row = selected
	
	active_row.set_selected(true)


func _on_add_binding_pressed() -> void:
	var binding_row := BINDING_ROW_SCENE.instantiate()
	
	binding_container.add_child(binding_row)
	
	binding_row.row_deleted.connect(_on_binding_row_deleted)
	binding_row.child_row_selected.connect(_on_modifier_selected)
	
	var row_data : InputBindings.InputMetadataAndModifiers = InputBindings.InputMetadataAndModifiers.new()
	current_bindings._bindings.append(row_data)
	
	binding_row._setup(row_data, head)
	
	head._save_bindings()
