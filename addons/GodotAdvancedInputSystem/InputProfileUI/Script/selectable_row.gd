@tool
extends PanelContainer

signal row_selected(node : Control)
signal row_deleted(node : Control)
signal resource_changed(res: InputAction , node : Control)

@export var resource_picker: EditorResourcePicker 
@onready var delete_btn: Button = $MarginContainer/Header/DeleteBtn


func _ready() -> void:
	delete_btn.icon = get_theme_icon("clear", "LineEdit")
	resource_picker.resource_changed.connect(resource_placed)
	
	delete_btn.pressed.connect(func(): row_deleted.emit(self); queue_free())

var is_selected: bool = false


func _input(event: InputEvent) -> void:
	# 1. Handle Selection (Mouse Clicks)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if get_global_rect().has_point(event.global_position):
			is_selected = true
			theme_type_variation = "SelectedEffect"
			row_selected.emit(self)
	# 2. Handle Hover (Mouse Movement)
	elif event is InputEventMouseMotion:
			
		var local_rect := Rect2(Vector2.ZERO, size)
		var is_hovering := local_rect.has_point(get_local_mouse_position())
		
		if is_hovering and theme_type_variation != "HoverEffect":
			theme_type_variation = "HoverEffect"
		if is_hovering:
			if theme_type_variation == "":
				theme_type_variation = "HoverEffect"
		else:
			theme_type_variation = "SelectedEffect" if is_selected else ""


func resource_placed(res: Resource)->void:
	resource_changed.emit(res,self)
	set_selected(true)


func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		var resource: Resource = resource_picker.edited_resource
		
		if resource != null:
			EditorInterface.edit_resource(resource)
		else:
			EditorInterface.inspect_object(null)
