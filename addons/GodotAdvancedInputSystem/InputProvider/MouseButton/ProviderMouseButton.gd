extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"


const InputMetadataMouseButton:= preload("res://addons/GodotAdvancedInputSystem/InputProvider/MouseButton/MouseButtonMetadata.gd")


var dict: Dictionary[int, String] = {
	MOUSE_BUTTON_LEFT        : "Left Mouse Button (LMB)",
	MOUSE_BUTTON_RIGHT       : "Right Mouse Button (RMB)",
	MOUSE_BUTTON_MIDDLE      : "Middle Mouse Button (MMB)",
	MOUSE_BUTTON_XBUTTON1    : "Mouse 4 (Back)",
	MOUSE_BUTTON_XBUTTON2    : "Mouse 5 (Forward)",
	MOUSE_BUTTON_WHEEL_UP    : "Wheel UP",
	MOUSE_BUTTON_WHEEL_DOWN  : "Wheel Down",
	MOUSE_BUTTON_WHEEL_LEFT  : "Wheel Left",
	MOUSE_BUTTON_WHEEL_RIGHT : "Wheel Right",
	-1                       : "Wheel X(Horizontal)",
	-2                       : "Wheel Y(Vertical)",
	-3                       : "Wheel XY 2D"
}

func get_category_name() -> String:
	return "Mouse Button"


func get_input_list() -> Array[String]:
	return dict.values()


func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	if not (Event is InputEventMouseButton):
		return ""
	
	var input : InputEventMouseButton = Event
	
	var is_wheel: bool = input.button_index >= 4 and input.button_index <= 7
	
	match variant_type:
		variant.FLOAT:
			if is_wheel:
				var x_axis: bool = input.button_index == MOUSE_BUTTON_WHEEL_LEFT or input.button_index == MOUSE_BUTTON_WHEEL_RIGHT
				return dict[-1 if x_axis else -2]
			return ""
		variant.VECTOR:
			if is_wheel:
				return dict[-3]
			return ""

	if dict.has(input.button_index):
		return dict[input.button_index]
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	if not (Event is InputEventMouseButton):
		return null

	var input: InputEventMouseButton = Event
	
	
	var is_wheel: bool = input.button_index >= 4 and input.button_index <= 7
	
	match variant_type:
		variant.FLOAT:
			if is_wheel:
				var x_axis: bool = input.button_index == MOUSE_BUTTON_WHEEL_LEFT or input.button_index == MOUSE_BUTTON_WHEEL_RIGHT
				var index: int = -1 if x_axis else -2
				return
				return InputMetadataMouseButton.new(dict[index],get_category_name(), index)
			return null
		variant.VECTOR:
			if is_wheel:
				return InputMetadataMouseButton.new(dict[-3],get_category_name(), -3)
			return null
	
	if not dict.has(input.button_index):
		return null
	
	var Name: String = dict[input.button_index]
	return InputMetadataMouseButton.new(Name,get_category_name(), input.button_index)


func generate_metadata_from_name(Name: String) -> InputMetadata:
	var key: Variant = dict.find_key(Name)
	if key!=null:
		var button_index: MouseButton = key
		return InputMetadataMouseButton.new(Name,get_category_name(), button_index)
	return null
