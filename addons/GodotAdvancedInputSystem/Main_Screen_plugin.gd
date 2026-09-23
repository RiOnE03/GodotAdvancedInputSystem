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
	
	EditorInterface.get_editor_main_screen().add_child(plugin_instance)

	_make_visible(false)

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	if plugin_instance:
		plugin_instance.queue_free()

# ==========================================
# MAIN SCREEN VIRTUAL OVERRIDES
# ==========================================
func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if plugin_instance:
		plugin_instance.visible = visible

func _get_plugin_name() -> String:
	return "Input Profiles"


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
		if plugin_instance and res.resource_path != "":
			plugin_instance.load_profile(object)
			
			EditorInterface.set_main_screen_editor("Input Profiles")
