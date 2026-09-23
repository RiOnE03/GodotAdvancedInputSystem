@tool
extends EditorScript

func _run():

	var ui_scene = load("res://addons/InputManager/InputProfileUI/Scene/InputProfileUI.tscn")
	var ui_instance = ui_scene.instantiate()
	var window : Window = Window.new()
	window.add_child(ui_instance)
	EditorInterface.get_base_control().add_child(window)
	window.close_requested.connect(window.queue_free)
	window.popup_centered(Vector2(900,800))
	var res : InputProfile = InputProfile.new()
	ui_instance.load_profile(res)
