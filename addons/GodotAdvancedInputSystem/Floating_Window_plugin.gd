@tool
extends EditorPlugin

# --- UI CONSTANTS ---
const UI_SCENE = preload("res://addons/GodotAdvancedInputSystem/InputProfileUI/Scene/InputProfileUI.tscn")
var window: Window = null

# --- AUTOLOAD CONSTANTS ---
const AUTOLOAD_NAME = "InputManager"
const AUTOLOAD_PATH = "res://addons/GodotAdvancedInputSystem/InputManager/InputManager.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	window = Window.new()
	window.title = "Input Profile Configuration"
	window.add_child(UI_SCENE.instantiate())
	window.close_requested.connect(_cancel_requested)


func _popup_requested()->void:
	if not window.get_parent():
		EditorInterface.get_base_control().add_child(window)
		window.popup_centered(Vector2(1200,900))
	else:
		window.grab_focus()


func _cancel_requested()->void:
	EditorInterface.get_base_control().remove_child(window)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	if window:
		window.queue_free()

# ==========================================
# RESOURCE HANDLING (Double-Click Support)
# ==========================================
func _handles(object: Object) -> bool:
	return object is InputProfile or object is InputIconsRegistry

var opened_mapper: Resource

func _edit(object: Object) -> void:
	if object is InputIconsRegistry:
		if object.resource_path.is_empty():
			return
		if opened_mapper and object != opened_mapper:
			opened_mapper._popped_window.queue_free()
		object._show_popup()
		return
	
	if object is InputProfile:
		var res: InputProfile = object
		if window and res.resource_path!="":
			_popup_requested()
			window.get_child(0).load_profile(object)
