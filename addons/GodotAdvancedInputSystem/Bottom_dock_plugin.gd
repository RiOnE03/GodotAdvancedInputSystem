@tool
extends EditorPlugin

# --- UI CONSTANTS ---
const UI_SCENE = preload("res://addons/GodotAdvancedInputSystem/InputProfileUI/Scene/InputProfileUI.tscn")
var plugin_instance: Control

# --- AUTOLOAD CONSTANTS ---
const AUTOLOAD_NAME = "InputManager"
const AUTOLOAD_PATH = "res://addons/GodotAdvancedInputSystem/InputManager/InputManager.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	
	plugin_instance = UI_SCENE.instantiate()
	add_control_to_bottom_panel(plugin_instance, "Input Profiles")


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	if plugin_instance:
		remove_control_from_bottom_panel(plugin_instance)
		plugin_instance.queue_free()

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
		if plugin_instance and res.resource_path!="":
			plugin_instance.load_profile(object)
			
			make_bottom_panel_item_visible(plugin_instance)
