@tool
extends EditorScript

func _run():

	var ui_scene = load("res://addons/GodotAdvancedInputSystem/InputSelectorUI/Scene/InputUISelector.tscn")
	var ui_instance = ui_scene.instantiate()
	
	EditorInterface.get_base_control().add_child(ui_instance)
	
	ui_instance.popup_centered(Vector2(600, 700))
